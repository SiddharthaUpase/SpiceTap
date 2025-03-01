import 'package:flutter/material.dart';
import 'package:spice_tap/screens/menu/add_menu_item_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_models.dart';
import '../../services/menu_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_category_dialog.dart';
import '../../services/quick_menu_service.dart';

class MenuPage extends StatefulWidget {
  final String canteenId;

  const MenuPage({super.key, required this.canteenId});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final MenuService _menuService = MenuService(Supabase.instance.client);
  final QuickMenuService _quickMenuService =
      QuickMenuService(Supabase.instance.client);

  // Add a ScrollController for horizontal scrolling
  final ScrollController _horizontalScrollController = ScrollController();

  List<MenuCategory> _categories = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;

  // Add new variables for search and filtering
  final TextEditingController _searchController = TextEditingController();
  MenuCategory? _selectedCategory;
  String _searchQuery = '';

  // Add a list to track items selected for quick menu
  List<MenuItem> _selectedForQuickMenu = [];

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
    // If no category is selected, don't pass any initial category
    showDialog(
      context: context,
      builder: (context) => AddMenuItemDialog(
        canteenId: widget.canteenId,
        categories: _categories,
        // Only pass category if it's not the "All" selection
        initialCategory: _selectedCategory,
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
            // Ensure we keep the current category selected or default to "All"
            if (_selectedCategory?.id == category.id) {
              _selectedCategory = category;
            } else if (_selectedCategory == null) {
              _selectedCategory = null; // This will show "All" as selected
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
    final categoryItems = {
      'Snacks': [
        ('Samosa', 'Crispy pastry filled with spiced potatoes and peas', 15.0),
        ('Vada Pav', 'Mumbai style potato patty burger with chutneys', 20.0),
        (
          'Pani Puri',
          'Crispy puris with spicy mint water and potato filling',
          30.0
        ),
        ('Bhel Puri', 'Puffed rice mixed with chutneys and vegetables', 25.0),
        ('Pakora', 'Mixed vegetable fritters with mint chutney', 20.0),
        ('Aloo Tikki', 'Spiced potato patties with chutneys', 25.0),
        ('Kachori', 'Deep fried spiced lentil balls', 15.0),
        ('Dabeli', 'Spiced potato filling in bun with chutneys', 20.0),
        (
          'Masala Sandwich',
          'Grilled sandwich with potato and vegetables',
          30.0
        ),
        ('Bread Pakora', 'Bread fritters with potato filling', 20.0),
      ],
      'Beverages': [
        ('Masala Chai', 'Indian spiced tea', 12.0),
        ('Filter Coffee', 'South Indian style coffee', 15.0),
        ('Sweet Lassi', 'Sweet yogurt drink', 25.0),
        ('Mango Lassi', 'Mango flavored yogurt drink', 30.0),
        ('Butter Milk', 'Spiced churned yogurt drink', 15.0),
        ('Lemon Soda', 'Fresh lime soda (sweet/salt)', 20.0),
        ('Mint Chaas', 'Spiced buttermilk with mint', 15.0),
        ('Rose Milk', 'Chilled milk with rose syrup', 25.0),
        ('Badam Milk', 'Almond flavored milk', 30.0),
        ('Ice Tea', 'Chilled tea with lemon', 20.0),
      ],
      'Meals': [
        ('Chole Bhature', 'Chickpea curry with fried bread', 50.0),
        ('Rajma Chawal', 'Kidney beans curry with rice', 45.0),
        ('Dal Khichdi', 'Lentil and rice porridge', 40.0),
        ('Veg Thali', 'Complete meal with roti, rice, dal and sabzi', 60.0),
        ('Pav Bhaji', 'Spiced vegetable curry with buttered buns', 45.0),
        ('Dal Makhani', 'Creamy black lentils with rice', 50.0),
        ('Kadai Paneer', 'Cottage cheese curry with roti', 60.0),
        ('Veg Biryani', 'Fragrant rice with vegetables', 55.0),
        ('Masala Dosa', 'Rice crepe with potato filling', 45.0),
        ('Idli Sambar', 'Steamed rice cakes with lentil soup', 40.0),
      ],
      'Desserts': [
        ('Gulab Jamun', 'Deep fried milk dumplings in sugar syrup', 20.0),
        ('Rasgulla', 'Bengali sweet dumplings', 20.0),
        ('Gajar Halwa', 'Carrot pudding (seasonal)', 25.0),
        ('Jalebi', 'Crispy spiral sweet', 20.0),
        ('Rice Kheer', 'Rice pudding with nuts', 25.0),
        ('Rasmalai', 'Cottage cheese dumplings in milk', 30.0),
        ('Kulfi', 'Indian ice cream', 25.0),
        ('Besan Ladoo', 'Sweet gram flour balls', 15.0),
        ('Sooji Halwa', 'Semolina pudding', 20.0),
        ('Phirni', 'Ground rice pudding', 25.0),
      ],
    };

    try {
      setState(() => _isLoading = true);

      for (var category in _categories) {
        final items = categoryItems[category.name];
        if (items != null) {
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

  // Add method to add item to quick menu
  Future<void> _addToQuickMenu(MenuItem item) async {
    try {
      await _quickMenuService.addToQuickMenu(widget.canteenId, item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} added to Quick Menu')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to Quick Menu: $e')),
        );
      }
    }
  }

  // Add method to add selected items to quick menu
  Future<void> _addSelectedToQuickMenu() async {
    if (_selectedForQuickMenu.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items selected')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      for (var item in _selectedForQuickMenu) {
        await _quickMenuService.addToQuickMenu(widget.canteenId, item.id);
      }

      setState(() {
        _selectedForQuickMenu.clear();
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_selectedForQuickMenu.length} items added to Quick Menu')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding items to Quick Menu: $e')),
        );
      }
    }
  }

  // Toggle selection of an item for quick menu
  void _toggleQuickMenuSelection(MenuItem item) {
    setState(() {
      if (_selectedForQuickMenu.any((i) => i.id == item.id)) {
        _selectedForQuickMenu.removeWhere((i) => i.id == item.id);
      } else {
        _selectedForQuickMenu.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure a category is always selected (null means "All" is selected)
    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _selectedCategory = null;
    }

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
              // Show quick menu cart if items are selected
              if (_selectedForQuickMenu.isNotEmpty)
                Container(
                  child: ElevatedButton.icon(
                    onPressed: _addSelectedToQuickMenu,
                    icon: const Icon(Icons.flash_on),
                    label: Text(
                      'Add ${_selectedForQuickMenu.length} to Quick Menu',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              // const SizedBox(width: 8),
              // PopupMenuButton(
              //   icon: const Icon(Icons.bug_report),
              //   itemBuilder: (context) => [
              //     PopupMenuItem(
              //       child: const Text('Add Sample Items'),
              //       onTap: _addDebugItems,
              //     ),
              //     PopupMenuItem(
              //       child: const Text(
              //         'Delete All Items',
              //         style: TextStyle(color: Colors.red),
              //       ),
              //       onTap: _deleteAllItems,
              //     ),
              //   ],
              // ),
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

        // Menu items grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, // 3 items per row
              childAspectRatio: 0.8, // Square aspect ratio
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _filteredItems.length,
            itemBuilder: (context, index) {
              final item = _filteredItems[index];
              final isSelected =
                  _selectedForQuickMenu.any((i) => i.id == item.id);

              return Card(
                elevation: isSelected ? 3 : 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isSelected
                      ? BorderSide(
                          color: const Color.fromARGB(255, 104, 230, 108),
                          width: 4)
                      : BorderSide.none,
                ),
                child: InkWell(
                  onTap: () => _toggleQuickMenuSelection(item),
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image container at the top (60% of height)
                      Expanded(
                        flex: 6,
                        child: Stack(
                          children: [
                            // Image
                            Container(
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
                            // Selection indicator
                            if (isSelected)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            // Action buttons
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Row(
                                children: [
                                  // // Quick add button
                                  // IconButton(
                                  //   onPressed: () => _addToQuickMenu(item),
                                  //   icon: Icon(
                                  //     Icons.flash_on,
                                  //     size: 18,
                                  //     color: Theme.of(context).primaryColor,
                                  //   ),
                                  //   style: IconButton.styleFrom(
                                  //     backgroundColor: Colors.white,
                                  //     padding: const EdgeInsets.all(4),
                                  //     minimumSize: const Size(30, 30),
                                  //   ),
                                  // ),
                                  // Edit button
                                  IconButton(
                                    onPressed: () => _showEditItemDialog(item),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(30, 30),
                                    ),
                                  ),
                                  // Delete button
                                  IconButton(
                                    onPressed: () => _deleteMenuItem(item),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red[400],
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: const EdgeInsets.all(4),
                                      minimumSize: const Size(30, 30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Text content at the bottom (40% of height)
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.grey[50] : Colors.white,
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(8),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${item.basePrice.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.deepOrange,
                                    ),
                                  ),
                                  Switch(
                                    value: item.isAvailable,
                                    onChanged: (_) =>
                                        _toggleItemAvailability(item),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    activeColor: Colors.deepOrange,
                                  ),
                                ],
                              ),
                            ],
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
