import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/customer.dart';

class AddCustomerDialog extends StatefulWidget {
  const AddCustomerDialog({super.key});

  @override
  State<AddCustomerDialog> createState() => _AddCustomerDialogState();
}

class _AddCustomerDialogState extends State<AddCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  CustomerType _customerType = CustomerType.credit;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _ownerRepNumberController = TextEditingController();
  final _creditLimitController = TextEditingController();
  final List<String> _shopNumbers = [];
  final _shopNumberController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add New Customer',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),

              // Customer Type Selection
              SegmentedButton<CustomerType>(
                segments: const [
                  ButtonSegment(
                    value: CustomerType.credit,
                    label: Text('Credit Customer'),
                    icon: Icon(Icons.business),
                  ),
                  ButtonSegment(
                    value: CustomerType.walkin,
                    label: Text('Walk-in Customer'),
                    icon: Icon(Icons.person),
                  ),
                ],
                selected: {_customerType},
                onSelectionChanged: (Set<CustomerType> newSelection) {
                  setState(() => _customerType = newSelection.first);
                },
              ),
              const SizedBox(height: 16),

              // Basic Info
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  hintText: 'Enter customer name',
                ),
                validator: _customerType == CustomerType.credit
                    ? (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter customer name';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter phone number',
                ),
                validator: _customerType == CustomerType.credit
                    ? (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter phone number';
                        }
                        return null;
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              // Credit Customer Specific Fields
              if (_customerType == CustomerType.credit) ...[
                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    hintText: 'Enter company name',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter company name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _ownerRepNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Owner/Rep Number',
                    hintText: 'Enter owner or representative number',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter owner/rep number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _creditLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit',
                    hintText: 'Enter credit limit',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter credit limit';
                    }
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Shop Numbers
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _shopNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Shop Number',
                          hintText: 'Enter shop number',
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

                if (_shopNumbers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: _shopNumbers.map((shopNumber) {
                      return Chip(
                        label: Text(shopNumber),
                        onDeleted: () {
                          setState(() {
                            _shopNumbers.remove(shopNumber);
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        Navigator.pop(context, {
                          'type': _customerType,
                          'name': _nameController.text,
                          'phoneNumber': _phoneController.text,
                          'companyName': _companyNameController.text,
                          'ownerRepNumber': _ownerRepNumberController.text,
                          'creditLimit':
                              double.tryParse(_creditLimitController.text) ??
                                  0.0,
                          'shopNumbers': _shopNumbers,
                        });
                      }
                    },
                    child: const Text('Add Customer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
