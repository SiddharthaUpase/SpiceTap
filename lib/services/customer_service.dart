import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';
import '../models/credit_customer.dart';
import '../models/walk_in_customer.dart';

class CustomerService {
  final SupabaseClient _supabase;

  CustomerService(this._supabase);

  // Get all customers for a canteen
  Future<List<Customer>> getCustomers(String canteenId) async {
    final response = await _supabase.from('customers').select('''
          *,
          credit_customers!credit_customers_customer_id_fkey(
            *,
            customer_shop_numbers(shop_number)
          )
        ''').eq('canteen_id', canteenId);

    return (response as List).map((customer) {
      if (customer['customer_type'] == 'credit') {
        final creditCustomer = customer['credit_customers'];
        if (creditCustomer == null) {
          return CreditCustomer.fromJson({
            ...customer,
            'company_name': '',
            'owner_rep_number': '',
            'credit_limit': 0.0,
            'current_balance': 0.0,
            'shop_numbers': [],
          });
        }

        final shopNumbers =
            ((creditCustomer['customer_shop_numbers'] ?? []) as List)
                .map((shop) => shop['shop_number'] as String)
                .toList();

        return CreditCustomer.fromJson({
          ...customer,
          ...creditCustomer,
          'shop_numbers': shopNumbers,
        });
      } else {
        return WalkInCustomer.fromJson(customer);
      }
    }).toList();
  }

  // Create a new customer (either walk-in or credit)
  Future<Customer> createCustomer({
    required CustomerType type,
    required String canteenId,
    String? name,
    String? phoneNumber,
    // Credit customer specific fields
    String? companyName,
    String? ownerRepNumber,
    double? creditLimit,
    List<String>? shopNumbers,
  }) async {
    final customerData = {
      'name': name,
      'phone_number': phoneNumber,
      'customer_type': type.toString().split('.').last,
      'canteen_id': canteenId,
    };

    final response = await _supabase
        .from('customers')
        .insert(customerData)
        .select()
        .single();

    if (type == CustomerType.credit) {
      // Insert credit customer details
      final creditData = {
        'customer_id': response['id'],
        'company_name': companyName,
        'owner_rep_number': ownerRepNumber,
        'credit_limit': creditLimit ?? 0.0,
        'current_balance': 0.0,
      };

      await _supabase.from('credit_customers').insert(creditData);

      // Insert shop numbers if provided
      if (shopNumbers != null && shopNumbers.isNotEmpty) {
        final shopNumbersData = shopNumbers
            .map((shopNumber) => {
                  'customer_id': response['id'],
                  'shop_number': shopNumber,
                })
            .toList();

        await _supabase.from('customer_shop_numbers').insert(shopNumbersData);
      }

      // Fetch the complete credit customer data
      return getCustomerById(response['id']);
    }

    return WalkInCustomer.fromJson(response);
  }

  // Get a single customer by ID
  Future<Customer> getCustomerById(String id) async {
    final response = await _supabase.from('customers').select('''
          *,
          credit_customers!credit_customers_customer_id_fkey(
            *,
            customer_shop_numbers(shop_number)
          )
        ''').eq('id', id).single();

    if (response['customer_type'] == 'credit') {
      final creditCustomer = response['credit_customers'];
      if (creditCustomer == null) {
        return CreditCustomer.fromJson({
          ...response,
          'company_name': '',
          'owner_rep_number': '',
          'credit_limit': 0.0,
          'current_balance': 0.0,
          'shop_numbers': [],
        });
      }

      final shopNumbers =
          ((creditCustomer['customer_shop_numbers'] ?? []) as List)
              .map((shop) => shop['shop_number'] as String)
              .toList();

      return CreditCustomer.fromJson({
        ...response,
        ...creditCustomer,
        'shop_numbers': shopNumbers,
      });
    }

    return WalkInCustomer.fromJson(response);
  }

  // Update customer
  Future<Customer> updateCustomer({
    required String id,
    String? name,
    String? phoneNumber,
    // Credit customer specific fields
    String? companyName,
    String? ownerRepNumber,
    double? creditLimit,
    List<String>? shopNumbers,
  }) async {
    final customerData = {
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };

    if (customerData.isNotEmpty) {
      await _supabase.from('customers').update(customerData).eq('id', id);
    }

    final customer = await getCustomerById(id);
    if (customer is CreditCustomer) {
      final creditData = {
        if (companyName != null) 'company_name': companyName,
        if (ownerRepNumber != null) 'owner_rep_number': ownerRepNumber,
        if (creditLimit != null) 'credit_limit': creditLimit,
      };

      if (creditData.isNotEmpty) {
        await _supabase
            .from('credit_customers')
            .update(creditData)
            .eq('customer_id', id);
      }

      if (shopNumbers != null) {
        // Delete existing shop numbers
        await _supabase
            .from('customer_shop_numbers')
            .delete()
            .eq('customer_id', id);

        // Insert new shop numbers
        final shopNumbersData = shopNumbers
            .map((shopNumber) => {
                  'customer_id': id,
                  'shop_number': shopNumber,
                })
            .toList();

        await _supabase.from('customer_shop_numbers').insert(shopNumbersData);
      }
    }

    return getCustomerById(id);
  }

  // Delete customer
  Future<void> deleteCustomer(String id) async {
    await _supabase.from('customers').delete().eq('id', id);
  }
}
