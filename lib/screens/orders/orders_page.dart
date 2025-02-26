import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/order_models.dart';
import '../../models/customer.dart';
import '../../models/credit_customer.dart';
import '../../services/order_service.dart';
import '../../services/customer_service.dart';
import 'order_details_screen.dart';
import '../../services/pdf_service.dart';

class OrdersPage extends StatefulWidget {
  final String canteenId;

  const OrdersPage({super.key, required this.canteenId});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderService _orderService = OrderService(Supabase.instance.client);
  final CustomerService _customerService =
      CustomerService(Supabase.instance.client);
  final PdfService _pdfService = PdfService();

  List<Order> _orders = [];
  List<Customer> _customers = [];
  bool _isLoading = true;

  // Filtering and sorting
  DateTime? _startDate;
  DateTime? _endDate;
  Customer? _selectedCustomer;
  String _searchQuery = '';
  String _sortBy = 'date_desc'; // Default sort by date descending

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadOrders(),
        _loadCustomers(),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadOrders() async {
    final orders = await _orderService.getOrders(widget.canteenId);
    if (mounted) {
      setState(() {
        _orders = orders;
      });
    }
  }

  Future<void> _loadCustomers() async {
    final customers = await _customerService.getCustomers(widget.canteenId);
    if (mounted) {
      setState(() {
        _customers = customers;
      });
    }
  }

  List<Order> get _filteredOrders {
    return _orders.where((order) {
      // Filter by date range
      if (_startDate != null && order.createdAt.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null) {
        final endOfDay = DateTime(
            _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (order.createdAt.isAfter(endOfDay)) {
          return false;
        }
      }

      // Filter by customer
      if (_selectedCustomer != null &&
          order.customerId != _selectedCustomer!.id) {
        return false;
      }

      // Filter by search query (order ID or customer name or shop number)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final customerName = order.customer?.name?.toLowerCase() ?? '';

        // Check shop numbers for credit customers
        bool matchesShopNumber = false;
        if (order.customer is CreditCustomer) {
          final creditCustomer = order.customer as CreditCustomer;
          matchesShopNumber = creditCustomer.shopNumbers
              .any((shopNumber) => shopNumber.toLowerCase().contains(query));
        }

        return order.id.toLowerCase().contains(query) ||
            customerName.contains(query) ||
            matchesShopNumber;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // Sort orders
        switch (_sortBy) {
          case 'date_asc':
            return a.createdAt.compareTo(b.createdAt);
          case 'date_desc':
            return b.createdAt.compareTo(a.createdAt);
          case 'amount_asc':
            return a.totalAmount.compareTo(b.totalAmount);
          case 'amount_desc':
            return b.totalAmount.compareTo(a.totalAmount);
          default:
            return b.createdAt.compareTo(a.createdAt);
        }
      });
  }

  Future<void> _selectDateRange() async {
    final initialDateRange = DateTimeRange(
      start: _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
      end: _endDate ?? DateTime.now(),
    );

    final pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCustomer = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _viewOrderDetails(Order order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(
          orderId: order.id,
          onOrderUpdated: _loadOrders,
        ),
      ),
    );
  }

  Future<void> _printOrdersReport() async {
    if (_filteredOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders to print')),
      );
      return;
    }

    try {
      await _pdfService.generateOrdersReport(
        orders: _filteredOrders,
        canteenName:
            'SpiceTap Canteen', // You might want to get this from your app state
        startDate:
            _startDate ?? DateTime.now().subtract(const Duration(days: 7)),
        endDate: _endDate ?? DateTime.now(),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Orders',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _printOrdersReport,
            icon: const Icon(Icons.print),
            tooltip: 'Print Orders Report',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Date range filter
                          Expanded(
                            child: InkWell(
                              onTap: _selectDateRange,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _startDate == null
                                            ? 'Select Date Range'
                                            : '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate ?? DateTime.now())}',
                                        style:
                                            GoogleFonts.poppins(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Customer filter
                          Expanded(
                            child: DropdownButtonFormField<Customer>(
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                hintText: 'Select Customer',
                              ),
                              value: _selectedCustomer,
                              items: [
                                const DropdownMenuItem<Customer>(
                                  value: null,
                                  child: Text('All Customers'),
                                ),
                                ..._customers.map((customer) {
                                  String displayText =
                                      customer.name ?? 'Unnamed';
                                  if (customer is CreditCustomer &&
                                      customer.shopNumbers.isNotEmpty) {
                                    displayText +=
                                        ' (${customer.shopNumbers.first})';
                                  }
                                  return DropdownMenuItem<Customer>(
                                    value: customer,
                                    child: Text(
                                      displayText,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCustomer = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          // Search field
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText:
                                    'Search by order ID, customer, shop...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(4),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Sort dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: DropdownButton<String>(
                              value: _sortBy,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'date_desc',
                                  child: Text('Newest First'),
                                ),
                                DropdownMenuItem(
                                  value: 'date_asc',
                                  child: Text('Oldest First'),
                                ),
                                DropdownMenuItem(
                                  value: 'amount_desc',
                                  child: Text('Highest Amount'),
                                ),
                                DropdownMenuItem(
                                  value: 'amount_asc',
                                  child: Text('Lowest Amount'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _sortBy = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Clear filters button
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear, size: 16),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Orders list
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? Center(
                          child: Text(
                            'No orders found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredOrders.length,
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final order = _filteredOrders[index];
                            final customer = order.customer;

                            // Get shop number for credit customers
                            String shopNumber = '';
                            if (customer is CreditCustomer &&
                                customer.shopNumbers.isNotEmpty) {
                              shopNumber = customer.shopNumbers.first;
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: InkWell(
                                onTap: () => _viewOrderDetails(order),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Order ID and date
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Order #${order.id.substring(0, 8)}',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormat(
                                                          'MMM d, yyyy • h:mm a')
                                                      .format(order.createdAt),
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Payment status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: order.paymentStatus ==
                                                      PaymentStatus.paid
                                                  ? Colors.green[50]
                                                  : Colors.orange[50],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              order.paymentStatus ==
                                                      PaymentStatus.paid
                                                  ? 'Paid'
                                                  : 'Pending',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: order.paymentStatus ==
                                                        PaymentStatus.paid
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      // Customer info
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Customer',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                Text(
                                                  customer?.name ?? 'Unknown',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (shopNumber.isNotEmpty)
                                                  Text(
                                                    'Shop: $shopNumber',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          // Order amount
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Amount',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              Text(
                                                '₹${order.totalAmount.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                  color: Theme.of(context)
                                                      .primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
