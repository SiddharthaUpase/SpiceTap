import 'package:flutter/material.dart';
import 'package:spice_tap/screens/menu/add_menu_item_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_models.dart';
import '../../services/menu_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_category_dialog.dart';

class MenuPage extends StatefulWidget {
  final String canteenId;

  const MenuPage({super.key, required this.canteenId});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuService _menuService = MenuService(Supabase.instance.client);

  // Add a ScrollController for horizontal scrolling
  final ScrollController _horizontalScrollController = ScrollController();

  List<MenuCategory> _categories = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;

  // Add new variables for search and filtering
  final TextEditingController _searchController = TextEditingController();
  MenuCategory? _selectedCategory;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeDefaultCategories();
    _loadMenuData();

    // Add listener for search
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

  Future<void> _initializeDefaultCategories() async {
    // First check if any categories exist
    final existingCategories =
        await _menuService.getCategories(widget.canteenId);
    if (existingCategories.isNotEmpty) {
      return; // Skip adding defaults if categories already exist
    }

    final defaultCategories = ['Snacks', 'Beverages', 'Meals', 'Desserts'];

    for (var categoryName in defaultCategories) {
      try {
        await _menuService.createCategory(
          categoryName,
          widget.canteenId,
          description: 'Default $categoryName category',
        );
      } catch (e) {
        // Category might already exist, ignore the error
      }
    }
  }

  Future<void> _loadMenuData() async {
    try {
      if (widget.canteenId.isEmpty) {
        throw ArgumentError('Invalid canteen ID');
      }

      final categories = await _menuService.getCategories(widget.canteenId);
      final menuItems = await _menuService.getMenuItems(widget.canteenId);

      setState(() {
        _categories = categories;
        _menuItems = menuItems;
        _isLoading = false;
      });
    } catch (e) {
      // Handle the error appropriately
      print('Error loading menu data: $e');
      // You might want to show a snackbar or dialog here
    }
  }

  void _showAddItemDialog([MenuCategory? category]) {
    showDialog(
      context: context,
      builder: (context) => AddMenuItemDialog(
        canteenId: widget.canteenId,
        categories: _categories,
        initialCategory: category,
        onItemAdded: (item) {
          setState(() => _menuItems.add(item));
        },
      ),
    );
  }

  void _showAddCategoryDialog([MenuCategory? category]) {
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        canteenId: widget.canteenId,
        categoryToEdit: category,
        onCategoryAdded: (category) {
          setState(() {
            final existingIndex =
                _categories.indexWhere((c) => c.id == category.id);
            if (existingIndex != -1) {
              _categories[existingIndex] = category;
            } else {
              _categories.add(category);
            }
          });
        },
      ),
    );
  }

  void _showEditItemDialog(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AddMenuItemDialog(
        canteenId: widget.canteenId,
        categories: _categories,
        itemToEdit: item,
        onItemAdded: (updatedItem) {
          setState(() {
            final index = _menuItems.indexWhere((i) => i.id == item.id);
            if (index != -1) {
              _menuItems[index] = updatedItem;
            }
          });
        },
      ),
    );
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteMenuItem(item.id);
        setState(() {
          _menuItems.removeWhere((i) => i.id == item.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _toggleItemAvailability(MenuItem item) async {
    try {
      final updatedItem = await _menuService.updateMenuItem(
        MenuItem(
          id: item.id,
          name: item.name,
          description: item.description,
          basePrice: item.basePrice,
          categoryId: item.categoryId,
          isAvailable: !item.isAvailable,
          canteenId: item.canteenId,
          createdAt: item.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      setState(() {
        final index = _menuItems.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _menuItems[index] = updatedItem;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteCategory(MenuCategory category) async {
    final categoryItems =
        _menuItems.where((item) => item.categoryId == category.id).toList();

    if (categoryItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot delete category with items. Please delete or move items first.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _menuService.deleteCategory(category.id);
        setState(() {
          _categories.removeWhere((c) => c.id == category.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _reorderCategories(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final category = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, category);
    });
  }

  Future<void> _addDebugItems() async {
    final items = [
      ('Samosa', 'Crispy pastry with spiced potatoes', 12.0),
      ('Vada Pav', 'Mumbai style burger', 15.0),
      ('Poha', 'Flattened rice breakfast', 20.0),
      ('Pani Puri', 'Crispy shells with spicy water', 25.0),
      ('Dosa', 'South Indian crepe', 40.0),
      ('Idli', 'Steamed rice cakes', 30.0),
      ('Upma', 'Semolina breakfast', 25.0),
      ('Pakora', 'Vegetable fritters', 15.0),
      ('Bhel Puri', 'Puffed rice snack', 20.0),
      ('Misal Pav', 'Spicy curry with bread', 35.0),
      ('Chai', 'Indian tea', 10.0),
      ('Coffee', 'Filter coffee', 15.0),
      ('Lassi', 'Yogurt drink', 25.0),
      ('Butter Chicken', 'Creamy chicken curry', 180.0),
      ('Paneer Tikka', 'Grilled cottage cheese', 120.0),
      ('Biryani', 'Fragrant rice dish', 150.0),
      ('Gulab Jamun', 'Sweet milk dumplings', 40.0),
      ('Rasgulla', 'Bengali sweet', 35.0),
      ('Jalebi', 'Spiral sweet', 30.0),
      ('Kheer', 'Rice pudding', 45.0),
    ];

    try {
      setState(() => _isLoading = true);

      for (var category in _categories) {
        for (var item in items) {
          try {
            final menuItem = await _menuService.createMenuItem(
              item.$1,
              item.$3,
              category.id,
              widget.canteenId,
              description: item.$2,
              isAvailable: true,
            );
            _menuItems.add(menuItem);
          } catch (e) {
            print('Error adding item ${item.$1}: $e');
          }
        }
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debug items added successfully')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding debug items: $e')),
        );
      }
    }
  }

  Future<void> _deleteAllItems() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Items'),
        content: const Text(
            'Are you sure you want to delete all menu items? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);

        // Delete all items
        for (var item in _menuItems) {
          try {
            await _menuService.deleteMenuItem(item.id);
          } catch (e) {
            print('Error deleting item ${item.name}: $e');
          }
        }

        setState(() {
          _menuItems.clear();
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All items deleted successfully')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting items: $e')),
          );
        }
      }
    }
  }

  // Add method to filter items
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Header with search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Menu',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              PopupMenuButton(
                icon: const Icon(Icons.bug_report),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Text('Add Sample Items'),
                    onTap: _addDebugItems,
                  ),
                  PopupMenuItem(
                    child: const Text(
                      'Delete All Items',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: _deleteAllItems,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
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
        ),

        // Categories row
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                        ),
                      );
                    }
                    final category = _categories[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onLongPress: () => _showCategoryOptions(category),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: _selectedCategory?.id == category.id,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category),
                        ),
                      ),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddCategoryDialog(),
              ),
            ],
          ),
        ),

        // Menu items list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    item.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                  ),
                  subtitle: item.description != null
                      ? Text(
                          item.description!,
                          style: GoogleFonts.poppins(fontSize: 12),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${item.basePrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: item.isAvailable,
                        onChanged: (_) => _toggleItemAvailability(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showEditItemDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteMenuItem(item),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Add item FAB
        Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton.extended(
            onPressed: () => _showAddItemDialog(_selectedCategory),
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ),
      ],
    );
  }

  void _showCategoryOptions(MenuCategory category) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Category'),
              onTap: () {
                Navigator.pop(context);
                _showAddCategoryDialog(category);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Category',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteCategory(category);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          item.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        subtitle: item.description != null
            ? Text(
                item.description!,
                style: GoogleFonts.poppins(fontSize: 12),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${item.basePrice.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            Switch(
              value: item.isAvailable,
              onChanged: (_) => onToggleAvailability(),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
