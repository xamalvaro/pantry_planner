// auth/reset_password_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/services/user_service.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _resetSent = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Send password reset email
  Future<void> _resetPassword() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Call the UserService to reset password
      await userService.resetPassword(_emailController.text.trim());

      // On success, show message
      if (mounted) {
        setState(() {
          _resetSent = true;
          _isLoading = false;
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

    if (error.toString().contains('user-not-found')) {
      errorMessage = 'No user found with this email address.';
    } else if (error.toString().contains('invalid-email')) {
      errorMessage = 'The email address is invalid.';
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
        title: Text('Reset Password'),
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
                // Icon
                Icon(
                  _resetSent ? Icons.check_circle : Icons.lock_reset,
                  size: 72,
                  color: _resetSent ? Colors.green : Colors.blueAccent,
                ),
                SizedBox(height: 24),

                // Title
                Text(
                  _resetSent ? 'Reset Email Sent' : 'Reset Your Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: themeController.currentFont,
                    color: _resetSent ? Colors.green : Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                // Description
                Text(
                  _resetSent
                      ? 'Check your email for a link to reset your password. The email might take a few minutes to arrive.'
                      : 'Enter your email address and we\'ll send you a link to reset your password.',
                  style: TextStyle(
                    fontFamily: themeController.currentFont,
                    fontSize: 16,
                    color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 32),

                // Error message
                if (_errorMessage.isNotEmpty && !_resetSent)
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

                if (_errorMessage.isNotEmpty && !_resetSent)
                  SizedBox(height: 24),

                // Email field (only show if reset not yet sent)
                if (!_resetSent)
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _resetPassword(),
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

                if (!_resetSent)
                  SizedBox(height: 24),

                // Send reset email button (only show if reset not yet sent)
                if (!_resetSent)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
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
                          'Sending...',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                      ],
                    )
                        : Text(
                      'Send Reset Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  ),

                // Back to login button (show different variants based on state)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      _resetSent
                          ? 'Return to Login'
                          : 'Cancel',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}