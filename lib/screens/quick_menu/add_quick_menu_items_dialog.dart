import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spice_tap/models/quick_menu_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_models.dart';
import '../../services/menu_service.dart';
import '../../services/quick_menu_service.dart';

class AddQuickMenuItemsDialog extends StatefulWidget {
  final String canteenId;
  final Function(MenuItem) onItemAdded;

  const AddQuickMenuItemsDialog({
    super.key,
    required this.canteenId,
    required this.onItemAdded,
  });

  @override
  State<AddQuickMenuItemsDialog> createState() =>
      _AddQuickMenuItemsDialogState();
}

class _AddQuickMenuItemsDialogState extends State<AddQuickMenuItemsDialog> {
  final MenuService _menuService = MenuService(Supabase.instance.client);
  final QuickMenuService _quickMenuService =
      QuickMenuService(Supabase.instance.client);
  final TextEditingController _searchController = TextEditingController();

  List<MenuItem> _menuItems = [];
  Set<String> _existingQuickMenuItemIds = {}; // Track existing quick menu items
  Set<String> _newlyAddedItemIds = {}; // Track items added during this session
  bool _isLoading = true;
  String _searchQuery = '';
  MenuCategory? _selectedCategory;
  Set<String> _selectedItemIds = {}; // Track selected items
  bool _isAddingItems = false; // Track batch addition progress

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  Future<void> _loadInitialData() async {
    try {
      // Load both menu items and quick menu items in parallel
      final results = await Future.wait([
        _menuService.getMenuItems(widget.canteenId),
        _quickMenuService.getQuickMenuItems(widget.canteenId),
      ]);

      if (mounted) {
        setState(() {
          _menuItems = results[0] as List<MenuItem>;
          final quickMenuItems = results[1] as List<QuickMenuItem>;
          _existingQuickMenuItemIds = quickMenuItems
              .where((item) => item.menuItem != null)
              .map((item) => item.menuItemId)
              .toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  List<MenuItem> get _filteredItems {
    return _menuItems.where((item) {
      final matchesSearch =
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (item.description
                      ?.toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ??
                  false);
      final matchesCategory =
          _selectedCategory == null || item.categoryId == _selectedCategory!.id;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _addToQuickMenu(MenuItem item) async {
    if (_existingQuickMenuItemIds.contains(item.id) ||
        _newlyAddedItemIds.contains(item.id)) {
      return; // Item already exists or was just added
    }

    try {
      await _quickMenuService.addToQuickMenu(widget.canteenId, item.id);
      setState(() {
        _newlyAddedItemIds.add(item.id);
      });
      widget.onItemAdded(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item added to quick menu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding item: $e')),
        );
      }
    }
  }

  Future<void> _addSelectedItemsToQuickMenu() async {
    if (_selectedItemIds.isEmpty) return;

    try {
      setState(() => _isAddingItems = true);

      // Add all selected items sequentially
      for (String itemId in _selectedItemIds) {
        if (_existingQuickMenuItemIds.contains(itemId) ||
            _newlyAddedItemIds.contains(itemId)) continue;

        final item = _menuItems.firstWhere((item) => item.id == itemId);
        await _quickMenuService.addToQuickMenu(widget.canteenId, itemId);
        _newlyAddedItemIds.add(itemId);
        widget.onItemAdded(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items added to quick menu')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding items: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingItems = false);
      }
    }
  }

  void _toggleItemSelection(MenuItem item) {
    if (_existingQuickMenuItemIds.contains(item.id) ||
        _newlyAddedItemIds.contains(item.id)) return;

    setState(() {
      if (_selectedItemIds.contains(item.id)) {
        _selectedItemIds.remove(item.id);
      } else {
        _selectedItemIds.add(item.id);
      }
    });
  }

  Future<void> _showConfirmationDialog() async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select items to add')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add to Quick Menu',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'Add ${_selectedItemIds.length} items to Quick Menu?',
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Add',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _addSelectedItemsToQuickMenu();
    }
  }

  Widget _buildItemCard(MenuItem item) {
    final bool isExisting = _existingQuickMenuItemIds.contains(item.id);
    final bool isNewlyAdded = _newlyAddedItemIds.contains(item.id);
    final bool isAdded = isExisting || isNewlyAdded;
    final bool isSelected = _selectedItemIds.contains(item.id);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isAdded ? null : () => _toggleItemSelection(item),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: isAdded ? Colors.grey : null,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${item.basePrice.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isAdded
                          ? Colors.grey
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdded)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isNewlyAdded ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            if (!isAdded && isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text(
                      'Add to Quick Menu',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedItemIds.isNotEmpty)
                      Text(
                        '${_selectedItemIds.length} selected',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search menu items...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 16),

                // Items grid
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            childAspectRatio: 1,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = _filteredItems[index];
                            return _buildItemCard(item);
                          },
                        ),
                ),

                // Add button
                if (_selectedItemIds.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isAddingItems ? null : _showConfirmationDialog,
                        child: Text(
                          'Add Selected Items',
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isAddingItems)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
