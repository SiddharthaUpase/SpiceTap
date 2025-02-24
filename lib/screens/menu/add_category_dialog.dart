import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/menu_models.dart';
import '../../services/menu_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddCategoryDialog extends StatefulWidget {
  final String canteenId;
  final Function(MenuCategory) onCategoryAdded;
  final MenuCategory? categoryToEdit;

  const AddCategoryDialog({
    super.key,
    required this.canteenId,
    required this.onCategoryAdded,
    this.categoryToEdit,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name;
      _descriptionController.text = widget.categoryToEdit!.description ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.categoryToEdit == null ? 'Add Category' : 'Edit Category',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g., Breakfast, Lunch, Snacks',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Add a description for this category',
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(),
          ),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          child: Text(
            widget.categoryToEdit == null ? 'Add' : 'Save',
            style: GoogleFonts.poppins(),
          ),
        ),
      ],
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final menuService = MenuService(Supabase.instance.client);
      final category = widget.categoryToEdit == null
          ? await menuService.createCategory(
              _nameController.text.trim(),
              widget.canteenId,
              description: _descriptionController.text.trim().isNotEmpty
                  ? _descriptionController.text.trim()
                  : null,
            )
          : await menuService.updateCategory(
              MenuCategory(
                id: widget.categoryToEdit!.id,
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isNotEmpty
                    ? _descriptionController.text.trim()
                    : null,
                canteenId: widget.canteenId,
                createdAt: widget.categoryToEdit!.createdAt,
                updatedAt: DateTime.now(),
              ),
            );

      if (mounted) {
        widget.onCategoryAdded(category);
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving category: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
