import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({Key? key}) : super(key: key);

  @override
  _TransactionHistoryScreenState createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');
  
  bool _isLoading = false;
  List<app_transaction.Transaction> _transactions = [];
  app_transaction.Transaction? _selectedTransaction;
  List<TransactionItem> _transactionItems = [];
  bool _showChart = false;
  int _totalTransactions = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await DatabaseHelper.instance.getAllTransactions();
      setState(() {
        _transactions = transactions;
        _selectedTransaction = null;
        _transactionItems = [];
        
        // Calculate statistics
        _totalTransactions = transactions.length;
        _totalRevenue = transactions.fold(0, (sum, tx) => sum + tx.totalAmount);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTransactionItems(app_transaction.Transaction transaction) async {
    setState(() {
      _isLoading = true;
      _selectedTransaction = transaction;
    });

    try {
      final items = await DatabaseHelper.instance.getTransactionItems(transaction.id!);
      setState(() {
        _transactionItems = items;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTransactionDetailsModal(BuildContext context) {
    if (_selectedTransaction == null) return;
    
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Transaksi #${_selectedTransaction!.id}',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                'Tanggal: ${dateFormatter.format(_selectedTransaction!.date)}',
                style: TextStyle(
                  color: Colors.grey[600], 
                  fontSize: isSmallScreen ? 13 : 15,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.receipt_long, color: Color(0xFF6C5CE7)),
                  const SizedBox(width: 8),
                  Text(
                    'Detail Item:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _transactionItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text('Tidak ada item'),
                          ],
                        ),
                      )
                    : AnimationLimiter(
                        child: ListView.builder(
                          itemCount: _transactionItems.length,
                          itemBuilder: (ctx, i) {
                            final item = _transactionItems[i];
                            return AnimationConfiguration.staggeredList(
                              position: i,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 8 : 16,
                                        vertical: 4,
                                      ),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                        radius: isSmallScreen ? 16 : 20,
                                        child: Text(
                                          "${item.quantity}",
                                          style: TextStyle(
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 12 : 14,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        item.productName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 13 : 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${currencyFormatter.format(item.productPrice)} / item',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 11 : 13, 
                                          color: Colors.grey[600]
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: Text(
                                        currencyFormatter.format(item.total),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                          fontSize: isSmallScreen ? 12 : 14,
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
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ),
                    Text(
                      currencyFormatter.format(_selectedTransaction!.totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 20,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 360;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchTransactions,
          ),
          IconButton(
            icon: Icon(_showChart ? Icons.list : Icons.bar_chart),
            onPressed: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
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
          : _transactions.isEmpty
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
                        'Belum ada transaksi',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Stats cards
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildStatCard(
                                'Jumlah Transaksi',
                                '$_totalTransactions',
                                Icons.receipt_long,
                                const Color(0xFF6C5CE7),
                                isSmallScreen: isSmallScreen,
                                width: isSmallScreen 
                                    ? constraints.maxWidth 
                                    : (constraints.maxWidth / 2) - 8,
                              ),
                              _buildStatCard(
                                'Total Pendapatan',
                                currencyFormatter.format(_totalRevenue),
                                Icons.attach_money,
                                Colors.green,
                                isSmallScreen: isSmallScreen,
                                width: isSmallScreen 
                                    ? constraints.maxWidth 
                                    : (constraints.maxWidth / 2) - 8,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Chart or List
                          _showChart
                              ? Expanded(
                                  child: _buildRevenueChart(),
                                )
                              : Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Daftar Transaksi',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: AnimationLimiter(
                                          child: ListView.builder(
                                            itemCount: _transactions.length,
                                            itemBuilder: (ctx, i) {
                                              final transaction = _transactions[i];
                                              final isSelected = _selectedTransaction?.id == transaction.id;
                                              
                                              return AnimationConfiguration.staggeredList(
                                                position: i,
                                                duration: const Duration(milliseconds: 375),
                                                child: SlideAnimation(
                                                  horizontalOffset: 50.0,
                                                  child: FadeInAnimation(
                                                    child: Card(
                                                      color: isSelected ? Colors.blue[50] : null,
                                                      margin: const EdgeInsets.only(bottom: 12),
                                                      elevation: isSelected ? 3 : 2,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                        side: isSelected
                                                            ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                                                            : BorderSide.none,
                                                      ),
                                                      child: InkWell(
                                                        onTap: () async {
                                                          await _fetchTransactionItems(transaction);
                                                          if (!mounted) return;
                                                          _showTransactionDetailsModal(context);
                                                        },
                                                        borderRadius: BorderRadius.circular(16),
                                                        child: Padding(
                                                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Row(
                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                children: [
                                                                  Expanded(
                                                                    child: Row(
                                                                      children: [
                                                                        Container(
                                                                          padding: const EdgeInsets.all(8),
                                                                          decoration: BoxDecoration(
                                                                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                                                                            borderRadius: BorderRadius.circular(12),
                                                                          ),
                                                                          child: Icon(
                                                                            Icons.receipt,
                                                                            color: Theme.of(context).primaryColor,
                                                                            size: isSmallScreen ? 16 : 20,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(width: 12),
                                                                        Expanded(
                                                                          child: Column(
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                'Transaksi #${transaction.id}',
                                                                                style: TextStyle(
                                                                                  fontWeight: FontWeight.bold,
                                                                                  fontSize: isSmallScreen ? 14 : 16,
                                                                                ),
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                              const SizedBox(height: 4),
                                                                              Text(
                                                                                dateFormatter.format(transaction.date),
                                                                                style: TextStyle(
                                                                                  color: Colors.grey[600],
                                                                                  fontSize: isSmallScreen ? 12 : 14,
                                                                                ),
                                                                                overflow: TextOverflow.ellipsis,
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                  Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                                    children: [
                                                                      Text(
                                                                        currencyFormatter.format(transaction.totalAmount),
                                                                        style: TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          color: Theme.of(context).primaryColor,
                                                                          fontSize: isSmallScreen ? 14 : 16,
                                                                        ),
                                                                      ),
                                                                      const SizedBox(height: 4),
                                                                      Text(
                                                                        'Tap untuk detail',
                                                                        style: TextStyle(
                                                                          fontSize: isSmallScreen ? 10 : 12,
                                                                          color: Colors.grey[600],
                                                                        ),
                                                                      ),
                                                                    ],
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
                        ],
                      ),
                    );
                  }
                ),
    );
  }

  Widget _buildRevenueChart() {
    // Group transactions by day for chart data
    Map<String, double> dailyRevenue = {};
    
    for (final transaction in _transactions) {
      final date = DateFormat('yyyy-MM-dd').format(transaction.date);
      dailyRevenue[date] = (dailyRevenue[date] ?? 0) + transaction.totalAmount;
    }
    
    // Sort by date
    List<MapEntry<String, double>> sortedEntries = dailyRevenue.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    
    // Only show last 7 days if we have more than 7 days of data
    if (sortedEntries.length > 7) {
      sortedEntries = sortedEntries.sublist(sortedEntries.length - 7);
    }
    
    final List<BarChartGroupData> barGroups = [];
    
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      String shortDate = DateFormat('dd/MM').format(DateTime.parse(entry.key));
      
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value,
              color: const Color(0xFF6C5CE7),
              width: 16,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendapatan per Hari',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: sortedEntries.isEmpty
                ? const Center(child: Text('Tidak ada data yang tersedia'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < sortedEntries.length) {
                                String shortDate = DateFormat('dd/MM').format(DateTime.parse(sortedEntries[index].key));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    shortDate, 
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  currencyFormatter.format(value),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {bool isSmallScreen = false, double? width}) {
    return Container(
      width: width,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isSmallScreen ? 10 : 12,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 2 : 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1, duration: 300.ms);
  }
} 