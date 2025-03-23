import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:uuid/uuid.dart';

class ExpiryService {
  // Singleton instance
  static final ExpiryService _instance = ExpiryService._internal();
  factory ExpiryService() => _instance;
  ExpiryService._internal();

  // UUID generator for item IDs
  final uuid = Uuid();

  // Streams for updates
  final _expiryUpdatesController = StreamController<List<PantryItem>>.broadcast();
  Stream<List<PantryItem>> get expiryUpdates => _expiryUpdatesController.stream;

  // Initialize the service
  Future<void> init() async {
    // Initialize expiry check timer
    _startExpiryCheckTimer();
  }

  // Start a timer to check for expiring items
  void _startExpiryCheckTimer() {
    // Check once a day
    Timer.periodic(Duration(hours: 24), (timer) => checkExpiringItems());

    // Also check immediately
    checkExpiringItems();
  }

  // Get all pantry items
  Future<List<PantryItem>> getAllItems() async {
    final box = await Hive.openBox('pantryItems');
    final List<PantryItem> items = [];

    for (final key in box.keys) {
      final itemData = box.get(key);
      if (itemData != null) {
        try {
          items.add(PantryItem.fromMap(itemData));
        } catch (e) {
          print('Error loading pantry item: $e');
        }
      }
    }

    return items;
  }

  // Get items expiring soon (within days)
  Future<List<PantryItem>> getExpiringItems({int withinDays = 7}) async {
    final items = await getAllItems();
    final now = DateTime.now();
    final expiryThreshold = now.add(Duration(days: withinDays));

    return items.where((item) =>
    item.expiryDate.isBefore(expiryThreshold) &&
        item.expiryDate.isAfter(now)
    ).toList();
  }

  // Get expired items
  Future<List<PantryItem>> getExpiredItems() async {
    final items = await getAllItems();
    final now = DateTime.now();

    return items.where((item) => item.expiryDate.isBefore(now)).toList();
  }

  // Check for expiring items (without notifications for now)
  Future<void> checkExpiringItems() async {
    // Update stream with latest expiry data
    _expiryUpdatesController.add(await getAllItems());
  }

  // Add a new pantry item
  Future<void> addItem(PantryItem item) async {
    final box = await Hive.openBox('pantryItems');
    await box.put(item.id, item.toMap());
    _expiryUpdatesController.add(await getAllItems());
  }

  // Update an existing pantry item
  Future<void> updateItem(PantryItem item) async {
    final box = await Hive.openBox('pantryItems');
    await box.put(item.id, item.toMap());
    _expiryUpdatesController.add(await getAllItems());
  }

  // Delete a pantry item
  Future<void> deleteItem(String itemId) async {
    final box = await Hive.openBox('pantryItems');
    await box.delete(itemId);
    _expiryUpdatesController.add(await getAllItems());
  }

  // Generate a unique ID for new items
  String generateItemId() {
    return uuid.v4();
  }

  // Get recipe suggestions for expiring items
  Future<List<RecipeSuggestion>> getRecipeSuggestions() async {
    final expiringItems = await getExpiringItems();
    if (expiringItems.isEmpty) return [];

    // Get all recipes
    final box = await Hive.openBox('recipes');
    final List<Recipe> recipes = [];

    for (final key in box.keys) {
      final recipeData = box.get(key);
      if (recipeData != null) {
        try {
          recipes.add(Recipe.fromMap(recipeData));
        } catch (e) {
          print('Error loading recipe: $e');
        }
      }
    }

    // Match recipes with expiring items
    final List<RecipeSuggestion> suggestions = [];

    for (final recipe in recipes) {
      final matchedItems = <String>[];
      final Map<String, double> matchScores = {};

      // Check each expiring item if it's used in the recipe
      for (final item in expiringItems) {
        final itemName = item.name.toLowerCase();
        final itemNameWords = itemName.split(' ');

        // Check each ingredient for matches
        for (final ingredient in recipe.ingredients) {
          final ingredientLower = ingredient.toLowerCase();
          double matchScore = 0.0;

          // Check for exact match (highest priority)
          if (ingredientLower.contains(itemName)) {
            matchScore = 1.0;
          }
          // Check for partial word matches
          else {
            for (final word in itemNameWords) {
              // Skip very short words (like "of", "a", etc)
              if (word.length < 3) continue;

              if (ingredientLower.contains(word)) {
                matchScore += 0.5 / itemNameWords.length;
              }
            }
          }

          // For common food types, check for related terms
          matchScore += _checkFoodTypeMatches(itemName, ingredientLower);

          // Store the highest match score for this item
          if (matchScore > 0 && (!matchScores.containsKey(item.name) || matchScore > matchScores[item.name]!)) {
            matchScores[item.name] = matchScore;
          }
        }
      }

      // Add items with a match score above the threshold
      for (final entry in matchScores.entries) {
        if (entry.value >= 0.3) { // Threshold for considering a match valid
          matchedItems.add(entry.key);
        }
      }

      // If we found any matches, add this recipe as a suggestion
      if (matchedItems.isNotEmpty) {
        suggestions.add(RecipeSuggestion(
          recipeTitle: recipe.title,
          usedExpiringItems: matchedItems,
        ));
      }
    }

    // Sort by number of expiring items used (most first)
    suggestions.sort((a, b) => b.usedExpiringItems.length.compareTo(a.usedExpiringItems.length));

    return suggestions;
  }

  // Helper method to check for related food type matches
  double _checkFoodTypeMatches(String itemName, String ingredient) {
    // Map of common food items and their related terms
    final Map<String, List<String>> relatedTerms = {
      'chicken': ['poultry', 'breast', 'thigh', 'drumstick', 'wing', 'tender'],
      'beef': ['steak', 'ground', 'chuck', 'sirloin', 'brisket', 'meat'],
      'pork': ['meat', 'chop', 'tenderloin', 'shoulder', 'bacon', 'ham'],
      'fish': ['salmon', 'tuna', 'cod', 'tilapia', 'fillet', 'seafood'],
      'milk': ['dairy', 'cream', 'whole milk', 'skim milk'],
      'cheese': ['cheddar', 'mozzarella', 'parmesan', 'dairy'],
      'egg': ['eggs', 'yolk', 'white'],
      'pasta': ['spaghetti', 'noodle', 'macaroni', 'penne', 'fettuccine'],
      'tomato': ['sauce', 'paste', 'diced', 'crushed'],
      'onion': ['yellow onion', 'red onion', 'white onion', 'scallion', 'shallot'],
      'garlic': ['clove', 'minced'],
      'potato': ['russet', 'yukon', 'sweet potato', 'spud'],
      'rice': ['grain', 'white rice', 'brown rice', 'jasmine', 'basmati'],
    };

    double score = 0.0;

    // Check for matches in our related terms dictionary
    for (final entry in relatedTerms.entries) {
      final baseFood = entry.key;
      final relatedWords = entry.value;

      // If the item is this food type
      if (itemName.contains(baseFood)) {
        // If the ingredient directly mentions this food
        if (ingredient.contains(baseFood)) {
          score += 0.8;
        }
        // Or if the ingredient contains any related terms
        else {
          for (final term in relatedWords) {
            if (ingredient.contains(term)) {
              score += 0.6;
              break;
            }
          }
        }
      }
      // If the ingredient mentions this food type but the item doesn't (weaker match)
      else if (ingredient.contains(baseFood)) {
        // Check if the item contains any related terms
        for (final term in relatedWords) {
          if (itemName.contains(term)) {
            score += 0.4;
            break;
          }
        }
      }
    }

    return score > 1.0 ? 1.0 : score; // Cap at 1.0
  }

  // Show expiry information in a SnackBar (instead of notifications)
  void showExpiryInfo(BuildContext context) async {
    final criticalItems = await getExpiringItems(withinDays: 3);
    final expiredItems = await getExpiredItems();

    // Don't show anything if no items are expiring soon or expired
    if (criticalItems.isEmpty && expiredItems.isEmpty) return;

    String message;
    Color backgroundColor;

    if (expiredItems.isNotEmpty) {
      message = '${expiredItems.length} item${expiredItems.length > 1 ? "s have" : " has"} expired';
      backgroundColor = Colors.red;
    } else {
      message = '${criticalItems.length} item${criticalItems.length > 1 ? "s are" : " is"} expiring soon';
      backgroundColor = Colors.orange;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to calendar page or directly to a list of expiring items
            Navigator.pushNamed(context, '/calendar');
          },
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  // Dispose of resources
  void dispose() {
    _expiryUpdatesController.close();
  }
}