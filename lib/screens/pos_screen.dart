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
import '../widgets/custom_notification.dart';

class POSScreen extends StatefulWidget {
  final Function(int)? onScreenChange;
  const POSScreen({super.key, this.onScreenChange});

  @override
  _POSScreenState createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen>
    with SingleTickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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
      showCustomNotification(
        context: context,
        message: 'Keranjang belanja masih kosong',
        type: NotificationType.warning,
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
      showCustomNotification(
        context: context,
        message: 'Stok $insufficientStockItem tidak mencukupi',
        type: NotificationType.error,
      );
      return;
    }

    // Show payment dialog
    final paymentResult = await _showPaymentDialog(cartProvider.totalAmount);
    if (paymentResult == null) {
      return; // User cancelled the payment process
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create transaction
      final transaction = app_transaction.Transaction(
        date: DateTime.now(),
        totalAmount: cartProvider.totalAmount,
        paymentMethod: paymentResult['paymentMethod'],
      );

      final transactionId = await DatabaseHelper.instance.insertTransaction(
        transaction,
      );

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
        await DatabaseHelper.instance.updateProductStock(
          item.product.id!,
          item.quantity,
        );
      }

      // Save transaction items for receipt
      final transactionItems = List<TransactionItem>.from(
        cartProvider.items.values.map(
          (item) => TransactionItem(
            transactionId: transactionId,
            productId: item.product.id!,
            productName: item.product.name,
            productPrice: item.product.price,
            quantity: item.quantity,
            total: item.total,
          ),
        ),
      );

      // Clear cart
      cartProvider.clear();

      setState(() {
        _isLoading = false;
      });

      // Show receipt
      if (context.mounted) {
        await _showTransactionReceipt(
          transactionId,
          transaction.date,
          transactionItems,
          transaction.totalAmount,
          paymentResult['amountPaid']!,
          paymentResult['change']!,
          paymentResult['paymentMethod']!,
        );
      }

      // Show success notification with payment info
      showCustomNotification(
        context: context,
        message: 'Transaksi berhasil disimpan',
        type: NotificationType.success,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      showCustomNotification(
        context: context,
        message: 'Error: ${e.toString()}',
        type: NotificationType.error,
      );
    }
  }

  // Payment dialog to calculate total, amount paid, and change
  Future<Map<String, dynamic>?> _showPaymentDialog(double totalAmount) async {
    final TextEditingController amountPaidController = TextEditingController();
    double? amountPaid;
    double change = 0;
    bool isAmountValid = false;
    String selectedPaymentMethod = 'Tunai';

    // Format input untuk ribuan (1000 -> 1.000)
    void formatInput() {
      String text = amountPaidController.text.replaceAll('.', '');
      if (text.isEmpty) return;

      final value = int.tryParse(text);
      if (value != null) {
        final formatter = NumberFormat('#,###', 'id');
        final formatted = formatter.format(value).replaceAll(',', '.');

        amountPaidController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    return showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void calculateChange() {
              if (amountPaidController.text.isNotEmpty) {
                try {
                  amountPaid = double.parse(
                    amountPaidController.text.replaceAll('.', ''),
                  );
                  change = amountPaid! - totalAmount;
                  isAmountValid = amountPaid! >= totalAmount;
                } catch (e) {
                  amountPaid = null;
                  change = 0;
                  isAmountValid = false;
                }
                setState(() {});
              }
            }

            return FractionallySizedBox(
              heightFactor: 0.95,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Pembayaran',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Total Amount
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.shopping_cart,
                                      color: Theme.of(context).primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Total Belanja',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          NumberFormat.currency(
                                            locale: 'id',
                                            symbol: 'Rp',
                                            decimalDigits: 0,
                                          ).format(totalAmount),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Payment Method Selection
                            const Text(
                              'Metode Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  RadioListTile<String>(
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.money,
                                          color: Colors.green.shade700,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Tunai (Cash)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Pembayaran dengan uang tunai',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    value: 'Tunai',
                                    groupValue: selectedPaymentMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedPaymentMethod = value!;
                                      });
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                  RadioListTile<String>(
                                    title: Row(
                                      children: [
                                        Icon(
                                          Icons.credit_card,
                                          color: Colors.blue.shade700,
                                          size: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Non-Tunai (Debit/QRIS)',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Pembayaran dengan kartu atau e-wallet',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    value: 'Non-Tunai',
                                    groupValue: selectedPaymentMethod,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedPaymentMethod = value!;
                                        // For non-cash, set amount paid equal to total
                                        if (value == 'Non-Tunai') {
                                          amountPaid = totalAmount;
                                          change = 0;
                                          isAmountValid = true;
                                        } else {
                                          amountPaid = null;
                                          change = 0;
                                          isAmountValid = false;
                                          amountPaidController.clear();
                                        }
                                      });
                                    },
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Amount Paid Input (only for cash)
                            if (selectedPaymentMethod == 'Tunai') ...[
                              const Text(
                                'Jumlah Dibayar',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: amountPaidController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 18),
                                onChanged: (value) {
                                  formatInput();
                                  calculateChange();
                                },
                                decoration: InputDecoration(
                                  hintText: 'Masukkan jumlah uang',
                                  prefixText: 'Rp ',
                                  prefixStyle: const TextStyle(fontSize: 18),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 20,
                                  ),
                                  errorText:
                                      amountPaid != null &&
                                              amountPaid! < totalAmount
                                          ? 'Jumlah kurang dari total belanja'
                                          : null,
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                              ),

                              // Quick Amount Buttons
                              const SizedBox(height: 20),
                              const Text(
                                'Pilihan Cepat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GridView.count(
                                crossAxisCount: 3,
                                shrinkWrap: true,
                                childAspectRatio: 2.5,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildQuickAmountButton(
                                    totalAmount,
                                    amountPaidController,
                                    () {
                                      formatInput();
                                      calculateChange();
                                    },
                                  ),
                                  _buildQuickAmountButton(
                                    totalAmount + 10000,
                                    amountPaidController,
                                    () {
                                      formatInput();
                                      calculateChange();
                                    },
                                  ),
                                  _buildQuickAmountButton(
                                    totalAmount + 20000,
                                    amountPaidController,
                                    () {
                                      formatInput();
                                      calculateChange();
                                    },
                                  ),
                                  _buildQuickAmountButton(
                                    totalAmount + 50000,
                                    amountPaidController,
                                    () {
                                      formatInput();
                                      calculateChange();
                                    },
                                  ),
                                  _buildQuickAmountButton(
                                    50000,
                                    amountPaidController,
                                    () {
                                      formatInput();
                                      calculateChange();
                                    },
                                  ),
                                  _buildQuickAmountButton(
                                    100000,
                                    amountPaidController,
                                    () {
                                      formatInput();
                                      calculateChange();
                                    },
                                  ),
                                ],
                              ),
                            ],

                            // Change Display (only for cash)
                            if (selectedPaymentMethod == 'Tunai') ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      isAmountValid
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isAmountValid
                                            ? Colors.green.withOpacity(0.3)
                                            : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            isAmountValid
                                                ? Colors.green.withOpacity(0.2)
                                                : Colors.grey.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.payments_outlined,
                                        color:
                                            isAmountValid
                                                ? Colors.green
                                                : Colors.grey,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Kembalian',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          Text(
                                            isAmountValid
                                                ? NumberFormat.currency(
                                                  locale: 'id',
                                                  symbol: 'Rp',
                                                  decimalDigits: 0,
                                                ).format(change)
                                                : '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 24,
                                              color:
                                                  isAmountValid
                                                      ? Colors.green
                                                      : Colors.grey,
                                            ),
                                          ),
                                        ],
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

                    // Footer with Actions
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
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Batal'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (selectedPaymentMethod == 'Non-Tunai' ||
                                            isAmountValid)
                                        ? Colors.green
                                        : Colors.grey,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  (selectedPaymentMethod == 'Non-Tunai' ||
                                          isAmountValid)
                                      ? () {
                                        if (selectedPaymentMethod ==
                                            'Non-Tunai') {
                                          Navigator.of(context).pop({
                                            'amountPaid': totalAmount,
                                            'change': 0,
                                            'paymentMethod':
                                                selectedPaymentMethod,
                                          });
                                        } else {
                                          Navigator.of(context).pop({
                                            'amountPaid': amountPaid!,
                                            'change': change,
                                            'paymentMethod':
                                                selectedPaymentMethod,
                                          });
                                        }
                                      }
                                      : null,
                              child: Text(
                                selectedPaymentMethod == 'Non-Tunai'
                                    ? 'Proses Pembayaran'
                                    : 'Selesai',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
            );
          },
        );
      },
    );
  }

  Widget _buildQuickAmountButton(
    double amount,
    TextEditingController controller,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: () {
        controller.text = amount.toInt().toString();
        onPressed();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Theme.of(context).primaryColor,
        elevation: 1,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Text(
        NumberFormat.currency(
          locale: 'id',
          symbol: 'Rp',
          decimalDigits: 0,
        ).format(amount),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  void _navigateToProductList() {
    if (widget.onScreenChange != null) {
      widget.onScreenChange!(3); // Index 3 adalah halaman Daftar Barang
    } else {
      // Fallback ke navigasi lama jika callback tidak tersedia
      final pageController = Provider.of<PageControllerProvider>(
        context,
        listen: false,
      );
      pageController.jumpToPage(3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      floatingActionButton:
          cartProvider.items.isNotEmpty
              ? null
              : Stack(
                children: [
                  FloatingActionButton.extended(
                    onPressed: _navigateToProductList,
                    backgroundColor: const Color(0xFF64B5F6), // Biru muda
                    foregroundColor: Colors.white,
                    elevation: 4,
                    icon: const Icon(Icons.grid_view),
                    label: const Text(
                      'Lihat Barang',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF9800), // Oranye
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
      body:
          _isLoading
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
                        child:
                            cartProvider.items.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.asset(
                                        'assets/animations/empty_cart.json',
                                        width: 200,
                                        height: 200,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Keranjang belanja kosong',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 40,
                                        ),
                                        child: Text(
                                          'Tambahkan produk ke keranjang untuk memulai transaksi',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      ElevatedButton.icon(
                                        onPressed: _navigateToProductList,
                                        icon: const Icon(Icons.shopping_bag),
                                        label: const Text('Pilih Barang'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : AnimationLimiter(
                                  child: ListView.builder(
                                    itemCount: cartProvider.items.length,
                                    itemBuilder: (ctx, i) {
                                      final cartItem =
                                          cartProvider.items.values.toList()[i];
                                      return AnimationConfiguration.staggeredList(
                                        position: i,
                                        duration: const Duration(
                                          milliseconds: 375,
                                        ),
                                        child: SlideAnimation(
                                          horizontalOffset: 50,
                                          child: FadeInAnimation(
                                            child: Dismissible(
                                              key: Key(
                                                cartItem.product.id.toString(),
                                              ),
                                              background: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade700,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                alignment:
                                                    Alignment.centerRight,
                                                padding: const EdgeInsets.only(
                                                  right: 20,
                                                ),
                                                child: const Icon(
                                                  Icons.delete_rounded,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                              confirmDismiss: (_) async {
                                                return await showDialog(
                                                  context: context,
                                                  builder:
                                                      (ctx) => AlertDialog(
                                                        title: const Text(
                                                          'Konfirmasi Hapus',
                                                        ),
                                                        content: Text(
                                                          'Hapus ${cartItem.product.name} dari keranjang?',
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                        ),
                                                        actions: <Widget>[
                                                          TextButton(
                                                            child: const Text(
                                                              'Batal',
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      ctx,
                                                                    ).pop(
                                                                      false,
                                                                    ),
                                                          ),
                                                          TextButton(
                                                            child: const Text(
                                                              'Hapus',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      ctx,
                                                                    ).pop(true),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                              },
                                              onDismissed: (_) {
                                                cartProvider.removeItem(
                                                  cartItem.product.id!,
                                                );
                                                showCustomNotification(
                                                  context: context,
                                                  message:
                                                      '${cartItem.product.name} dihapus dari keranjang',
                                                  type:
                                                      NotificationType.success,
                                                );
                                              },
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    8.0,
                                                  ),
                                                  child: ListTile(
                                                    leading: Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'Rp${NumberFormat("#,###").format(cartItem.product.price)}',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                            color:
                                                                Theme.of(
                                                                  context,
                                                                ).primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    title: Text(
                                                      cartItem.product.name,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      'Total: Rp${NumberFormat("#,###").format(cartItem.total)}',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .green
                                                                .shade700,
                                                      ),
                                                    ),
                                                    trailing: Container(
                                                      width: 120,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .end,
                                                        children: [
                                                          Material(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade200,
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              onTap: () {
                                                                if (cartItem
                                                                        .quantity >
                                                                    1) {
                                                                  cartProvider.updateItemQuantity(
                                                                    cartItem
                                                                        .product
                                                                        .id!,
                                                                    cartItem.quantity -
                                                                        1,
                                                                  );
                                                                }
                                                              },
                                                              child: Container(
                                                                width: 32,
                                                                height: 32,
                                                                child: Icon(
                                                                  Icons.remove,
                                                                  size: 18,
                                                                  color:
                                                                      Colors
                                                                          .black87,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      8.0,
                                                                ),
                                                            child: Text(
                                                              '${cartItem.quantity}',
                                                              style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                          Material(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  20,
                                                                ),
                                                            color:
                                                                Theme.of(
                                                                  context,
                                                                ).primaryColor,
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                              onTap: () {
                                                                if (cartItem
                                                                        .quantity <
                                                                    cartItem
                                                                        .product
                                                                        .stock) {
                                                                  cartProvider.updateItemQuantity(
                                                                    cartItem
                                                                        .product
                                                                        .id!,
                                                                    cartItem.quantity +
                                                                        1,
                                                                  );
                                                                } else {
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Stok ${cartItem.product.name} tidak mencukupi',
                                                                      ),
                                                                      duration: Duration(
                                                                        seconds:
                                                                            2,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                              child: Container(
                                                                width: 32,
                                                                height: 32,
                                                                child: Icon(
                                                                  Icons.add,
                                                                  size: 18,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      currencyFormatter.format(
                                        cartProvider.totalAmount,
                                      ),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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

  // Show transaction receipt after successful payment
  Future<void> _showTransactionReceipt(
    int transactionId,
    DateTime transactionDate,
    List<TransactionItem> items,
    double totalAmount,
    double amountPaid,
    double change,
    String paymentMethod,
  ) async {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Struk Pembayaran',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Receipt Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Receipt Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaksi #$transactionId',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateFormat.format(transactionDate),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Store Info
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'APLIKASI KASIR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Jl. Contoh No. 123, Kota',
                                style: TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Telp: (021) 123-4567',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Item Header
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'Barang',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  'Jml',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Harga',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Items
                        ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: items.length,
                          separatorBuilder:
                              (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      item.productName,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp',
                                        decimalDigits: 0,
                                      ).format(item.productPrice),
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp',
                                        decimalDigits: 0,
                                      ).format(item.total),
                                      style: const TextStyle(fontSize: 14),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // Divider
                        const Divider(thickness: 1),
                        const SizedBox(height: 12),

                        // Payment Summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id',
                                      symbol: 'Rp',
                                      decimalDigits: 0,
                                    ).format(totalAmount),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Metode Pembayaran:',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              paymentMethod == 'Tunai'
                                                  ? Colors.green.withOpacity(
                                                    0.2,
                                                  )
                                                  : Colors.blue.withOpacity(
                                                    0.2,
                                                  ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              paymentMethod == 'Tunai'
                                                  ? Icons.money
                                                  : Icons.credit_card,
                                              size: 14,
                                              color:
                                                  paymentMethod == 'Tunai'
                                                      ? Colors.green.shade700
                                                      : Colors.blue.shade700,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              paymentMethod,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color:
                                                    paymentMethod == 'Tunai'
                                                        ? Colors.green.shade700
                                                        : Colors.blue.shade700,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (paymentMethod == 'Tunai') ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Tunai:',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp',
                                        decimalDigits: 0,
                                      ).format(amountPaid),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Kembali:',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      NumberFormat.currency(
                                        locale: 'id',
                                        symbol: 'Rp',
                                        decimalDigits: 0,
                                      ).format(change),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Footer
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Transaksi Berhasil',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Terima kasih telah berbelanja',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Barang yang sudah dibeli tidak dapat dikembalikan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
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
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement printing functionality
                            showCustomNotification(
                              context: context,
                              message: 'Fitur cetak struk akan segera tersedia',
                              type: NotificationType.info,
                            );
                          },
                          icon: const Icon(Icons.print),
                          label: const Text('Cetak Struk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Selesai'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
        );
      },
    );
  }
}
