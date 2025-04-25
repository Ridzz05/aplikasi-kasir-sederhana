import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'providers/cart_provider.dart';
import 'providers/page_controller_provider.dart';
import 'screens/product_form_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/product_list_screen.dart';
import 'widgets/custom_notification.dart';
import 'providers/cached_product_provider.dart';
import 'database/database_helper.dart';

void main() {
  // Optimasi startup
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientasi optimal untuk aplikasi kasir
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF64B5F6),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Pra-cache font untuk menghindari jank saat runtime
    final textTheme = GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => PageControllerProvider()),
        ChangeNotifierProvider(create: (ctx) => CachedProductProvider()),
      ],
      child: MaterialApp(
        title: 'Aplikasi Kasir',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF64B5F6),
            secondary: Color(0xFFFF9800),
            surface: Colors.white,
            background: Color(0xFFF5F5F5),
            error: Color(0xFFB00020),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          textTheme: textTheme,
          // Optimasi performa dengan meminimalkan properti yang tidak diperlukan
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64B5F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          cardTheme: const CardTheme(
            elevation: 1, // Kurangi elevasi untuk performa
            clipBehavior: Clip.hardEdge, // Lebih cepat dari antiAlias
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF64B5F6),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6C5CE7), width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
            labelStyle: TextStyle(color: Colors.grey[700]),
          ),
        ),
        // Batasi framerate untuk menghemat baterai jika diperlukan
        // builder: (context, child) {
        //   return MediaQuery(
        //     data: MediaQuery.of(context).copyWith(
        //       textScaleFactor: 1.0, // Menghindari perubahan ukuran teks sistem
        //     ),
        //     child: child!,
        //   );
        // },
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<Widget> _screens;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    _screens = [
      POSScreen(onScreenChange: _navigateToScreen),
      ProductFormScreen(onScreenChange: _navigateToScreen),
      TransactionHistoryScreen(onScreenChange: _navigateToScreen),
      ProductListScreen(onScreenChange: _navigateToScreen),
    ];
  }

  void _navigateToScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    final pageProvider = Provider.of<PageControllerProvider>(
      context,
      listen: false,
    );
    pageProvider.setPage(index);
  }

  @override
  Widget build(BuildContext context) {
    final pageProvider = Provider.of<PageControllerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitleForPage(_selectedIndex)),
        actions: [
          ..._getActionsForPage(_selectedIndex) ?? [],
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Kasir',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Tambah'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Barang'),
        ],
        onTap: (index) {
          _navigateToScreen(index);
        },
      ),
    );
  }

  String _getTitleForPage(int index) {
    switch (index) {
      case 0:
        return 'Kasir';
      case 1:
        return 'Tambah Barang';
      case 2:
        return 'Riwayat Transaksi';
      case 3:
        return 'Daftar Barang';
      default:
        return 'Aplikasi Kasir';
    }
  }

  List<Widget>? _getActionsForPage(int index) {
    final pageProvider = Provider.of<PageControllerProvider>(
      context,
      listen: false,
    );

    switch (index) {
      case 0: // Kasir screen
        return null;

      case 1: // Product Form screen
        final isEditing = false; // This would need to be maintained somewhere
        return isEditing
            ? [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // Reset product form
                },
              ),
            ]
            : null;

      case 2: // Transaction History screen
        final bool showChart =
            false; // This would need to be maintained somewhere
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh transactions
            },
          ),
          IconButton(
            icon: Icon(showChart ? Icons.list : Icons.bar_chart),
            onPressed: () {
              // Toggle chart view
            },
          ),
        ];

      case 3: // Product List screen
        final cartProvider = Provider.of<CartProvider>(context, listen: false);
        return [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh products
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Navigate to cart
                  _navigateToScreen(0); // Index 0 is POS/Kasir screen
                },
                tooltip: 'Lihat Keranjang',
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
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
        ];

      default:
        return null;
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Pengaturan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Reset Database'),
                  subtitle: const Text(
                    'Hapus semua data (transaksi, barang, dll)',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showResetDatabaseConfirmation(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Versi Aplikasi'),
                  subtitle: const Text('1.0.0'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }

  void _showResetDatabaseConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Database'),
            content: const Text(
              'Tindakan ini akan menghapus SEMUA data, termasuk barang, '
              'transaksi, dan pengaturan. Data yang terhapus tidak dapat dikembalikan.\n\n'
              'Yakin ingin melanjutkan?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () async {
                  Navigator.of(context).pop();

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Mereset database...'),
                          ],
                        ),
                      );
                    },
                  );

                  try {
                    final bool success =
                        await DatabaseHelper.instance.resetDatabase();

                    // Close loading dialog
                    Navigator.of(context).pop();

                    if (success) {
                      showCustomNotification(
                        context: context,
                        message: 'Database berhasil direset',
                        type: NotificationType.success,
                      );

                      // Clear the cart
                      final cartProvider = Provider.of<CartProvider>(
                        context,
                        listen: false,
                      );
                      cartProvider.clear();

                      // Reset cached products
                      final productProvider =
                          Provider.of<CachedProductProvider>(
                            context,
                            listen: false,
                          );
                      await productProvider.loadAllProducts(forceRefresh: true);

                      // Navigate to POS screen
                      _navigateToScreen(0);
                    } else {
                      showCustomNotification(
                        context: context,
                        message: 'Gagal mereset database',
                        type: NotificationType.error,
                      );
                    }
                  } catch (e) {
                    // Close loading dialog
                    Navigator.of(context).pop();

                    showCustomNotification(
                      context: context,
                      message: 'Error: ${e.toString()}',
                      type: NotificationType.error,
                    );
                  }
                },
                child: const Text('Reset Database'),
              ),
            ],
          ),
    );
  }
}
