// utils/recipe_utils.dart
import 'package:flutter/foundation.dart';

/// Utility functions for recipe management
class RecipeUtils {
  /// Creates a recipe map from recipe data for Hive storage
  static Map<String, dynamic> createRecipeMap(Map<String, dynamic> params) {
    return {
      'title': params['title'],
      'description': params['description'],
      'ingredients': params['ingredients'],
      'steps': params['steps'],
      'servings': params['servings'],
      'prepTimeMinutes': params['prepTimeMinutes'],
      'cookTimeMinutes': params['cookTimeMinutes'],
      'tags': params['tags'],
    };
  }

  /// Process recipe data in a separate isolate to avoid UI jank
  static Future<Map<String, dynamic>> processRecipeDataAsync({
    required String title,
    required String description,
    required List<String> ingredients,
    required List<String> steps,
    required int servings,
    required int prepTimeMinutes,
    required int cookTimeMinutes,
    required List<String> tags,
  }) async {
    return compute(createRecipeMap, {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'servings': servings,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'tags': tags,
    });
  }
}