import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/bill_models.dart';
import '../../models/customer.dart';
import '../../services/bill_service.dart';
import '../../services/customer_service.dart';
import 'bill_details_dialog.dart';

class BillsPage extends StatefulWidget {
  final String canteenId;

  const BillsPage({super.key, required this.canteenId});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final _billService = BillService(Supabase.instance.client);
  final _customerService = CustomerService(Supabase.instance.client);
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');

  bool _isLoading = true;
  List<Bill> _bills = [];
  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadBills(),
        _loadCustomers(),
      ]);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBills() async {
    final bills = await _billService.getBills(widget.canteenId);
    setState(() => _bills = bills);
  }

  Future<void> _loadCustomers() async {
    final customers = await _customerService.getCustomers(widget.canteenId);
    setState(() => _customers = customers);
  }

  Future<void> _generateBill() async {
    if (_selectedCustomer == null || _selectedDateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select customer and date range')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final orders = await _billService.getUnpaidOrders(
        canteenId: widget.canteenId,
        customerId: _selectedCustomer!.id,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
      );

      if (orders.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No unpaid orders found for selected period')),
          );
        }
        return;
      }

      await _billService.generateBill(
        canteenId: widget.canteenId,
        customerId: _selectedCustomer!.id,
        startDate: _selectedDateRange!.start,
        endDate: _selectedDateRange!.end,
        orders: orders,
      );

      // Reset selection
      setState(() {
        _selectedCustomer = null;
        _selectedDateRange = null;
      });

      // Refresh bills list
      await _loadBills();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating bill: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markBillAsPaid(Bill bill) async {
    try {
      setState(() => _isLoading = true);
      await _billService.markBillAsPaid(bill.id);
      await _loadBills();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill marked as paid')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking bill as paid: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bills',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildBillGenerator(),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBillsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillGenerator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Generate New Bill',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<Customer>(
                    value: _selectedCustomer,
                    decoration: const InputDecoration(
                      labelText: 'Select Customer',
                      border: OutlineInputBorder(),
                    ),
                    items: _customers.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text(customer.name ?? 'Unknown'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCustomer = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final dateRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        initialDateRange: _selectedDateRange ??
                            DateTimeRange(
                              start: DateTime.now().subtract(
                                const Duration(days: 30),
                              ),
                              end: DateTime.now(),
                            ),
                      );
                      if (dateRange != null) {
                        setState(() => _selectedDateRange = dateRange);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Select Date Range',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _selectedDateRange != null
                            ? '${_dateFormat.format(_selectedDateRange!.start)} - ${_dateFormat.format(_selectedDateRange!.end)}'
                            : 'Select dates',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _generateBill,
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Generate Bill'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsList() {
    if (_bills.isEmpty) {
      return Center(
        child: Text(
          'No bills generated yet',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _bills.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final bill = _bills[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                bill.status == BillStatus.paid
                    ? Icons.check_circle
                    : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text(
              bill.customer?.name ?? 'Unknown Customer',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_dateFormat.format(bill.startDate)} - ${_dateFormat.format(bill.endDate)}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currencyFormat.format(bill.totalAmount),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                if (bill.status == BillStatus.pending)
                  FilledButton.icon(
                    onPressed: () => _markBillAsPaid(bill),
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Paid'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => BillDetailsDialog(bill: bill),
                      );
                    },
                    icon: const Icon(Icons.print),
                    label: const Text('View & Print'),
                  ),
              ],
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => BillDetailsDialog(bill: bill),
              );
            },
          );
        },
      ),
    );
  }
}
