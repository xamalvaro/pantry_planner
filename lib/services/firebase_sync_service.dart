// services/firebase_sync_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/hive_manager.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';

/// Service to handle synchronization between local Hive storage and Firebase
class FirebaseSyncService {
  // Singleton pattern
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  // Reference to Firebase service
  final FirebaseService _firebase = firebaseService;

  // Reference to Hive Manager
  final HiveManager _hiveManager = hiveManager;

  // Flag to prevent duplicate syncs
  bool _isSyncing = false;

  // Stream controllers for sync events
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatus => _syncStatusController.stream;

  /// Initialize the sync service
  Future<void> initialize() async {
    // Listen to authentication state changes
    _firebase.authStateChanges.listen((user) async {
      if (user != null) {
        // User logged in, sync data from Firestore
        await syncFromFirestore();
      }
    });

    print('FirebaseSyncService: Initialized');
  }

  /// Sync data from local storage to Firestore
  Future<void> syncToFirestore() async {
    if (!_firebase.isLoggedIn || _isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus(isActive: true, message: 'Uploading data...'));

    try {
      print('FirebaseSyncService: Starting sync to Firestore');

      // Check if user ID is valid
      if (_firebase.uid == null || _firebase.uid!.isEmpty) {
        throw Exception('User ID is null or empty');
      }

      // 1. Sync grocery lists
      try {
        await _syncGroceryListsToFirestore();
      } catch (e) {
        print('FirebaseSyncService: Error syncing grocery lists: $e');
        // Continue with other syncs despite this error
      }

      // 2. Sync recipes
      try {
        await _syncRecipesToFirestore();
      } catch (e) {
        print('FirebaseSyncService: Error syncing recipes: $e');
        // Continue with other syncs despite this error
      }

      // 3. Sync pantry items
      try {
        await _syncPantryItemsToFirestore();
      } catch (e) {
        print('FirebaseSyncService: Error syncing pantry items: $e');
        // Continue with other syncs despite this error
      }

      _syncStatusController.add(SyncStatus(isActive: false, message: 'Data uploaded successfully'));
      print('FirebaseSyncService: Sync to Firestore completed');
    } catch (e) {
      print('FirebaseSyncService: Error syncing to Firestore: $e');
      _syncStatusController.add(SyncStatus(isActive: false, message: 'Error uploading data: $e', isError: true));
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync data from Firestore to local storage
  Future<void> syncFromFirestore() async {
    if (!_firebase.isLoggedIn || _isSyncing) return;

    _isSyncing = true;
    _syncStatusController.add(SyncStatus(isActive: true, message: 'Downloading data...'));

    try {
      print('FirebaseSyncService: Starting sync from Firestore');

      // 1. Sync grocery lists
      await _syncGroceryListsFromFirestore();

      // 2. Sync recipes
      await _syncRecipesFromFirestore();

      // 3. Sync pantry items
      await _syncPantryItemsFromFirestore();

      _syncStatusController.add(SyncStatus(isActive: false, message: 'Data downloaded successfully'));
      print('FirebaseSyncService: Sync from Firestore completed');
    } catch (e) {
      print('FirebaseSyncService: Error syncing from Firestore: $e');
      _syncStatusController.add(SyncStatus(isActive: false, message: 'Error downloading data: $e', isError: true));
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync grocery lists to Firestore
  Future<void> _syncGroceryListsToFirestore() async {
    try {
      final groceryBox = await _hiveManager.openBox('groceryLists');
      if (groceryBox == null) return;

      // Get Firestore collection
      final collection = _firebase.getUserGroceryLists();

      // Batch operations for efficiency
      final batch = _firebase.firestore.batch();
      int operationCount = 0;

      // Iterate through all grocery lists
      for (final key in groceryBox.keys) {
        final listData = groceryBox.get(key);
        if (listData == null) continue;

        // Skip empty keys
        if (key.toString().trim().isEmpty) {
          print('FirebaseSyncService: Skipping item with empty key');
          continue;
        }

        // Create Firestore document ID from list name
        final docId = key.toString().trim()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(' ', '_')
            .toLowerCase();

        // Skip if docId is empty
        if (docId.isEmpty) {
          print('FirebaseSyncService: Generated empty docId for key: $key');
          continue;
        }

        // Convert dynamic map to Map<String, dynamic>
        Map<String, dynamic> sanitizedData = _sanitizeMap(listData);

        // Add data with timestamp
        batch.set(
          collection.doc(docId),
          {
            ...sanitizedData,
            'name': key.toString(),
            'lastSynced': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        operationCount++;

        // Firebase has a limit of 500 operations per batch
        if (operationCount >= 400) {
          await batch.commit();
          operationCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      print('FirebaseSyncService: Synced ${groceryBox.keys.length} grocery lists to Firestore');
    } catch (e) {
      print('FirebaseSyncService: Error syncing grocery lists to Firestore: $e');
      throw e;
    }
  }

  /// Add this helper method to sanitize data for Firestore
  Map<String, dynamic> _sanitizeMap(dynamic map) {
    if (map is! Map) {
      return {}; // Return empty map if not a map
    }

    Map<String, dynamic> result = {};

    map.forEach((key, value) {
      // Convert key to string
      String stringKey = key.toString();

      // Handle nested maps
      if (value is Map) {
        result[stringKey] = _sanitizeMap(value);
      }
      // Handle lists that might contain maps
      else if (value is List) {
        result[stringKey] = _sanitizeList(value);
      }
      // Handle simple values
      else {
        result[stringKey] = value;
      }
    });

    return result;
  }

  /// Helper to sanitize lists that might contain maps
  List<dynamic> _sanitizeList(List<dynamic> list) {
    return list.map((item) {
      if (item is Map) {
        return _sanitizeMap(item);
      } else if (item is List) {
        return _sanitizeList(item);
      } else {
        return item;
      }
    }).toList();
  }

  /// Sync recipes to Firestore
  Future<void> _syncRecipesToFirestore() async {
    try {
      final recipeBox = await _hiveManager.openBox('recipes');
      if (recipeBox == null) return;

      // Get Firestore collection
      final collection = _firebase.getUserRecipes();

      // Batch operations for efficiency
      final batch = _firebase.firestore.batch();
      int operationCount = 0;

      // Iterate through all recipes
      for (final key in recipeBox.keys) {
        final recipeData = recipeBox.get(key);
        if (recipeData == null) continue;

        // Create Firestore document ID from recipe title
        final docId = key.toString().trim()
            .replaceAll(RegExp(r'[^\w\s]'), '')
            .replaceAll(' ', '_')
            .toLowerCase();

        // Add data with timestamp
        Map<String, dynamic> sanitizedData = _sanitizeMap(recipeData);

        batch.set(
          collection.doc(docId),
          {
            ...sanitizedData,
            'title': key.toString(),
            'lastSynced': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        operationCount++;

        // Firebase has a limit of 500 operations per batch
        if (operationCount >= 400) {
          await batch.commit();
          operationCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      print('FirebaseSyncService: Synced ${recipeBox.keys.length} recipes to Firestore');
    } catch (e) {
      print('FirebaseSyncService: Error syncing recipes to Firestore: $e');
      throw e;
    }
  }

  /// Sync pantry items to Firestore
  Future<void> _syncPantryItemsToFirestore() async {
    try {
      final pantryBox = await _hiveManager.openBox('pantryItems');
      if (pantryBox == null) return;

      // Get Firestore collection
      final collection = _firebase.getUserPantryItems();

      // Batch operations for efficiency
      final batch = _firebase.firestore.batch();
      int operationCount = 0;

      // Iterate through all pantry items
      for (final key in pantryBox.keys) {
        final itemData = pantryBox.get(key);
        if (itemData == null) continue;

        // Add data with timestamp
        Map<String, dynamic> sanitizedData = _sanitizeMap(itemData);

        batch.set(
          collection.doc(key.toString()),
          {
            ...sanitizedData,
            'lastSynced': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        operationCount++;

        // Firebase has a limit of 500 operations per batch
        if (operationCount >= 400) {
          await batch.commit();
          operationCount = 0;
        }
      }

      // Commit any remaining operations
      if (operationCount > 0) {
        await batch.commit();
      }

      print('FirebaseSyncService: Synced ${pantryBox.keys.length} pantry items to Firestore');
    } catch (e) {
      print('FirebaseSyncService: Error syncing pantry items to Firestore: $e');
      throw e;
    }
  }

  /// Sync grocery lists from Firestore
  Future<void> _syncGroceryListsFromFirestore() async {
    try {
      // Get Firestore collection
      final collection = _firebase.getUserGroceryLists();

      // Get all documents
      final querySnapshot = await collection.get();

      // Open local box
      final groceryBox = await _hiveManager.openBox('groceryLists');
      if (groceryBox == null) return;

      // Process each document
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract the name from the document
        final name = data['name'] ?? doc.id;

        // Remove fields that shouldn't be in the local storage
        data.remove('lastSynced');

        // Save to local storage
        await groceryBox.put(name, data);
      }

      print('FirebaseSyncService: Synced ${querySnapshot.docs.length} grocery lists from Firestore');
    } catch (e) {
      print('FirebaseSyncService: Error syncing grocery lists from Firestore: $e');
      throw e;
    }
  }

  /// Sync recipes from Firestore
  Future<void> _syncRecipesFromFirestore() async {
    try {
      // Get Firestore collection
      final collection = _firebase.getUserRecipes();

      // Get all documents
      final querySnapshot = await collection.get();

      // Open local box
      final recipeBox = await _hiveManager.openBox('recipes');
      if (recipeBox == null) return;

      // Process each document
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Extract the title from the document
        final title = data['title'] ?? doc.id;

        // Remove fields that shouldn't be in the local storage
        data.remove('lastSynced');

        // Save to local storage
        await recipeBox.put(title, data);
      }

      print('FirebaseSyncService: Synced ${querySnapshot.docs.length} recipes from Firestore');
    } catch (e) {
      print('FirebaseSyncService: Error syncing recipes from Firestore: $e');
      throw e;
    }
  }

  /// Sync pantry items from Firestore
  Future<void> _syncPantryItemsFromFirestore() async {
    try {
      // Get Firestore collection
      final collection = _firebase.getUserPantryItems();

      // Get all documents
      final querySnapshot = await collection.get();

      // Open local box
      final pantryBox = await _hiveManager.openBox('pantryItems');
      if (pantryBox == null) return;

      // Process each document
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Remove fields that shouldn't be in the local storage
        data.remove('lastSynced');

        // Convert Firestore Timestamp to DateTime for expiryDate
        if (data['expiryDate'] is Timestamp) {
          final timestamp = data['expiryDate'] as Timestamp;
          data['expiryDate'] = timestamp.toDate().millisecondsSinceEpoch;
        }

        // Save to local storage
        await pantryBox.put(doc.id, data);
      }

      print('FirebaseSyncService: Synced ${querySnapshot.docs.length} pantry items from Firestore');
    } catch (e) {
      print('FirebaseSyncService: Error syncing pantry items from Firestore: $e');
      throw e;
    }
  }

  // Clean up resources
  void dispose() {
    _syncStatusController.close();
  }
}

/// Class to represent sync status
class SyncStatus {
  final bool isActive;
  final String message;
  final bool isError;

  SyncStatus({
    required this.isActive,
    required this.message,
    this.isError = false,
  });
}

// Global instance
final firebaseSyncService = FirebaseSyncService();