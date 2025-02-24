import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/quick_menu_models.dart';
import '../../services/quick_menu_service.dart';
import '../menu/add_menu_item_dialog.dart';
import '../quick_menu/add_quick_menu_items_dialog.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
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
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _quickMenuItems.length,
            itemBuilder: (context, index) {
              final item = _quickMenuItems[index];
              if (item.menuItem == null) return const SizedBox.shrink();

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    // TODO: Implement quick order/bill creation
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.menuItem!.name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${item.menuItem!.basePrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _showDeleteConfirmation(item),
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.red[400],
                              ),
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
