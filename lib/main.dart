import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/auth_page.dart';
import 'screens/dashboard/dashboard_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Add these constants at the top of the file
const String tokenKey = 'session_token';
const String userNameKey = 'user_name';
const String userIdKey = 'user_id';

// Update the isAuthenticated function and add user data helpers
Future<bool> isAuthenticated() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(tokenKey);
  return token != null;
}

Future<void> saveUserData({
  required String token,
  required String userName,
  required String userId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(tokenKey, token);
  await prefs.setString(userNameKey, userName);
  await prefs.setString(userIdKey, userId);
}

Future<Map<String, String?>> getUserData() async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'userName': prefs.getString(userNameKey),
    'userId': prefs.getString(userIdKey),
  };
}

Future<void> clearUserData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(tokenKey);
  await prefs.remove(userNameKey);
  await prefs.remove(userIdKey);
}

// Placeholder screens - we'll implement these later
class CreateCanteenPage extends StatelessWidget {
  const CreateCanteenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Canteen')),
      body: const Center(child: Text('Create Canteen Page')),
    );
  }
}

class ManageStaffPage extends StatelessWidget {
  const ManageStaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Staff')),
      body: const Center(child: Text('Manage Staff Page')),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wzxgkhehfkshazoyufxv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind6eGdraGVoZmtzaGF6b3l1Znh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDAyNTU5MjcsImV4cCI6MjA1NTgzMTkyN30.XTHoMgx9cP-8VJag5Cab3v7di-eGnRrbImyxxKshOZQ',
  );

  runApp(const MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final authenticated = await isAuthenticated();

    // If user is not logged in and trying to access any page other than auth
    if (!authenticated && state.matchedLocation != '/') {
      return '/';
    }

    // If user is logged in and on the auth page, redirect to dashboard
    if (authenticated && state.matchedLocation == '/') {
      return '/dashboard';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthPage(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SpiceTap',
      theme: ThemeData(
        primaryColor: const Color(0xFFFF5722), // Deep Orange
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5722),
          primary: const Color(0xFFFF5722),
          secondary: const Color(0xFFFFA000), // Amber
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
