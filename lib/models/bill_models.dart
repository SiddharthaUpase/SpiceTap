import 'package:spice_tap/models/customer.dart';
import 'package:spice_tap/models/order_models.dart';

enum BillStatus { pending, paid }

class Bill {
  final String id;
  final String canteenId;
  final String customerId;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime generatedAt;
  final DateTime? paidAt;
  final double totalAmount;
  final BillStatus status;
  final List<String> orderIds;

  // Optional fields for UI convenience
  final Customer? customer;
  final List<Order>? orders;

  Bill({
    required this.id,
    required this.canteenId,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
    this.paidAt,
    required this.totalAmount,
    required this.status,
    required this.orderIds,
    this.customer,
    this.orders,
  });

  factory Bill.fromJson(Map<String, dynamic> json,
      {Customer? customer, List<Order>? orders}) {
    return Bill(
      id: json['id'],
      canteenId: json['canteen_id'],
      customerId: json['customer_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      generatedAt: DateTime.parse(json['generated_at']),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      totalAmount: double.parse(json['total_amount'].toString()),
      status: BillStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      orderIds: List<String>.from(json['order_ids']),
      customer: customer,
      orders: orders,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canteen_id': canteenId,
      'customer_id': customerId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'generated_at': generatedAt.toIso8601String(),
      'paid_at': paidAt?.toIso8601String(),
      'total_amount': totalAmount,
      'status': status.toString().split('.').last,
      'order_ids': orderIds,
    };
  }
}
