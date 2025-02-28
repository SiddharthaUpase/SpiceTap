import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bill_models.dart';
import '../models/customer.dart';
import '../models/order_models.dart';
import '../models/menu_models.dart';

class BillService {
  final SupabaseClient _supabase;

  BillService(this._supabase);

  // Get all bills for a canteen
  Future<List<Bill>> getBills(String canteenId) async {
    // First, get all bills
    final billsResponse = await _supabase
        .from('bills')
        .select('*, customers (*)')
        .eq('canteen_id', canteenId);

    final bills = await Future.wait((billsResponse as List).map((bill) async {
      final customer = Customer.fromJson(bill['customers']);

      // Then, fetch orders for each bill using the order_ids array
      final ordersResponse = await _supabase.from('orders').select('''
            *,
            order_items (
              *,
              menu_items (*)
            )
          ''').in_('id', bill['order_ids']);

      final orders = (ordersResponse as List).map((order) {
        final orderItems = (order['order_items'] as List).map((item) {
          return OrderItem.fromJson(
            item,
            menuItem: MenuItem.fromJson(item['menu_items']),
          );
        }).toList();

        return Order.fromJson(
          order,
          customer: customer,
          orderItems: orderItems,
        );
      }).toList();

      return Bill.fromJson(bill, customer: customer, orders: orders);
    }));

    return bills;
  }

  // Get unpaid orders for a customer in date range
  Future<List<Order>> getUnpaidOrders({
    required String canteenId,
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await _supabase
        .from('orders')
        .select('''
          *,
          order_items (
            *,
            menu_items (*)
          ),
          customers (*)
        ''')
        .eq('canteen_id', canteenId)
        .eq('customer_id', customerId)
        .eq('payment_status', 'pending')
        .eq('order_status', 'completed')
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());

    return (response as List).map((order) {
      final orderItems = (order['order_items'] as List).map((item) {
        return OrderItem.fromJson(
          item,
          menuItem: MenuItem.fromJson(item['menu_items']),
        );
      }).toList();

      return Order.fromJson(
        order,
        customer: Customer.fromJson(order['customers']),
        orderItems: orderItems,
      );
    }).toList();
  }

  // Generate a new bill
  Future<Bill> generateBill({
    required String canteenId,
    required String customerId,
    required DateTime startDate,
    required DateTime endDate,
    required List<Order> orders,
  }) async {
    final totalAmount = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    // Insert the bill first
    final billResponse = await _supabase
        .from('bills')
        .insert({
          'canteen_id': canteenId,
          'customer_id': customerId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'total_amount': totalAmount,
          'order_ids': orders.map((o) => o.id).toList(),
          'status': 'pending',
        })
        .select('*, customers (*)')
        .single();

    // Then fetch the orders separately
    final ordersResponse = await _supabase.from('orders').select('''
          *,
          order_items (
            *,
            menu_items (*)
          )
        ''').in_('id', billResponse['order_ids']);

    final customer = Customer.fromJson(billResponse['customers']);
    final billOrders = (ordersResponse as List).map((order) {
      final orderItems = (order['order_items'] as List).map((item) {
        return OrderItem.fromJson(
          item,
          menuItem: MenuItem.fromJson(item['menu_items']),
        );
      }).toList();

      return Order.fromJson(
        order,
        customer: customer,
        orderItems: orderItems,
      );
    }).toList();

    return Bill.fromJson(billResponse, customer: customer, orders: billOrders);
  }

  // Mark a bill as paid
  Future<Bill> markBillAsPaid(String billId) async {
    // Start a transaction to update both bill and orders
    final response = await _supabase.rpc('mark_bill_as_paid', params: {
      'bill_id': billId,
    });

    // Fetch the updated bill with its related data
    final billResponse = await _supabase
        .from('bills')
        .select('*, customers (*)')
        .eq('id', billId)
        .single();

    final ordersResponse = await _supabase.from('orders').select('''
          *,
          order_items (
            *,
            menu_items (*)
          )
        ''').in_('id', billResponse['order_ids']);

    final customer = Customer.fromJson(billResponse['customers']);
    final orders = (ordersResponse as List).map((order) {
      final orderItems = (order['order_items'] as List).map((item) {
        return OrderItem.fromJson(
          item,
          menuItem: MenuItem.fromJson(item['menu_items']),
        );
      }).toList();

      return Order.fromJson(
        order,
        customer: customer,
        orderItems: orderItems,
      );
    }).toList();

    return Bill.fromJson(billResponse, customer: customer, orders: orders);
  }

  // Get a single bill by ID
  Future<Bill> getBillById(String id) async {
    final billResponse = await _supabase
        .from('bills')
        .select('*, customers (*)')
        .eq('id', id)
        .single();

    final ordersResponse = await _supabase.from('orders').select('''
          *,
          order_items (
            *,
            menu_items (*)
          )
        ''').in_('id', billResponse['order_ids']);

    final customer = Customer.fromJson(billResponse['customers']);
    final orders = (ordersResponse as List).map((order) {
      final orderItems = (order['order_items'] as List).map((item) {
        return OrderItem.fromJson(
          item,
          menuItem: MenuItem.fromJson(item['menu_items']),
        );
      }).toList();

      return Order.fromJson(
        order,
        customer: customer,
        orderItems: orderItems,
      );
    }).toList();

    return Bill.fromJson(billResponse, customer: customer, orders: orders);
  }
}
