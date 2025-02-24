enum CustomerType { credit, walkin }

class Customer {
  final String id;
  final String? name;
  final String? phoneNumber;
  final CustomerType customerType;
  final String canteenId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    this.name,
    this.phoneNumber,
    required this.customerType,
    required this.canteenId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      customerType: CustomerType.values.firstWhere(
        (e) => e.toString().split('.').last == json['customer_type'],
      ),
      canteenId: json['canteen_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'customer_type': customerType.toString().split('.').last,
      'canteen_id': canteenId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
