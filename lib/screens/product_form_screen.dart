import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../utils/image_helper.dart';
import '../widgets/custom_notification.dart';

class ProductFormScreen extends StatefulWidget {
  final Function(int)? onScreenChange;
  const ProductFormScreen({Key? key, this.onScreenChange}) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  late AnimationController _animationController;
  bool _isLoading = false;
  List<Product> _products = [];

  Product? _editingProduct;
  bool _isEditing = false;

  String? _selectedImagePath;
  bool _isUploading = false;

  // View mode (0 = form, 1 = list)
  int _viewMode = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchProducts();
    print("ProductFormScreen initialized");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      setState(() {
        _products = products;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _stockController.clear();
    setState(() {
      _isEditing = false;
      _editingProduct = null;
      _selectedImagePath = null;
    });
  }

  void _showErrorSnackBar(String message) {
    showCustomNotification(
      context: context,
      message: message,
      type: NotificationType.error,
    );
  }

  void _prepareEdit(Product product) {
    setState(() {
      _isEditing = true;
      _editingProduct = product;
      _nameController.text = product.name;
      _priceController.text = product.price.toString();
      _stockController.text = product.stock.toString();
      _selectedImagePath = product.imageUrl;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final imagePath = await ImageHelper.pickAndProcessImage(source: source);

      if (imagePath != null) {
        // Jika sebelumnya sudah ada gambar, hapus yang lama
        if (_selectedImagePath != null &&
            _isEditing &&
            _editingProduct?.imageUrl != _selectedImagePath) {
          await ImageHelper.deleteImage(_selectedImagePath);
        }

        setState(() {
          _selectedImagePath = imagePath;
        });
      }
    } catch (e) {
      _showErrorSnackBar('Gagal mengambil gambar: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Ambil Foto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                if (_selectedImagePath != null)
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text(
                      'Hapus Gambar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedImagePath = null;
                      });
                    },
                  ),
              ],
            ),
          ),
    );
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isEditing && _editingProduct != null) {
        // Jika imageUrl berubah, hapus gambar lama
        if (_editingProduct!.imageUrl != null &&
            _selectedImagePath != _editingProduct!.imageUrl) {
          await ImageHelper.deleteImage(_editingProduct!.imageUrl);
        }

        // Update existing product
        final updatedProduct = _editingProduct!.copyWith(
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          imageUrl: _selectedImagePath,
        );
        await DatabaseHelper.instance.updateProduct(updatedProduct);

        setState(() {
          _isLoading = false;
        });

        showCustomNotification(
          context: context,
          message: 'Produk ${updatedProduct.name} berhasil diperbarui',
          type: NotificationType.success,
        );
      } else {
        // Create new product
        final product = Product(
          name: _nameController.text.trim(),
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          imageUrl: _selectedImagePath,
        );
        await DatabaseHelper.instance.insertProduct(product);

        setState(() {
          _isLoading = false;
        });

        showCustomNotification(
          context: context,
          message: 'Produk ${product.name} berhasil ditambahkan',
          type: NotificationType.success,
        );
      }

      _resetForm();

      // Refresh product list
      _fetchProducts();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    final double imageSize = isSmallScreen ? 120 : 150;

    print("Building ProductFormScreen with viewMode: $_viewMode");

    return Scaffold(
      appBar: AppBar(
        title: Text(_viewMode == 0 ? 'Tambah Barang' : 'Daftar Produk'),
        actions: [
          IconButton(
            icon: Icon(_viewMode == 0 ? Icons.list : Icons.add),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == 0 ? 1 : 0;
                // Reset form when switching to add mode
                if (_viewMode == 0 && _isEditing == false) {
                  _resetForm();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? Center(
                  child: Lottie.asset(
                    'assets/animations/loading.json',
                    width: 200,
                    height: 200,
                  ),
                )
                : _viewMode == 0
                // Form view
                ? _buildFormView(context, screenSize, isSmallScreen, imageSize)
                // List view
                : _buildListView(context),
      ),
    );
  }

  Widget _buildFormView(
    BuildContext context,
    Size screenSize,
    bool isSmallScreen,
    double imageSize,
  ) {
    print("Building form view");
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    _isEditing ? 'Edit Produk' : 'Tambah Produk Baru',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Product Image
                Center(
                  child: GestureDetector(
                    onTap: _isUploading ? null : _showImagePickerModal,
                    child: Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        image:
                            _selectedImagePath != null
                                ? DecorationImage(
                                  image: FileImage(File(_selectedImagePath!)),
                                  fit: BoxFit.cover,
                                )
                                : null,
                      ),
                      child:
                          _isUploading
                              ? const Center(child: CircularProgressIndicator())
                              : _selectedImagePath == null
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: isSmallScreen ? 32 : 40,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tambah Gambar',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Barang',
                    prefixIcon: Icon(Icons.inventory),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan nama barang';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price Field
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan harga barang';
                    }
                    try {
                      final price = double.parse(value);
                      if (price <= 0) {
                        return 'Harga harus lebih dari 0';
                      }
                    } catch (e) {
                      return 'Format harga tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Stock Field
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok',
                    prefixIcon: Icon(Icons.inventory_2),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mohon masukkan jumlah stok';
                    }
                    try {
                      final stock = int.parse(value);
                      if (stock < 0) {
                        return 'Stok tidak boleh negatif';
                      }
                    } catch (e) {
                      return 'Format stok tidak valid';
                    }
                    return null;
                  },
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),

                // Action Buttons
                Row(
                  children: [
                    if (_isEditing)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _resetForm,
                          icon: const Icon(Icons.cancel),
                          label: const Text('Batal'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    if (_isEditing) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveForm,
                        icon: Icon(_isEditing ? Icons.update : Icons.add),
                        label: Text(
                          _isEditing ? 'Perbarui Produk' : 'Tambah Produk',
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    print("Building list view with ${_products.length} products");
    return _products.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/loading.json',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada produk',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _viewMode = 0;
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah Produk'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        )
        : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${_products.length} item',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: ListView.builder(
                  key: const PageStorageKey<String>('productList'),
                  itemCount: _products.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 4),
                  itemBuilder: (ctx, i) {
                    final product = _products[i];
                    return Dismissible(
                      key: Key(product.id.toString()),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        // Konfirmasi hapus
                        return await showDialog(
                          context: context,
                          builder:
                              (ctx) => AlertDialog(
                                title: const Text(
                                  'Konfirmasi Hapus',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Yakin ingin menghapus ${product.name}?',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                contentPadding: const EdgeInsets.fromLTRB(
                                  20,
                                  10,
                                  20,
                                  0,
                                ),
                                titlePadding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  0,
                                ),
                                actionsPadding: const EdgeInsets.fromLTRB(
                                  8,
                                  0,
                                  8,
                                  8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text(
                                      'Batal',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                    onPressed:
                                        () => Navigator.of(ctx).pop(false),
                                  ),
                                  TextButton(
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                    onPressed:
                                        () => Navigator.of(ctx).pop(true),
                                  ),
                                ],
                              ),
                        );
                      },
                      onDismissed: (_) async {
                        // Hapus gambar jika ada
                        if (product.imageUrl != null) {
                          await ImageHelper.deleteImage(product.imageUrl);
                        }

                        await DatabaseHelper.instance.deleteProduct(
                          product.id!,
                        );
                        _fetchProducts();

                        if (context.mounted) {
                          showCustomNotification(
                            context: context,
                            message: '${product.name} telah dihapus',
                            type: NotificationType.success,
                          );
                        }
                      },
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      child: Card(
                        margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: InkWell(
                          onTap: () {
                            _prepareEdit(product);
                            setState(() {
                              _viewMode = 0; // Switch to form view
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Row(
                              children: [
                                // Gambar produk
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    image:
                                        product.imageUrl != null
                                            ? DecorationImage(
                                              image: FileImage(
                                                File(product.imageUrl!),
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                            : null,
                                  ),
                                  child:
                                      product.imageUrl == null
                                          ? const Icon(
                                            Icons.inventory,
                                            size: 18,
                                          )
                                          : null,
                                ),
                                const SizedBox(width: 8),

                                // Info produk
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        'Rp ${product.price.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              product.stock > 0
                                                  ? Colors.green.withOpacity(
                                                    0.2,
                                                  )
                                                  : Colors.red.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                        child: Text(
                                          'Stok: ${product.stock}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                product.stock > 0
                                                    ? Colors.green.shade700
                                                    : Colors.red.shade700,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Edit icon
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF64B5F6,
                                    ).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF64B5F6),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
  }
}
