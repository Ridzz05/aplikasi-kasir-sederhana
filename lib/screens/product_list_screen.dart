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

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  bool _isLoading = false;
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterProducts() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredProducts = List.from(_products);
      });
      return;
    }
    
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await DatabaseHelper.instance.getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = List.from(products);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddProduct() {
    final pageController = Provider.of<PageControllerProvider>(context, listen: false);
    pageController.jumpToPage(1); // Index 1 adalah halaman Tambah Barang
  }

  void _navigateToCart() {
    final pageController = Provider.of<PageControllerProvider>(context, listen: false);
    pageController.jumpToPage(0); // Index 0 adalah halaman Kasir
  }

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stok kosong'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(product);
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} ditambahkan ke keranjang'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Lihat Keranjang',
          onPressed: _navigateToCart,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final cartProvider = Provider.of<CartProvider>(context);
    
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProduct,
        child: const Icon(Icons.add),
        tooltip: 'Tambah Barang',
      ),
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
                width: 200,
                height: 200,
              ),
            )
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        'assets/animations/empty_box.json',
                        width: 200,
                        height: 200,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Belum ada barang',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddProduct,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Barang'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari barang...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
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
                    
                    // Products Grid
                    Expanded(
                      child: Padding(
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
                                Text('${_filteredProducts.length} item'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: AnimationLimiter(
                                child: GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.8,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                  ),
                                  itemCount: _filteredProducts.length,
                                  itemBuilder: (ctx, i) {
                                    final product = _filteredProducts[i];
                                    return AnimationConfiguration.staggeredGrid(
                                      position: i,
                                      duration: const Duration(milliseconds: 375),
                                      columnCount: 2,
                                      child: SlideAnimation(
                                        child: FadeInAnimation(
                                          child: Card(
                                            elevation: 2,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: InkWell(
                                              onTap: () => _addToCart(product),
                                              splashColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  // Product Image (1:1 ratio)
                                                  Stack(
                                                    children: [
                                                      AspectRatio(
                                                        aspectRatio: 1,
                                                        child: ClipRRect(
                                                          borderRadius: const BorderRadius.only(
                                                            topLeft: Radius.circular(12),
                                                            topRight: Radius.circular(12),
                                                          ),
                                                          child: product.imageUrl != null
                                                              ? Image.file(
                                                                  File(product.imageUrl!),
                                                                  fit: BoxFit.cover,
                                                                )
                                                              : Container(
                                                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                                  child: Center(
                                                                    child: Icon(
                                                                      Icons.inventory_2_outlined,
                                                                      size: 40,
                                                                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                                                                    ),
                                                                  ),
                                                                ),
                                                        ),
                                                      ),
                                                      if (product.stock <= 0)
                                                        Positioned.fill(
                                                          child: Container(
                                                            decoration: BoxDecoration(
                                                              color: Colors.black.withOpacity(0.5),
                                                              borderRadius: const BorderRadius.only(
                                                                topLeft: Radius.circular(12),
                                                                topRight: Radius.circular(12),
                                                              ),
                                                            ),
                                                            child: const Center(
                                                              child: Text(
                                                                'STOK HABIS',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  
                                                  // Product Details
                                                  Padding(
                                                    padding: const EdgeInsets.all(12.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          product.name,
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          currencyFormatter.format(product.price),
                                                          style: TextStyle(
                                                            color: Theme.of(context).primaryColor,
                                                            fontWeight: FontWeight.w500,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                          children: [
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                horizontal: 8,
                                                                vertical: 2,
                                                              ),
                                                              decoration: BoxDecoration(
                                                                color: product.stock > 0
                                                                    ? Colors.green.withOpacity(0.2)
                                                                    : Colors.red.withOpacity(0.2),
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                              child: Text(
                                                                'Stok: ${product.stock}',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: product.stock > 0
                                                                      ? Colors.green.shade700
                                                                      : Colors.red.shade700,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ),
                                                            if (product.stock > 0)
                                                              Container(
                                                                decoration: BoxDecoration(
                                                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: Padding(
                                                                  padding: const EdgeInsets.all(4.0),
                                                                  child: Icon(
                                                                    Icons.add_shopping_cart,
                                                                    color: Theme.of(context).primaryColor,
                                                                    size: 16,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
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
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
} 