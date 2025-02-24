import 'package:spice_tap/models/customer.dart';

class WalkInCustomer extends Customer {
  WalkInCustomer({
    required String id,
    String? name,
    String? phoneNumber,
    required String canteenId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super(
          id: id,
          name: name,
          phoneNumber: phoneNumber,
          customerType: CustomerType.walkin,
          canteenId: canteenId,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory WalkInCustomer.fromJson(Map<String, dynamic> json) {
    return WalkInCustomer(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      canteenId: json['canteen_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
