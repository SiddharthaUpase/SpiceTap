import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:spice_tap/models/order_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/quick_menu_models.dart';
import '../../providers/cart_provider.dart';
import '../../services/quick_menu_service.dart';
import '../menu/add_menu_item_dialog.dart';
import '../quick_menu/add_quick_menu_items_dialog.dart';
import '../orders/cart_screen.dart';

class QuickMenuPage extends StatefulWidget {
  final String canteenId;

  const QuickMenuPage({super.key, required this.canteenId});

  @override
  State<QuickMenuPage> createState() => _QuickMenuPageState();
}

class _QuickMenuPageState extends State<QuickMenuPage> {
  final QuickMenuService _quickMenuService =
      QuickMenuService(Supabase.instance.client);
  final TextEditingController _searchController = TextEditingController();

  List<QuickMenuItem> _quickMenuItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadQuickMenuItems();
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

  Future<void> _loadQuickMenuItems() async {
    try {
      final items = await _quickMenuService.getQuickMenuItems(widget.canteenId);
      if (mounted) {
        setState(() {
          _quickMenuItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading quick menu: $e')),
        );
      }
    }
  }

  Future<void> _removeFromQuickMenu(QuickMenuItem item) async {
    try {
      await _quickMenuService.removeFromQuickMenu(item.id);
      setState(() {
        _quickMenuItems.removeWhere((i) => i.id == item.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item removed from quick menu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing item: $e')),
        );
      }
    }
  }

  // Filter items based on search query
  List<QuickMenuItem> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return _quickMenuItems;
    }
    return _quickMenuItems.where((item) {
      return item.menuItem != null &&
          item.menuItem!.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Navigate to cart screen
  void _navigateToCart() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CartScreen(canteenId: widget.canteenId),
      ),
    );

    if (result != null) {
      // Order was created successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order created successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Quick Menu',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (cart.itemCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Badge(
                      label: Text(cart.totalQuantity.toString()),
                      child: IconButton(
                        icon: const Icon(Icons.shopping_cart),
                        onPressed: _navigateToCart,
                        tooltip: 'View Cart',
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddQuickMenuItemsDialog(
                        canteenId: widget.canteenId,
                        onItemAdded: (item) {
                          _loadQuickMenuItems(); // Reload the quick menu items
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Items'),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search quick menu items...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),

          // Quick menu items grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                if (item.menuItem == null) return const SizedBox.shrink();

                // Find if this item is in the cart
                final cartItem = cart.items.firstWhere(
                  (cartItem) => cartItem.menuItem.id == item.menuItem!.id,
                  orElse: () => CartItem(menuItem: item.menuItem!),
                );
                final inCart = cartItem != null;
                final quantity = inCart ? cartItem.quantity : 0;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Add item to cart
                      cart.addItem(item.menuItem!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${item.menuItem!.name} added to cart'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Image container at the top
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/images/pc.jpg'),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Text content at the bottom
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      item.menuItem!.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₹${item.menuItem!.basePrice.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Delete button positioned at top-right
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            onPressed: () => _showDeleteConfirmation(item),
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red[400],
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(4),
                            ),
                          ),
                        ),
                        // Cart quantity indicator
                        if (inCart)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$quantity',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // Floating action button to view cart
      floatingActionButton: cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToCart,
              icon: const Icon(Icons.shopping_cart),
              label: Text(
                'View Cart (${cart.totalQuantity})',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Theme.of(context).primaryColor,
            ),
    );
  }

  Future<void> _showDeleteConfirmation(QuickMenuItem item) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Remove Item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Remove "${item.menuItem?.name}" from Quick Menu?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromQuickMenu(item);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(
                'Remove',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );
  }
}
