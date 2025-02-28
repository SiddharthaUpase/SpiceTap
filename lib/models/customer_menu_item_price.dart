import 'package:spice_tap/models/menu_models.dart';

class CustomerMenuItemPrice {
  final String id;
  final String canteenId;
  final String customerId;
  final String menuItemId;
  final double customPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional field for UI convenience
  final MenuItem? menuItem;

  CustomerMenuItemPrice({
    required this.id,
    required this.canteenId,
    required this.customerId,
    required this.menuItemId,
    required this.customPrice,
    required this.createdAt,
    required this.updatedAt,
    this.menuItem,
  });

  factory CustomerMenuItemPrice.fromJson(Map<String, dynamic> json,
      {MenuItem? menuItem}) {
    return CustomerMenuItemPrice(
      id: json['id'],
      canteenId: json['canteen_id'],
      customerId: json['customer_id'],
      menuItemId: json['menu_item_id'],
      customPrice: double.parse(json['custom_price'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      menuItem: menuItem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canteen_id': canteenId,
      'customer_id': customerId,
      'menu_item_id': menuItemId,
      'custom_price': customPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
