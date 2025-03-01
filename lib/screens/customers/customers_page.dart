import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer.dart';
import '../../models/credit_customer.dart';
import '../../services/customer_service.dart';
import 'add_customer_dialog.dart';
import 'customer_details_dialog.dart';

class CustomersPage extends StatefulWidget {
  final String canteenId;

  const CustomersPage({
    super.key,
    required this.canteenId,
  });

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _customerService = CustomerService(Supabase.instance.client);
  bool _isLoading = true;
  List<Customer> _customers = [];

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      setState(() => _isLoading = true);
      final customers = await _customerService.getCustomers(widget.canteenId);
      if (mounted) {
        setState(() {
          _customers = customers;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading customers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading customers: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddCustomerDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddCustomerDialog(),
    );

    if (result != null) {
      try {
        await _customerService.createCustomer(
          type: result['type'],
          canteenId: widget.canteenId,
          name: result['name'],
          phoneNumber: result['phoneNumber'],
          companyName: result['companyName'],
          ownerRepNumber: result['ownerRepNumber'],
          creditLimit: result['creditLimit'],
          shopNumbers: result['shopNumbers'],
        );

        // Refresh the customer list
        await _loadCustomers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer added successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding customer: $e')),
          );
        }
      }
    }
  }

  Future<void> _addDummyData() async {
    try {
      print('Starting to add dummy data...');

      print('Adding first credit customer...');
      // Add a credit customer with multiple shops
      await _customerService.createCustomer(
        type: CustomerType.credit,
        canteenId: widget.canteenId,
        name: 'John Doe',
        phoneNumber: '9876543210',
        companyName: 'ABC Trading Co.',
        ownerRepNumber: '1234567890',
        creditLimit: 50000,
        shopNumbers: ['SHOP-A1', 'SHOP-B2', 'SHOP-C3'],
      );
      print('First credit customer added successfully');

      print('Adding second credit customer...');
      // Add another credit customer
      await _customerService.createCustomer(
        type: CustomerType.credit,
        canteenId: widget.canteenId,
        name: 'Jane Smith',
        phoneNumber: '9876543211',
        companyName: 'XYZ Enterprises',
        ownerRepNumber: '9876543211',
        creditLimit: 25000,
        shopNumbers: ['SHOP-X1'],
      );
      print('Second credit customer added successfully');

      print('Adding walk-in customer...');
      // Add a walk-in customer
      await _customerService.createCustomer(
        type: CustomerType.walkin,
        canteenId: widget.canteenId,
        name: 'Walk-in Customer',
        phoneNumber: '9876543212',
      );
      print('Walk-in customer added successfully');

      print('Refreshing customer list...');
      // Refresh the list
      await _loadCustomers();
      print('Customer list refreshed successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dummy data added successfully')),
        );
      }
    } catch (e, stackTrace) {
      print('Error adding dummy data: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding dummy data: $e')),
        );
      }
    }
  }

  Future<void> _deleteCustomer(Customer customer) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Customer',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete ${customer is CreditCustomer ? customer.companyName : customer.name}? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _customerService.deleteCustomer(customer.id);
        await _loadCustomers(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Customer deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting customer: $e')),
          );
        }
      }
    }
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => CustomerDetailsDialog(
        customer: customer,
        canteenId: widget.canteenId,
        onCustomerUpdated: (updatedCustomer) {
          setState(() {
            final index =
                _customers.indexWhere((c) => c.id == updatedCustomer.id);
            if (index != -1) {
              _customers[index] = updatedCustomer;
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Customers',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // // Add Test Data Button
              // OutlinedButton.icon(
              //   onPressed: _addDummyData,
              //   icon: const Icon(Icons.data_array),
              //   label: const Text('Add Test Data'),
              // ),
              // const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _showAddCustomerDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Customer'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    child: ListView.separated(
                      itemCount: _customers.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final customer = _customers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Icon(
                              customer.customerType == CustomerType.credit
                                  ? Icons.business
                                  : Icons.person,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            customer is CreditCustomer
                                ? customer.companyName
                                : (customer.name ?? 'Walk-in Customer'),
                            style: GoogleFonts.poppins(),
                          ),
                          subtitle: Text(
                            customer is CreditCustomer
                                ? 'Credit Customer • ${customer.shopNumbers.length} shops'
                                : 'Walk-in Customer',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // if (customer is CreditCustomer) ...[
                              //   Text(
                              //     'Balance: ₹${customer.currentBalance}',
                              //     style: GoogleFonts.poppins(
                              //       color: customer.currentBalance > 0
                              //           ? Colors.red
                              //           : Colors.green,
                              //     ),
                              //   ),
                              //   const SizedBox(width: 16),
                              // ],
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showCustomerDetails(customer),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteCustomer(customer),
                              ),
                            ],
                          ),
                          onTap: () => _showCustomerDetails(customer),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
