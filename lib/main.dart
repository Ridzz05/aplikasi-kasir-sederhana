import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'providers/cart_provider.dart';
import 'providers/page_controller_provider.dart';
import 'providers/cached_product_provider.dart';
import 'providers/store_info_provider.dart';
import 'providers/category_provider.dart';
import 'screens/pos_screen_cupertino.dart';
import 'screens/product_form_screen_cupertino.dart';
import 'screens/transaction_history_screen_cupertino.dart';
import 'screens/product_list_screen_cupertino.dart';
import 'screens/category_screen_cupertino.dart';
import 'screens/store_settings_screen_cupertino.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => PageControllerProvider()),
        ChangeNotifierProvider(create: (ctx) => CachedProductProvider()),
        ChangeNotifierProvider(create: (ctx) => StoreInfoProvider()),
        ChangeNotifierProvider(create: (ctx) => CategoryProvider()),
      ],
      child: CupertinoApp(
        title: 'Kasir Sederhana',
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          primaryColor: Color(0xFF64B5F6),
          brightness: Brightness.light,
          scaffoldBackgroundColor: Color(0xFFF5F5F5),
          textTheme: CupertinoTextThemeData(
            primaryColor: Color(0xFF64B5F6),
            textStyle: TextStyle(
              fontFamily: 'Poppins',
              color: CupertinoColors.black,
            ),
          ),
        ),
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
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    // Gunakan try-catch untuk menangani error saat inisialisasi
    try {
      final storeInfoProvider = Provider.of<StoreInfoProvider>(
        context,
        listen: false,
      );

      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );

      final productProvider = Provider.of<CachedProductProvider>(
        context,
        listen: false,
      );

      // Load data secara asynchronous
      await storeInfoProvider.initializeStoreInfo();
      await categoryProvider.loadCategories();
      await productProvider.loadAllProducts();
    } catch (e) {
      print('Error initializing providers: $e');
      // Jangan throw error, biarkan aplikasi tetap berjalan
    }
  }

  void _initializeScreens() {
    // Urutan layar sesuai dengan indeks tab:
    // 0: Kasir (POS)
    // 1: Riwayat Transaksi
    // 2: Tambah Produk (di tengah)
    // 3: Daftar Produk
    // 4: Kategori
    _screens = [
      POSScreenCupertino(onScreenChange: _navigateToScreen), // Tab 0
      TransactionHistoryScreenCupertino(
        onScreenChange: _navigateToScreen,
      ), // Tab 1
      ProductFormScreenCupertino(onScreenChange: _navigateToScreen), // Tab 2
      ProductListScreenCupertino(onScreenChange: _navigateToScreen), // Tab 3
      CategoryScreenCupertino(onScreenChange: _navigateToScreen), // Tab 4
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
    // Warna tema
    final activeColor = const Color(0xFF1976D2); // Material Blue 700

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _selectedIndex,
        onTap: _navigateToScreen,
        activeColor: activeColor,
        items: const [
          // Icon Kasir - Shopping Cart
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cart),
            activeIcon: Icon(CupertinoIcons.cart_fill),
            label: 'Kasir',
          ),
          // Icon Riwayat - History/Time
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            activeIcon: Icon(CupertinoIcons.clock_fill),
            label: 'Riwayat',
          ),
          // Icon Tambah - di tengah
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            activeIcon: Icon(CupertinoIcons.add_circled_solid),
            label: 'Tambah',
          ),
          // Icon Barang - Box/Product
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cube),
            activeIcon: Icon(CupertinoIcons.cube_fill),
            label: 'Produk',
          ),
          // Icon Kategori - Kategori
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Kategori',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            return _screens[_selectedIndex];
          },
        );
      },
    );
  }
}
