import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/auth/login_page.dart';
import 'package:pantry_pal/services/firebase_sync_service.dart';
import 'package:pantry_pal/widgets/sync_status_widget.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the theme controller
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Theme Toggle Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Switch(
                        value: themeController.isDarkMode,
                        activeColor: Colors.blueAccent,
                        onChanged: (value) {
                          themeController.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Add Sync Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Sync',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Sync status indicator
                  SyncStatusWidget(),
                  SizedBox(height: 8),
                  // Manual sync button
                  if (firebaseService.isLoggedIn)
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // First sync local data to Firestore
                          await firebaseSyncService.syncToFirestore();

                          // Then sync from Firestore to get any data from other devices
                          await firebaseSyncService.syncFromFirestore();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sync completed successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error syncing: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.sync),
                      label: Text('Sync Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (!firebaseService.isLoggedIn)
                    Text(
                      'Sign in to enable data sync',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Font Selection Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Font Family',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    value: themeController.currentFont,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        themeController.setFont(newValue);
                      }
                    },
                    items: ThemeController.availableFonts
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: value,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Logout Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showLogoutConfirmation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              child: Text('Logout'),
              onPressed: () async {
                try {
                  // Perform logout
                  await firebaseService.signOut();

                  // Navigate to login page, removing all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  // Show error if logout fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}