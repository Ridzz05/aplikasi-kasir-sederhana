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
  const ProductFormScreen({Key? key}) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> with SingleTickerProviderStateMixin {
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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchProducts();
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
        if (_selectedImagePath != null && _isEditing && _editingProduct?.imageUrl != _selectedImagePath) {
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => SafeArea(
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
                title: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
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
    
    return Scaffold(
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
                width: 200,
                height: 200,
              ),
            )
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                          image: _selectedImagePath != null
                                              ? DecorationImage(
                                                  image: FileImage(File(_selectedImagePath!)),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: _isUploading
                                            ? const Center(
                                                child: CircularProgressIndicator(),
                                              )
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
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
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
                                  
                                  // Save Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _saveForm,
                                      icon: Icon(_isEditing ? Icons.update : Icons.add),
                                      label: Text(_isEditing ? 'Perbarui Produk' : 'Tambah Produk'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Products List - Only show if not editing and there are products
                        if (!_isEditing && _products.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Daftar Produk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: AnimationLimiter(
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: _products.length,
                                itemBuilder: (ctx, i) {
                                  final product = _products[i];
                                  return AnimationConfiguration.staggeredList(
                                    position: i,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      horizontalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 12, 
                                              vertical: 4
                                            ),
                                            leading: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(8),
                                                image: product.imageUrl != null
                                                    ? DecorationImage(
                                                        image: FileImage(File(product.imageUrl!)),
                                                        fit: BoxFit.cover,
                                                      )
                                                    : null,
                                              ),
                                              child: product.imageUrl == null
                                                  ? const Icon(Icons.inventory, size: 24)
                                                  : null,
                                            ),
                                            title: Text(
                                              product.name,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            subtitle: Text(
                                              'Rp ${product.price.toStringAsFixed(0)} · Stok: ${product.stock}',
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                                  onPressed: () => _prepareEdit(product),
                                                  visualDensity: VisualDensity.compact,
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () async {
                                                    // Hapus gambar jika ada
                                                    if (product.imageUrl != null) {
                                                      await ImageHelper.deleteImage(product.imageUrl);
                                                    }
                                                    
                                                    await DatabaseHelper.instance.deleteProduct(product.id!);
                                                    _fetchProducts();
                                                    
                                                    if (context.mounted) {
                                                      showCustomNotification(
                                                        context: context,
                                                        message: '${product.name} telah dihapus',
                                                        type: NotificationType.success,
                                                      );
                                                    }
                                                  },
                                                  visualDensity: VisualDensity.compact,
                                                  constraints: const BoxConstraints(),
                                                  padding: const EdgeInsets.all(8),
                                                ),
                                              ],
                                            ),
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
                      ],
                    ),
                  );
                }
              ),
            ),
    );
  }
} 