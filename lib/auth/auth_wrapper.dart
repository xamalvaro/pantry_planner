// auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/user_service.dart';
import 'package:pantry_pal/services/firebase_sync_service.dart';
import 'package:pantry_pal/app/home_page.dart';
import 'package:pantry_pal/auth/login_page.dart';
import 'package:pantry_pal/splash_screen.dart';

/// A wrapper widget that handles authentication state
/// It shows either the login screen or the home page based on auth state
class AuthWrapper extends StatelessWidget {
  final bool isInitialized;

  const AuthWrapper({Key? key, this.isInitialized = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If Firebase is not yet initialized, show the splash screen
    if (!isInitialized) {
      return AdaptiveSplashScreen(showProgress: true);
    }

    return StreamBuilder<User?>(
      stream: firebaseService.authStateChanges,
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AdaptiveSplashScreen(showProgress: true);
        }

        // Debug print to understand authentication state
        print('Auth Snapshot: ${snapshot.data}');
        print('Is Logged In: ${snapshot.hasData}');

        // Explicitly check if user is authenticated
        if (snapshot.hasData && snapshot.data != null) {
          // Fetch current user data
          userService.getCurrentUser().then((_) {
            // Trigger sync from Firestore
            firebaseSyncService.syncFromFirestore();
          });
          return MyHomePage();
        } else {
          // No user logged in, show login page
          return LoginPage();
        }
      },
    );
  }
}

/// A wrapper for the app to listen for deep links for actions like password reset
class DeepLinkHandler extends StatefulWidget {
  final Widget child;

  const DeepLinkHandler({Key? key, required this.child}) : super(key: key);

  @override
  _DeepLinkHandlerState createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  @override
  void initState() {
    super.initState();
    _handleDeepLinks();
  }

  // Handle deep links (password reset, email verification, etc.)
  Future<void> _handleDeepLinks() async {
    try {
      // Check if we have any pending dynamic links
      // For example, password reset links or email verification
      if (firebaseService.isInitialized) {
        final auth = firebaseService.auth;

        // Check for any pending password reset codes
        final PendingDynamicLinkData? data = await FirebaseDynamicLinks.instance.getInitialLink();
        if (data != null) {
          // Handle links here (e.g., password reset)
          final Uri deepLink = data.link;

          // Example: handle password reset
          if (deepLink.path.contains('resetPassword')) {
            // Extract the oobCode from the URL
            final code = deepLink.queryParameters['oobCode'];
            if (code != null) {
              try {
                // Verify the code is valid
                await auth.verifyPasswordResetCode(code);

                // Navigate to a password reset confirmation page
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => PasswordResetConfirmationPage(code: code),
                    ),
                  );
                }
              } catch (e) {
                print('Error verifying password reset code: $e');
                // Show an error message if needed
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error handling deep links: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Firebase Dynamic Links for handling deep links
/// This is used for password reset and email verification
class FirebaseDynamicLinks {
  static final FirebaseDynamicLinks _instance = FirebaseDynamicLinks._internal();
  static FirebaseDynamicLinks get instance => _instance;
  FirebaseDynamicLinks._internal();

  /// Get the initial dynamic link if the app was opened with one
  Future<PendingDynamicLinkData?> getInitialLink() async {
    // This would be implemented with Firebase Dynamic Links package
    // For now, we return null
    return null;
  }
}

/// Placeholder for PendingDynamicLinkData
class PendingDynamicLinkData {
  final Uri link;
  PendingDynamicLinkData(this.link);
}

/// Password reset confirmation page
class PasswordResetConfirmationPage extends StatefulWidget {
  final String code;

  const PasswordResetConfirmationPage({Key? key, required this.code}) : super(key: key);

  @override
  _PasswordResetConfirmationPageState createState() => _PasswordResetConfirmationPageState();
}

class _PasswordResetConfirmationPageState extends State<PasswordResetConfirmationPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';
  bool _success = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Reset password with the confirmation code
  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Confirm password reset
      await firebaseService.auth.confirmPasswordReset(
        code: widget.code,
        newPassword: _passwordController.text,
      );

      // On success
      setState(() {
        _success = true;
        _isLoading = false;
      });

      // Redirect to login after delay
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      });
    } catch (e) {
      // Show error
      setState(() {
        _errorMessage = 'Error resetting password: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icon
                Icon(
                  _success ? Icons.check_circle : Icons.lock_reset,
                  size: 72,
                  color: _success ? Colors.green : Colors.blueAccent,
                ),
                SizedBox(height: 24),

                // Title
                Text(
                  _success ? 'Password Reset Successful' : 'Set New Password',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                if (!_success) ...[
                  // Error message if any
                  if (_errorMessage.isNotEmpty)
                    Container(
                      padding: EdgeInsets.all(16),
                      color: Colors.red.shade50,
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                  if (_errorMessage.isNotEmpty)
                    SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 16),

                  // Confirm password field
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    child: _isLoading
                        ? CircularProgressIndicator()
                        : Text('Reset Password'),
                  ),
                ],

                if (_success)
                  Text(
                    'Your password has been reset successfully. Redirecting to login...',
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}