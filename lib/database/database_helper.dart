import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/product.dart';
import '../models/transaction.dart' as app_transaction;
import '../models/transaction_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // Constant untuk web
  static const String webDatabasePath = ':memory:';

  // Flag untuk menunjukkan apakah kita dalam mode web (untuk simulasi/debugging)
  final bool isWebMode = kIsWeb;

  // List sementara untuk menyimpan data di memory saat dalam mode web
  final List<Product> _memoryProducts = [];
  final List<app_transaction.Transaction> _memoryTransactions = [];
  final List<TransactionItem> _memoryTransactionItems = [];
  int _productCounter = 1;
  int _transactionCounter = 1;
  int _transactionItemCounter = 1;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    if (isWebMode) {
      // Di web, kita akan menggunakan pendekatan memori saja untuk demo
      // dan mengembalikan database dummy yang tidak digunakan
      await _initMemoryDB();
      return _database!;
    }
    
    _database = await _initDB('aplikasir.db');
    return _database!;
  }

  Future<void> _initMemoryDB() async {
    // Ini hanya untuk inisialisasi awal jika diperlukan
    if (_database == null) {
      // Buat database dummy hanya agar kode tidak error
      String path = webDatabasePath;
      _database = await openDatabase(path, version: 1, onCreate: _createDB);
    }
  }

  Future<Database> _initDB(String filePath) async {
    if (isWebMode) {
      return await openDatabase(webDatabasePath, version: 1, onCreate: _createDB);
    }
    
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const textNullable = 'TEXT';

    // Create products table
    await db.execute('''
    CREATE TABLE products (
      id $idType,
      name $textType,
      price $realType,
      stock $integerType,
      image_url $textNullable
    )
    ''');

    // Create transactions table
    await db.execute('''
    CREATE TABLE transactions (
      id $idType,
      date $integerType,
      total_amount $realType
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

  // CRUD for Products
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
      return newProduct.id!;
    }
    
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    if (isWebMode) {
      return [..._memoryProducts];
    }
    
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('products');
    return List.generate(maps.length, (i) {
      return Product.fromMap(maps[i]);
    });
  }

  Future<Product?> getProduct(int id) async {
    if (isWebMode) {
      try {
        return _memoryProducts.firstWhere((p) => p.id == id);
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
      return Product.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(Product product) async {
    if (isWebMode) {
      final index = _memoryProducts.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _memoryProducts[index] = product;
        return 1;
      }
      return 0;
    }
    
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    if (isWebMode) {
      final prevLength = _memoryProducts.length;
      _memoryProducts.removeWhere((p) => p.id == id);
      return prevLength - _memoryProducts.length;
    }
    
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction methods
  Future<int> insertTransaction(app_transaction.Transaction transaction) async {
    if (isWebMode) {
      final newTransaction = app_transaction.Transaction(
        id: _transactionCounter++,
        date: transaction.date,
        totalAmount: transaction.totalAmount,
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
    final List<Map<String, dynamic>> maps = await db.query('transactions', orderBy: 'date DESC');
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
      return _memoryTransactionItems.where((item) => item.transactionId == transactionId).toList();
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

  // Close the database
  Future close() async {
    if (!isWebMode) {
      final db = await instance.database;
      db.close();
    }
  }
} 