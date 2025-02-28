import 'package:flutter/foundation.dart';
import '../models/menu_models.dart';
import '../models/order_models.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  Map<String, double> _customPrices = {};
  Set<String> _ignoredCustomPrices = {};

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.length;

  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => _items.fold(0, (sum, item) {
        final price = getEffectivePrice(item.menuItem.id);
        return sum + (price * item.quantity);
      });

  bool get isEmpty => _items.isEmpty;

  // Method to set custom prices
  void setCustomPrices(Map<String, double> customPrices) {
    _customPrices = customPrices;
    _ignoredCustomPrices.clear();
    notifyListeners();
  }

  // Check if an item has a custom price
  bool hasCustomPrice(String menuItemId) {
    return _customPrices.containsKey(menuItemId) &&
        !_ignoredCustomPrices.contains(menuItemId);
  }

  // Get base price for a menu item
  double getBasePrice(String menuItemId) {
    return _items
        .firstWhere((item) => item.menuItem.id == menuItemId)
        .menuItem
        .basePrice;
  }

  // Get the effective price for a menu item (custom or base)
  double getEffectivePrice(String menuItemId) {
    if (_ignoredCustomPrices.contains(menuItemId)) {
      return getBasePrice(menuItemId);
    }
    return _customPrices[menuItemId] ?? getBasePrice(menuItemId);
  }

  // Toggle custom price for an item
  void toggleCustomPrice(String menuItemId) {
    if (_ignoredCustomPrices.contains(menuItemId)) {
      _ignoredCustomPrices.remove(menuItemId);
    } else {
      _ignoredCustomPrices.add(menuItemId);
    }
    notifyListeners();
  }

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
    _customPrices.clear();
    notifyListeners();
  }
}
