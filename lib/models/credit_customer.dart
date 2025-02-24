import 'package:spice_tap/models/customer.dart';

class CreditCustomer extends Customer {
  final String companyName;
  final String ownerRepNumber;
  final double creditLimit;
  final double currentBalance;
  final List<String> shopNumbers;

  CreditCustomer({
    required String id,
    String? name,
    String? phoneNumber,
    required String canteenId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required this.companyName,
    required this.ownerRepNumber,
    required this.creditLimit,
    required this.currentBalance,
    required this.shopNumbers,
  }) : super(
          id: id,
          name: name,
          phoneNumber: phoneNumber,
          customerType: CustomerType.credit,
          canteenId: canteenId,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );

  factory CreditCustomer.fromJson(Map<String, dynamic> json) {
    return CreditCustomer(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      canteenId: json['canteen_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      companyName: json['company_name'],
      ownerRepNumber: json['owner_rep_number'],
      creditLimit: double.parse(json['credit_limit'].toString()),
      currentBalance: double.parse(json['current_balance'].toString()),
      shopNumbers: List<String>.from(json['shop_numbers'] ?? []),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'company_name': companyName,
      'owner_rep_number': ownerRepNumber,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
      'shop_numbers': shopNumbers,
    };
  }
}
