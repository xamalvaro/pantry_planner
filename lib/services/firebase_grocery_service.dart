// services/firebase_grocery_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pantry_pal/services/firebase_service.dart';

/// Service to manage grocery lists using Firebase
class FirebaseGroceryService {
  // Singleton pattern
  static final FirebaseGroceryService _instance = FirebaseGroceryService._internal();
  factory FirebaseGroceryService() => _instance;
  FirebaseGroceryService._internal();

  // Reference to Firebase service
  final FirebaseService _firebase = firebaseService;

  // Get grocery lists collection reference
  CollectionReference _getGroceryListsCollection() {
    return _firebase.getUserGroceryLists();
  }

  /// Get all grocery lists
  Stream<QuerySnapshot> getAllGroceryLists() {
    if (!_firebase.isLoggedIn) return Stream.value(null as QuerySnapshot);

    return _getGroceryListsCollection()
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  /// Get a specific grocery list
  Stream<DocumentSnapshot> getGroceryList(String listId) {
    if (!_firebase.isLoggedIn) return Stream.value(null as DocumentSnapshot);

    return _getGroceryListsCollection().doc(listId).snapshots();
  }

  /// Create or update a grocery list
  Future<String> saveGroceryList(String listName, Map<String, dynamic> data) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    // Sanitize list name to use as document ID
    final docId = listName.trim().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_').toLowerCase();

    // Add timestamp and other metadata
    final listData = {
      ...data,
      'name': listName,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // Save to Firestore
    await _getGroceryListsCollection().doc(docId).set(
      listData,
      SetOptions(merge: true),
    );

    return docId;
  }

  /// Delete a grocery list
  Future<void> deleteGroceryList(String listId) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    await _getGroceryListsCollection().doc(listId).delete();
  }

  /// Convert Firestore data to the format expected by the app
  Map<String, dynamic> convertFirestoreData(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Make sure categories and tags are in the right format for the app
    if (!data.containsKey('categories')) {
      data['categories'] = {};
    }

    if (!data.containsKey('tags')) {
      data['tags'] = [];
    }

    return {
      ...data,
      'id': doc.id,
    };
  }

  /// Get all unique tags from all grocery lists
  Future<List<String>> getAllTags() async {
    if (!_firebase.isLoggedIn) return [];

    try {
      final snapshot = await _getGroceryListsCollection().get();

      final Set<String> tags = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final listTags = data['tags'] as List<dynamic>? ?? [];

        for (final tag in listTags) {
          tags.add(tag.toString());
        }
      }

      return tags.toList();
    } catch (e) {
      print('FirebaseGroceryService: Error getting tags: $e');
      return [];
    }
  }

  /// Search grocery lists by name or tags
  Future<List<DocumentSnapshot>> searchGroceryLists(String query) async {
    if (!_firebase.isLoggedIn) return [];

    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _getGroceryListsCollection().get();

      // Filter results client-side (Firestore doesn't support complex text search)
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final name = data['name']?.toString().toLowerCase() ?? '';
        final tags = data['tags'] as List<dynamic>? ?? [];

        // Check if name contains query
        if (name.contains(queryLower)) return true;

        // Check if any tag contains query
        for (final tag in tags) {
          if (tag.toString().toLowerCase().contains(queryLower)) {
            return true;
          }
        }

        return false;
      }).toList();
    } catch (e) {
      print('FirebaseGroceryService: Error searching lists: $e');
      return [];
    }
  }

  /// Share a grocery list with another user
  Future<void> shareGroceryList(String listId, String recipientEmail) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    try {
      // Get list data
      final docSnapshot = await _getGroceryListsCollection().doc(listId).get();
      if (!docSnapshot.exists) throw Exception('List not found');

      final listData = docSnapshot.data() as Map<String, dynamic>? ?? {};

      // Create a shared list record
      await _firebase.firestore.collection('sharedLists').add({
        'sourceUserId': _firebase.uid,
        'recipientEmail': recipientEmail.toLowerCase(),
        'listData': listData,
        'listId': listId,
        'sharedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('FirebaseGroceryService: Error sharing list: $e');
      rethrow;
    }
  }

  /// Accept a shared grocery list
  Future<void> acceptSharedList(String sharedListId) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    try {
      // Get shared list data
      final sharedListDoc = await _firebase.firestore
          .collection('sharedLists')
          .doc(sharedListId)
          .get();

      if (!sharedListDoc.exists) throw Exception('Shared list not found');

      final sharedData = sharedListDoc.data() as Map<String, dynamic>? ?? {};
      final listData = sharedData['listData'] as Map<String, dynamic>? ?? {};
      final listId = sharedData['listId'] as String? ?? '';

      // Save to user's grocery lists
      await _getGroceryListsCollection().doc(listId).set({
        ...listData,
        'sharedFrom': sharedData['sourceUserId'],
        'sharedAt': sharedData['sharedAt'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update status in shared lists
      await _firebase.firestore
          .collection('sharedLists')
          .doc(sharedListId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseGroceryService: Error accepting shared list: $e');
      rethrow;
    }
  }

  /// Get shared lists for the current user
  Stream<QuerySnapshot> getSharedLists() {
    if (!_firebase.isLoggedIn) return Stream.value(null as QuerySnapshot);

    return _firebase.firestore
        .collection('sharedLists')
        .where('recipientEmail', isEqualTo: _firebase.auth.currentUser?.email?.toLowerCase())
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
}

// Global instance
final firebaseGroceryService = FirebaseGroceryService();