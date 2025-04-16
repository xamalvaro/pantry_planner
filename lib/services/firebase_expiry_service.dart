// services/firebase_expiry_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/expiry/matching/ingredient_matcher.dart';

/// Service to manage pantry items with expiry dates using Firebase
class FirebaseExpiryService {
  // Singleton pattern
  static final FirebaseExpiryService _instance = FirebaseExpiryService._internal();
  factory FirebaseExpiryService() => _instance;
  FirebaseExpiryService._internal();

  // Dependencies
  final _uuid = Uuid();
  final _ingredientMatcher = IngredientMatcher();
  final FirebaseService _firebase = firebaseService;

  // Stream controller for updates
  final _expiryUpdatesController = StreamController<List<PantryItem>>.broadcast();
  Stream<List<PantryItem>> get expiryUpdates => _expiryUpdatesController.stream;

  // Get pantry items collection reference
  CollectionReference _getPantryItemsCollection() {
    return _firebase.getUserPantryItems();
  }

  /// Initialize the service
  Future<void> init() async {
    // Start expiry check timer
    _startExpiryCheckTimer();
    print('FirebaseExpiryService: Service initialized');
  }

  /// Generate a unique ID for new items
  String generateItemId() => _uuid.v4();

  /// Get all pantry items
  Stream<List<PantryItem>> getAllItemsStream() {
    if (!_firebase.isLoggedIn) return Stream.value([]);

    return _getPantryItemsCollection()
        .snapshots()
        .map((snapshot) {
      final items = <PantryItem>[];
      for (final doc in snapshot.docs) {
        try {
          items.add(_convertDocToPantryItem(doc));
        } catch (e) {
          print('FirebaseExpiryService: Error converting doc to PantryItem: $e');
        }
      }
      return items;
    });
  }

  /// Get all pantry items (Future version)
  Future<List<PantryItem>> getAllItems() async {
    if (!_firebase.isLoggedIn) return [];

    try {
      final snapshot = await _getPantryItemsCollection().get();
      final items = <PantryItem>[];

      for (final doc in snapshot.docs) {
        try {
          items.add(_convertDocToPantryItem(doc));
        } catch (e) {
          print('FirebaseExpiryService: Error converting doc to PantryItem: $e');
        }
      }

      return items;
    } catch (e) {
      print('FirebaseExpiryService: Error getting all items: $e');
      return [];
    }
  }

  /// Get items expiring soon
  Future<List<PantryItem>> getExpiringItems({int withinDays = 7}) async {
    final items = await getAllItems();
    final now = DateTime.now();
    final expiryThreshold = now.add(Duration(days: withinDays));

    return items.where((item) =>
    (item.expiryDate.isAfter(now) && item.expiryDate.isBefore(expiryThreshold)) ||
        _isSameDay(item.expiryDate, now) ||
        (item.expiryDate.isBefore(now) && now.difference(item.expiryDate).inDays <= 3)
    ).toList();
  }

  /// Get expired items (past their expiration date)
  Future<List<PantryItem>> getExpiredItems() async {
    final items = await getAllItems();
    final now = DateTime.now();
    return items.where((item) => item.expiryDate.isBefore(now)).toList();
  }

  /// Check for expiring items (for notifications)
  Future<void> checkExpiringItems() async {
    // Update stream with latest data
    final items = await getAllItems();
    _expiryUpdatesController.add(items);
  }

  /// Add a new pantry item
  Future<void> addItem(PantryItem item) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    try {
      await _getPantryItemsCollection().doc(item.id).set(_pantryItemToMap(item));

      // Notify listeners
      _expiryUpdatesController.add(await getAllItems());
    } catch (e) {
      print('FirebaseExpiryService: Error adding item: $e');
      rethrow;
    }
  }

  /// Update an existing pantry item
  Future<void> updateItem(PantryItem item) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    try {
      await _getPantryItemsCollection().doc(item.id).update(_pantryItemToMap(item));

      // Notify listeners
      _expiryUpdatesController.add(await getAllItems());
    } catch (e) {
      print('FirebaseExpiryService: Error updating item: $e');
      rethrow;
    }
  }

  /// Delete a pantry item
  Future<void> deleteItem(String itemId) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    try {
      await _getPantryItemsCollection().doc(itemId).delete();

      // Notify listeners
      _expiryUpdatesController.add(await getAllItems());
    } catch (e) {
      print('FirebaseExpiryService: Error deleting item: $e');
      rethrow;
    }
  }

  /// Generate recipe suggestions based on expiring items
  Future<List<RecipeSuggestion>> getRecipeSuggestions() async {
    final expiringItems = await getExpiringItems(withinDays: 14);

    if (expiringItems.isEmpty) {
      return [];
    }

    // The IngredientMatcher class should be refactored to use the FirebaseRecipeService
    // For now, we'll just return fallback suggestions
    return _ingredientMatcher.createFallbackSuggestions(expiringItems);
  }

  /// Force refresh recipe suggestions
  Future<List<RecipeSuggestion>> forceRefreshSuggestions() async {
    return getRecipeSuggestions();
  }

  /// Show expiry information notification
  Future<void> showExpiryInfo(BuildContext context) async {
    try {
      // Get expiring and expired items
      final futures = await Future.wait([
        getExpiringItems(withinDays: 3),
        getExpiredItems(),
      ]);

      final criticalItems = futures[0];
      final expiredItems = futures[1];

      // Don't show anything if nothing is expiring soon
      if (criticalItems.isEmpty && expiredItems.isEmpty) {
        return;
      }

      // Prepare notification message
      String message;
      Color backgroundColor;

      if (expiredItems.isNotEmpty) {
        message = '${expiredItems.length} item${expiredItems.length > 1 ? "s have" : " has"} expired';
        backgroundColor = Colors.red;
      } else {
        message = '${criticalItems.length} item${criticalItems.length > 1 ? "s are" : " is"} expiring soon';
        backgroundColor = Colors.orange;
      }

      // Show notification
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/calendar');
              },
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('FirebaseExpiryService: Error showing expiry info: $e');
    }
  }

  /// Convert a Firestore document to a PantryItem
  PantryItem _convertDocToPantryItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return PantryItem(
      id: doc.id,
      name: data['name'] ?? '',
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : DateTime.now().add(Duration(days: 7)),
      category: data['category'] ?? 'Other',
      location: data['location'] ?? 'Pantry',
      notes: data['notes'],
      quantity: data['quantity'] ?? 1,
      quantityUnit: data['quantityUnit'] ?? 'pcs',
      isNotified: data['isNotified'] ?? false,
    );
  }

  /// Convert a PantryItem to a Map for Firestore
  Map<String, dynamic> _pantryItemToMap(PantryItem item) {
    return {
      'name': item.name,
      'expiryDate': Timestamp.fromDate(item.expiryDate),
      'category': item.category,
      'location': item.location,
      'notes': item.notes,
      'quantity': item.quantity,
      'quantityUnit': item.quantityUnit,
      'isNotified': item.isNotified,
      'lastSynced': FieldValue.serverTimestamp(),
    };
  }

  /// Start a timer to check for expiring items
  void _startExpiryCheckTimer() {
    // Check once a day
    Timer.periodic(Duration(hours: 24), (timer) => checkExpiringItems());

    // Also check immediately
    checkExpiringItems();
  }

  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Dispose resources
  void dispose() {
    _expiryUpdatesController.close();
  }
}

// Global instance
final firebaseExpiryService = FirebaseExpiryService();