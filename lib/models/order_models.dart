import 'package:spice_tap/models/customer.dart';
import 'package:spice_tap/models/menu_models.dart';

enum PaymentStatus { paid, pending }

enum OrderStatus { completed, cancelled }

class Order {
  final String id;
  final String canteenId;
  final String customerId;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final OrderStatus orderStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional fields for UI convenience
  final Customer? customer;
  final List<OrderItem>? orderItems;

  Order({
    required this.id,
    required this.canteenId,
    required this.customerId,
    required this.totalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.createdAt,
    required this.updatedAt,
    this.customer,
    this.orderItems,
  });

  factory Order.fromJson(Map<String, dynamic> json,
      {Customer? customer, List<OrderItem>? orderItems}) {
    return Order(
      id: json['id'],
      canteenId: json['canteen_id'],
      customerId: json['customer_id'],
      totalAmount: double.parse(json['total_amount'].toString()),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['payment_status'],
      ),
      orderStatus: OrderStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['order_status'],
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      customer: customer,
      orderItems: orderItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'canteen_id': canteenId,
      'customer_id': customerId,
      'total_amount': totalAmount,
      'payment_status': paymentStatus.toString().split('.').last,
      'order_status': orderStatus.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String menuItemId;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional field for UI convenience
  final MenuItem? menuItem;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.menuItemId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
    this.menuItem,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json, {MenuItem? menuItem}) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      menuItemId: json['menu_item_id'],
      quantity: json['quantity'],
      pricePerUnit: double.parse(json['price_per_unit'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      menuItem: menuItem,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'menu_item_id': menuItemId,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// For cart functionality
class CartItem {
  final MenuItem menuItem;
  int quantity;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
  });

  double get totalPrice => menuItem.basePrice * quantity;
}
