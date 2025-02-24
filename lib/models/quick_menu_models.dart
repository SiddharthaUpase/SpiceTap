import 'package:spice_tap/models/menu_models.dart';

class QuickMenuItem {
  final String id;
  final String canteenId;
  final String menuItemId;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Reference to the actual menu item
  final MenuItem? menuItem;

  QuickMenuItem({
    required this.id,
    required this.canteenId,
    required this.menuItemId,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.menuItem,
  });

  factory QuickMenuItem.fromJson(Map<String, dynamic> json,
      {MenuItem? menuItem}) {
    return QuickMenuItem(
      id: json['id'],
      canteenId: json['canteen_id'],
      menuItemId: json['menu_item_id'],
      position: json['position'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      menuItem: menuItem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canteen_id': canteenId,
      'menu_item_id': menuItemId,
      'position': position,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
