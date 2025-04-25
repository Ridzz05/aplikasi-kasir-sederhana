import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../providers/page_controller_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/cached_product_provider.dart';
import '../widgets/custom_notification.dart';

class ProductListScreen extends StatefulWidget {
  final Function(int)? onScreenChange;
  const ProductListScreen({Key? key, this.onScreenChange}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);

    _loadProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;

      if (query.isEmpty) {
        final productProvider = Provider.of<CachedProductProvider>(
          context,
          listen: false,
        );
        _filteredProducts = productProvider.allProducts ?? [];
      } else {
        final productProvider = Provider.of<CachedProductProvider>(
          context,
          listen: false,
        );
        _filteredProducts = productProvider.filterProducts(query);
      }
    });
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final productProvider = Provider.of<CachedProductProvider>(
        context,
        listen: false,
      );
      final products = await productProvider.loadAllProducts();

      if (!mounted) return;

      setState(() {
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      showCustomNotification(
        context: context,
        message: 'Error: ${e.toString()}',
        type: NotificationType.error,
      );

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProducts() async {
    if (!mounted) return;

    try {
      final productProvider = Provider.of<CachedProductProvider>(
        context,
        listen: false,
      );
      final products = await productProvider.loadAllProducts(
        forceRefresh: true,
      );

      if (!mounted) return;

      setState(() {
        _filteredProducts = products;
      });
    } catch (e) {
      if (!mounted) return;

      showCustomNotification(
        context: context,
        message: 'Error: ${e.toString()}',
        type: NotificationType.error,
      );
    }
  }

  void _navigateToAddProduct() {
    if (widget.onScreenChange != null) {
      widget.onScreenChange!(1); // Index 1 adalah halaman Tambah Barang
    } else {
      final pageController = Provider.of<PageControllerProvider>(
        context,
        listen: false,
      );
      pageController.jumpToPage(1);
    }
  }

  void _navigateToCart() {
    if (widget.onScreenChange != null) {
      widget.onScreenChange!(0); // Index 0 adalah halaman Kasir
    } else {
      final pageController = Provider.of<PageControllerProvider>(
        context,
        listen: false,
      );
      pageController.jumpToPage(0);
    }
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      showCustomNotification(
        context: context,
        message: 'Stok produk ${product.name} kosong',
        type: NotificationType.warning,
      );
      return;
    }

    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(product);

    showCustomNotification(
      context: context,
      message: '${product.name} ditambahkan ke keranjang',
      type: NotificationType.success,
      onAction: _navigateToCart,
      actionLabel: 'Lihat Keranjang',
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (cartProvider.itemCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton.extended(
                onPressed: _navigateToCart,
                backgroundColor: const Color(0xFF64B5F6),
                foregroundColor: Colors.white,
                elevation: 4,
                heroTag: 'back_to_cart',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.shopping_cart),
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                label: const Text(
                  'Lihat Keranjang',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          FloatingActionButton(
            onPressed: _navigateToAddProduct,
            backgroundColor: const Color(0xFFFF9800), // Oranye
            foregroundColor: Colors.white,
            elevation: 4,
            heroTag: 'add_product',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.add, size: 28),
            tooltip: 'Tambah Barang',
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body:
          _isLoading
              ? Container(
                color: Colors.white.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/loading.json',
                        width: 150,
                        height: 150,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Memuat produk...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : _buildProductContent(screenSize, isSmallScreen),
    );
  }

  Widget _buildProductContent(Size screenSize, bool isSmallScreen) {
    final bool hasProducts = _filteredProducts.isNotEmpty;

    if (!hasProducts && !_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/animations/loading.json',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const Text('Belum ada barang', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Barang'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari barang...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                      : null,
            ),
          ),
        ),

        // Products Grid or Empty Results
        Expanded(
          child:
              !hasProducts && _isSearching
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada hasil untuk "${_searchController.text}"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Barang',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Text('${_filteredProducts.length} item'),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 20),
                                  onPressed: _refreshProducts,
                                  tooltip: 'Refresh',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: GridView.builder(
                            key: const PageStorageKey<String>('productGrid'),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.7,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (ctx, i) {
                              final product = _filteredProducts[i];
                              return _buildProductCard(product, ctx);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product product, BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Card(
          elevation: 3,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image (1:1 ratio)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child:
                        product.imageUrl != null
                            ? Image.file(
                              File(product.imageUrl!),
                              fit: BoxFit.cover,
                              cacheHeight: 150,
                              gaplessPlayback: true,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: const Color(0xFFF5F5F5),
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                  ),
                                );
                              },
                            )
                            : Container(
                              color: const Color(0xFFF5F5F5),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 40,
                              ),
                            ),
                  ),
                  product.stock <= 0
                      ? Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          color: Colors.black.withOpacity(0.7),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'STOK HABIS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
                ],
              ),

              // Product details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      'Rp ${currencyFormatter.format(product.price)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Stock
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color:
                              product.stock > 0
                                  ? product.stock <= 5
                                      ? Colors.orange
                                      : Theme.of(context).colorScheme.primary
                                  : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.stock > 0
                              ? 'Stok: ${product.stock}'
                              : 'Stok habis',
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                product.stock > 0
                                    ? product.stock <= 5
                                        ? Colors.orange
                                        : Colors.black87
                                    : Colors.red,
                            fontWeight:
                                product.stock <= 5
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        if (product.stock > 0 && product.stock <= 5)
                          Padding(
                            padding: const EdgeInsets.only(left: 4.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Hampir habis',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Add to cart button
                    if (product.stock > 0)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCart(product),
                          icon: const Icon(Icons.add_shopping_cart, size: 18),
                          label: const Text('Tambah'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
