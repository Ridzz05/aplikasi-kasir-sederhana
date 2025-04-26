import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';

class TransactionHistoryScreenCupertino extends StatefulWidget {
  final Function(int)? onScreenChange;

  const TransactionHistoryScreenCupertino({super.key, this.onScreenChange});

  @override
  State<TransactionHistoryScreenCupertino> createState() =>
      _TransactionHistoryScreenCupertinoState();
}

class _TransactionHistoryScreenCupertinoState
    extends State<TransactionHistoryScreenCupertino> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
  bool _isLoading = false;
  List<app_transaction.Transaction> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await DatabaseHelper.instance.getAllTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Gagal memuat transaksi: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showTransactionDetails(app_transaction.Transaction transaction) async {
    setState(() => _isLoading = true);
    try {
      final items = await DatabaseHelper.instance.getTransactionItems(
        transaction.id!,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        _showDetailsDialog(transaction, items);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Gagal memuat detail transaksi: ${e.toString()}');
    }
  }

  void _showDetailsDialog(
    app_transaction.Transaction transaction,
    List<TransactionItem> items,
  ) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('Detail Transaksi'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Tanggal: ${dateFormatter.format(transaction.date)}'),
                const SizedBox(height: 8),
                Text(
                  'Total: ${currencyFormatter.format(transaction.totalAmount)}',
                ),
                const SizedBox(height: 8),
                Text('Metode: ${transaction.paymentMethod}'),
                const SizedBox(height: 16),
                const Text('Item:'),
                const SizedBox(height: 8),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${item.quantity}x @ ${currencyFormatter.format(item.productPrice)}',
                              ),
                            ],
                          ),
                        ),
                        Text(currencyFormatter.format(item.total)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Tutup'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Riwayat Transaksi'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _loadTransactions,
        ),
      ),
      child: SafeArea(
        child:
            _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _transactions.isEmpty
                ? const Center(child: Text('Belum ada transaksi'))
                : ListView.builder(
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.systemGrey5,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: CupertinoListTile(
                        title: Text(
                          dateFormatter.format(transaction.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(transaction.totalAmount),
                              style: const TextStyle(
                                fontSize: 14,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                            Text(
                              'Pembayaran: ${transaction.paymentMethod}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(
                          CupertinoIcons.chevron_right,
                          color: CupertinoColors.systemGrey,
                        ),
                        onTap: () => _showTransactionDetails(transaction),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}
