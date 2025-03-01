import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/customer.dart';
import '../../models/credit_customer.dart';
import '../../services/customer_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom_prices_tab.dart';

class CustomerDetailsDialog extends StatefulWidget {
  final Customer customer;
  final Function(Customer) onCustomerUpdated;
  final String canteenId;

  const CustomerDetailsDialog({
    super.key,
    required this.customer,
    required this.onCustomerUpdated,
    required this.canteenId,
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
    return DefaultTabController(
      length: 2,
      child: Dialog(
        child: Container(
          width: 800,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
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
              TabBar(
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'Custom Prices'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Information',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                hintText: 'Enter customer name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.white,
                                labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              enabled: _isEditing,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight:
                                    !_isEditing ? FontWeight.w500 : null,
                              ),
                              validator: (value) => value?.isEmpty == true
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                hintText: 'Enter phone number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: !_isEditing,
                                fillColor: _isEditing ? null : Colors.white,
                                labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                                floatingLabelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              enabled: _isEditing,
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight:
                                    !_isEditing ? FontWeight.w500 : null,
                              ),
                            ),
                            if (widget.customer is CreditCustomer) ...[
                              const SizedBox(height: 32),
                              Text(
                                'Company Information',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _companyNameController,
                                decoration: InputDecoration(
                                  labelText: 'Company Name',
                                  hintText: 'Enter company name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: !_isEditing,
                                  fillColor: _isEditing ? null : Colors.white,
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                enabled: _isEditing,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight:
                                      !_isEditing ? FontWeight.w500 : null,
                                ),
                                validator: (value) => value?.isEmpty == true
                                    ? 'Company name is required'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _ownerRepNumberController,
                                decoration: InputDecoration(
                                  labelText:
                                      'Owner/Representative Number (Optional)',
                                  hintText:
                                      'Enter owner or representative number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: !_isEditing,
                                  fillColor: _isEditing ? null : Colors.white,
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                enabled: _isEditing,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight:
                                      !_isEditing ? FontWeight.w500 : null,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _creditLimitController,
                                decoration: InputDecoration(
                                  labelText: 'Credit Limit (Optional)',
                                  hintText: 'Enter credit limit',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: !_isEditing,
                                  fillColor: _isEditing ? null : Colors.white,
                                  labelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                enabled: _isEditing,
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight:
                                      !_isEditing ? FontWeight.w500 : null,
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value?.isEmpty == true) {
                                    return null;
                                  }
                                  if (double.tryParse(value!) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Shop Numbers',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_isEditing)
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _shopNumberController,
                                        decoration: InputDecoration(
                                          labelText: 'Add Shop Number',
                                          hintText:
                                              'Enter shop number and press Enter',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onFieldSubmitted: (_) =>
                                            _addShopNumber(),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: _addShopNumber,
                                      icon: const Icon(Icons.add),
                                      style: IconButton.styleFrom(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              if (_shopNumbers.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _shopNumbers.map((shopNumber) {
                                      return Chip(
                                        label: Text(shopNumber),
                                        onDeleted: _isEditing
                                            ? () =>
                                                _removeShopNumber(shopNumber)
                                            : null,
                                        backgroundColor: Colors.grey[100],
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    CustomPricesTab(
                      canteenId: widget.canteenId,
                      customer: widget.customer,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
