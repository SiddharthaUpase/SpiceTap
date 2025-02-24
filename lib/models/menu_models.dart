class MenuCategory {
  final String id;
  final String name;
  final String? description;
  final String canteenId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuCategory({
    required this.id,
    required this.name,
    this.description,
    required this.canteenId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      canteenId: json['canteen_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'canteen_id': canteenId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final double basePrice;
  final String categoryId;
  final bool isAvailable;
  final String canteenId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.basePrice,
    required this.categoryId,
    required this.isAvailable,
    required this.canteenId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      basePrice: double.parse(json['base_price'].toString()),
      categoryId: json['category_id'],
      isAvailable: json['is_available'],
      canteenId: json['canteen_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'category_id': categoryId,
      'is_available': isAvailable,
      'canteen_id': canteenId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
