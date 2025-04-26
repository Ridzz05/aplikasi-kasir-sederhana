import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/cart_provider.dart';
import 'providers/page_controller_provider.dart';
import 'providers/cached_product_provider.dart';
import 'providers/store_info_provider.dart';
import 'providers/category_provider.dart';
import 'screens/pos_screen_cupertino.dart';

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

  void _initializeProviders() {
    Future.delayed(Duration.zero, () {
      Provider.of<StoreInfoProvider>(
        context,
        listen: false,
      ).initializeStoreInfo();
    });
  }

  void _initializeScreens() {
    _screens = [
      POSScreenCupertino(onScreenChange: _navigateToScreen),
      // Add other Cupertino-style screens here
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
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        currentIndex: _selectedIndex,
        onTap: _navigateToScreen,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.shopping_cart),
            label: 'Kasir',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.add_circled),
            label: 'Tambah',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.cube_box),
            label: 'Barang',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.collections),
            label: 'Kategori',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(builder: (context) => _screens[index]);
      },
    );
  }
}
