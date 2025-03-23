import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';
import 'package:pantry_pal/recipes/view_recipe_page.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';

/// Show a bottom sheet with recipe suggestions
void showSuggestionsBottomSheet(
    BuildContext context,
    List<RecipeSuggestion> suggestions
    ) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      final themeController = Provider.of<ThemeController>(context);
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;

      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          color: Colors.blueAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Recipe Suggestions',
                          style: TextStyle(
                            fontFamily: themeController.currentFont,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Number of suggestions
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${suggestions.length}',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Based on your expiring ingredients',
                  style: TextStyle(
                    fontFamily: themeController.currentFont,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),

              Divider(height: 24),

              // List of suggestions
              Expanded(
                child: suggestions.isEmpty
                    ? Center(
                  child: Text(
                    'No recipe suggestions available',
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                )
                    : ListView.builder(
                  controller: scrollController,
                  itemCount: suggestions.length,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final suggestion = suggestions[index];

                    return Card(
                      key: ValueKey(suggestion.recipeTitle),
                      margin: EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          // Navigate to the recipe view
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewRecipePage(recipeTitle: suggestion.recipeTitle),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                suggestion.recipeTitle,
                                style: TextStyle(
                                  fontFamily: themeController.currentFont,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),

                              // Only show ingredients if there are any
                              if (suggestion.usedExpiringItems.isNotEmpty) ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.shopping_basket,
                                      size: 16,
                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                    SizedBox(width: 4),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Uses expiring items:',
                                            style: TextStyle(
                                              fontFamily: themeController.currentFont,
                                              fontWeight: FontWeight.w500,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            children: suggestion.usedExpiringItems.map((item) =>
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueAccent.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    item,
                                                    style: TextStyle(
                                                      fontFamily: themeController.currentFont,
                                                      fontSize: 12,
                                                      color: Colors.blueAccent,
                                                    ),
                                                  ),
                                                )
                                            ).toList(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}