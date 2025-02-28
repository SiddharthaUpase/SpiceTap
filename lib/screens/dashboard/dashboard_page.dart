import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart' show getUserData, clearUserData;
import '../menu/menu_page.dart';
import '../quick_menu/quick_menu_page.dart';
import '../customers/customers_page.dart';
import '../orders/orders_page.dart';
import '../sales/sales_page.dart';
import '../bills/bills_page.dart';
import '../settings/canteen_settings_page.dart';
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  bool _isExpanded = true;
  int _selectedIndex = 0;
  String _userName = '';
  String _userId = '';
  String _canteenId = '';
  bool _isLoading = true;

  // Add this to implement AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserData(),
      _loadCanteenId(),
      _loadSelectedTab(),
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final userData = await getUserData();
    if (mounted) {
      setState(() {
        _userName = userData['userName'] ?? 'User';
        _userId = userData['userId'] ?? '';
      });
    }
  }

  Future<void> _loadCanteenId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _canteenId = prefs.getString('canteenId') ?? '';
      });
    }
  }

  Future<void> _loadSelectedTab() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedIndex = prefs.getInt('selectedTabIndex') ?? 0;
      });
    }
  }

  Future<void> _saveSelectedTab(int index) async {
    if (_selectedIndex == index) return; // Skip if already selected

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedTabIndex', index);
    setState(() {
      _selectedIndex = index;
    });
  }

  // Create a map to cache content widgets
  final Map<int, Widget> _cachedContent = {};

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Quick Menu',
      icon: Icons.dashboard_rounded,
      selectedIcon: Icons.dashboard,
    ),
    NavigationItem(
      title: 'Orders', // Add Orders tab
      icon: Icons.receipt_outlined,
      selectedIcon: Icons.receipt,
    ),
    NavigationItem(
      title: 'Menu',
      icon: Icons.restaurant_menu_outlined,
      selectedIcon: Icons.restaurant_menu,
    ),
    NavigationItem(
      title: 'Customers',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
    ),
    NavigationItem(
      title: 'Sales',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
    ),
    NavigationItem(
      title: 'Bills',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
    ),
    // NavigationItem(
    //   title: 'Users',
    //   icon: Icons.manage_accounts_outlined,
    //   selectedIcon: Icons.manage_accounts,
    // ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
    ),
  ];

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Return cached widget if available
    if (_cachedContent.containsKey(_selectedIndex)) {
      return _cachedContent[_selectedIndex]!;
    }

    // Create and cache the widget
    Widget content;
    switch (_selectedIndex) {
      case 0:
        content = QuickMenuPage(canteenId: _canteenId);
        break;
      case 1:
        content = OrdersPage(canteenId: _canteenId);
        break;
      case 2:
        content = MenuPage(canteenId: _canteenId);
        break;
      case 3:
        content = CustomersPage(canteenId: _canteenId);
        break;
      case 4:
        content = SalesPage(canteenId: _canteenId);
        break;
      case 5:
        content = BillsPage(canteenId: _canteenId);
        break;
      case 6: // Settings tab
        content = CanteenSettingsPage(canteenId: _canteenId);
        break;
      default:
        content = Center(
          child: Text(
            _navigationItems[_selectedIndex].title,
            style: GoogleFonts.poppins(fontSize: 24),
          ),
        );
    }

    // Cache the content
    _cachedContent[_selectedIndex] = content;
    return content;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isExpanded ? 250 : 70,
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  // Logo and toggle button
                  Container(
                    height: 70,
                    padding: EdgeInsets.symmetric(
                      horizontal: _isExpanded ? 16 : 8,
                    ),
                    child: Row(
                      children: [
                        if (_isExpanded) ...[
                          Text(
                            'SpiceTap',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const Spacer(),
                        ] else ...[
                          Expanded(
                            child: Text(
                              'ST',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        IconButton(
                          onPressed: () {
                            setState(() => _isExpanded = !_isExpanded);
                          },
                          icon: Icon(
                            _isExpanded
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Navigation items
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navigationItems.length,
                      itemBuilder: (context, index) {
                        final item = _navigationItems[index];
                        return ListTile(
                          selected: _selectedIndex == index,
                          selectedTileColor:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          leading: Icon(
                            _selectedIndex == index
                                ? item.selectedIcon
                                : item.icon,
                            color: _selectedIndex == index
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          title: _isExpanded
                              ? Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    color: _selectedIndex == index
                                        ? Theme.of(context).primaryColor
                                        : null,
                                  ),
                                )
                              : null,
                          onTap: () => _saveSelectedTab(index),
                        );
                      },
                    ),
                  ),
                  // User profile section
                  const Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.person_outline,
                        color: Colors.white,
                      ),
                    ),
                    title: _isExpanded
                        ? Text(
                            _userName,
                            style: GoogleFonts.poppins(),
                          )
                        : null,
                    subtitle: _isExpanded
                        ? Text(
                            'Owner',
                            style: GoogleFonts.poppins(fontSize: 12),
                          )
                        : null,
                  ),
                  // Add logout button
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Colors.red[400],
                    ),
                    title: _isExpanded
                        ? Text(
                            'Logout',
                            style: GoogleFonts.poppins(
                              color: Colors.red[400],
                            ),
                          )
                        : null,
                    onTap: handleLogout,
                  ),
                ],
              ),
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cachedContent.clear();
    super.dispose();
  }

  Future<void> handleLogout() async {
    await clearUserData(); // Use the new helper function
    if (mounted) {
      context.go('/');
    }
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
}
