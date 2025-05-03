// auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/services/user_service.dart';
import 'package:pantry_pal/app/home_page.dart';
import 'package:pantry_pal/auth/register_page.dart';
import 'package:pantry_pal/auth/reset_password_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Attempt login
  Future<void> _login() async {
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call the UserService to sign in
      final user = await userService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (user != null) {
        // Navigate to home page, removing all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MyHomePage()),
              (Route<dynamic> route) => false,
        );
      } else {
        // This shouldn't happen if an exception wasn't thrown
        setState(() {
          _errorMessage = 'Failed to sign in. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      // Format the error message
      setState(() {
        _errorMessage = _formatAuthError(e);
        _isLoading = false;
      });
    }
  }
  Future<void> _signInAsGuest() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call the UserService to sign in as guest (local only)
      final user = await userService.signInAsGuest();

      if (user != null) {
        // Navigate to home page, removing all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MyHomePage()),
              (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Failed to start guest mode. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error starting guest mode: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Format Firebase Auth errors into user-friendly messages
  String _formatAuthError(dynamic error) {
    String errorMessage = 'An unknown error occurred. Please try again.';

    // This will catch Firebase Auth exceptions
    if (error.toString().contains('user-not-found')) {
      errorMessage = 'No user found with this email.';
    } else if (error.toString().contains('wrong-password')) {
      errorMessage = 'Incorrect password.';
    } else if (error.toString().contains('invalid-email')) {
      errorMessage = 'The email address is invalid.';
    } else if (error.toString().contains('user-disabled')) {
      errorMessage = 'This account has been disabled.';
    } else if (error.toString().contains('too-many-requests')) {
      errorMessage = 'Too many failed login attempts. Try again later.';
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
        title: Text('Sign In to PantryPal'),
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
                  'PantryPal',
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
                  'Your kitchen companion',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: themeController.currentFont,
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 48),

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
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),

                SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResetPasswordPage(),
                        ),
                      );
                    },
                    child: Text('Forgot Password?'),
                  ),
                ),

                SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
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
                        'Signing in...',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                ),

                SizedBox(height: 32),

                OutlinedButton(
                  onPressed: _isLoading ? null : _signInAsGuest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
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
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Signing in...',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    'Continue as Guest',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                ),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account?',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegisterPage(),
                          ),
                        );
                      },
                      child: Text('Register Now'),
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