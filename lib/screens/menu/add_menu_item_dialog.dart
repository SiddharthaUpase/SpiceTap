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

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? widget.categories.first;

    if (widget.itemToEdit != null) {
      _nameController.text = widget.itemToEdit!.name;
      _descriptionController.text = widget.itemToEdit!.description ?? '';
      _priceController.text = widget.itemToEdit!.basePrice.toString();
      _isAvailable = widget.itemToEdit!.isAvailable;
      _selectedCategory = widget.categories
          .firstWhere((cat) => cat.id == widget.itemToEdit!.categoryId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.itemToEdit == null ? 'Add Menu Item' : 'Edit Menu Item'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<MenuCategory>(
                value: _selectedCategory,
                items: widget.categories
                    .map((cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a price';
                  if (double.tryParse(value!) == null) return 'Invalid price';
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Available'),
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveItem,
          child: Text(widget.itemToEdit == null ? 'Add' : 'Save'),
        ),
      ],
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
