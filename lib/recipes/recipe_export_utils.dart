import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';

class RecipeExportUtils {
  // Method to show export options
  static void showExportOptions(BuildContext context, Recipe recipe) {
    // Simply share as text since the image option has been removed
    _shareAsText(recipe);
  }

  // Share as formatted text
  static Future<void> _shareAsText(Recipe recipe) async {
    final StringBuffer buffer = StringBuffer();

    // Add title and description
    buffer.writeln('🍽️ ${recipe.title.toUpperCase()} 🍽️');
    if (recipe.description.isNotEmpty) {
      buffer.writeln('\n${recipe.description}');
    }

    // Add prep & cook time
    buffer.writeln('\n⏱️ Prep: ${recipe.prepTimeFormatted}');
    buffer.writeln('⏱️ Cook: ${recipe.cookTimeFormatted}');
    buffer.writeln('👥 Servings: ${recipe.servings}');

    // Add tags
    if (recipe.tags.isNotEmpty) {
      buffer.write('\nTags: ');
      buffer.writeln(recipe.tags.map((tag) => '#$tag').join(' '));
    }

    // Add ingredients
    buffer.writeln('\n🛒 INGREDIENTS:');
    for (final ingredient in recipe.ingredients) {
      buffer.writeln('• $ingredient');
    }

    // Add steps
    buffer.writeln('\n📝 INSTRUCTIONS:');
    for (int i = 0; i < recipe.steps.length; i++) {
      buffer.writeln('${i + 1}. ${recipe.steps[i]}');
    }

    buffer.writeln('\nCreated with PantryPal app');

    // Share the text
    await Share.share(
      buffer.toString(),
      subject: 'Recipe: ${recipe.title}',
    );
  }
}