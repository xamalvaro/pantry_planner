import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/recipes/recipe_model.dart'; // Import your existing Recipe model

import 'matching/ingredient_matcher.dart';

/// A streamlined service for managing pantry items with expiry dates
/// and generating recipe suggestions based on expiring ingredients
class ExpiryService {
  // Singleton pattern
  static final ExpiryService _instance = ExpiryService._internal();
  factory ExpiryService() => _instance;
  ExpiryService._internal();

  // Dependencies
  final _uuid = Uuid();
  final _ingredientMatcher = IngredientMatcher();

  // Stream controller for updates
  final _expiryUpdatesController = StreamController<List<PantryItem>>.broadcast();
  Stream<List<PantryItem>> get expiryUpdates => _expiryUpdatesController.stream;

  // In-memory cache
  List<Recipe>? _recipesCache;
  List<PantryItem>? _pantryItemsCache;
  DateTime? _lastCacheTime;

  // Debug flag
  final bool _debug = true;

  /// Initialize the service
  Future<void> init() async {
    // Start expiry check timer
    _startExpiryCheckTimer();
    _log("ExpiryService initialized");
  }

  /// Generate a unique ID for new items
  String generateItemId() => _uuid.v4();

  /// Get all pantry items
  Future<List<PantryItem>> getAllItems() async {
    // Return cached items if fresh (last 30 seconds)
    final now = DateTime.now();
    if (_pantryItemsCache != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!).inSeconds < 30) {
      return List.from(_pantryItemsCache!);
    }

    // Otherwise load from storage
    try {
      final box = await Hive.openBox('pantryItems');
      final items = <PantryItem>[];

      _log("Processing ${box.keys.length} pantry items");

      // Process all items
      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          try {
            items.add(PantryItem.fromMap(data));
          } catch (e) {
            _log("Error loading pantry item: $e");
          }
        }
      }

      // Update cache
      _pantryItemsCache = items;
      _lastCacheTime = now;

      _log("Retrieved ${items.length} pantry items");
      return List.from(items);
    } catch (e) {
      _log("Error loading pantry items: $e");
      return [];
    }
  }

  /// Get items expiring soon
  Future<List<PantryItem>> getExpiringItems({int withinDays = 7}) async {
    final items = await getAllItems();
    final now = DateTime.now();
    final expiryThreshold = now.add(Duration(days: withinDays));

    _log("Looking for items expiring between ${_formatDate(now)} and ${_formatDate(expiryThreshold)}");

    final expiringItems = items.where((item) =>
    (item.expiryDate.isAfter(now) && item.expiryDate.isBefore(expiryThreshold)) ||
        _isSameDay(item.expiryDate, now) ||
        (item.expiryDate.isBefore(now) && now.difference(item.expiryDate).inDays <= 3)
    ).toList();

    _log("Found ${expiringItems.length} expiring items");
    return expiringItems;
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
    try {
      final box = await Hive.openBox('pantryItems');
      await box.put(item.id, item.toMap());
      _log("Added pantry item: ${item.name}");

      // Clear cache
      _invalidateCache();

      // Notify listeners
      _expiryUpdatesController.add(await getAllItems());
    } catch (e) {
      _log("Error adding item: $e");
    }
  }

  /// Update an existing pantry item
  Future<void> updateItem(PantryItem item) async {
    try {
      final box = await Hive.openBox('pantryItems');
      await box.put(item.id, item.toMap());
      _log("Updated pantry item: ${item.name}");

      // Clear cache
      _invalidateCache();

      // Notify listeners
      _expiryUpdatesController.add(await getAllItems());
    } catch (e) {
      _log("Error updating item: $e");
    }
  }

  /// Delete a pantry item
  Future<void> deleteItem(String itemId) async {
    try {
      final box = await Hive.openBox('pantryItems');
      await box.delete(itemId);
      _log("Deleted pantry item ID: $itemId");

      // Clear cache
      _invalidateCache();

      // Notify listeners
      _expiryUpdatesController.add(await getAllItems());
    } catch (e) {
      _log("Error deleting item: $e");
    }
  }

  /// Get all recipes
  Future<List<Recipe>> getAllRecipes() async {
    // Return cached recipes if available
    if (_recipesCache != null) {
      return List.from(_recipesCache!);
    }

    // Otherwise load from storage
    try {
      final box = await Hive.openBox('recipes');
      final recipes = <Recipe>[];

      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          try {
            recipes.add(Recipe.fromMap(data));
          } catch (e) {
            _log("Error loading recipe: $e");
          }
        }
      }

      // Update cache
      _recipesCache = recipes;

      _log("Loaded ${recipes.length} recipes");
      return List.from(recipes);
    } catch (e) {
      _log("Error loading recipes: $e");
      return [];
    }
  }

  /// Generate recipe suggestions based on expiring items
  Future<List<RecipeSuggestion>> getRecipeSuggestions() async {
    final expiringItems = await getExpiringItems(withinDays: 14);

    if (expiringItems.isEmpty) {
      _log("No expiring items found");
      return [];
    }

    final recipes = await getAllRecipes();

    if (recipes.isEmpty) {
      _log("No recipes available - creating fallback suggestions");
      return _ingredientMatcher.createFallbackSuggestions(expiringItems);
    }

    // Match recipes with expiring items
    final suggestions = _ingredientMatcher.matchIngredientsToRecipes(recipes, expiringItems);

    if (suggestions.isNotEmpty) {
      _log("Generated ${suggestions.length} recipe suggestions");
      return suggestions;
    }

    // If no matches found, generate fallback suggestions
    _log("No matches found - creating fallback suggestions");
    return _ingredientMatcher.createFallbackSuggestions(expiringItems);
  }

  /// Force refresh recipe suggestions
  Future<List<RecipeSuggestion>> forceRefreshSuggestions() async {
    _log("Force refreshing recipe suggestions");

    // Clear recipe cache to ensure fresh data
    _recipesCache = null;

    // Get expiring items
    final expiringItems = await getExpiringItems(withinDays: 14);

    // Log expiring items for debugging
    for (final item in expiringItems) {
      _log("- Expiring Item: ${item.name} (${item.daysRemaining} days remaining)");
    }

    // Get recipes
    final recipes = await getAllRecipes();

    // Log recipes for debugging
    for (final recipe in recipes) {
      _log("- Recipe: ${recipe.title}");
      _log("  Ingredients: ${recipe.ingredients.join(', ')}");
    }

    // If no recipes, generate fallback suggestions
    if (recipes.isEmpty) {
      _log("No recipes available - creating fallback suggestions");
      return _ingredientMatcher.createFallbackSuggestions(expiringItems);
    }

    // If no expiring items, return empty list
    if (expiringItems.isEmpty) {
      _log("No expiring items found");
      return [];
    }

    // Match recipes with expiring items
    final suggestions = _ingredientMatcher.matchIngredientsToRecipes(recipes, expiringItems);

    // Log suggestions for debugging
    for (final suggestion in suggestions) {
      _log("- Suggestion: ${suggestion.recipeTitle} uses: ${suggestion.usedExpiringItems.join(", ")}");
    }

    if (suggestions.isNotEmpty) {
      return suggestions;
    }

    // If no matches found, generate fallback suggestions
    _log("No matches found - creating fallback suggestions");
    return _ingredientMatcher.createFallbackSuggestions(expiringItems);
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
        _log("No items to show alerts for");
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

      _log("Displaying alert message: $message");

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
      _log("Error showing expiry info: $e");
    }
  }

  /// Start a timer to check for expiring items
  void _startExpiryCheckTimer() {
    // Check once a day
    Timer.periodic(Duration(hours: 24), (timer) => checkExpiringItems());

    // Also check immediately
    checkExpiringItems();
  }

  /// Clear cache
  void _invalidateCache() {
    _pantryItemsCache = null;
    _lastCacheTime = null;
  }

  /// Helper to format dates for logging
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Helper to check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Debug logging
  void _log(String message) {
    if (_debug) {
      print("🥫 ExpiryService: $message");
    }
  }

  /// Dispose resources
  void dispose() {
    _expiryUpdatesController.close();
    _invalidateCache();
    _recipesCache = null;
  }
}