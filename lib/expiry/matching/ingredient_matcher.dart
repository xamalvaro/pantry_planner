import '../expiry_model.dart';
import 'package:pantry_pal/recipes/recipe_model.dart'; // Import your existing Recipe model


/// A simple and efficient class to match pantry items with recipe ingredients
class IngredientMatcher {
  /// Match pantry items to recipes and generate recipe suggestions
  List<RecipeSuggestion> matchIngredientsToRecipes(
      List<Recipe> recipes, List<PantryItem> pantryItems) {
    // Create a list to store our suggestions
    final suggestions = <RecipeSuggestion>[];

    // Create a map of pantry item names to make lookups faster
    final normalizedPantryItems = {
      for (var item in pantryItems)
        _normalizeText(item.name): item.name
    };

    // Process each recipe
    for (final recipe in recipes) {
      final matchedItems = <String>{};

      // Check each ingredient against all pantry items
      for (final ingredient in recipe.ingredients) {
        final normalizedIngredient = _normalizeText(ingredient);

        // Find matching pantry items for this ingredient
        for (final entry in normalizedPantryItems.entries) {
          final normalizedItemName = entry.key;
          final originalItemName = entry.value;

          if (_isIngredientMatch(normalizedItemName, normalizedIngredient)) {
            matchedItems.add(originalItemName);
          }
        }
      }

      // If we found matches, create a suggestion
      if (matchedItems.isNotEmpty) {
        suggestions.add(RecipeSuggestion(
          recipeTitle: recipe.title,
          usedExpiringItems: matchedItems.toList(),
        ));
      }
    }

    // Sort by number of matching ingredients (most first)
    suggestions.sort((a, b) =>
        b.usedExpiringItems.length.compareTo(a.usedExpiringItems.length));

    return suggestions;
  }

  /// Check if a pantry item matches an ingredient
  bool _isIngredientMatch(String normalizedItemName, String normalizedIngredient) {
    // Direct containment match
    if (normalizedIngredient.contains(normalizedItemName) ||
        normalizedItemName.contains(normalizedIngredient)) {
      return true;
    }

    // Check for word overlap
    if (_haveSignificantWordOverlap(normalizedItemName, normalizedIngredient)) {
      return true;
    }

    return false;
  }

  /// Normalize text for comparison by converting to lowercase,
  /// removing punctuation, and normalizing whitespace
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' ')    // Normalize whitespace
        .trim();
  }

  /// Check if two texts share significant words
  bool _haveSignificantWordOverlap(String text1, String text2) {
    // Extract significant words (longer than 3 chars)
    final words1 = text1
        .split(' ')
        .where((w) => w.length > 3)
        .toSet();

    final words2 = text2
        .split(' ')
        .where((w) => w.length > 3)
        .toSet();

    // Check for intersection
    return words1.intersection(words2).isNotEmpty;
  }

  /// Create fallback suggestions when no recipes are available
  List<RecipeSuggestion> createFallbackSuggestions(List<PantryItem> pantryItems) {
    if (pantryItems.isEmpty) {
      return [];
    }

    final suggestions = <RecipeSuggestion>[];

    // Group items into common recipe categories
    final itemsByCategory = <String, List<String>>{};

    for (final item in pantryItems) {
      final name = item.name.toLowerCase();
      String category;

      // Categorize by common food types
      if (name.contains('chicken') || name.contains('meat') ||
          name.contains('beef') || name.contains('pork')) {
        category = 'Protein';
      } else if (name.contains('pasta') || name.contains('rice') ||
          name.contains('grain') || name.contains('bread')) {
        category = 'Carbs';
      } else if (name.contains('veggie') || name.contains('vegetable') ||
          name.contains('tomato') || name.contains('carrot') ||
          name.contains('onion') || name.contains('potato')) {
        category = 'Vegetables';
      } else {
        category = 'Other';
      }

      // Add to the appropriate category
      if (!itemsByCategory.containsKey(category)) {
        itemsByCategory[category] = [];
      }
      itemsByCategory[category]!.add(item.name);
    }

    // Create combination recipes for main categories
    if (itemsByCategory.containsKey('Protein') &&
        (itemsByCategory.containsKey('Carbs') || itemsByCategory.containsKey('Vegetables'))) {

      final usedItems = <String>[];
      usedItems.addAll(itemsByCategory['Protein']!);

      if (itemsByCategory.containsKey('Carbs')) {
        usedItems.addAll(itemsByCategory['Carbs']!.take(1));
      }

      if (itemsByCategory.containsKey('Vegetables')) {
        usedItems.addAll(itemsByCategory['Vegetables']!.take(2));
      }

      // Create a main dish suggestion
      final mainIngredient = itemsByCategory['Protein']!.first;
      suggestions.add(RecipeSuggestion(
        recipeTitle: "$mainIngredient Recipe",
        usedExpiringItems: usedItems,
      ));
    }

    // Create individual suggestions for remaining items
    for (final category in itemsByCategory.keys) {
      if (category == 'Protein' && suggestions.isNotEmpty) {
        continue; // Skip protein items already used
      }

      for (final item in itemsByCategory[category]!) {
        // Check if already used in a combination recipe
        if (suggestions.any((s) => s.usedExpiringItems.contains(item))) {
          continue;
        }

        suggestions.add(RecipeSuggestion(
          recipeTitle: "$item Recipe",
          usedExpiringItems: [item],
        ));
      }
    }

    return suggestions;
  }
}