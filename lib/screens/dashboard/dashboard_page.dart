import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart'
    show getUserData, clearUserData; // Import the helper functions
import '../menu/menu_page.dart';
import '../quick_menu/quick_menu_page.dart';
import '../customers/customers_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isExpanded = true;
  int _selectedIndex = 0;
  String _userName = '';
  String _userId = '';
  String _canteenId = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserData(),
      _loadCanteenId(),
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

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Quick Menu',
      icon: Icons.dashboard_rounded,
      selectedIcon: Icons.dashboard,
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
      title: 'Users',
      icon: Icons.manage_accounts_outlined,
      selectedIcon: Icons.manage_accounts,
    ),
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

    switch (_selectedIndex) {
      case 0:
        return QuickMenuPage(canteenId: _canteenId);
      case 1:
        return MenuPage(canteenId: _canteenId);
      case 2:
        return CustomersPage(canteenId: _canteenId);
      default:
        return Center(
          child: Text(
            _navigationItems[_selectedIndex].title,
            style: GoogleFonts.poppins(fontSize: 24),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                          onTap: () {
                            setState(() => _selectedIndex = index);
                          },
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
