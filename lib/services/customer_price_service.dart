import 'package:spice_tap/models/customer_menu_item_price.dart';
import 'package:spice_tap/models/menu_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerPriceService {
  final SupabaseClient _supabase;

  CustomerPriceService(this._supabase);

  // Get all custom prices for a customer in a specific canteen
  Future<Map<String, double>> getCustomPrices({
    required String canteenId,
    required String customerId,
  }) async {
    final response = await _supabase
        .from('customer_menu_item_prices')
        .select()
        .eq('canteen_id', canteenId)
        .eq('customer_id', customerId);

    return Map.fromEntries(
      (response as List).map(
        (item) => MapEntry(
          item['menu_item_id'],
          double.parse(item['custom_price'].toString()),
        ),
      ),
    );
  }

  // Set custom price for a menu item
  Future<void> setCustomPrice({
    required String canteenId,
    required String customerId,
    required String menuItemId,
    required double customPrice,
  }) async {
    await _supabase.from('customer_menu_item_prices').upsert({
      'canteen_id': canteenId,
      'customer_id': customerId,
      'menu_item_id': menuItemId,
      'custom_price': customPrice,
    });
  }

  // Remove custom price
  Future<void> removeCustomPrice({
    required String canteenId,
    required String customerId,
    required String menuItemId,
  }) async {
    await _supabase
        .from('customer_menu_item_prices')
        .delete()
        .eq('canteen_id', canteenId)
        .eq('customer_id', customerId)
        .eq('menu_item_id', menuItemId);
  }

  // Get all customers with custom prices for a specific canteen
  Future<List<String>> getCustomersWithCustomPrices(String canteenId) async {
    final response = await _supabase
        .from('customer_menu_item_prices')
        .select('customer_id')
        .eq('canteen_id', canteenId)
        .execute();

    return (await response)
        .data
        .map((item) => item['customer_id'] as String)
        .toSet()
        .toList();
  }

  // Get all menu items with custom prices for a specific customer in a canteen
  Future<List<CustomerMenuItemPrice>> getCustomPricedItems({
    required String canteenId,
    required String customerId,
  }) async {
    final response =
        await _supabase.from('customer_menu_item_prices').select('''
          *,
          menu_items (*)
        ''').eq('canteen_id', canteenId).eq('customer_id', customerId);

    return (response as List).map((item) {
      final menuItem = item['menu_items'] != null
          ? MenuItem.fromJson(item['menu_items'])
          : null;
      return CustomerMenuItemPrice.fromJson(item, menuItem: menuItem);
    }).toList();
  }
}
