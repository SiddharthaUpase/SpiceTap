import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_models.dart';
import '../models/customer.dart';
import '../models/menu_models.dart';
import 'dart:math';

class SalesAnalytics {
  final double totalSales;
  final List<MenuItemSales> topSellingItems;
  final List<CustomerSales> topCustomers;
  final Map<String, double> dailySales;
  final Map<String, double> monthlySales;

  SalesAnalytics({
    required this.totalSales,
    required this.topSellingItems,
    required this.topCustomers,
    required this.dailySales,
    required this.monthlySales,
  });
}

class MenuItemSales {
  final MenuItem menuItem;
  final int totalQuantity;
  final double totalRevenue;

  MenuItemSales({
    required this.menuItem,
    required this.totalQuantity,
    required this.totalRevenue,
  });
}

class CustomerSales {
  final Customer customer;
  final double totalSpent;
  final int orderCount;

  CustomerSales({
    required this.customer,
    required this.totalSpent,
    required this.orderCount,
  });
}

class SalesService {
  final SupabaseClient _supabase;

  SalesService(this._supabase);

  Future<SalesAnalytics> getSalesAnalytics({
    required String canteenId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get orders within the date range with all related data
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
        .eq('order_status', OrderStatus.completed.toString().split('.').last)
        .gte('created_at', startDate.toIso8601String())
        .lte('created_at', endDate.toIso8601String());

    final orders = (response as List).map((orderData) {
      final orderItems = (orderData['order_items'] as List).map((item) {
        return OrderItem.fromJson(
          item,
          menuItem: MenuItem.fromJson(item['menu_items']),
        );
      }).toList();

      return Order.fromJson(
        orderData,
        customer: Customer.fromJson(orderData['customers']),
        orderItems: orderItems,
      );
    }).toList();

    // Calculate total sales
    final totalSales = orders.fold<double>(
      0,
      (sum, order) => sum + order.totalAmount,
    );

    // Calculate sales by menu item
    final menuItemSales = <String, MenuItemSales>{};
    for (final order in orders) {
      for (final item in order.orderItems ?? []) {
        final menuItem = item.menuItem;
        if (menuItem == null) continue;

        final existing = menuItemSales[menuItem.id];
        if (existing == null) {
          menuItemSales[menuItem.id] = MenuItemSales(
            menuItem: menuItem,
            totalQuantity: item.quantity,
            totalRevenue: item.totalPrice,
          );
        } else {
          menuItemSales[menuItem.id] = MenuItemSales(
            menuItem: menuItem,
            totalQuantity: (existing.totalQuantity + item.quantity).toInt(),
            totalRevenue: existing.totalRevenue + item.totalPrice,
          );
        }
      }
    }

    // Calculate sales by customer
    final customerSales = <String, CustomerSales>{};
    for (final order in orders) {
      final customer = order.customer;
      if (customer == null) continue;

      final existing = customerSales[customer.id];
      if (existing == null) {
        customerSales[customer.id] = CustomerSales(
          customer: customer,
          totalSpent: order.totalAmount,
          orderCount: 1,
        );
      } else {
        customerSales[customer.id] = CustomerSales(
          customer: customer,
          totalSpent: existing.totalSpent + order.totalAmount,
          orderCount: existing.orderCount + 1,
        );
      }
    }

    // Calculate daily and monthly sales
    final dailySales = <String, double>{};
    final monthlySales = <String, double>{};

    for (final order in orders) {
      final date = order.createdAt;
      final dayKey = '${date.year}-${date.month}-${date.day}';
      final monthKey = '${date.year}-${date.month}';

      dailySales[dayKey] = (dailySales[dayKey] ?? 0) + order.totalAmount;
      monthlySales[monthKey] =
          (monthlySales[monthKey] ?? 0) + order.totalAmount;
    }

    return SalesAnalytics(
      totalSales: totalSales,
      topSellingItems: menuItemSales.values.toList()
        ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue)),
      topCustomers: customerSales.values.toList()
        ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent)),
      dailySales: dailySales,
      monthlySales: monthlySales,
    );
  }

  Future<void> generateDummyData(String canteenId) async {
    final startDate = DateTime(2025, 1, 1);
    final endDate = DateTime(2025, 3, 1);
    final random = Random();

    // Get all customers
    final customersResponse = await _supabase
        .from('customers')
        .select('*')
        .eq('canteen_id', canteenId);

    final customers = (customersResponse as List);
    if (customers.isEmpty) {
      throw Exception('No customers found. Please add customers first.');
    }

    // Get all menu items
    final menuItemsResponse = await _supabase
        .from('menu_items')
        .select('*')
        .eq('canteen_id', canteenId);

    final menuItems = (menuItemsResponse as List);
    if (menuItems.isEmpty) {
      throw Exception('No menu items found. Please add menu items first.');
    }

    // Generate orders for each day
    var currentDate = startDate;
    while (currentDate.isBefore(endDate)) {
      // Generate 5-15 orders per day
      final ordersPerDay = random.nextInt(10) + 5;

      for (var i = 0; i < ordersPerDay; i++) {
        // Create order
        final customer = customers[random.nextInt(customers.length)];
        final orderTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          random.nextInt(12) + 8, // Between 8 AM and 8 PM
          random.nextInt(60),
        );

        // Generate 1-5 items per order
        final itemCount = random.nextInt(4) + 1;
        final orderItems = <Map<String, dynamic>>[];
        double totalAmount = 0;

        for (var j = 0; j < itemCount; j++) {
          final menuItem = menuItems[random.nextInt(menuItems.length)];
          final quantity = random.nextInt(3) + 1;
          final pricePerUnit = menuItem['base_price'];
          final totalPrice = pricePerUnit * quantity;
          totalAmount += totalPrice;

          orderItems.add({
            'menu_item_id': menuItem['id'],
            'quantity': quantity,
            'price_per_unit': pricePerUnit,
            'total_price': totalPrice,
          });
        }

        // Insert order
        final orderResponse = await _supabase
            .from('orders')
            .insert({
              'canteen_id': canteenId,
              'customer_id': customer['id'],
              'total_amount': totalAmount,
              'payment_status': 'pending',
              'order_status': 'completed',
              'created_at': orderTime.toIso8601String(),
              'updated_at': orderTime.toIso8601String(),
            })
            .select()
            .single();

        // Insert order items
        for (final item in orderItems) {
          await _supabase.from('order_items').insert({
            'order_id': orderResponse['id'],
            'menu_item_id': item['menu_item_id'],
            'quantity': item['quantity'],
            'price_per_unit': item['price_per_unit'],
            'total_price': item['total_price'],
            'created_at': orderTime.toIso8601String(),
            'updated_at': orderTime.toIso8601String(),
          });
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
}
