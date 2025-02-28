import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_models.dart';

class MenuService {
  final SupabaseClient _supabase;

  MenuService(this._supabase);

  // Categories CRUD
  Future<List<MenuCategory>> getCategories(String? canteenId) async {
    try {
      if (canteenId == null || canteenId.isEmpty) {
        throw ArgumentError('canteenId cannot be null or empty');
      }

      final response = await _supabase
          .from('menu_categories')
          .select()
          .eq('canteen_id', canteenId)
          .order('name');

      return (response as List)
          .map((category) => MenuCategory.fromJson(category))
          .toList();
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  Future<MenuCategory> createCategory(String name, String? canteenId,
      {String? description}) async {
    try {
      if (canteenId == null || canteenId.isEmpty) {
        throw ArgumentError('canteenId cannot be null or empty');
      }

      final response = await _supabase
          .from('menu_categories')
          .insert({
            'name': name,
            'description': description,
            'canteen_id': canteenId,
          })
          .select()
          .single();

      return MenuCategory.fromJson(response);
    } catch (e) {
      print('Error creating category: $e');
      rethrow;
    }
  }

  Future<MenuCategory> updateCategory(MenuCategory category) async {
    try {
      final response = await _supabase
          .from('menu_categories')
          .update(category.toJson())
          .eq('id', category.id)
          .select()
          .single();

      return MenuCategory.fromJson(response);
    } catch (e) {
      print('Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _supabase.from('menu_categories').delete().eq('id', categoryId);
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Menu Items CRUD
  Future<List<MenuItem>> getMenuItems(String canteenId) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .select()
          .eq('canteen_id', canteenId)
          .order('name');

      return (response as List).map((item) => MenuItem.fromJson(item)).toList();
    } catch (e) {
      print('Error getting menu items: $e');
      rethrow;
    }
  }

  Future<MenuItem> createMenuItem(
    String name,
    double basePrice,
    String categoryId,
    String canteenId, {
    String? description,
    bool isAvailable = true,
  }) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .insert({
            'name': name,
            'description': description,
            'base_price': basePrice,
            'category_id': categoryId,
            'is_available': isAvailable,
            'canteen_id': canteenId,
          })
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      print('Error creating menu item: $e');
      rethrow;
    }
  }

  Future<MenuItem> updateMenuItem(MenuItem item) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .update(item.toJson())
          .eq('id', item.id)
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      print('Error updating menu item: $e');
      rethrow;
    }
  }

  Future<void> deleteMenuItem(String itemId) async {
    try {
      await _supabase.from('menu_items').delete().eq('id', itemId);
    } catch (e) {
      print('Error deleting menu item: $e');
      rethrow;
    }
  }

  Future<List<MenuCategory>> getMenuCategories(String canteenId) async {
    final response = await _supabase
        .from('menu_categories')
        .select()
        .eq('canteen_id', canteenId);

    return (response as List)
        .map((json) => MenuCategory.fromJson(json))
        .toList();
  }
}
