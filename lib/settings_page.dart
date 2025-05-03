import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/auth/login_page.dart';
import 'package:pantry_pal/services/firebase_sync_service.dart';
import 'package:pantry_pal/widgets/sync_status_widget.dart';
import 'package:pantry_pal/auth/register_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

          // Add Sync Section (only show for non-guest users)
          if (!firebaseService.isGuestMode)
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

          SizedBox(height: 16),

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

          // Data Management Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Management',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  // Display if user is in guest mode
                  if (firebaseService.isGuestMode)
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.amber),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You are using guest mode. Your data is stored only locally and will be deleted if you uninstall the app.',
                              style: TextStyle(
                                fontFamily: themeController.currentFont,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (firebaseService.isGuestMode)
                    SizedBox(height: 16),
                  // Data deletion button
                  ElevatedButton.icon(
                    icon: Icon(Icons.delete_forever),
                    label: Text('Delete All My Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () => _showDataDeletionConfirmation(context),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Account Section
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

                  // Show current login status
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: firebaseService.isGuestMode
                          ? Colors.grey.withOpacity(0.2)
                          : Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          firebaseService.isGuestMode ? Icons.person_outline : Icons.verified_user,
                          size: 20,
                          color: firebaseService.isGuestMode ? Colors.grey : Colors.green,
                        ),
                        SizedBox(width: 8),
                        Text(
                          firebaseService.isGuestMode
                              ? 'Using Guest Mode (data stored locally)'
                              : 'Signed in as ${firebaseService.auth.currentUser?.email ?? "User"}',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Create account button (for guest users)
                  if (firebaseService.isGuestMode)
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to register page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => RegisterPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(
                        'Create an Account',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (firebaseService.isGuestMode)
                    SizedBox(height: 12),

                  // Logout button (or "Exit Guest Mode" for guests)
                  ElevatedButton(
                    onPressed: () => _showLogoutConfirmation(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text(
                      firebaseService.isGuestMode ? 'Exit Guest Mode' : 'Logout',
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
    final isGuest = firebaseService.isGuestMode;
    final confirmationMessage = isGuest
        ? 'You are currently using guest mode. If you exit, your data will remain on this device. Are you sure you want to exit guest mode?'
        : 'Are you sure you want to log out?';
    final buttonText = isGuest ? 'Exit Guest Mode' : 'Logout';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isGuest ? 'Exit Guest Mode' : 'Logout'),
          content: Text(confirmationMessage),
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
              child: Text(buttonText),
              onPressed: () async {
                try {
                  if (isGuest) {
                    // End guest mode
                    await firebaseService.endGuestMode();
                  } else {
                    // Perform logout
                    await firebaseService.signOut();
                  }

                  // Navigate to login page, removing all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  // Show error if logout fails
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
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

  // Data deletion confirmation dialog
  // Update the data deletion confirmation method
  // Improved data deletion confirmation method
  void _showDataDeletionConfirmation(BuildContext context) {
    final isGuest = firebaseService.isGuestMode;
    final confirmationMessage = isGuest
        ? 'Are you sure you want to delete all your data? This action cannot be undone.'
        : 'Are you sure you want to delete all your data from this device and the cloud? This action cannot be undone.';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {  // Use a separate context for the dialog
        return AlertDialog(
          title: Text('Delete All Data'),
          content: Text(confirmationMessage),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              child: Text('Delete All Data'),
              onPressed: () {
                // First pop the confirmation dialog
                Navigator.of(dialogContext).pop();

                // Then perform the data deletion in a separate function
                _performDataDeletion(context, isGuest);
              },
            ),
          ],
        );
      },
    );
  }

// Separate function to handle the data deletion process
  Future<void> _performDataDeletion(BuildContext context, bool isGuest) async {
    // Show loading dialog
    BuildContext? loadingDialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        loadingDialogContext = dialogContext;
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Deleting all data..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Delete local data
      await _deleteLocalData();

      // Delete cloud data if not in guest mode
      if (!isGuest && firebaseService.isLoggedIn) {
        await _deleteCloudData();
      }

      // Close loading dialog safely
      if (loadingDialogContext != null && Navigator.canPop(loadingDialogContext!)) {
        Navigator.of(loadingDialogContext!).pop();
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isGuest
              ? 'All local data deleted successfully'
              : 'All data deleted successfully from this device and the cloud'),
          backgroundColor: Colors.green,
        ),
      );

      // If in guest mode, navigate back to login page
      if (isGuest) {
        await firebaseService.endGuestMode();

        // Use a short delay to ensure all UI operations complete
        await Future.delayed(Duration(milliseconds: 500));

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginPage()),
                (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      print('Error during data deletion: $e');

      // Close loading dialog safely
      if (loadingDialogContext != null && Navigator.canPop(loadingDialogContext!)) {
        Navigator.of(loadingDialogContext!).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Helper method to delete local data
  Future<void> _deleteLocalData() async {
    try {
      // Delete grocery lists
      final groceryBox = await Hive.openBox('groceryLists');
      await groceryBox.clear();

      // Delete recipes
      final recipesBox = await Hive.openBox('recipes');
      await recipesBox.clear();

      // Delete pantry items
      final pantryBox = await Hive.openBox('pantryItems');
      await pantryBox.clear();

      print('Local data deleted successfully');
    } catch (e) {
      print('Error deleting local data: $e');
      throw e;
    }
  }

// Add a method to delete cloud data
  Future<void> _deleteCloudData() async {
    try {
      if (!firebaseService.isLoggedIn) {
        print('Cannot delete cloud data: User not logged in');
        return;
      }

      // Delete grocery lists from Firestore
      final groceryListsCollection = firebaseService.getUserGroceryLists();
      final groceryListsSnapshot = await groceryListsCollection.get();

      for (var doc in groceryListsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete recipes from Firestore
      final recipesCollection = firebaseService.getUserRecipes();
      final recipesSnapshot = await recipesCollection.get();

      for (var doc in recipesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete pantry items from Firestore
      final pantryItemsCollection = firebaseService.getUserPantryItems();
      final pantryItemsSnapshot = await pantryItemsCollection.get();

      for (var doc in pantryItemsSnapshot.docs) {
        await doc.reference.delete();
      }

      print('Cloud data deleted successfully');
    } catch (e) {
      print('Error deleting cloud data: $e');
      throw e;
    }
  }
}