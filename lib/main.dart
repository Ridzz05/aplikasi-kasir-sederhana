import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
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
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

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
    // Definisikan warna untuk background dan navigasi
    final backgroundColor = const Color(0xFFF5F5F5);
    final activeColor = const Color(0xFF1976D2); // Material Blue 700

    // Item navigasi dengan icon yang lebih konsisten
    final items = <Widget>[
      // Icon Kasir - Shopping Cart
      const Icon(CupertinoIcons.cart_fill, size: 26, color: Colors.white),
      // Icon Riwayat - History/Time
      const Icon(CupertinoIcons.clock_fill, size: 26, color: Colors.white),
      // Icon Tambah - di tengah
      const Icon(CupertinoIcons.add, size: 30, color: Colors.white),
      // Icon Barang - Box/Product
      const Icon(CupertinoIcons.cube_fill, size: 26, color: Colors.white),
      // Icon Kategori - Kategori
      const Icon(
        CupertinoIcons.square_grid_2x2_fill,
        size: 26,
        color: Colors.white,
      ),
    ];

    // Definisikan padding bawah untuk semua halaman
    const bottomNavPadding = 70.0; // Mengakomodasi CurvedNavigationBar

    // Wrap setiap screen dengan padding
    final wrappedScreens =
        _screens.map((screen) {
          return Padding(
            padding: const EdgeInsets.only(bottom: bottomNavPadding),
            child: screen,
          );
        }).toList();

    return CupertinoPageScaffold(
      child: SafeArea(
        bottom:
            false, // Jangan gunakan safe area di bawah karena kita menangani sendiri
        child: Scaffold(
          extendBody: true, // Penting agar body extend ke bawah navbar
          backgroundColor: backgroundColor,
          body: wrappedScreens[_selectedIndex],
          bottomNavigationBar: Theme(
            data: Theme.of(
              context,
            ).copyWith(iconTheme: const IconThemeData(color: Colors.white)),
            child: CurvedNavigationBar(
              key: _bottomNavigationKey,
              index: _selectedIndex,
              height: 60.0,
              items: items,
              color: activeColor.withOpacity(0.8),
              buttonBackgroundColor: activeColor,
              backgroundColor: Colors.transparent,
              animationCurve: Curves.easeInOut,
              animationDuration: const Duration(milliseconds: 300),
              onTap: _navigateToScreen,
              letIndexChange: (index) => true,
            ),
          ),
        ),
      ),
    );
  }
}
