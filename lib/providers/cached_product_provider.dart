import 'package:flutter/material.dart';
import '../models/product.dart';
import '../database/database_helper.dart';

class CachedProductProvider with ChangeNotifier {
  final Map<int, Product> _productCache = {};
  List<Product>? _allProductsCache;
  DateTime? _lastProductFetch;
  bool _isLoading = false;

  // Cache expiry duration
  static const cacheDuration = Duration(minutes: 15);

  Map<int, Product> get productCache => _productCache;
  List<Product>? get allProducts => _allProductsCache;
  bool get isLoading => _isLoading;

  // Getter untuk daftar produk
  List<Product> get products => _allProductsCache ?? [];

  // Verifikasi apakah cache masih valid
  bool _isCacheValid() {
    if (_lastProductFetch == null) return false;
    return DateTime.now().difference(_lastProductFetch!) < cacheDuration;
  }

  // Load semua produk dengan caching
  Future<List<Product>> loadAllProducts({bool forceRefresh = false}) async {
    if (!forceRefresh && _allProductsCache != null && _isCacheValid()) {
      return [..._allProductsCache!];
    }

    _isLoading = true;
    notifyListeners();

    try {
      final products = await DatabaseHelper.instance.getAllProducts();

      // Update cache
      _allProductsCache = products;
      for (var product in products) {
        _productCache[product.id!] = product;
      }
      _lastProductFetch = DateTime.now();

      _isLoading = false;
      notifyListeners();

      return products;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Mendapatkan produk tunggal dengan caching
  Future<Product?> getProduct(int id, {bool forceRefresh = false}) async {
    if (!forceRefresh && _productCache.containsKey(id)) {
      return _productCache[id];
    }

    try {
      final product = await DatabaseHelper.instance.getProduct(id);
      if (product != null) {
        _productCache[id] = product;
      }
      return product;
    } catch (e) {
      rethrow;
    }
  }

  // Menambahkan produk dengan update cache
  Future<int> addProduct(Product product) async {
    try {
      final productId = await DatabaseHelper.instance.insertProduct(product);

      // Update cache
      final newProduct = product.copyWith(id: productId);
      _productCache[productId] = newProduct;

      if (_allProductsCache != null) {
        _allProductsCache!.add(newProduct);
        notifyListeners();
      }

      return productId;
    } catch (e) {
      rethrow;
    }
  }

  // Update produk dengan update cache
  Future<bool> updateProduct(Product product) async {
    try {
      final result = await DatabaseHelper.instance.updateProduct(product);

      if (result > 0) {
        // Update cache
        _productCache[product.id!] = product;

        if (_allProductsCache != null) {
          final index = _allProductsCache!.indexWhere(
            (p) => p.id == product.id,
          );
          if (index >= 0) {
            _allProductsCache![index] = product;
          }
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Hapus produk dengan update cache
  Future<bool> deleteProduct(int id) async {
    try {
      final result = await DatabaseHelper.instance.deleteProduct(id);

      if (result > 0) {
        // Update cache
        _productCache.remove(id);

        if (_allProductsCache != null) {
          _allProductsCache!.removeWhere((p) => p.id == id);
        }

        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  // Filter produk dari cache
  List<Product> filterProducts(String query) {
    if (_allProductsCache == null) return [];

    if (query.isEmpty) return [..._allProductsCache!];

    final lowerQuery = query.toLowerCase();
    return _allProductsCache!
        .where((product) => product.name.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // Clear cache
  void clearCache() {
    _productCache.clear();
    _allProductsCache = null;
    _lastProductFetch = null;
    notifyListeners();
  }
}
