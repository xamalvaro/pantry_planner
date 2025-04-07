// services/firebase_recipe_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';

/// Service to manage recipes using Firebase
class FirebaseRecipeService {
  // Singleton pattern
  static final FirebaseRecipeService _instance = FirebaseRecipeService._internal();
  factory FirebaseRecipeService() => _instance;
  FirebaseRecipeService._internal();

  // Reference to Firebase service
  final FirebaseService _firebase = firebaseService;

  // Get recipes collection reference
  CollectionReference _getRecipesCollection() {
    return _firebase.getUserRecipes();
  }

  /// Get all recipes
  Stream<QuerySnapshot> getAllRecipes() {
    if (!_firebase.isLoggedIn) return Stream.value(null as QuerySnapshot);

    return _getRecipesCollection()
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  /// Get a specific recipe
  Stream<DocumentSnapshot> getRecipe(String recipeId) {
    if (!_firebase.isLoggedIn) return Stream.value(null as DocumentSnapshot);

    return _getRecipesCollection().doc(recipeId).snapshots();
  }

  /// Save a recipe
  Future<String> saveRecipe(Recipe recipe) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    // Sanitize recipe title to use as document ID
    final docId = recipe.title.trim().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_').toLowerCase();

    // Convert recipe to map and add metadata
    final recipeData = {
      ...recipe.toMap(),
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    // Save to Firestore
    await _getRecipesCollection().doc(docId).set(
      recipeData,
      SetOptions(merge: true),
    );

    return docId;
  }

  /// Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    await _getRecipesCollection().doc(recipeId).delete();
  }

  /// Convert Firestore data to Recipe model
  Recipe convertToRecipe(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Extract lists with type safety
    final ingredients = _extractStringList(data['ingredients']);
    final steps = _extractStringList(data['steps']);
    final tags = _extractStringList(data['tags']);

    return Recipe(
      title: data['title'] ?? 'Untitled Recipe',
      description: data['description'] ?? '',
      ingredients: ingredients,
      steps: steps,
      servings: data['servings'] ?? 2,
      prepTimeMinutes: data['prepTimeMinutes'] ?? 10,
      cookTimeMinutes: data['cookTimeMinutes'] ?? 20,
      tags: tags,
    );
  }

  /// Helper to extract string lists from Firestore data
  List<String> _extractStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }

  /// Get all unique tags from all recipes
  Future<List<String>> getAllTags() async {
    if (!_firebase.isLoggedIn) return [];

    try {
      final snapshot = await _getRecipesCollection().get();

      final Set<String> tags = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final recipeTags = data['tags'] as List<dynamic>? ?? [];

        for (final tag in recipeTags) {
          tags.add(tag.toString());
        }
      }

      return tags.toList();
    } catch (e) {
      print('FirebaseRecipeService: Error getting tags: $e');
      return [];
    }
  }

  /// Search recipes by title, ingredients, or tags
  Future<List<DocumentSnapshot>> searchRecipes(String query) async {
    if (!_firebase.isLoggedIn) return [];

    try {
      final queryLower = query.toLowerCase();
      final snapshot = await _getRecipesCollection().get();

      // Filter results client-side
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final title = data['title']?.toString().toLowerCase() ?? '';
        final description = data['description']?.toString().toLowerCase() ?? '';
        final tags = _extractStringList(data['tags']);
        final ingredients = _extractStringList(data['ingredients']);

        // Check title and description
        if (title.contains(queryLower) || description.contains(queryLower)) {
          return true;
        }

        // Check tags
        for (final tag in tags) {
          if (tag.toLowerCase().contains(queryLower)) {
            return true;
          }
        }

        // Check ingredients
        for (final ingredient in ingredients) {
          if (ingredient.toLowerCase().contains(queryLower)) {
            return true;
          }
        }

        return false;
      }).toList();
    } catch (e) {
      print('FirebaseRecipeService: Error searching recipes: $e');
      return [];
    }
  }

  /// Share a recipe with another user
  Future<void> shareRecipe(String recipeId, String recipientEmail) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    try {
      // Get recipe data
      final docSnapshot = await _getRecipesCollection().doc(recipeId).get();
      if (!docSnapshot.exists) throw Exception('Recipe not found');

      final recipeData = docSnapshot.data() as Map<String, dynamic>? ?? {};

      // Create a shared recipe record
      await _firebase.firestore.collection('sharedRecipes').add({
        'sourceUserId': _firebase.uid,
        'recipientEmail': recipientEmail.toLowerCase(),
        'recipeData': recipeData,
        'recipeId': recipeId,
        'sharedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      print('FirebaseRecipeService: Error sharing recipe: $e');
      rethrow;
    }
  }

  /// Accept a shared recipe
  Future<void> acceptSharedRecipe(String sharedRecipeId) async {
    if (!_firebase.isLoggedIn) throw Exception('User not logged in');

    try {
      // Get shared recipe data
      final sharedRecipeDoc = await _firebase.firestore
          .collection('sharedRecipes')
          .doc(sharedRecipeId)
          .get();

      if (!sharedRecipeDoc.exists) throw Exception('Shared recipe not found');

      final sharedData = sharedRecipeDoc.data() as Map<String, dynamic>? ?? {};
      final recipeData = sharedData['recipeData'] as Map<String, dynamic>? ?? {};

      // Create a recipe ID
      final recipeTitle = recipeData['title'] ?? 'Shared Recipe';
      final recipeId = recipeTitle.trim().replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_').toLowerCase();

      // Save to user's recipes
      await _getRecipesCollection().doc(recipeId).set({
        ...recipeData,
        'sharedFrom': sharedData['sourceUserId'],
        'sharedAt': sharedData['sharedAt'],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Update status in shared recipes
      await _firebase.firestore
          .collection('sharedRecipes')
          .doc(sharedRecipeId)
          .update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('FirebaseRecipeService: Error accepting shared recipe: $e');
      rethrow;
    }
  }

  /// Get shared recipes for the current user
  Stream<QuerySnapshot> getSharedRecipes() {
    if (!_firebase.isLoggedIn) return Stream.value(null as QuerySnapshot);

    return _firebase.firestore
        .collection('sharedRecipes')
        .where('recipientEmail', isEqualTo: _firebase.auth.currentUser?.email?.toLowerCase())
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Get recipes with specific ingredients (for suggesting recipes based on expiring ingredients)
  Future<List<DocumentSnapshot>> getRecipesWithIngredients(List<String> ingredients) async {
    if (!_firebase.isLoggedIn) return [];

    try {
      final snapshot = await _getRecipesCollection().get();
      final normalizedIngredients = ingredients.map((i) => i.toLowerCase()).toList();

      // Client-side filtering for ingredient matching
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        final recipeIngredients = _extractStringList(data['ingredients']);
        final normalizedRecipeIngredients = recipeIngredients.map((i) => i.toLowerCase()).toList();

        // Check if any of the user's ingredients are used in this recipe
        for (final ingredient in normalizedIngredients) {
          for (final recipeIngredient in normalizedRecipeIngredients) {
            if (recipeIngredient.contains(ingredient) || ingredient.contains(recipeIngredient)) {
              return true;
            }
          }
        }

        return false;
      }).toList();
    } catch (e) {
      print('FirebaseRecipeService: Error getting recipes with ingredients: $e');
      return [];
    }
  }
}

// Global instance
final firebaseRecipeService = FirebaseRecipeService();