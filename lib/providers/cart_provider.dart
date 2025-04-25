import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  double get total => product.price * quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  Map<int, CartItem> _items = {};

  Map<int, CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    double sum = 0.0;
    _items.forEach((key, cartItem) {
      sum += cartItem.total;
    });
    return sum;
  }

  void addItem(Product product, {int quantity = 1}) {
    if (_items.containsKey(product.id)) {
      int currentQty = _items[product.id]!.quantity;
      int newQty = currentQty + quantity;

      if (newQty > product.stock) {
        newQty = product.stock;
      }

      _items.update(
        product.id!,
        (existingCartItem) =>
            CartItem(product: existingCartItem.product, quantity: newQty),
      );
    } else {
      int newQty = quantity;
      if (newQty > product.stock) {
        newQty = product.stock;
      }

      _items.putIfAbsent(
        product.id!,
        () => CartItem(product: product, quantity: newQty),
      );
    }
    notifyListeners();
  }

  void updateItemQuantity(int productId, int quantity) {
    if (_items.containsKey(productId) && quantity > 0) {
      _items.update(
        productId,
        (existingCartItem) =>
            CartItem(product: existingCartItem.product, quantity: quantity),
      );
      notifyListeners();
    }
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
