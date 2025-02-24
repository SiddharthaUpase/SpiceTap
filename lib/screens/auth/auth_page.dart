import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../main.dart' show saveUserData; // Import the saveUserData function

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _canteenNameController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isSignUp = true; // Start with signup form
  String? _errorMessage;

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;

      if (_isSignUp) {
        result = await _authService.signUp(
          phone: _phoneController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
        );

        print("Result from signup: $result");

        if (result['success']) {
          await saveUserData(
            token: result['token'],
            userName: _nameController.text,
            userId: result['user']['id'], // Make sure your API returns this
          );
          if (mounted) {
            await _checkAndSetupCanteen(result['user']['id']);
          }
        }
      } else {
        result = await _authService.signIn(
          phone: _phoneController.text,
          password: _passwordController.text,
        );

        print("Result from signin: $result");

        if (result['success']) {
          await saveUserData(
            token: result['token'],
            userName: result['user']
                ['full_name'], // Make sure your API returns this
            userId: result['user']['id'], // Make sure your API returns this
          );

          if (mounted) {
            await _checkAndSetupCanteen(result['user']['id']);
          }
        }
      }

      if (!result['success'] && mounted) {
        setState(() => _errorMessage = result['message']);
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkAndSetupCanteen(String userId) async {
    try {
      final hasCanteen = await _authService.checkCanteenExists(userId);

      //if canteen exists, save the canteen id to shared preferences
      if (hasCanteen['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('canteenId', hasCanteen['canteenId']);
      }

      if (!hasCanteen['success'] && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Column(
              children: [
                Icon(
                  Icons.store_rounded,
                  size: 48,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Setup Your Canteen',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Before you continue, let\'s set up your canteen profile. This is where you\'ll manage your menu and orders.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _canteenNameController,
                  decoration: InputDecoration(
                    labelText: 'Canteen Name',
                    hintText: 'Enter your canteen name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_canteenNameController.text.isNotEmpty) {
                      final result = await _authService.createCanteen(
                        userId: userId,
                        name: _canteenNameController.text,
                      );
                      if (result['success'] && mounted) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('canteenId', result['canteenId']);
                        context.go('/dashboard');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Create Canteen',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.all(24),
          ),
        );
      } else if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to setup canteen');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Text(
                  'SpiceTap',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSignUp
                      ? 'Create your account\nto get started'
                      : 'Welcome back!\nLogin to continue',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.grey[700],
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 48),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_isSignUp) ...[
                        TextFormField(
                          controller: _nameController,
                          style: GoogleFonts.poppins(),
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(),
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          hintText: 'Enter your phone number',
                          prefixIcon: Icon(Icons.phone_android),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: GoogleFonts.poppins(),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (_isSignUp && value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                _isSignUp ? 'Create Account' : 'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSignUp = !_isSignUp;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Login'
                              : 'Need an account? Sign Up',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (true) // Change to false before production
                        TextButton.icon(
                          onPressed: () {
                            _phoneController.text = '9822421417';
                            _passwordController.text = '123456';
                            if (_isSignUp) {
                              _nameController.text = 'Test User';
                            }
                          },
                          icon: const Icon(Icons.bug_report),
                          label: const Text('Add Test Credentials'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _canteenNameController.dispose();
    super.dispose();
  }
}
