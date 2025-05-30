import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/category_provider.dart';
import '../providers/cached_product_provider.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductFormScreenCupertino extends StatefulWidget {
  final Function(int)? onScreenChange;
  final Product? product;

  const ProductFormScreenCupertino({
    super.key,
    this.onScreenChange,
    this.product,
  });

  @override
  State<ProductFormScreenCupertino> createState() =>
      _ProductFormScreenCupertinoState();
}

class _ProductFormScreenCupertinoState
    extends State<ProductFormScreenCupertino> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _costPriceController = TextEditingController(); // Harga modal
  final _stockController = TextEditingController();
  final _skuController = TextEditingController(); // SKU/Kode Produk
  final _descriptionController = TextEditingController(); // Deskripsi produk
  final _barcodeController = TextEditingController(); // Barcode
  int? _selectedCategoryId;
  bool _isLoading = false;
  String? _imagePath;
  File? _imageFile;

  // Format untuk mata uang
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();

    // Load data kategori saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );

      // Pastikan kategori diload
      await categoryProvider.loadCategories();

      // Jika tidak ada kategori yang dipilih tapi ada kategori tersedia, pilih yang pertama
      if (_selectedCategoryId == null &&
          categoryProvider.categories.isNotEmpty) {
        setState(() {
          _selectedCategoryId = categoryProvider.categories.first.id;
        });
      }
    });

    if (widget.product != null) {
      _nameController.text = widget.product!.name;

      // Format harga dengan currency formatter
      _priceController.text = _currencyFormatter
          .format(widget.product!.price)
          .replaceAll('Rp ', '');

      // Format harga modal jika ada
      if (widget.product!.costPrice != null) {
        _costPriceController.text = _currencyFormatter
            .format(widget.product!.costPrice!)
            .replaceAll('Rp ', '');
      }

      _stockController.text = widget.product!.stock.toString();
      _selectedCategoryId = widget.product!.categoryId;
      _imagePath = widget.product!.imageUrl;

      // Isi field baru
      if (widget.product!.sku != null) {
        _skuController.text = widget.product!.sku!;
      }

      if (widget.product!.description != null) {
        _descriptionController.text = widget.product!.description!;
      }

      if (widget.product!.barcode != null) {
        _barcodeController.text = widget.product!.barcode!;
      }

      // Load image jika ada
      if (_imagePath != null && _imagePath!.isNotEmpty) {
        _imageFile = File(_imagePath!);
      }
    }
  }

  // Method untuk memformat input harga
  void _formatPrice(TextEditingController controller) {
    final text = controller.text;
    if (text.isEmpty) return;

    final cleanText = text.replaceAll('.', '').replaceAll(',', '');
    if (cleanText.isEmpty) return;

    final number = int.tryParse(cleanText);
    if (number == null) return;

    final formatted = NumberFormat.decimalPattern('id').format(number);

    controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  // Method untuk memilih gambar
  Future<void> _pickImage() async {
    if (!mounted) return;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: const Text('Pilih Gambar Produk'),
          message: const Text('Pilih sumber gambar'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _getImage(ImageSource.camera);
              },
              child: const Text('Kamera'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _getImage(ImageSource.gallery);
              },
              child: const Text('Galeri'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
        );
      },
    );
  }

  // Ambil gambar dari kamera atau galeri
  Future<void> _getImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        try {
          // Buat direktori jika belum ada
          final appDir = await getApplicationDocumentsDirectory();
          final productsDir = Directory('${appDir.path}/products');

          if (!await productsDir.exists()) {
            await productsDir.create(recursive: true);
          }

          // Salin gambar ke direktori aplikasi agar persisten
          final fileName =
              'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImage = await File(
            pickedFile.path,
          ).copy('${productsDir.path}/$fileName');

          setState(() {
            _imageFile = savedImage;
            _imagePath = savedImage.path;
          });
        } catch (e) {
          print('Error menyimpan gambar: $e');
          _showErrorDialog('Gagal menyimpan gambar: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      print('Error dalam mengambil gambar: $e');
      _showErrorDialog('Gagal mengambil gambar: $e');
    }
  }

  // Hapus gambar yang sudah dipilih
  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imagePath = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) return;

    if (_selectedCategoryId == null) {
      if (!mounted) return;
      await showCupertinoDialog(
        context: context,
        builder:
            (ctx) => CupertinoAlertDialog(
              title: const Text('Kategori Tidak Dipilih'),
              content: const Text('Silakan pilih kategori produk'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Ok'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Parse harga dari string terformat ke double
      final priceText = _priceController.text.replaceAll('.', '');
      final price = double.tryParse(priceText) ?? 0.0;

      // Parse harga modal jika ada
      double? costPrice;
      if (_costPriceController.text.isNotEmpty) {
        final costPriceText = _costPriceController.text.replaceAll('.', '');
        costPrice = double.tryParse(costPriceText);
      }

      // Membuat objek produk dengan data yang diinput
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text.trim(),
        price: price,
        costPrice: costPrice,
        stock: int.tryParse(_stockController.text) ?? 0,
        categoryId: _selectedCategoryId!,
        imageUrl: _imagePath,
        sku:
            _skuController.text.trim().isEmpty
                ? null
                : _skuController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        barcode:
            _barcodeController.text.trim().isEmpty
                ? null
                : _barcodeController.text.trim(),
      );

      // Menyimpan produk
      final cachedProductProvider = Provider.of<CachedProductProvider>(
        context,
        listen: false,
      );

      if (widget.product == null) {
        await cachedProductProvider.addProduct(product);
      } else {
        await cachedProductProvider.updateProduct(product);
      }

      if (!mounted) return;

      // Tampilkan notifikasi sukses
      await showCupertinoDialog(
        context: context,
        builder:
            (ctx) => CupertinoAlertDialog(
              title: const Text('Sukses'),
              content: Text(
                widget.product == null
                    ? 'Produk berhasil ditambahkan'
                    : 'Produk berhasil diperbarui',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(ctx).pop();

                    // Reset form jika ini adalah produk baru
                    if (widget.product == null) {
                      _resetForm();
                    } else if (widget.onScreenChange != null) {
                      // Jika edit produk dan ada callback, panggil callback
                      widget.onScreenChange!(0);
                    }
                  },
                ),
              ],
            ),
      );
    } catch (e) {
      // Tampilkan dialog error
      if (!mounted) return;

      await showCupertinoDialog(
        context: context,
        builder:
            (ctx) => CupertinoAlertDialog(
              title: const Text('Error'),
              content: Text('Terjadi kesalahan: ${e.toString()}'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Sukses'),
            content: Text(
              widget.product == null
                  ? 'Produk berhasil ditambahkan'
                  : 'Produk berhasil diperbarui',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (widget.product == null) {
                    _resetForm();
                  }
                },
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
    );
  }

  void _resetForm() {
    // Reset semua controller
    _nameController.clear();
    _priceController.clear();
    _costPriceController.clear();
    _stockController.clear();
    _skuController.clear();
    _descriptionController.clear();
    _barcodeController.clear();

    // Reset kategori yang dipilih
    final categoryProvider = Provider.of<CategoryProvider>(
      context,
      listen: false,
    );

    setState(() {
      // Pilih kategori default jika ada
      if (categoryProvider.categories.isNotEmpty) {
        _selectedCategoryId = categoryProvider.categories.first.id;
      } else {
        _selectedCategoryId = null;
      }

      // Reset gambar
      _imageFile = null;
      _imagePath = null;

      // Reset loading state
      _isLoading = false;
    });

    // Lepaskan fokus dari semua field
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text(
            'Simpan',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF64B5F6),
            ),
          ),
          onPressed: _saveForm,
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Gambar produk
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.systemGrey4,
                            ),
                          ),
                          child:
                              _imageFile != null
                                  ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: _removeImage,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color:
                                                  CupertinoColors.systemGrey6,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              CupertinoIcons
                                                  .clear_circled_solid,
                                              color:
                                                  CupertinoColors
                                                      .destructiveRed,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                  : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        CupertinoIcons.camera,
                                        size: 48,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Tambahkan foto produk',
                                        style: TextStyle(
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section: Informasi Dasar Produk
                      _buildSectionHeader('Informasi Dasar'),
                      const SizedBox(height: 12),

                      // Nama Produk
                      _buildFieldLabel('Nama Produk *'),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        controller: _nameController,
                        placeholder: 'Masukkan nama produk',
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SKU / Kode Produk
                      _buildFieldLabel('Kode Produk (SKU)'),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        controller: _skuController,
                        placeholder: 'Masukkan kode produk (opsional)',
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barcode
                      _buildFieldLabel('Barcode'),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        controller: _barcodeController,
                        placeholder: 'Masukkan barcode (opsional)',
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffix: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(
                              CupertinoIcons.barcode_viewfinder,
                              size: 20,
                            ),
                            onPressed: () {
                              // Implementasi scan barcode di masa depan
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Kategori
                      _buildFieldLabel('Kategori *'),
                      const SizedBox(height: 4),
                      Consumer<CategoryProvider>(
                        builder: (context, categoryProvider, child) {
                          final categories = categoryProvider.categories;

                          // Tampilkan loading jika masih memuat kategori
                          if (categoryProvider.isLoading) {
                            return Container(
                              height: 56,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                border: Border.all(
                                  color: CupertinoColors.systemGrey4,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            );
                          }

                          // Tampilkan pesan jika tidak ada kategori
                          if (categories.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                border: Border.all(
                                  color: CupertinoColors.systemGrey4,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Tidak ada kategori tersedia',
                                style: TextStyle(
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            );
                          }

                          // Gunakan kategori default jika _selectedCategoryId tidak ditemukan
                          Category selectedCategory =
                              categoryProvider.defaultCategory;
                          if (_selectedCategoryId != null) {
                            // Temukan kategori yang dipilih
                            final categoryFound = categories.firstWhere(
                              (c) => c.id == _selectedCategoryId,
                              orElse: () => categoryProvider.defaultCategory,
                            );
                            selectedCategory = categoryFound;
                          } else if (categories.isNotEmpty) {
                            // Jika tidak ada kategori yang dipilih, pilih yang pertama
                            selectedCategory = categories.first;
                            // Pastikan _selectedCategoryId terisi
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              setState(() {
                                _selectedCategoryId = selectedCategory.id;
                              });
                            });
                          }

                          return Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              border: Border.all(
                                color: CupertinoColors.systemGrey4,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: CupertinoButton(
                              padding: const EdgeInsets.all(12),
                              onPressed: () => _showCategoryPicker(categories),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedCategoryId == null
                                        ? 'Pilih kategori'
                                        : selectedCategory.name,
                                    style: TextStyle(
                                      color:
                                          _selectedCategoryId == null
                                              ? CupertinoColors.systemGrey
                                              : CupertinoColors.black,
                                    ),
                                  ),
                                  const Icon(
                                    CupertinoIcons.chevron_down,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Deskripsi
                      _buildFieldLabel('Deskripsi Produk'),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        controller: _descriptionController,
                        placeholder: 'Masukkan deskripsi produk (opsional)',
                        padding: const EdgeInsets.all(12),
                        maxLines: 3,
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section: Harga & Stok
                      _buildSectionHeader('Harga & Stok'),
                      const SizedBox(height: 12),

                      // Harga Modal
                      _buildFieldLabel('Harga Modal'),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        controller: _costPriceController,
                        placeholder: 'Masukkan harga modal',
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(12),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text('Rp'),
                        ),
                        onChanged: (value) {
                          _formatPrice(_costPriceController);
                        },
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Harga Jual
                      _buildFieldLabel('Harga Jual *'),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        controller: _priceController,
                        placeholder: 'Masukkan harga jual',
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(12),
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 12),
                          child: Text('Rp'),
                        ),
                        onChanged: (value) {
                          _formatPrice(_priceController);
                        },
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Stok
                      _buildFieldLabel('Stok *'),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        controller: _stockController,
                        placeholder: 'Masukkan jumlah stok',
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tombol Simpan
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: const Color(0xFF64B5F6),
                        borderRadius: BorderRadius.circular(8),
                        onPressed: _saveForm,
                        child: const Text(
                          'Simpan Produk',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
      ),
    );
  }

  // Helper method untuk membuat header section
  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64B5F6),
          ),
        ),
      ],
    );
  }

  // Helper method untuk membuat label field
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: CupertinoColors.systemGrey,
      ),
    );
  }

  void _showCategoryPicker(List<Category> categories) {
    // Jika tidak ada kategori, tampilkan pesan
    if (categories.isEmpty) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: const Text('Tidak Ada Kategori'),
              content: const Text(
                'Belum ada kategori tersedia. Silakan tambahkan kategori terlebih dahulu.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
      );
      return;
    }

    // Simpan nilai sementara untuk kategori yang dipilih
    int? tempSelectedId = _selectedCategoryId;

    // Jika belum ada kategori yang dipilih, gunakan kategori pertama
    if (tempSelectedId == null && categories.isNotEmpty) {
      tempSelectedId = categories.first.id;
    }

    // Cari indeks kategori yang dipilih
    int initialIndex = 0;
    if (tempSelectedId != null) {
      final index = categories.indexWhere((c) => c.id == tempSelectedId);
      if (index >= 0) {
        initialIndex = index;
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => Container(
            height: 300,
            color: CupertinoTheme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                // Header dengan tombol
                Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    border: Border(
                      bottom: BorderSide(
                        color: CupertinoColors.systemGrey5,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          // Batalkan perubahan dengan tidak menyimpan nilai tempSelectedId
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                      ),
                      const Text(
                        'Pilih Kategori',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () {
                          // Simpan perubahan
                          setState(() {
                            _selectedCategoryId = tempSelectedId;
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Selesai',
                          style: TextStyle(color: CupertinoColors.activeBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                // Wheel picker
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: CupertinoColors.white,
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: initialIndex,
                    ),
                    onSelectedItemChanged: (index) {
                      // Perubahan hanya disimpan ke variabel sementara
                      tempSelectedId = categories[index].id;
                    },
                    children:
                        categories
                            .map(
                              (category) => Center(
                                child: Text(
                                  category.name,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                // Tambahkan padding di bawah pada perangkat dengan home indicator
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
    );
  }
}
