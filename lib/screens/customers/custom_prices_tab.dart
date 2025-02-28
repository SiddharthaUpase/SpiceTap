import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/customer.dart';
import '../../models/menu_models.dart';
import '../../models/customer_menu_item_price.dart';
import '../../services/customer_price_service.dart';
import '../../services/menu_service.dart';

class CustomPricesTab extends StatefulWidget {
  final String canteenId;
  final Customer customer;

  const CustomPricesTab({
    super.key,
    required this.canteenId,
    required this.customer,
  });

  @override
  State<CustomPricesTab> createState() => _CustomPricesTabState();
}

class _CustomPricesTabState extends State<CustomPricesTab> {
  final _customerPriceService = CustomerPriceService(Supabase.instance.client);
  final _menuService = MenuService(Supabase.instance.client);

  bool _isLoading = true;
  List<MenuCategory> _categories = [];
  Map<String, List<MenuItem>> _menuItemsByCategory = {};
  Map<String, double> _customPrices = {};
  String? _searchQuery;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [categories, menuItems, customPrices] = await Future.wait([
        _menuService.getCategories(widget.canteenId),
        _menuService.getMenuItems(widget.canteenId),
        _customerPriceService.getCustomPrices(
          canteenId: widget.canteenId,
          customerId: widget.customer.id,
        ),
      ]);

      // Group menu items by category
      final itemsByCategory = <String, List<MenuItem>>{};
      for (final item in menuItems as List<MenuItem>) {
        if (!itemsByCategory.containsKey(item.categoryId)) {
          itemsByCategory[item.categoryId] = [];
        }
        itemsByCategory[item.categoryId]!.add(item);
      }

      if (mounted) {
        setState(() {
          _categories = categories as List<MenuCategory>;
          _menuItemsByCategory = itemsByCategory;
          _customPrices = customPrices as Map<String, double>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  List<MenuItem> _getFilteredMenuItems(String categoryId) {
    final items = _menuItemsByCategory[categoryId] ?? [];
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return items;
    }
    return items.where((item) {
      return item.name.toLowerCase().contains(_searchQuery!.toLowerCase());
    }).toList();
  }

  Future<void> _setCustomPrice(MenuItem item) async {
    final currentPrice = _customPrices[item.id] ?? item.basePrice;

    final result = await showDialog<double>(
      context: context,
      builder: (context) => CustomPriceDialog(
        menuItem: item,
        currentPrice: currentPrice,
      ),
    );

    if (result != null) {
      try {
        await _customerPriceService.setCustomPrice(
          canteenId: widget.canteenId,
          customerId: widget.customer.id,
          menuItemId: item.id,
          customPrice: result,
        );

        setState(() {
          _customPrices[item.id] = result;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom price updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating custom price: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeCustomPrice(MenuItem item) async {
    try {
      await _customerPriceService.removeCustomPrice(
        canteenId: widget.canteenId,
        customerId: widget.customer.id,
        menuItemId: item.id,
      );

      setState(() {
        _customPrices.remove(item.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Custom price removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing custom price: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search and filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Category dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedCategoryId = value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Search field
              Expanded(
                flex: 3,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ],
          ),
        ),
        // Menu items list grouped by category
        Expanded(
          child: ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];

              // Skip category if filtered out
              if (_selectedCategoryId != null &&
                  _selectedCategoryId != category.id) {
                return const SizedBox.shrink();
              }

              final items = _getFilteredMenuItems(category.id);
              if (items.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category header
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Category items
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final hasCustomPrice =
                            _customPrices.containsKey(item.id);
                        final customPrice = _customPrices[item.id];

                        return ListTile(
                          title: Text(
                            item.name,
                            style: GoogleFonts.poppins(),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Base Price: ₹${item.basePrice}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (hasCustomPrice)
                                Text(
                                  'Custom Price: ₹$customPrice',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _setCustomPrice(item),
                              ),
                              if (hasCustomPrice)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeCustomPrice(item),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// Dialog for setting custom price
class CustomPriceDialog extends StatefulWidget {
  final MenuItem menuItem;
  final double currentPrice;

  const CustomPriceDialog({
    super.key,
    required this.menuItem,
    required this.currentPrice,
  });

  @override
  State<CustomPriceDialog> createState() => _CustomPriceDialogState();
}

class _CustomPriceDialogState extends State<CustomPriceDialog> {
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.currentPrice.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Set Custom Price',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.menuItem.name,
            style: GoogleFonts.poppins(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Base Price: ₹${widget.menuItem.basePrice}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Custom Price',
              prefixText: '₹',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(),
          ),
        ),
        FilledButton(
          onPressed: () {
            final price = double.tryParse(_priceController.text);
            if (price != null && price > 0) {
              Navigator.of(context).pop(price);
            }
          },
          child: Text(
            'Save',
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }
}
