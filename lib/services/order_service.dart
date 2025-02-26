import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_models.dart';
import '../models/customer.dart';
import '../models/menu_models.dart';

class OrderService {
  final SupabaseClient _client;
  static const String _ordersTable = 'orders';
  static const String _orderItemsTable = 'order_items';

  OrderService(this._client);

  // Create a new order with items
  Future<Order> createOrder({
    required String canteenId,
    required String customerId,
    required List<CartItem> cartItems,
    required PaymentStatus paymentStatus,
  }) async {
    try {
      // Calculate total amount
      final totalAmount = cartItems.fold<double>(
        0,
        (sum, item) => sum + (item.menuItem.basePrice * item.quantity),
      );

      // Begin transaction
      final response = await _client
          .rpc('create_order', params: {
            'p_canteen_id': canteenId,
            'p_customer_id': customerId,
            'p_total_amount': totalAmount,
            'p_payment_status': paymentStatus.toString().split('.').last,
          })
          .select()
          .single();

      final orderId = response['id'];

      // Insert order items
      for (var item in cartItems) {
        await _client.from(_orderItemsTable).insert({
          'order_id': orderId,
          'menu_item_id': item.menuItem.id,
          'quantity': item.quantity,
          'price_per_unit': item.menuItem.basePrice,
          'total_price': item.menuItem.basePrice * item.quantity,
        });
      }

      // Get the complete order with items
      return getOrderById(orderId);
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get order by ID with items
  Future<Order> getOrderById(String orderId) async {
    try {
      final orderResponse = await _client
          .from(_ordersTable)
          .select('*, customers(*)')
          .eq('id', orderId)
          .single();

      final itemsResponse = await _client
          .from(_orderItemsTable)
          .select('*, menu_items(*)')
          .eq('order_id', orderId);

      final customer = Customer.fromJson(orderResponse['customers']);

      final orderItems = itemsResponse.map<OrderItem>((item) {
        final menuItem = MenuItem.fromJson(item['menu_items']);
        return OrderItem.fromJson(item, menuItem: menuItem);
      }).toList();

      return Order.fromJson(
        orderResponse,
        customer: customer,
        orderItems: orderItems,
      );
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Get all orders for a canteen
  Future<List<Order>> getOrders(String canteenId) async {
    try {
      final response = await _client
          .from(_ordersTable)
          .select('*, customers(*)')
          .eq('canteen_id', canteenId)
          .order('created_at', ascending: false);

      return response.map<Order>((order) {
        final customer = Customer.fromJson(order['customers']);
        return Order.fromJson(order, customer: customer);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get orders: $e');
    }
  }

  // Get order items for an order
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      final response = await _client
          .from(_orderItemsTable)
          .select('*, menu_items(*)')
          .eq('order_id', orderId);

      return response.map<OrderItem>((item) {
        final menuItem = MenuItem.fromJson(item['menu_items']);
        return OrderItem.fromJson(item, menuItem: menuItem);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get order items: $e');
    }
  }

  // Update order payment status
  Future<void> updatePaymentStatus(String orderId, PaymentStatus status) async {
    try {
      await _client.from(_ordersTable).update({
        'payment_status': status.toString().split('.').last,
      }).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Cancel an order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _client.from(_ordersTable).update({
        'order_status': OrderStatus.cancelled.toString().split('.').last,
      }).eq('id', orderId);
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }
}
