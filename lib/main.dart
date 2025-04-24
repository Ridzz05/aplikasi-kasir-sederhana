import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/page_controller_provider.dart';
import 'screens/product_form_screen.dart';
import 'screens/pos_screen.dart';
import 'screens/transaction_history_screen.dart';
import 'screens/product_list_screen.dart';

void main() {
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
      ],
      child: MaterialApp(
        title: 'Aplikasi Kasir',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C5CE7),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.grey[50],
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: const Color(0xFF6C5CE7),
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
  final List<Widget> _screens = [
    const POSScreen(),
    const ProductFormScreen(),
    const TransactionHistoryScreen(),
    const ProductListScreen(),
  ];
  
  bool _isDrawerFixed = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final pageProvider = Provider.of<PageControllerProvider>(context);
    
    if (_isDrawerFixed) {
      // Layout dengan drawer permanen
      return Scaffold(
        body: Row(
          children: [
            // Drawer permanen
            SizedBox(
              width: 280, // Fixed drawer width
              child: Drawer(
                elevation: 0,
                child: _buildDrawerContent(context, pageProvider),
              ),
            ),
            // Konten
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Text(_getTitleForPage(pageProvider.currentIndex)),
                  actions: _getActionsForPage(pageProvider.currentIndex),
                ),
                body: PageView(
                  controller: pageProvider.pageController,
                  children: _screens,
                  onPageChanged: (index) {
                    pageProvider.setPage(index);
                  },
                  physics: const NeverScrollableScrollPhysics(),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Layout dengan drawer collapsible
      return Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: _buildDrawerContent(context, pageProvider),
        ),
        appBar: AppBar(
          title: Text(_getTitleForPage(pageProvider.currentIndex)),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
          actions: _getActionsForPage(pageProvider.currentIndex),
        ),
        body: PageView(
          controller: pageProvider.pageController,
          children: _screens,
          onPageChanged: (index) {
            pageProvider.setPage(index);
          },
          physics: const NeverScrollableScrollPhysics(),
        ),
      );
    }
  }

  String _getTitleForPage(int index) {
    switch (index) {
      case 0: return 'Kasir';
      case 1: return 'Tambah Barang';
      case 2: return 'Riwayat Transaksi';
      case 3: return 'Daftar Barang';
      default: return 'Aplikasi Kasir';
    }
  }
  
  List<Widget>? _getActionsForPage(int index) {
    final pageProvider = Provider.of<PageControllerProvider>(context, listen: false);
    
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
        final bool showChart = false; // This would need to be maintained somewhere
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
                  pageProvider.jumpToPage(0); // Index 0 is POS/Kasir screen
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
  
  Widget _buildDrawerContent(BuildContext context, PageControllerProvider pageProvider) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.7),
                Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.point_of_sale,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aplikasi Kasir',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 2,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Menu Navigasi',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 2,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ListTile(
          selected: pageProvider.currentIndex == 0,
          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
          leading: const Icon(Icons.point_of_sale),
          title: const Text('Kasir'),
          onTap: () {
            pageProvider.jumpToPage(0);
            if (!_isDrawerFixed) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
          selected: pageProvider.currentIndex == 1,
          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
          leading: const Icon(Icons.add_box),
          title: const Text('Tambah Barang'),
          onTap: () {
            pageProvider.jumpToPage(1);
            if (!_isDrawerFixed) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
          selected: pageProvider.currentIndex == 2,
          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
          leading: const Icon(Icons.history),
          title: const Text('Riwayat Transaksi'),
          onTap: () {
            pageProvider.jumpToPage(2);
            if (!_isDrawerFixed) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
          selected: pageProvider.currentIndex == 3,
          selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
          leading: const Icon(Icons.grid_view),
          title: const Text('Daftar Barang'),
          onTap: () {
            pageProvider.jumpToPage(3);
            if (!_isDrawerFixed) {
              Navigator.pop(context);
            }
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Mode Sidebar Tetap'),
          subtitle: const Text('Tampilkan sidebar secara permanen'),
          secondary: const Icon(Icons.dock),
          value: _isDrawerFixed,
          onChanged: (value) {
            setState(() {
              _isDrawerFixed = value;
            });
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Pengaturan'),
          onTap: () {
            if (!_isDrawerFixed) {
              Navigator.pop(context);
            }
            // Show settings dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Fitur pengaturan akan segera tersedia'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('Tentang Aplikasi'),
          onTap: () {
            if (!_isDrawerFixed) {
              Navigator.pop(context);
            }
            // Show about dialog
            showAboutDialog(
              context: context, 
              applicationName: 'Aplikasi Kasir',
              applicationVersion: '1.0.0',
              applicationIcon: const Icon(Icons.point_of_sale, size: 48),
              children: [
                const Text('Aplikasi point of sale sederhana untuk kebutuhan usaha kecil.'),
              ],
            );
          },
        ),
      ],
    );
  }
}
