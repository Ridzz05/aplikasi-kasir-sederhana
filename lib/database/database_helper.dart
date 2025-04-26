import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';
import '../models/category.dart';
import '../providers/cached_product_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Constant untuk web
  static const String webDatabasePath = ':memory:';

  // Flag untuk menunjukkan apakah kita dalam mode web (untuk simulasi/debugging)
  final bool isWebMode = kIsWeb;

  // Caching untuk mengurangi akses database
  Map<int, Product> _productCache = {};
  List<Product>? _allProductsCache;
  DateTime? _lastProductFetch;

  // Category cache
  List<Category>? _allCategoriesCache;
  DateTime? _lastCategoryFetch;

  // Cache expiry duration
  static const cacheDuration = Duration(minutes: 15);

  // List sementara untuk menyimpan data di memory saat dalam mode web
  final List<Product> _memoryProducts = [];
  final List<app_transaction.Transaction> _memoryTransactions = [];
  final List<TransactionItem> _memoryTransactionItems = [];
  final List<Category> _memoryCategories = [];
  int _productCounter = 1;
  int _transactionCounter = 1;
  int _transactionItemCounter = 1;
  int _categoryCounter = 1;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (isWebMode) {
      // Di web, kita akan menggunakan pendekatan memori saja untuk demo
      // dan mengembalikan database dummy yang tidak digunakan
      await _initMemoryDB();
      return _database!;
    }

    try {
      _database = await _initDB('aplikasir.db');
      return _database!;
    } catch (e) {
      // Jika terjadi error saat upgrade database (misal: kolom tidak bisa ditambahkan)
      // Maka hapus database lama dan buat yang baru
      print("Error upgrading database: $e");

      try {
        Directory documentsDirectory = await getApplicationDocumentsDirectory();
        String path = join(documentsDirectory.path, 'aplikasir.db');
        await deleteDatabase(path);
        print("Old database deleted, creating new one");

        _database = await _initDB('aplikasir.db');
        return _database!;
      } catch (deleteError) {
        print("Error creating new database after deletion: $deleteError");
        rethrow;
      }
    }
  }

  Future<void> _initMemoryDB() async {
    // Ini hanya untuk inisialisasi awal jika diperlukan
    if (_database == null) {
      // Buat database dummy hanya agar kode tidak error
      String path = webDatabasePath;
      _database = await openDatabase(path, version: 2, onCreate: _createDB);
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (isWebMode) {
      return await openDatabase(
        webDatabasePath,
        version: 2,
        onCreate: _createDB,
        onUpgrade: _onUpgrade,
      );
    }

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // Create categories table
    await db.execute('''
    CREATE TABLE categories (
      id $idType,
      name $textType,
      description $textNullable,
      color $textNullable
    )
    ''');

    // Create products table
    await db.execute('''
    CREATE TABLE products (
      id $idType,
      name $textType,
      price $realType,
      stock $integerType,
      image_url $textNullable,
      category_id INTEGER,
      FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
    )
    ''');

    // Create transactions table
    await db.execute('''
    CREATE TABLE transactions (
      id $idType,
      date $integerType,
      total_amount $realType,
      payment_method $textNullable DEFAULT 'Tunai'
    )
    ''');

    // Create transaction items table
    await db.execute('''
    CREATE TABLE transaction_items (
      id $idType,
      transaction_id $integerType,
      product_id $integerType,
      product_name $textType,
      product_price $realType,
      quantity $integerType,
      total $realType,
      FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE
    )
    ''');
  }

  // Migration to handle database upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add payment_method column to transactions table for version 2
      await db.execute(
        'ALTER TABLE transactions ADD COLUMN payment_method TEXT DEFAULT "Tunai"',
      );
    }

    if (oldVersion < 3) {
      // Add categories table
      await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        color TEXT
      )
      ''');

      // Add category_id to products table
      await db.execute('ALTER TABLE products ADD COLUMN category_id INTEGER');
      await db.execute(
        'ALTER TABLE products ADD FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL',
      );
    }
  }

  // Optimasi: Clear cache untuk membebaskan memori
  void clearCache() {
    _productCache.clear();
    _allProductsCache = null;
    _lastProductFetch = null;
  }

  // Optimasi: Periksa apakah cache masih valid
  bool _isCacheValid() {
    if (_lastProductFetch == null) return false;
    return DateTime.now().difference(_lastProductFetch!) < cacheDuration;
  }

  // CRUD for Products - dengan caching
  Future<int> insertProduct(Product product) async {
    if (isWebMode) {
      final newProduct = Product(
        id: _productCounter++,
        name: product.name,
        price: product.price,
        stock: product.stock,
        imageUrl: product.imageUrl,
      );
      _memoryProducts.add(newProduct);

      // Update cache juga
      if (_allProductsCache != null) {
        _allProductsCache!.add(newProduct);
      }

      return newProduct.id!;
    }

    final db = await instance.database;
    final productId = await db.insert('products', product.toMap());

    // Update cache
    final newProduct = product.copyWith(id: productId);
    _productCache[productId] = newProduct;

    // Update list cache jika ada
    if (_allProductsCache != null) {
      _allProductsCache!.add(newProduct);
    }

    return productId;
  }

  Future<List<Product>> getAllProducts() async {
    // Cek cache dulu jika valid
    if (_allProductsCache != null && _isCacheValid()) {
      return [..._allProductsCache!];
    }

    if (isWebMode) {
      _allProductsCache = [..._memoryProducts];
      _lastProductFetch = DateTime.now();
      return [..._memoryProducts];
    }

    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('products');

    final products = List.generate(maps.length, (i) {
      final product = Product.fromMap(maps[i]);
      // Update single product cache
      _productCache[product.id!] = product;
      return product;
    });

    // Update cache
    _allProductsCache = products;
    _lastProductFetch = DateTime.now();

    return products;
  }

  Future<Product?> getProduct(int id) async {
    // Cek cache dulu
    if (_productCache.containsKey(id)) {
      return _productCache[id];
    }

    if (isWebMode) {
      try {
        final product = _memoryProducts.firstWhere((p) => p.id == id);
        _productCache[id] = product;
        return product;
      } catch (e) {
        return null;
      }
    }

    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      final product = Product.fromMap(maps.first);
      // Update cache
      _productCache[id] = product;
      return product;
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    if (isWebMode) {
      final index = _memoryProducts.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _memoryProducts[index] = product;
        // Update cache
        _productCache[product.id!] = product;

        // Update list cache jika ada
        if (_allProductsCache != null) {
          final cacheIndex = _allProductsCache!.indexWhere(
            (p) => p.id == product.id,
          );
          if (cacheIndex >= 0) {
            _allProductsCache![cacheIndex] = product;
          }
        }

        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    final result = await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    // Update cache
    if (result > 0) {
      _productCache[product.id!] = product;

      // Update list cache jika ada
      if (_allProductsCache != null) {
        final index = _allProductsCache!.indexWhere((p) => p.id == product.id);
        if (index >= 0) {
          _allProductsCache![index] = product;
        }
      }
    }

    return result;
  }

  Future<int> deleteProduct(int id) async {
    if (isWebMode) {
      final prevLength = _memoryProducts.length;
      _memoryProducts.removeWhere((p) => p.id == id);

      // Update cache
      _productCache.remove(id);

      // Update list cache jika ada
      if (_allProductsCache != null) {
        _allProductsCache!.removeWhere((p) => p.id == id);
      }

      return prevLength - _memoryProducts.length;
    }

    final db = await instance.database;
    final result = await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Update cache
    if (result > 0) {
      _productCache.remove(id);

      // Update list cache jika ada
      if (_allProductsCache != null) {
        _allProductsCache!.removeWhere((p) => p.id == id);
      }
    }

    return result;
  }

  // Transaction methods
  Future<int> insertTransaction(app_transaction.Transaction transaction) async {
    if (isWebMode) {
      final newTransaction = app_transaction.Transaction(
        id: _transactionCounter++,
        date: transaction.date,
        totalAmount: transaction.totalAmount,
        paymentMethod: transaction.paymentMethod,
      );
      _memoryTransactions.add(newTransaction);
      return newTransaction.id!;
    }

    final db = await instance.database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<app_transaction.Transaction>> getAllTransactions() async {
    if (isWebMode) {
      return [..._memoryTransactions]..sort((a, b) => b.date.compareTo(a.date));
    }

    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return app_transaction.Transaction.fromMap(maps[i]);
    });
  }

  Future<int> insertTransactionItem(TransactionItem item) async {
    if (isWebMode) {
      final newItem = TransactionItem(
        id: _transactionItemCounter++,
        transactionId: item.transactionId,
        productId: item.productId,
        productName: item.productName,
        productPrice: item.productPrice,
        quantity: item.quantity,
        total: item.total,
      );
      _memoryTransactionItems.add(newItem);
      return newItem.id!;
    }

    final db = await instance.database;
    return await db.insert('transaction_items', item.toMap());
  }

  Future<List<TransactionItem>> getTransactionItems(int transactionId) async {
    if (isWebMode) {
      return _memoryTransactionItems
          .where((item) => item.transactionId == transactionId)
          .toList();
    }

    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transaction_items',
      where: 'transaction_id = ?',
      whereArgs: [transactionId],
    );
    return List.generate(maps.length, (i) {
      return TransactionItem.fromMap(maps[i]);
    });
  }

  // Update product stock
  Future<void> updateProductStock(int productId, int quantity) async {
    if (isWebMode) {
      final index = _memoryProducts.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        int newStock = _memoryProducts[index].stock - quantity;
        if (newStock < 0) newStock = 0;

        final updatedProduct = _memoryProducts[index].copyWith(stock: newStock);
        _memoryProducts[index] = updatedProduct;
      }
      return;
    }

    final db = await instance.database;
    Product? product = await getProduct(productId);
    if (product != null) {
      int newStock = product.stock - quantity;
      if (newStock < 0) newStock = 0;

      await db.update(
        'products',
        {'stock': newStock},
        where: 'id = ?',
        whereArgs: [productId],
      );
    }
  }

  // Optimasi: batch transaction insert untuk mengoptimalkan kinerja database
  Future<int> createFullTransaction(
    app_transaction.Transaction transaction,
    List<TransactionItem> items,
    List<Map<int, int>> stockUpdates,
  ) async {
    if (isWebMode) {
      // Proses transaksi di memory
      final transactionId = await insertTransaction(transaction);

      // Tambahkan semua item transaksi
      for (var item in items) {
        final updatedItem = item.copyWith(transactionId: transactionId);
        await insertTransactionItem(updatedItem);
      }

      // Update stok produk
      for (var update in stockUpdates) {
        update.forEach((productId, quantity) async {
          await updateProductStock(productId, quantity);
        });
      }

      return transactionId;
    }

    final db = await instance.database;
    int transactionId = 0;

    // Gunakan batch operation untuk optimasi
    await db.transaction((txn) async {
      // 1. Buat transaksi
      transactionId = await txn.insert('transactions', transaction.toMap());

      // 2. Masukkan semua item transaksi
      for (var item in items) {
        final updatedItem = item.copyWith(transactionId: transactionId);
        await txn.insert('transaction_items', updatedItem.toMap());
      }

      // 3. Update stok produk dalam satu batch
      for (var update in stockUpdates) {
        update.forEach((productId, quantity) async {
          Product? product = await getProduct(productId);
          if (product != null) {
            int newStock = product.stock - quantity;
            if (newStock < 0) newStock = 0;

            await txn.update(
              'products',
              {'stock': newStock},
              where: 'id = ?',
              whereArgs: [productId],
            );

            // Update cache jika produk ada di cache
            if (_productCache.containsKey(productId)) {
              final updatedProduct = _productCache[productId]!.copyWith(
                stock: newStock,
              );
              _productCache[productId] = updatedProduct;

              // Update list cache jika ada
              if (_allProductsCache != null) {
                final index = _allProductsCache!.indexWhere(
                  (p) => p.id == productId,
                );
                if (index >= 0) {
                  _allProductsCache![index] = updatedProduct;
                }
              }
            }
          }
        });
      }
    });

    return transactionId;
  }

  // Reset database (for emergency use when there's a schema conflict)
  Future<bool> resetDatabase() async {
    if (isWebMode) {
      // In web mode, just clear the memory lists
      _memoryProducts.clear();
      _memoryTransactions.clear();
      _memoryTransactionItems.clear();
      _productCounter = 1;
      _transactionCounter = 1;
      _transactionItemCounter = 1;

      // Clear cache
      clearCache();

      return true;
    }

    try {
      // Close the database first
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Delete the database file
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'aplikasir.db');
      await deleteDatabase(path);

      // Clear cache
      clearCache();

      // Reinitialize the database
      _database = await _initDB('aplikasir.db');

      return true;
    } catch (e) {
      print("Error resetting database: $e");
      return false;
    }
  }

  // Close the database and clear cache
  Future close() async {
    clearCache();

    if (!isWebMode) {
      final db = await instance.database;
      db.close();
    }
  }

  // CRUD operations for Categories
  Future<int> insertCategory(Category category) async {
    if (isWebMode) {
      final newCategory = Category(
        id: _categoryCounter++,
        name: category.name,
        description: category.description,
        color: category.color,
      );
      _memoryCategories.add(newCategory);

      if (_allCategoriesCache != null) {
        _allCategoriesCache!.add(newCategory);
      }

      return newCategory.id!;
    }

    final db = await instance.database;
    final categoryId = await db.insert('categories', category.toMap());

    // Update cache
    final newCategory = category.copyWith(id: categoryId);
    if (_allCategoriesCache != null) {
      _allCategoriesCache!.add(newCategory);
    }

    return categoryId;
  }

  Future<Category?> getCategory(int id) async {
    if (isWebMode) {
      return _memoryCategories.firstWhere(
        (cat) => cat.id == id,
        orElse: () => Category(name: 'Not Found', id: -1),
      );
    }

    final db = await instance.database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Category.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Category>> getAllCategories() async {
    if (_allCategoriesCache != null && _isCategoryCacheValid()) {
      return _allCategoriesCache!;
    }

    if (isWebMode) {
      _allCategoriesCache = List.from(_memoryCategories);
      _lastCategoryFetch = DateTime.now();
      return _allCategoriesCache!;
    }

    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name');

    _allCategoriesCache = result.map((map) => Category.fromMap(map)).toList();
    _lastCategoryFetch = DateTime.now();
    return _allCategoriesCache!;
  }

  bool _isCategoryCacheValid() {
    if (_lastCategoryFetch == null) return false;
    return DateTime.now().difference(_lastCategoryFetch!) < cacheDuration;
  }

  Future<int> updateCategory(Category category) async {
    if (isWebMode) {
      final index = _memoryCategories.indexWhere((c) => c.id == category.id);
      if (index >= 0) {
        _memoryCategories[index] = category;

        if (_allCategoriesCache != null) {
          final cacheIndex = _allCategoriesCache!.indexWhere(
            (c) => c.id == category.id,
          );
          if (cacheIndex >= 0) {
            _allCategoriesCache![cacheIndex] = category;
          }
        }

        return 1;
      }
      return 0;
    }

    final db = await instance.database;
    final result = await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );

    // Update cache if needed
    if (result > 0 && _allCategoriesCache != null) {
      final index = _allCategoriesCache!.indexWhere((c) => c.id == category.id);
      if (index >= 0) {
        _allCategoriesCache![index] = category;
      }
    }

    return result;
  }

  Future<int> deleteCategory(int id) async {
    if (isWebMode) {
      final removedCount = _memoryCategories.where((c) => c.id == id).length;
      _memoryCategories.removeWhere((c) => c.id == id);

      if (_allCategoriesCache != null) {
        _allCategoriesCache!.removeWhere((c) => c.id == id);
      }

      return removedCount;
    }

    final db = await instance.database;

    // Update products with this category to no category
    await db.update(
      'products',
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [id],
    );

    final result = await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    // Update cache if needed
    if (result > 0 && _allCategoriesCache != null) {
      _allCategoriesCache!.removeWhere((c) => c.id == id);
    }

    return result;
  }

  // Get all transactions adalah alias untuk getAllTransactions
  Future<List<app_transaction.Transaction>> getTransactions() async {
    return getAllTransactions();
  }
}
