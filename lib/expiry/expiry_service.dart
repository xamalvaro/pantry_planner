import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/firebase_expiry_service.dart';
import 'package:pantry_pal/expiry/item_details_page.dart';
import 'package:intl/intl.dart';

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
    // Reduced cache time to 5 seconds for better responsiveness
    final now = DateTime.now();
    if (_pantryItemsCache != null &&
        _lastCacheTime != null &&
        now.difference(_lastCacheTime!).inSeconds < 5) {
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
            // Create the item
            var item = PantryItem.fromMap(data);

            // If the item's ID doesn't match the key, use the key as the ID
            if (item.id != key.toString()) {
              item = item.copyWith(id: key.toString());

              // Update the stored data with the correct ID
              final updatedData = item.toMap();
              await box.put(key, updatedData);
            }

            items.add(item);
          } catch (e) {
            _log("Error loading pantry item: $e");
          }
        }
      }

      // Update cache
      _pantryItemsCache = items;
      _lastCacheTime = DateTime.now();

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

  /// Add a new item with cache invalidation
  Future<void> addItem(PantryItem item) async {
    try {
      // Ensure the item has a valid ID
      if (item.id.isEmpty) {
        throw Exception('Item ID cannot be empty');
      }

      final box = await Hive.openBox('pantryItems');
      await box.put(item.id, item.toMap());

      // Invalidate cache after adding item
      _invalidateCache();

      // Update stream with fresh data
      _expiryUpdatesController.add(await getAllItems());

      // Sync to Firestore if the user is logged in
      if (firebaseService.isLoggedIn) {
        try {
          await firebaseExpiryService.addItem(item);
        } catch (e) {
          print('Error syncing item to Firestore: $e');
        }
      }
    } catch (e) {
      print('Error adding item: $e');
      rethrow;
    }
  }

  /// Update an item with cache invalidation
  Future<void> updateItem(PantryItem item) async {
    try {
      final box = await Hive.openBox('pantryItems');
      await box.put(item.id, item.toMap());

      // Invalidate cache after updating item
      _invalidateCache();

      // Update stream with fresh data
      _expiryUpdatesController.add(await getAllItems());

      // Sync to Firestore if the user is logged in
      if (firebaseService.isLoggedIn) {
        try {
          await firebaseExpiryService.updateItem(item);
        } catch (e) {
          print('Error syncing item update to Firestore: $e');
        }
      }
    } catch (e) {
      print('Error updating item: $e');
      rethrow;
    }
  }

  /// Delete an item with cache invalidation
  Future<void> deleteItem(String itemId) async {
    try {
      print('Deleting item with ID: $itemId');

      final box = await Hive.openBox('pantryItems');

      // Check if the item exists before deleting
      if (box.containsKey(itemId)) {
        await box.delete(itemId);
        print('Item deleted from Hive');
      } else {
        print('Item not found in Hive with ID: $itemId');
      }

      // Force clear cache immediately
      _pantryItemsCache = null;
      _lastCacheTime = null;

      // Get fresh data (this will reload from storage)
      final updatedItems = await getAllItems();

      // Update stream with fresh data
      _expiryUpdatesController.add(updatedItems);

      print('Updated items count after deletion: ${updatedItems.length}');

      // Sync to Firestore if the user is logged in
      if (firebaseService.isLoggedIn) {
        try {
          await firebaseExpiryService.deleteItem(itemId);
          print('Item deleted from Firestore');
        } catch (e) {
          print('Error syncing item deletion to Firestore: $e');
        }
      }
    } catch (e) {
      print('Error deleting item: $e');
      rethrow;
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

    // Clear both caches to ensure fresh data
    _recipesCache = null;
    _invalidateCache();

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
                // Use a post-frame callback to ensure the context is valid
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Check if the context is still mounted before showing dialog
                  if (context.mounted) {
                    _showExpiryDialog(context, criticalItems, expiredItems);
                  }
                });
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

// Add this as a separate method
  void _showExpiryDialog(BuildContext context, List<PantryItem> criticalItems, List<PantryItem> expiredItems) {
    if (!context.mounted) return;

    final itemsToShow = expiredItems.isNotEmpty ? expiredItems : criticalItems;
    final isExpired = expiredItems.isNotEmpty;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isExpired
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isExpired ? Icons.error_outline : Icons.access_time,
                        color: isExpired ? Colors.red : Colors.orange,
                        size: 30,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExpired ? 'Expired Items' : 'Expiring Soon',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${itemsToShow.length} item${itemsToShow.length > 1 ? "s" : ""} need attention',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Items list with better styling
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: itemsToShow.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = itemsToShow[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey[800]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item.statusColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.pop(dialogContext);
                              // Use navigator from the root context
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsPage(item: item),
                                ),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Item icon/category
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: item.statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(item.category),
                                      color: item.statusColor,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),

                                  // Item details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${item.category} • ${item.location}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Expires: ${DateFormat('MMM d, yyyy').format(item.expiryDate)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: item.statusColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Days badge
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: item.statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: item.statusColor.withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          item.daysRemaining >= 0
                                              ? '${item.daysRemaining}'
                                              : '${-item.daysRemaining}',
                                          style: TextStyle(
                                            color: item.statusColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          item.daysRemaining >= 0 ? 'days' : 'ago',
                                          style: TextStyle(
                                            color: item.statusColor,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Action buttons with better styling
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        foregroundColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method to get category icons
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Icons.egg;
      case 'produce':
        return Icons.grass;
      case 'meat':
        return Icons.restaurant;
      case 'seafood':
        return Icons.set_meal;
      case 'bakery':
        return Icons.bakery_dining;
      case 'grains':
        return Icons.grain;
      case 'canned goods':
        return Icons.kitchen;
      case 'frozen':
        return Icons.ac_unit;
      case 'spices':
        return Icons.local_fire_department;
      case 'snacks':
        return Icons.cookie;
      case 'beverages':
        return Icons.local_drink;
      case 'condiments':
        return Icons.water_drop;
      default:
        return Icons.inventory_2;
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