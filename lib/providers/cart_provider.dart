import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  int get itemCount => _items.length;

  int get totalItems {
    int count = 0;
    _items.forEach((key, cartItem) {
      count += cartItem.quantity;
    });
    return count;
  }

  double get totalAmount {
    double sum = 0.0;
    _items.forEach((key, cartItem) {
      sum += cartItem.price * cartItem.quantity;
    });
    return sum;
  }

  void addItem(int productId, String title, double price, String? imageUrl) {
    if (_items.containsKey(productId)) {
      // Update existing item
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          productId: productId,
          title: title,
          quantity: existingCartItem.quantity + 1,
          price: price,
          imageUrl: imageUrl,
        ),
      );
    } else {
      // Add new item
      _items.putIfAbsent(
        productId,
        () => CartItem(
          productId: productId,
          title: title,
          quantity: 1,
          price: price,
          imageUrl: imageUrl,
        ),
      );
    }
    notifyListeners();
  }

  void removeSingleItem(int productId) {
    if (!_items.containsKey(productId)) {
      return;
    }

    if (_items[productId]!.quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          productId: productId,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity - 1,
          price: existingCartItem.price,
          imageUrl: existingCartItem.imageUrl,
        ),
      );
    } else {
      _items.remove(productId);
    }

    notifyListeners();
  }

  void removeItem(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
