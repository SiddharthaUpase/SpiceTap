import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/quick_menu_models.dart';
import '../models/menu_models.dart';

class QuickMenuService {
  final SupabaseClient _client;
  static const String _tableName = 'quick_menu_items';

  QuickMenuService(this._client);

  Future<List<QuickMenuItem>> getQuickMenuItems(String canteenId) async {
    try {
      if (canteenId.isEmpty) {
        throw ArgumentError('Invalid canteen ID');
      }

      final response = await _client
          .from(_tableName)
          .select('*, menu_items(*)')
          .eq('canteen_id', canteenId)
          .order('position');

      return response.map<QuickMenuItem>((item) {
        final menuItem = item['menu_items'] != null
            ? MenuItem.fromJson(item['menu_items'])
            : null;
        return QuickMenuItem.fromJson(item, menuItem: menuItem);
      }).toList();
    } catch (e) {
      print("error: $e");
      throw Exception('Failed to get quick menu items: $e');
    }
  }

  Future<QuickMenuItem> addToQuickMenu(
      String canteenId, String menuItemId) async {
    try {
      // Get the highest position
      final positionResponse = await _client
          .from(_tableName)
          .select('position')
          .eq('canteen_id', canteenId)
          .order('position', ascending: false)
          .limit(1)
          .maybeSingle();

      final newPosition = (positionResponse?['position'] ?? 0) + 1;

      final response = await _client
          .from(_tableName)
          .insert({
            'canteen_id': canteenId,
            'menu_item_id': menuItemId,
            'position': newPosition,
          })
          .select('*, menu_items(*)')
          .single();

      final menuItem = response['menu_items'] != null
          ? MenuItem.fromJson(response['menu_items'])
          : null;
      return QuickMenuItem.fromJson(response, menuItem: menuItem);
    } catch (e) {
      throw Exception('Failed to add item to quick menu: $e');
    }
  }

  Future<void> removeFromQuickMenu(String quickMenuItemId) async {
    try {
      await _client.from(_tableName).delete().eq('id', quickMenuItemId);
    } catch (e) {
      throw Exception('Failed to remove item from quick menu: $e');
    }
  }

  Future<void> updatePosition(String itemId, int newPosition) async {
    try {
      await _client
          .from(_tableName)
          .update({'position': newPosition}).eq('id', itemId);
    } catch (e) {
      throw Exception('Failed to update item position: $e');
    }
  }
}
