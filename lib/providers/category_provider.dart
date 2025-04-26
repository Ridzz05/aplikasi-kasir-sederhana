import 'package:flutter/material.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  // Default category jika tidak ditemukan
  Category get defaultCategory => Category(id: 0, name: 'Tidak terkategori');

  Future<List<Category>> loadCategories() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await DatabaseHelper.instance.getAllCategories();

      // Pastikan daftar kategori tidak null
      if (_categories.isEmpty) {
        // Tambahkan kategori default jika tidak ada kategori tersedia
        final defaultCategory = Category(id: 0, name: 'Tidak terkategori');
        _categories = [defaultCategory];

        // Tambahkan ke database juga
        try {
          await DatabaseHelper.instance.insertCategory(defaultCategory);
        } catch (e) {
          print('Error adding default category: $e');
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
      // Gunakan kategori default jika terjadi error
      _categories = [Category(id: 0, name: 'Tidak terkategori')];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _categories;
  }

  Future<bool> addCategory(Category category) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await DatabaseHelper.instance.insertCategory(category);
      await loadCategories(); // Reload the categories
      return id > 0;
    } catch (e) {
      print('Error adding category: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCategory(Category category) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await DatabaseHelper.instance.updateCategory(category);
      await loadCategories(); // Reload the categories
      return result > 0;
    } catch (e) {
      print('Error updating category: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await DatabaseHelper.instance.deleteCategory(id);
      await loadCategories(); // Reload the categories
      return result > 0;
    } catch (e) {
      print('Error deleting category: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
