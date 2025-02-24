import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/customer.dart';
import '../../models/credit_customer.dart';
import '../../services/customer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerDetailsDialog extends StatefulWidget {
  final Customer customer;
  final Function(Customer) onCustomerUpdated;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
    required this.onCustomerUpdated,
  });

  @override
  State<CustomerDetailsDialog> createState() => _CustomerDetailsDialogState();
}

class _CustomerDetailsDialogState extends State<CustomerDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditing = false;
  final _customerService = CustomerService(Supabase.instance.client);

  // Form controllers
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _companyNameController;
  late final TextEditingController _ownerRepNumberController;
  late final TextEditingController _creditLimitController;
  late final TextEditingController _shopNumberController;
  late List<String> _shopNumbers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);

    if (widget.customer is CreditCustomer) {
      final creditCustomer = widget.customer as CreditCustomer;
      _companyNameController =
          TextEditingController(text: creditCustomer.companyName);
      _ownerRepNumberController =
          TextEditingController(text: creditCustomer.ownerRepNumber);
      _creditLimitController =
          TextEditingController(text: creditCustomer.creditLimit.toString());
      _shopNumberController = TextEditingController();
      _shopNumbers = List.from(creditCustomer.shopNumbers);
    } else {
      _companyNameController = TextEditingController();
      _ownerRepNumberController = TextEditingController();
      _creditLimitController = TextEditingController();
      _shopNumberController = TextEditingController();
      _shopNumbers = [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _ownerRepNumberController.dispose();
    _creditLimitController.dispose();
    _shopNumberController.dispose();
    super.dispose();
  }

  void _addShopNumber() {
    final shopNumber = _shopNumberController.text.trim();
    if (shopNumber.isNotEmpty && !_shopNumbers.contains(shopNumber)) {
      setState(() {
        _shopNumbers.add(shopNumber);
        _shopNumberController.clear();
      });
    }
  }

  void _removeShopNumber(String shopNumber) {
    setState(() {
      _shopNumbers.remove(shopNumber);
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final updatedCustomer = await _customerService.updateCustomer(
        id: widget.customer.id,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        companyName: widget.customer is CreditCustomer
            ? _companyNameController.text
            : null,
        ownerRepNumber: widget.customer is CreditCustomer
            ? _ownerRepNumberController.text
            : null,
        creditLimit: widget.customer is CreditCustomer
            ? double.parse(_creditLimitController.text)
            : null,
        shopNumbers: widget.customer is CreditCustomer ? _shopNumbers : null,
      );

      if (mounted) {
        widget.onCustomerUpdated(updatedCustomer);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer updated successfully')),
        );
        setState(() => _isEditing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating customer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Customer Details',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!_isEditing)
                    FilledButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    )
                  else
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _initializeControllers();
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: _saveChanges,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                enabled: _isEditing,
                validator: (value) =>
                    value?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                enabled: _isEditing,
              ),
              if (widget.customer is CreditCustomer) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(),
                  ),
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty == true
                      ? 'Company name is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ownerRepNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Owner/Representative Number',
                    border: OutlineInputBorder(),
                  ),
                  enabled: _isEditing,
                  validator: (value) => value?.isEmpty == true
                      ? 'Owner/Representative number is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _creditLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true)
                      return 'Credit limit is required';
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Shop Numbers',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (_isEditing)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _shopNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Add Shop Number',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _addShopNumber,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _shopNumbers.map((shopNumber) {
                    return Chip(
                      label: Text(shopNumber),
                      onDeleted: _isEditing
                          ? () => _removeShopNumber(shopNumber)
                          : null,
                    );
                  }).toList(),
                ),
                if (widget.customer is CreditCustomer) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Current Balance: ₹${(widget.customer as CreditCustomer).currentBalance}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color:
                          (widget.customer as CreditCustomer).currentBalance > 0
                              ? Colors.red
                              : Colors.green,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
