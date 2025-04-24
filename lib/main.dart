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

  @override
  Widget build(BuildContext context) {
    final pageProvider = Provider.of<PageControllerProvider>(context);
    
    return Scaffold(
      body: PageView(
        controller: pageProvider.pageController,
        children: _screens,
        onPageChanged: (index) {
          pageProvider.setPage(index);
        },
        physics: const NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.point_of_sale),
                label: 'Kasir',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_box),
                label: 'Tambah Barang',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                label: 'Daftar Barang',
              ),
            ],
            currentIndex: pageProvider.currentIndex,
            selectedItemColor: const Color(0xFF6C5CE7),
            unselectedItemColor: Colors.grey[400],
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: (index) {
              pageProvider.jumpToPage(index);
            },
          ),
        ),
      ),
    );
  }
}
