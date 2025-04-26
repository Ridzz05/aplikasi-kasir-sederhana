import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/cart_provider.dart';
import '../providers/cached_product_provider.dart';
import '../providers/category_provider.dart';
import '../models/product.dart';
import '../models/cart_item.dart';

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
              padding: const EdgeInsets.all(16.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child:
                    product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: _buildProductImage(product.imageUrl!),
                        )
                        : Center(
                          child: Icon(
                            CupertinoIcons.cube_box,
                            size: 40,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormatter.format(product.price),
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.activeBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          product.stock > 0
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.destructiveRed,
                    ),
                  ),
                ],
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

    // Implement payment processing
    showCupertinoDialog(
      context: context,
      builder:
          (dialogCtx) => CupertinoAlertDialog(
            title: const Text('Proses Pembayaran'),
            content: const Text(
              'Fitur pembayaran akan tersedia pada versi berikutnya.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                },
              ),
            ],
          ),
    );
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
