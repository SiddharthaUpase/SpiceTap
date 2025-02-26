import 'package:flutter/foundation.dart';
import '../models/menu_models.dart';
import '../models/order_models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(
      0, (sum, item) => sum + (item.menuItem.basePrice * item.quantity));

  bool get isEmpty => _items.isEmpty;

  void addItem(MenuItem menuItem) {
    final existingIndex =
        _items.indexWhere((item) => item.menuItem.id == menuItem.id);

    if (existingIndex >= 0) {
      _items[existingIndex].quantity += 1;
    } else {
      _items.add(CartItem(menuItem: menuItem));
    }

    notifyListeners();
  }

  void removeItem(String menuItemId) {
    final existingIndex =
        _items.indexWhere((item) => item.menuItem.id == menuItemId);

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity > 1) {
        _items[existingIndex].quantity -= 1;
      } else {
        _items.removeAt(existingIndex);
      }

      notifyListeners();
    }
  }

  void updateQuantity(String menuItemId, int quantity) {
    final existingIndex =
        _items.indexWhere((item) => item.menuItem.id == menuItemId);

    if (existingIndex >= 0) {
      if (quantity <= 0) {
        _items.removeAt(existingIndex);
      } else {
        _items[existingIndex].quantity = quantity;
      }

      notifyListeners();
    }
  }

  void removeItemCompletely(String menuItemId) {
    _items.removeWhere((item) => item.menuItem.id == menuItemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
