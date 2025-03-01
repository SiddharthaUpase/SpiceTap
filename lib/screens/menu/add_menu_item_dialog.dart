import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/menu_models.dart';
import '../../services/menu_service.dart';

class AddMenuItemDialog extends StatefulWidget {
  final String canteenId;
  final List<MenuCategory> categories;
  final MenuCategory? initialCategory;
  final Function(MenuItem) onItemAdded;
  final MenuItem? itemToEdit;

  const AddMenuItemDialog({
    super.key,
    required this.canteenId,
    required this.categories,
    this.initialCategory,
    required this.onItemAdded,
    this.itemToEdit,
  });

  @override
  State<AddMenuItemDialog> createState() => _AddMenuItemDialogState();
}

class _AddMenuItemDialogState extends State<AddMenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  late MenuCategory? _selectedCategory;
  bool _isAvailable = true;
  String _selectedCategoryId = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedCategoryId = _selectedCategory?.id ?? '';

    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.name;
      _descriptionController.text = widget.itemToEdit!.description ?? '';
      _priceController.text = widget.itemToEdit!.basePrice.toString();
      _isAvailable = widget.itemToEdit!.isAvailable;
      _selectedCategory = widget.categories
          .firstWhere((cat) => cat.id == widget.itemToEdit!.categoryId);
      _selectedCategoryId = _selectedCategory?.id ?? '';
    }
  }

  // Helper method to find category by ID
  MenuCategory? _findCategoryById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return widget.categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 400, // Fixed width for better layout
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              widget.itemToEdit == null ? 'Add Menu Item' : 'Edit Menu Item',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 24),

            // Form
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          hintText: 'Enter item name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter item description (optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Price field
                      TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price',
                          hintText: 'Enter price',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Category dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategoryId.isEmpty
                            ? null
                            : _selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          hintText: 'Select a category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: widget.categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategoryId = value ?? '';
                            _selectedCategory = _findCategoryById(value);
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                        hint: const Text('Select a category'),
                      ),
                      const SizedBox(height: 16),

                      // Availability switch
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SwitchListTile(
                          title: const Text('Available'),
                          subtitle: Text(
                            _isAvailable
                                ? 'Item is available'
                                : 'Item is unavailable',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          value: _isAvailable,
                          onChanged: (value) =>
                              setState(() => _isAvailable = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final menuService = MenuService(Supabase.instance.client);
      final item = widget.itemToEdit == null
          ? await menuService.createMenuItem(
              _nameController.text,
              double.parse(_priceController.text),
              _selectedCategory!.id,
              widget.canteenId,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              isAvailable: _isAvailable,
            )
          : await menuService.updateMenuItem(
              MenuItem(
                id: widget.itemToEdit!.id,
                name: _nameController.text,
                description: _descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text,
                basePrice: double.parse(_priceController.text),
                categoryId: _selectedCategory!.id,
                isAvailable: _isAvailable,
                canteenId: widget.canteenId,
                createdAt: widget.itemToEdit!.createdAt,
                updatedAt: DateTime.now(),
              ),
            );

      if (mounted) {
        widget.onItemAdded(item);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving item: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
