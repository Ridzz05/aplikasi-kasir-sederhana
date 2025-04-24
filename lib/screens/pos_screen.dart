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
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 1)
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

  void _navigateToProductList() {
    // Navigasi ke halaman daftar produk
    final pageController = Provider.of<PageControllerProvider>(context, listen: false);
    pageController.jumpToPage(3); // Index 3 adalah halaman Daftar Barang
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
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
      ),
      floatingActionButton: Stack(
        children: [
          FloatingActionButton.extended(
            onPressed: _navigateToProductList,
            icon: const Icon(Icons.grid_view),
            label: const Text('Lihat Barang'),
          ),
          if (cartProvider.itemCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
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
      body: _isLoading
          ? Center(
              child: Lottie.asset(
                'assets/animations/loading.json',
                width: 200,
                height: 200,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      child: const Text(
                        'Keranjang Belanja',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    // Cart List
                    Expanded(
                      child: cartProvider.items.isEmpty
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
                                    'Keranjang kosong',
                                    style: TextStyle(fontSize: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _navigateToProductList,
                                    icon: const Icon(Icons.shopping_bag),
                                    label: const Text('Pilih Barang'),
                                  ),
                                ],
                              ),
                            )
                          : AnimationLimiter(
                              child: ListView.builder(
                                itemCount: cartProvider.items.length,
                                itemBuilder: (ctx, i) {
                                  final cartItem = cartProvider.items.values.toList()[i];
                                  return AnimationConfiguration.staggeredList(
                                    position: i,
                                    duration: const Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      horizontalOffset: 50,
                                      child: FadeInAnimation(
                                        child: Slidable(
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
                                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Row(
                                                children: [
                                                  // Product Image (if available)
                                                  if (cartItem.product.imageUrl != null)
                                                    ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.file(
                                                        File(cartItem.product.imageUrl!),
                                                        width: 60,
                                                        height: 60,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  if (cartItem.product.imageUrl != null)
                                                    const SizedBox(width: 12),
                                                    
                                                  // Product Info
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          cartItem.product.name,
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 6),
                                                        Text(
                                                          '${currencyFormatter.format(cartItem.product.price)} x ${cartItem.quantity}',
                                                          style: TextStyle(color: Colors.grey[600]),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  
                                                  // Price and Quantity
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        currencyFormatter.format(cartItem.total),
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: Theme.of(context).primaryColor,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[200],
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
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
                                                              width: 30,
                                                              child: Text(
                                                                '${cartItem.quantity}',
                                                                textAlign: TextAlign.center,
                                                                style: const TextStyle(fontWeight: FontWeight.bold),
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

                    // Cart Summary
                    if (cartProvider.items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                AnimatedScale(
                                  scale: _animationController.value + 1,
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    currencyFormatter.format(cartProvider.totalAmount),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _createTransaction,
                                icon: const Icon(Icons.check_circle),
                                label: const Text('Selesaikan Transaksi'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
} 