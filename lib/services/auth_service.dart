import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AuthService {
  final supabase = Supabase.instance.client;
  Future<Map<String, dynamic>> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      debugPrint('Attempting sign in for phone: $phone');

      // First check if user exists in our users table
      final response = await supabase
          .from('users')
          .select()
          .eq('phone_number', phone)
          .single();

      debugPrint('User found: ${response.toString()}');

      // Get associated canteen if it exists
      String? canteenId;
      try {
        final canteenResponse = await supabase
            .from('canteens')
            .select('id')
            .eq('owner_id', response['id'])
            .single();
        canteenId = canteenResponse['id'];
      } catch (e) {
        debugPrint('No canteen found for user: ${e.toString()}');
      }

      //create a session token a uuid
      final sessionToken = Uuid().v4();

      // Verify password (in production, use proper password hashing)
      if (response['password'] == password) {
        debugPrint('Password verified successfully');
        print('Login successful');
        return {
          'success': true,
          'user': response,
          'token': sessionToken,
          'canteenId': canteenId,
        };
      } else {
        debugPrint('Password verification failed');
        return {
          'success': false,
          'message': 'Invalid credentials',
        };
      }
    } catch (e) {
      debugPrint('Sign in error: ${e.toString()}');
      return {
        'success': false,
        'message': 'User not found',
      };
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String phone,
    required String password,
    required String fullName,
  }) async {
    try {
      // Check if user already exists
      final existing =
          await supabase.from('users').select().eq('phone_number', phone);

      if (existing.isNotEmpty) {
        return {
          'success': false,
          'message': 'Phone number already registered',
        };
      }

      // Create new user
      final response = await supabase.from('users').insert({
        'phone_number': phone,
        'password': password, // In production, hash this password
        'full_name': fullName,
      }).select();

      //create a session token a uuid
      final sessionToken = Uuid().v4();

      return {
        'success': true,
        'user': response[0],
        'token': sessionToken,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to create account',
      };
    }
  }

  Future<Map<String, dynamic>> checkCanteenExists(String userId) async {
    try {
      final response = await supabase
          .from('canteens')
          .select()
          .eq('owner_id', userId)
          .single();
      if (response.isNotEmpty) {
        return {
          'success': true,
          'canteenId': response['id'],
        };
      } else {
        return {
          'success': false,
          'canteenId': null,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'canteenId': null,
      };
    }
  }

  Future<Map<String, dynamic>> createCanteen(
      {required String userId, required String name}) async {
    try {
      final response = await supabase
          .from('canteens')
          .insert({
            'owner_id': userId,
            'name': name,
          })
          .select()
          .single();

      return {
        'success': true,
        'canteenId': response['id'],
      };
    } catch (e) {
      print('Error creating canteen: $e');
      return {
        'success': false,
        'canteenId': null,
      };
    }
  }
}
