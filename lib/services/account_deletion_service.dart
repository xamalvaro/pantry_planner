// services/account_deletion_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/hive_manager.dart';

/// Service to handle complete account deletion
class AccountDeletionService {
  // Singleton pattern
  static final AccountDeletionService _instance = AccountDeletionService._internal();
  factory AccountDeletionService() => _instance;
  AccountDeletionService._internal();

  // References
  final FirebaseService _firebase = firebaseService;
  final HiveManager _hiveManager = hiveManager;

  /// Delete the user's account and all associated data
  Future<void> deleteAccountAndAllData() async {
    if (!_firebase.isLoggedIn) {
      throw Exception('User must be logged in to delete account');
    }

    final user = _firebase.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }

    try {
      // 1. Delete all cloud data first
      await _deleteAllCloudData();

      // 2. Delete all local data
      await _deleteAllLocalData();

      // 3. Delete the Firebase user account
      await user.delete();

      // 4. Sign out (cleanup)
      await _firebase.signOut();

      print('Account and all data deleted successfully');
    } catch (e) {
      print('Error during account deletion: $e');
      throw AccountDeletionException('Failed to delete account: $e');
    }
  }

  /// Delete all cloud data from Firestore
  Future<void> _deleteAllCloudData() async {
    try {
      // Batch delete for efficiency
      final batch = _firebase.firestore.batch();
      int operationCount = 0;

      // Delete user document
      final userDoc = _firebase.getUserDocument();
      batch.delete(userDoc);
      operationCount++;

      // Delete all grocery lists
      final groceryLists = await _firebase.getUserGroceryLists().get();
      for (final doc in groceryLists.docs) {
        batch.delete(doc.reference);
        operationCount++;

        // Firestore has a limit of 500 operations per batch
        if (operationCount >= 400) {
          await batch.commit();
          operationCount = 0;
        }
      }

      // Delete all recipes
      final recipes = await _firebase.getUserRecipes().get();
      for (final doc in recipes.docs) {
        batch.delete(doc.reference);
        operationCount++;

        if (operationCount >= 400) {
          await batch.commit();
          operationCount = 0;
        }
      }

      // Delete all pantry items
      final pantryItems = await _firebase.getUserPantryItems().get();
      for (final doc in pantryItems.docs) {
        batch.delete(doc.reference);
        operationCount++;

        if (operationCount >= 400) {
          await batch.commit();
          operationCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      print('All cloud data deleted successfully');
    } catch (e) {
      print('Error deleting cloud data: $e');
      throw e;
    }
  }

  /// Delete all local data from Hive
  Future<void> _deleteAllLocalData() async {
    try {
      // Clear all boxes
      await _hiveManager.clearLocalData();

      // Also clear settings box
      final settingsBox = await _hiveManager.openBox('settings');
      if (settingsBox != null) {
        await settingsBox.clear();
      }

      print('All local data deleted successfully');
    } catch (e) {
      print('Error deleting local data: $e');
      throw e;
    }
  }

  /// Check if the user needs to reauthenticate
  /// Firebase requires recent authentication for account deletion
  Future<bool> needsReauthentication() async {
    final user = _firebase.currentUser;
    if (user == null) return false;

    // Check if the user signed in recently (within last 5 minutes)
    final metadata = user.metadata;
    if (metadata.lastSignInTime == null) return true;

    final lastSignIn = metadata.lastSignInTime!;
    final now = DateTime.now();
    final difference = now.difference(lastSignIn);

    // If more than 5 minutes have passed, require reauthentication
    return difference.inMinutes > 5;
  }

  /// Reauthenticate the user before account deletion
  Future<void> reauthenticate(String email, String password) async {
    final user = _firebase.currentUser;
    if (user == null) {
      throw Exception('No user to reauthenticate');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      print('User reauthenticated successfully');
    } catch (e) {
      print('Error during reauthentication: $e');
      throw ReauthenticationException('Failed to reauthenticate: $e');
    }
  }
}

/// Custom exception for account deletion errors
class AccountDeletionException implements Exception {
  final String message;
  AccountDeletionException(this.message);

  @override
  String toString() => message;
}

/// Custom exception for reauthentication errors
class ReauthenticationException implements Exception {
  final String message;
  ReauthenticationException(this.message);

  @override
  String toString() => message;
}

// Global instance
final accountDeletionService = AccountDeletionService();