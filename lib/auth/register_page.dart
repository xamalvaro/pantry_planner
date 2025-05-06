// auth/register_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/services/user_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  // Attempt registration
  Future<void> _register() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call the UserService to register
      final user = await userService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
      );

      if (user == null) {
        setState(() {
          _errorMessage = 'Failed to create account. Please try again.';
          _isLoading = false;
        });
        return;
      }

      // On success, show success message and wait for navigation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Wait a bit before returning to login screen
        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      }
    } catch (e) {
      // Format error message
      setState(() {
        _errorMessage = _formatAuthError(e);
        _isLoading = false;
      });
    }
  }

  // Format Firebase Auth errors into user-friendly messages
  String _formatAuthError(dynamic error) {
    String errorMessage = 'An unknown error occurred. Please try again.';

    if (error.toString().contains('email-already-in-use')) {
      errorMessage = 'An account already exists with this email.';
    } else if (error.toString().contains('invalid-email')) {
      errorMessage = 'The email address is invalid.';
    } else if (error.toString().contains('weak-password')) {
      errorMessage = 'The password is too weak. Please use a stronger password.';
    } else if (error.toString().contains('operation-not-allowed')) {
      errorMessage = 'Account creation is disabled at this time.';
    } else if (error.toString().contains('network-request-failed')) {
      errorMessage = 'Network error. Check your connection and try again.';
    }

    return errorMessage;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo/icon
                Icon(
                  Icons.kitchen,
                  size: 72,
                  color: Colors.blueAccent,
                ),
                SizedBox(height: 24),

                // App name
                Text(
                  'Join PantryPlanner',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: themeController.currentFont,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8),

                // Tagline
                Text(
                  'Create an account to sync your data',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: themeController.currentFont,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32),

                // Error message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontFamily: themeController.currentFont,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                if (_errorMessage.isNotEmpty)
                  SizedBox(height: 24),

                // Display name field
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.person),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),

                SizedBox(height: 16),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),

                SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'At least 8 characters with letters and numbers',
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }

                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }

                    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$').hasMatch(value)) {
                      return 'Include both letters and numbers';
                    }

                    return null;
                  },
                  enabled: !_isLoading,
                ),

                SizedBox(height: 16),

                // Confirm password field
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _register(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }

                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                  enabled: !_isLoading,
                ),

                SizedBox(height: 32),

                // Register button
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Creating account...',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Back to login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text('Sign In'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}