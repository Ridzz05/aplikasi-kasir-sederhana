import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/cart_provider.dart';
import '../providers/cached_product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';

class POSScreenCupertino extends StatefulWidget {
  final Function(int)? onScreenChange;

  const POSScreenCupertino({super.key, this.onScreenChange});

  @override
  State<POSScreenCupertino> createState() => _POSScreenCupertinoState();
}

class _POSScreenCupertinoState extends State<POSScreenCupertino> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final productProvider = Provider.of<CachedProductProvider>(
        context,
        listen: false,
      );
      await productProvider.loadAllProducts(forceRefresh: true);

      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      await categoryProvider.loadCategories();
    } catch (e) {
      print('Error loading products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Kasir'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.cart),
          onPressed: () => _showCart(context),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: 'Cari produk...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Quick Menu
            _buildQuickMenu(),

            // Category filter
            SizedBox(
              height: 44,
              child: Consumer<CategoryProvider>(
                builder: (context, categoryProvider, child) {
                  final categories = categoryProvider.categories;

                  if (categories.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1, // +1 for "Semua" option
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      // First item is "All categories"
                      if (index == 0) {
                        return _buildCategoryChip(
                          'Semua',
                          isSelected: _selectedCategoryId == null,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = null;
                            });
                          },
                        );
                      }

                      final category = categories[index - 1];
                      return _buildCategoryChip(
                        category.name,
                        isSelected: _selectedCategoryId == category.id,
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),

            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CupertinoActivityIndicator())
                      : _buildProductGrid(context),
            ),
            _buildCartSection(context),
          ],
        ),
      ),
    );
  }

  // Widget untuk quick menu
  Widget _buildQuickMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildQuickMenuItem(
            icon: CupertinoIcons.cart_badge_plus,
            label: 'Tambah',
            color: CupertinoColors.activeBlue,
            onTap: () {
              if (widget.onScreenChange != null) {
                widget.onScreenChange!(1); // Ganti ke tab produk
              }
            },
          ),
          _buildQuickMenuItem(
            icon: CupertinoIcons.barcode_viewfinder,
            label: 'Scan',
            color: CupertinoColors.activeGreen,
            onTap: () {
              // Placeholder untuk fungsi scan barcode
              showCupertinoDialog(
                context: context,
                builder:
                    (ctx) => CupertinoAlertDialog(
                      title: const Text('Scan Barcode'),
                      content: const Text(
                        'Fitur scan barcode akan segera hadir',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
              );
            },
          ),
          _buildQuickMenuItem(
            icon: CupertinoIcons.money_dollar_circle,
            label: 'Transaksi',
            color: CupertinoColors.systemIndigo,
            onTap: () {
              if (widget.onScreenChange != null) {
                widget.onScreenChange!(2); // Ganti ke tab transaksi
              }
            },
          ),
          _buildQuickMenuItem(
            icon: CupertinoIcons.star,
            label: 'Favorit',
            color: CupertinoColors.systemOrange,
            onTap: () {
              // Placeholder untuk fungsi favorit
              showCupertinoDialog(
                context: context,
                builder:
                    (ctx) => CupertinoAlertDialog(
                      title: const Text('Produk Favorit'),
                      content: const Text(
                        'Fitur produk favorit akan segera hadir',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey4,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? CupertinoColors.white : CupertinoColors.black,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(BuildContext context) {
    return Consumer<CachedProductProvider>(
      builder: (context, productProvider, child) {
        final allProducts = productProvider.products;

        // Filter products by search query and category
        final filteredProducts =
            allProducts.where((product) {
              // Filter by search query
              final matchesQuery =
                  _searchQuery.isEmpty ||
                  product.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );

              // Filter by category
              final matchesCategory =
                  _selectedCategoryId == null ||
                  product.categoryId == _selectedCategoryId;

              return matchesQuery && matchesCategory;
            }).toList();

        if (filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.cube_box,
                  size: 48,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty
                      ? 'Tidak ada produk yang sesuai dengan pencarian'
                      : 'Belum ada produk yang ditambahkan',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _loadProducts),
            SliverPadding(
              padding: const EdgeInsets.all(12.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = filteredProducts[index];
                  return _buildProductCard(product);
                }, childCount: filteredProducts.length),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10),
                  ),
                ),
                child:
                    product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10),
                          ),
                          child: _buildProductImage(product.imageUrl!),
                        )
                        : Center(
                          child: Icon(
                            CupertinoIcons.cube_box,
                            size: 30,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(product.price),
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.activeBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stok: ${product.stock}',
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            product.stock > 0
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.destructiveRed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(String imageUrl) {
    try {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Center(
            child: Icon(
              CupertinoIcons.photo,
              size: 40,
              color: CupertinoColors.systemGrey,
            ),
          );
        },
      );
    } catch (e) {
      print('Error loading image: $e');
      return Center(
        child: Icon(
          CupertinoIcons.photo,
          size: 40,
          color: CupertinoColors.systemGrey,
        ),
      );
    }
  }

  Widget _buildCartSection(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (cart.items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cart.totalItems} Item',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${currencyFormatter.format(cart.totalAmount)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                onPressed: _showCart,
                child: const Text('Lihat Keranjang'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addToCart(Product product) {
    if (!mounted) return;

    if (product.stock <= 0) {
      _showOutOfStockDialog();
      return;
    }

    final cart = Provider.of<CartProvider>(context, listen: false);
    cart.addItem(product.id!, product.name, product.price, product.imageUrl);

    // Show a quick feedback
    if (mounted) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext modalContext) {
          return CupertinoActionSheet(
            title: const Text('Produk ditambahkan ke keranjang'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  // Pastikan kita menutup action sheet terlebih dahulu
                  Navigator.of(modalContext).pop();
                  // Kemudian tampilkan keranjang
                  if (mounted) {
                    _showCart();
                  }
                },
                child: const Text('Lihat Keranjang'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(modalContext).pop();
              },
              child: const Text('Lanjut Belanja'),
            ),
          );
        },
      );
    }
  }

  void _showOutOfStockDialog([BuildContext? ctx]) {
    final localContext = ctx ?? context;
    if (!localContext.mounted) return;

    showCupertinoDialog(
      context: localContext,
      builder:
          (dialogCtx) => CupertinoAlertDialog(
            title: const Text('Stok Habis'),
            content: const Text('Maaf, produk ini sedang tidak tersedia.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
    );
  }

  void _showCart([BuildContext? ctx]) {
    // Jika widget utama tidak mounted, dan tidak ada context yang diberikan, jangan lakukan apa-apa
    if (!mounted && ctx == null) return;

    // Gunakan context yang diberikan atau context dari widget ini
    final localContext = ctx ?? context;

    // Ambil data keranjang
    final cart = Provider.of<CartProvider>(localContext, listen: false);

    // Jika keranjang kosong, tampilkan pesan
    if (cart.items.isEmpty) {
      showCupertinoDialog(
        context: localContext,
        builder:
            (dialogCtx) => CupertinoAlertDialog(
              title: const Text('Keranjang Kosong'),
              content: const Text(
                'Silakan tambahkan produk ke keranjang terlebih dahulu.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(dialogCtx).pop();
                  },
                ),
              ],
            ),
      );
      return;
    }

    // Tampilkan keranjang dengan Consumer untuk auto-update
    showCupertinoModalPopup(
      context: localContext,
      builder:
          (modalCtx) => Consumer<CartProvider>(
            builder:
                (ctx, cartData, child) => Container(
                  height: MediaQuery.of(localContext).size.height * 0.7,
                  decoration: BoxDecoration(
                    color:
                        CupertinoTheme.of(localContext).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Keranjang Belanja',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                Navigator.of(modalCtx).pop();
                              },
                              child: const Icon(CupertinoIcons.xmark_circle),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            cartData.items.isEmpty
                                ? const Center(child: Text('Keranjang kosong'))
                                : ListView.builder(
                                  itemCount: cartData.items.length,
                                  itemBuilder: (listCtx, index) {
                                    final cartItem =
                                        cartData.items.values.toList()[index];
                                    return _buildCartItemTile(
                                      cartItem,
                                      cartData,
                                      modalCtx,
                                    );
                                  },
                                ),
                      ),
                      _buildCartSummary(cartData, modalCtx),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildCartItemTile(
    CartItem cartItem,
    CartProvider cart,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product image or placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: CupertinoColors.systemGrey6,
            ),
            child:
                cartItem.imageUrl != null && cartItem.imageUrl!.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildProductImage(cartItem.imageUrl!),
                    )
                    : const Icon(
                      CupertinoIcons.cube_box,
                      color: CupertinoColors.systemGrey,
                    ),
          ),
          const SizedBox(width: 12),
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter.format(cartItem.price),
                  style: TextStyle(color: CupertinoColors.activeBlue),
                ),
              ],
            ),
          ),
          // Quantity controls
          Row(
            children: [
              // Tombol kurang
              GestureDetector(
                onTap: () {
                  // Mengurangi item langsung tanpa pengecekan stok
                  cart.removeSingleItem(cartItem.productId);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.minus,
                    size: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ),

              // Jumlah item
              Container(
                width: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${cartItem.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Tombol tambah
              GestureDetector(
                onTap: () async {
                  try {
                    // Ambil data produk untuk cek stok
                    final productProvider = Provider.of<CachedProductProvider>(
                      context,
                      listen: false,
                    );

                    final product = await productProvider.getProduct(
                      cartItem.productId,
                    );

                    if (product == null) {
                      if (context.mounted) {
                        _showErrorDialog('Produk tidak ditemukan', context);
                      }
                      return;
                    }

                    // Cek apakah stok masih tersedia
                    if (product.stock > cartItem.quantity) {
                      // Tambah item ke keranjang
                      cart.addItem(
                        cartItem.productId,
                        cartItem.title,
                        cartItem.price,
                        cartItem.imageUrl,
                      );
                    } else {
                      if (context.mounted) {
                        _showOutOfStockDialog(context);
                      }
                    }
                  } catch (e) {
                    print('Error saat menambah item: $e');
                    if (context.mounted) {
                      _showErrorDialog('Gagal menambah item: $e', context);
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.plus,
                    size: 16,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(CartProvider cart, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Summary rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal'),
              Text(currencyFormatter.format(cart.totalAmount)),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 0.5, color: CupertinoColors.systemGrey4),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              Text(
                currencyFormatter.format(cart.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () {
                // Close cart modal using context from parameter
                Navigator.of(ctx).pop();

                // Only call process payment if parent widget is still mounted
                if (mounted) {
                  // Delay sedikit untuk memastikan dialog sebelumnya sudah tertutup
                  Future.delayed(Duration(milliseconds: 300), () {
                    if (mounted) {
                      _processPayment();
                    }
                  });
                }
              },
              child: const Text('Lanjutkan ke Pembayaran'),
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    if (!mounted) return;

    final cart = Provider.of<CartProvider>(context, listen: false);

    // Tampilkan modal pembayaran dengan layout modern
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext modalContext) {
        // Controller untuk input jumlah uang diterima
        final cashController = TextEditingController();
        // Nilai kembalian yang akan dihitung
        double changeAmount = 0.0;
        // Metode pembayaran yang dipilih
        String selectedPaymentMethod = 'cash'; // Default: cash

        return StatefulBuilder(
          builder: (ctx, setState) {
            // Hitung kembalian saat input berubah
            void calculateChange() {
              final cashAmount =
                  double.tryParse(
                    cashController.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0.0;
              setState(() {
                changeAmount = cashAmount - cart.totalAmount;
              });
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: CupertinoTheme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pembayaran',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.white,
                              ),
                            ),
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: CupertinoColors.white,
                              ),
                              onPressed: () => Navigator.of(modalContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: ${currencyFormatter.format(cart.totalAmount)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content - Payment Methods
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Metode Pembayaran
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Opsi Metode Pembayaran
                            Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemGrey
                                        .withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Cash Option
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedPaymentMethod = 'cash';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedPaymentMethod == 'cash'
                                                ? CupertinoColors.systemBlue
                                                    .withOpacity(0.1)
                                                : CupertinoColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: CupertinoColors.systemGreen
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons
                                                  .money_dollar_circle,
                                              color:
                                                  CupertinoColors.systemGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Expanded(
                                            child: Text(
                                              'Tunai',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            selectedPaymentMethod == 'cash'
                                                ? CupertinoIcons
                                                    .checkmark_circle_fill
                                                : CupertinoIcons.circle,
                                            color:
                                                selectedPaymentMethod == 'cash'
                                                    ? CupertinoColors.activeBlue
                                                    : CupertinoColors
                                                        .systemGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // QRIS Option
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedPaymentMethod = 'qris';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedPaymentMethod == 'qris'
                                                ? CupertinoColors.systemBlue
                                                    .withOpacity(0.1)
                                                : CupertinoColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: CupertinoColors.systemBlue
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.qrcode,
                                              color: CupertinoColors.systemBlue,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Expanded(
                                            child: Text(
                                              'QRIS',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            selectedPaymentMethod == 'qris'
                                                ? CupertinoIcons
                                                    .checkmark_circle_fill
                                                : CupertinoIcons.circle,
                                            color:
                                                selectedPaymentMethod == 'qris'
                                                    ? CupertinoColors.activeBlue
                                                    : CupertinoColors
                                                        .systemGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Transfer Bank Option
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        selectedPaymentMethod = 'transfer';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color:
                                            selectedPaymentMethod == 'transfer'
                                                ? CupertinoColors.systemBlue
                                                    .withOpacity(0.1)
                                                : CupertinoColors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: CupertinoColors
                                                  .systemIndigo
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              CupertinoIcons.creditcard,
                                              color:
                                                  CupertinoColors.systemIndigo,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          const Expanded(
                                            child: Text(
                                              'Transfer Bank',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            selectedPaymentMethod == 'transfer'
                                                ? CupertinoIcons
                                                    .checkmark_circle_fill
                                                : CupertinoIcons.circle,
                                            color:
                                                selectedPaymentMethod ==
                                                        'transfer'
                                                    ? CupertinoColors.activeBlue
                                                    : CupertinoColors
                                                        .systemGrey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Jika pembayaran tunai, tampilkan input jumlah uang
                            if (selectedPaymentMethod == 'cash') ...[
                              const Text(
                                'Uang Diterima',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              CupertinoTextField(
                                controller: cashController,
                                placeholder: 'Masukkan jumlah uang',
                                keyboardType: TextInputType.number,
                                prefix: const Padding(
                                  padding: EdgeInsets.only(left: 12),
                                  child: Text('Rp'),
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: CupertinoColors.systemGrey4,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.all(12),
                                onChanged: (value) => calculateChange(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Kembalian:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    currencyFormatter.format(changeAmount),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          changeAmount >= 0
                                              ? CupertinoColors.activeGreen
                                              : CupertinoColors.destructiveRed,
                                    ),
                                  ),
                                ],
                              ),

                              // Tombol Cepat
                              const SizedBox(height: 16),
                              const Text(
                                'Tombol Cepat',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildQuickCashButton(
                                    '10.000',
                                    cashController,
                                    calculateChange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuickCashButton(
                                    '20.000',
                                    cashController,
                                    calculateChange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuickCashButton(
                                    '50.000',
                                    cashController,
                                    calculateChange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildQuickCashButton(
                                    '100.000',
                                    cashController,
                                    calculateChange,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildQuickCashButton(
                                    'Uang Pas',
                                    cashController,
                                    () {
                                      cashController.text = currencyFormatter
                                          .format(cart.totalAmount);
                                      calculateChange();
                                    },
                                  ),
                                ],
                              ),
                            ],

                            // QRIS - Tampilkan QR Code (Simulasi)
                            if (selectedPaymentMethod == 'qris') ...[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CupertinoColors.systemGrey
                                          .withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Scan QRIS untuk Pembayaran',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Placeholder QR code
                                    Container(
                                      width: 200,
                                      height: 200,
                                      color: CupertinoColors.systemGrey6,
                                      child: const Center(
                                        child: Icon(
                                          CupertinoIcons.qrcode,
                                          size: 100,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Total: ${currencyFormatter.format(cart.totalAmount)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Silakan scan kode QR di atas menggunakan aplikasi e-wallet atau mobile banking Anda',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Transfer Bank
                            if (selectedPaymentMethod == 'transfer') ...[
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CupertinoColors.systemGrey
                                          .withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Transfer ke Rekening Berikut:',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    _buildBankDetail(
                                      'Bank BCA',
                                      '1234567890',
                                      'Toko Saya',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildBankDetail(
                                      'Bank Mandiri',
                                      '0987654321',
                                      'Toko Saya',
                                    ),
                                    const SizedBox(height: 16),

                                    Text(
                                      'Total: ${currencyFormatter.format(cart.totalAmount)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Silakan transfer sesuai jumlah di atas dan konfirmasi pembayaran setelah transfer.',
                                      style: TextStyle(
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: () => Navigator.of(modalContext).pop(),
                              child: const Text('Batal'),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: CupertinoButton.filled(
                              padding: EdgeInsets.zero,
                              onPressed: () {
                                bool canProceed = true;

                                // Validasi berdasarkan metode pembayaran
                                if (selectedPaymentMethod == 'cash') {
                                  final cashAmount =
                                      double.tryParse(
                                        cashController.text.replaceAll(
                                          RegExp(r'[^0-9]'),
                                          '',
                                        ),
                                      ) ??
                                      0.0;
                                  canProceed = cashAmount >= cart.totalAmount;
                                }

                                if (canProceed) {
                                  // Tutup modal pembayaran
                                  Navigator.of(modalContext).pop();

                                  // Proses transaksi
                                  _completeTransaction(selectedPaymentMethod);
                                } else {
                                  // Tampilkan pesan jika uang tidak cukup
                                  showCupertinoDialog(
                                    context: context,
                                    builder:
                                        (ctx) => CupertinoAlertDialog(
                                          title: const Text('Uang Tidak Cukup'),
                                          content: const Text(
                                            'Jumlah uang yang dimasukkan kurang dari total pembayaran.',
                                          ),
                                          actions: [
                                            CupertinoDialogAction(
                                              child: const Text('OK'),
                                              onPressed:
                                                  () => Navigator.pop(ctx),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                              },
                              child: const Text('Proses Pembayaran'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget untuk tombol cepat pilihan uang tunai
  Widget _buildQuickCashButton(
    String amount,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          controller.text = amount;
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          alignment: Alignment.center,
          child: Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  // Widget untuk detail rekening bank
  Widget _buildBankDetail(
    String bankName,
    String accountNumber,
    String accountName,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemIndigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            CupertinoIcons.creditcard,
            color: CupertinoColors.systemIndigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bankName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '$accountNumber - $accountName',
                style: const TextStyle(color: CupertinoColors.systemGrey),
              ),
            ],
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            // Copy to clipboard functionality would go here
          },
          child: const Text('Salin'),
        ),
      ],
    );
  }

  // Proses menyelesaikan transaksi
  void _completeTransaction(String paymentMethod) async {
    if (!mounted) return;

    final cart = Provider.of<CartProvider>(context, listen: false);
    final productProvider = Provider.of<CachedProductProvider>(
      context,
      listen: false,
    );

    try {
      // Buat objek transaksi
      final transaction = app_transaction.Transaction(
        date: DateTime.now(),
        totalAmount: cart.totalAmount,
        paymentMethod: _getPaymentMethodName(paymentMethod),
      );

      // Buat list item transaksi
      final transactionItems =
          cart.items.values.map((cartItem) {
            return TransactionItem(
              transactionId: 0, // Ini akan diisi oleh database saat menyimpan
              productId: cartItem.productId,
              productName: cartItem.title,
              productPrice: cartItem.price,
              quantity: cartItem.quantity,
              total: cartItem.price * cartItem.quantity,
            );
          }).toList();

      // Buat list untuk update stok
      final stockUpdates =
          cart.items.values.map((cartItem) {
            return {cartItem.productId: cartItem.quantity};
          }).toList();

      // Simpan ke database
      final transactionId = await DatabaseHelper.instance.createFullTransaction(
        transaction,
        transactionItems,
        stockUpdates,
      );

      // Refresh data produk setelah update stok
      await productProvider.loadAllProducts(forceRefresh: true);

      // Tampilkan pesan sukses
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (BuildContext ctx) => CupertinoAlertDialog(
                title: const Text('Transaksi Berhasil'),
                content: Column(
                  children: [
                    const Text('Pembayaran telah berhasil diproses.'),
                    const SizedBox(height: 12),
                    Text(
                      'Total: ${currencyFormatter.format(cart.totalAmount)}',
                    ),
                    const SizedBox(height: 4),
                    Text('Metode: ${_getPaymentMethodName(paymentMethod)}'),
                    const SizedBox(height: 8),
                    Text(
                      'No. Transaksi: #${transactionId.toString().padLeft(4, '0')}',
                    ),
                  ],
                ),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Cetak Struk'),
                    onPressed: () {
                      // Handle print receipt
                      Navigator.pop(ctx);
                      // Reset cart
                      cart.clear();
                    },
                  ),
                  CupertinoDialogAction(
                    child: const Text('Selesai'),
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.pop(ctx);
                      // Reset cart
                      cart.clear();
                    },
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('Error saat menyimpan transaksi: $e');
      if (mounted) {
        _showErrorDialog('Gagal menyimpan transaksi: $e');
      }
    }
  }

  // Helper untuk mendapatkan nama metode pembayaran
  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'qris':
        return 'QRIS';
      case 'transfer':
        return 'Transfer Bank';
      default:
        return method;
    }
  }

  void _showErrorDialog(String message, [BuildContext? ctx]) {
    final localContext = ctx ?? this.context;
    if (!localContext.mounted) return;

    showCupertinoDialog(
      context: localContext,
      builder:
          (dialogCtx) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          ),
    );
  }
}
