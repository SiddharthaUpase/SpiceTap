import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as provider;
import 'package:spice_tap/models/order_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/quick_menu_models.dart';
import '../../providers/cart_provider.dart';
import '../../services/quick_menu_service.dart';
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
  final _focusNode = FocusNode();

  List<QuickMenuItem> _quickMenuItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _numpadMode = false;
  String _currentInput = '';
  bool _awaitingQuantity = false;
  int? _selectedPosition;

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
    _focusNode.dispose();
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
    List<QuickMenuItem> items;
    if (_searchQuery.isEmpty) {
      items = _quickMenuItems;
    } else {
      items = _quickMenuItems.where((item) {
        return item.menuItem != null &&
            item.menuItem!.name
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }
    // Sort items by position
    items.sort((a, b) => a.position.compareTo(b.position));
    return items;
  }

  // Navigate to cart screen
  void _navigateToCart() async {
    final cart = provider.Provider.of<CartProvider>(context, listen: false);
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

  void _showDeleteConfirmation(QuickMenuItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Remove Item',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Are you sure you want to remove "${item.menuItem?.name}" from the quick menu?',
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

  bool _isNumericKey(LogicalKeyboardKey key) {
    // Check for regular number keys
    if (RegExp(r'^[0-9]$').hasMatch(key.keyLabel ?? '')) {
      return true;
    }

    // Check for numpad keys
    final numpadKeys = {
      LogicalKeyboardKey.numpad0,
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    };

    return numpadKeys.contains(key);
  }

  void _handleKeyPress(KeyEvent event) {
    if (!_numpadMode) return;

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        // Add numpadEnter
        print('Enter pressed - Current Input: $_currentInput');
        _handleEnterPress();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _currentInput = '';
          _awaitingQuantity = false;
          _selectedPosition = null;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_currentInput.isNotEmpty) {
          setState(() {
            _currentInput =
                _currentInput.substring(0, _currentInput.length - 1);
          });
        }
      } else if (_isNumericKey(event.logicalKey)) {
        // Convert numpad key to actual number
        String number = event.logicalKey.keyLabel ?? '';
        if (event.logicalKey.keyId >= LogicalKeyboardKey.numpad0.keyId &&
            event.logicalKey.keyId <= LogicalKeyboardKey.numpad9.keyId) {
          number = (event.logicalKey.keyId - LogicalKeyboardKey.numpad0.keyId)
              .toString();
        }

        setState(() {
          _currentInput += number;
        });
        print('Current input: $_currentInput');
      }
    }
  }

  void _handleEnterPress() {
    if (_currentInput.isEmpty) return;

    if (!_awaitingQuantity) {
      // First enter press - selecting the item and adding 1 quantity
      final position = int.tryParse(_currentInput);
      if (position != null) {
        final item = _findItemByPosition(position);
        if (item != null && item.menuItem != null) {
          print('Selected item: ${item.menuItem!.name}');
          // Add 1 quantity immediately
          final cart =
              provider.Provider.of<CartProvider>(context, listen: false);
          cart.addItem(item.menuItem!);

          setState(() {
            _selectedPosition = position;
            _awaitingQuantity = true;
            _currentInput = '1'; // Set initial quantity to 1
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid position number'),
              duration: Duration(seconds: 1),
            ),
          );
          setState(() {
            _currentInput = '';
          });
        }
      }
    } else {
      // Second enter press - updating quantity
      final quantity = int.tryParse(_currentInput);
      if (quantity != null && _selectedPosition != null) {
        final item = _findItemByPosition(_selectedPosition!);
        if (item != null && item.menuItem != null) {
          final cart =
              provider.Provider.of<CartProvider>(context, listen: false);
          cart.updateQuantity(item.menuItem!.id, quantity);
        }
      }
      setState(() {
        _currentInput = '';
        _awaitingQuantity = false;
        _selectedPosition = null;
      });
    }
  }

  // Add this new method to handle manual quantity changes
  void _handleQuantityChange(String value, String menuItemId) {
    final quantity = int.tryParse(value);
    if (quantity != null) {
      final cart = provider.Provider.of<CartProvider>(context, listen: false);
      if (quantity > 0) {
        cart.updateQuantity(menuItemId, quantity);
      } else {
        cart.removeItem(menuItemId);
      }
    }
  }

  // Update the quantity controls in the card
  // Replace the existing quantity controls with this new version
  Widget _buildQuantityControls(CartItem cartItem, int quantity) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(8),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Decrease quantity button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (quantity > 1) {
                  provider.Provider.of<CartProvider>(context, listen: false)
                      .updateQuantity(cartItem.menuItem.id, quantity - 1);
                } else {
                  provider.Provider.of<CartProvider>(context, listen: false)
                      .removeItem(cartItem.menuItem.id);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          // Quantity input field
          SizedBox(
            width: 50,
            child: TextField(
              controller: TextEditingController(text: quantity.toString())
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: quantity.toString().length)),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: GoogleFonts.poppins(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              onChanged: (value) {
                final newQuantity = int.tryParse(value);
                if (newQuantity != null && newQuantity > 0) {
                  provider.Provider.of<CartProvider>(context, listen: false)
                      .updateQuantity(cartItem.menuItem.id, newQuantity);
                } else if (newQuantity == 0) {
                  provider.Provider.of<CartProvider>(context, listen: false)
                      .removeItem(cartItem.menuItem.id);
                }
              },
            ),
          ),
          // Increase quantity button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                provider.Provider.of<CartProvider>(context, listen: false)
                    .addItem(cartItem.menuItem);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
          // Remove item button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                //iterate through the cart and remove all the items with the same menuItemId
                provider.Provider.of<CartProvider>(context, listen: false)
                    .removeItemCompletely(cartItem.menuItem.id);
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.red[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  QuickMenuItem? _findItemByPosition(int position) {
    return _quickMenuItems.firstWhere(
      (item) => item.position == position,
      orElse: () => QuickMenuItem(
        id: '',
        canteenId: '',
        menuItemId: '',
        position: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Widget _buildNumpadOverlay() {
    if (!_numpadMode) return const SizedBox.shrink();

    return Positioned(
      top: 80,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _awaitingQuantity ? 'Enter Quantity:' : 'Enter Position Number:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentInput.isEmpty ? '_' : _currentInput,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (_selectedPosition != null)
              Text(
                'Selected: ${_findItemByPosition(_selectedPosition!)?.menuItem?.name ?? ""}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Update the position indicator widget
  Widget _buildPositionIndicator(int position) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.tag,
            size: 14,
            color: Colors.white.withOpacity(0.9),
          ),
          const SizedBox(width: 4),
          Text(
            position.toString(),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = provider.Provider.of<CartProvider>(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyPress,
      autofocus: true,
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
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

                      // IconButton(
                      //   onPressed: () {
                      //     setState(() {
                      //       _numpadMode = !_numpadMode;
                      //       _currentInput = '';
                      //       _awaitingQuantity = false;
                      //       _selectedPosition = null;
                      //     });
                      //   },
                      //   icon: Icon(
                      //     _numpadMode ? Icons.dialpad : Icons.dialpad_outlined,
                      //     color: _numpadMode
                      //         ? Theme.of(context).primaryColor
                      //         : null,
                      //   ),
                      //   tooltip: 'Toggle Numpad Mode',
                      // ),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                      final inCart = cart.items
                          .any((i) => i.menuItem.id == item.menuItem!.id);
                      final quantity = inCart ? cartItem.quantity : 0;

                      return Card(
                        elevation: inCart
                            ? 2
                            : 1, // Slightly more elevation when in cart
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        // Update the card color to a more subtle highlight
                        color: Colors.white,
                        child: Container(
                          decoration: inCart
                              ? BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                )
                              : null,
                          child: InkWell(
                            onTap: () {
                              // Add item to cart
                              cart.addItem(item.menuItem!);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Image container at the top
                                    Expanded(
                                      flex: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(8),
                                          ),
                                          image: const DecorationImage(
                                            image: AssetImage(
                                                'assets/images/pc.jpg'),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.menuItem!.name,
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Base Price: ₹${item.menuItem!.basePrice.toStringAsFixed(2)}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                            if (inCart)
                                              const SizedBox(height: 40),
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
                                    onPressed: () =>
                                        _showDeleteConfirmation(item),
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
                                // Updated quantity controls with improved design
                                if (inCart)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: _buildQuantityControls(
                                        cartItem, quantity),
                                  ),
                                if (_numpadMode)
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child:
                                        _buildPositionIndicator(item.position),
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
          ],
        ),
        floatingActionButton: cart.itemCount > 0
            ? FloatingActionButton.extended(
                onPressed: _navigateToCart,
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text(
                  'Checkout (${cart.totalQuantity})',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              )
            : null,
      ),
    );
  }
}
