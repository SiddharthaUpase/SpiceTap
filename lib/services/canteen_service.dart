import 'package:supabase_flutter/supabase_flutter.dart';

class CanteenService {
  final SupabaseClient _client;
  static const String _tableName = 'canteens';

  CanteenService(this._client);

  // Get canteen details
  Future<Map<String, dynamic>> getCanteen(String canteenId) async {
    try {
      final response =
          await _client.from(_tableName).select().eq('id', canteenId).single();
      return response;
    } catch (e) {
      throw Exception('Failed to get canteen details: $e');
    }
  }

  // Update canteen name
  Future<void> updateCanteenName(String canteenId, String name) async {
    try {
      await _client.from(_tableName).update({
        'name': name,
        'updated_at': DateTime.now().toIso8601String()
      }).eq('id', canteenId);
    } catch (e) {
      throw Exception('Failed to update canteen name: $e');
    }
  }
}
