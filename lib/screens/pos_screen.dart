import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';
import '../providers/cart_provider.dart';
import '../providers/page_controller_provider.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({Key? key}) : super(key: key);

  @override
  _POSScreenState createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> with SingleTickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _showSuccess = false;
  List<Product> _products = [];
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 1)
    );
    _fetchProducts();
    _searchController.addListener(_filterProducts);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
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

  Future<void> _createTransaction() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang kosong'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if all products have enough stock
    bool sufficientStock = true;
    String insufficientStockItem = '';
    
    for (final item in cartProvider.items.values) {
      if (item.product.stock < item.quantity) {
        sufficientStock = false;
        insufficientStockItem = item.product.name;
        break;
      }
    }

    if (!sufficientStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stok ${insufficientStockItem} tidak mencukupi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create transaction
      final transaction = app_transaction.Transaction(
        date: DateTime.now(),
        totalAmount: cartProvider.totalAmount,
      );

      final transactionId = await DatabaseHelper.instance.insertTransaction(transaction);

      // 2. Create transaction items and update stock
      for (final item in cartProvider.items.values) {
        final transactionItem = TransactionItem(
          transactionId: transactionId,
          productId: item.product.id!,
          productName: item.product.name,
          productPrice: item.product.price,
          quantity: item.quantity,
          total: item.total,
        );

        await DatabaseHelper.instance.insertTransactionItem(transactionItem);
        
        // Update product stock
        await DatabaseHelper.instance.updateProductStock(item.product.id!, item.quantity);
      }

      // Clear cart
      cartProvider.clear();
      
      // Show success animation
      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
      
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _showSuccess = false;
      });

      // Refresh product list to show updated stock
      _fetchProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddProduct() {
    // Menggunakan Navbar Bottom untuk navigasi
    final pageController = Provider.of<PageControllerProvider>(context, listen: false);
    pageController.jumpToPage(1); // Index 1 adalah halaman Tambah Barang
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    
    // Success overlay
    if (_showSuccess) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/success.json',
                width: 200,
                height: 200,
                repeat: false,
              ),
              const SizedBox(height: 24),
              const Text(
                'Transaksi Berhasil!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fade().slideY(
                begin: 0.5,
                curve: Curves.easeOutBack,
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kasir'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProducts,
          ),
        ],
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
                        'assets/animations/empty_cart.json',
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
                    
                    // Product List
                    Expanded(
                      flex: 3,
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
                                    childAspectRatio: 1.1,
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
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: product.stock > 0
                                                  ? () {
                                                      cartProvider.addItem(product);
                                                      // Add small animation effect
                                                      _animationController.reset();
                                                      _animationController.forward();
                                                      
                                                      // Show snackbar
                                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(
                                                          content: Text('${product.name} ditambahkan ke keranjang'),
                                                          behavior: SnackBarBehavior.floating,
                                                          duration: const Duration(seconds: 1),
                                                        ),
                                                      );
                                                    }
                                                  : null,
                                              borderRadius: BorderRadius.circular(16),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  gradient: product.stock > 0
                                                      ? LinearGradient(
                                                          colors: [
                                                            Colors.white,
                                                            Colors.blue.shade50,
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        )
                                                      : LinearGradient(
                                                          colors: [
                                                            Colors.grey.shade200,
                                                            Colors.grey.shade300,
                                                          ],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.grey.withOpacity(0.2),
                                                      spreadRadius: 1,
                                                      blurRadius: 5,
                                                      offset: const Offset(0, 3),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(12),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (product.imageUrl != null)
                                                      Expanded(
                                                        flex: 2,
                                                        child: Center(
                                                          child: ClipRRect(
                                                            borderRadius: BorderRadius.circular(8),
                                                            child: Image.file(
                                                              File(product.imageUrl!),
                                                              fit: BoxFit.cover,
                                                              width: double.infinity,
                                                              height: 70,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    if (product.imageUrl != null)
                                                      const SizedBox(height: 8),
                                                    Text(
                                                      product.name,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      currencyFormatter.format(product.price),
                                                      style: TextStyle(
                                                        color: Theme.of(context).primaryColor,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 4,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: product.stock > 0
                                                                ? Colors.green.withOpacity(0.2)
                                                                : Colors.red.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(12),
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
                                                        const Spacer(),
                                                        Icon(
                                                          Icons.add_circle,
                                                          color: product.stock > 0
                                                              ? Theme.of(context).primaryColor
                                                              : Colors.grey,
                                                          size: 24,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
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
                    
                    // Divider
                    const Divider(height: 1),
                    
                    // Cart
                    Container(
                      color: Colors.grey[50],
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Keranjang',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                AnimatedScale(
                                  scale: _animationController.value + 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    'Total: ${currencyFormatter.format(cartProvider.totalAmount)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.25,
                              child: cartProvider.items.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Keranjang kosong',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: cartProvider.items.length,
                                      itemBuilder: (ctx, i) {
                                        final cartItem = cartProvider.items.values.toList()[i];
                                        return Slidable(
                                          key: ValueKey(cartItem.product.id),
                                          endActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            dismissible: DismissiblePane(
                                              onDismissed: () {
                                                cartProvider.removeItem(cartItem.product.id!);
                                              }
                                            ),
                                            children: [
                                              SlidableAction(
                                                onPressed: (context) {
                                                  cartProvider.removeItem(cartItem.product.id!);
                                                },
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                icon: Icons.delete,
                                                label: 'Hapus',
                                              ),
                                            ],
                                          ),
                                          child: Card(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          cartItem.product.name,
                                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Text(
                                                          '${currencyFormatter.format(cartItem.product.price)} x ${cartItem.quantity}',
                                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    currencyFormatter.format(cartItem.total),
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).primaryColor,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 16),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[200],
                                                      borderRadius: BorderRadius.circular(20),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        IconButton(
                                                          icon: const Icon(Icons.remove, size: 16),
                                                          onPressed: cartItem.quantity > 1
                                                              ? () => cartProvider.updateItemQuantity(
                                                                  cartItem.product.id!, cartItem.quantity - 1)
                                                              : () => cartProvider.removeItem(cartItem.product.id!),
                                                          padding: const EdgeInsets.all(4),
                                                          constraints: const BoxConstraints(),
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                        SizedBox(
                                                          width: 24,
                                                          child: Text(
                                                            '${cartItem.quantity}',
                                                            textAlign: TextAlign.center,
                                                            style: const TextStyle(fontSize: 14),
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.add, size: 16),
                                                          onPressed: cartItem.quantity < cartItem.product.stock
                                                              ? () => cartProvider.updateItemQuantity(
                                                                  cartItem.product.id!, cartItem.quantity + 1)
                                                              : null,
                                                          padding: const EdgeInsets.all(4),
                                                          constraints: const BoxConstraints(),
                                                          visualDensity: VisualDensity.compact,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: cartProvider.items.isEmpty ? null : _createTransaction,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Selesaikan Transaksi'),
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