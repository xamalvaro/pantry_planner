// widgets/recipe/recipe_display.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';
import 'package:pantry_pal/widgets/recipe/recipe_info_card.dart';

class RecipeDisplay extends StatelessWidget {
  final Recipe recipe;
  final bool isDisabled;
  final VoidCallback onCreateShoppingList;
  final bool isCreatingShoppingList;

  const RecipeDisplay({
    Key? key,
    required this.recipe,
    this.isDisabled = false,
    required this.onCreateShoppingList,
    required this.isCreatingShoppingList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        physics: isDisabled ? NeverScrollableScrollPhysics() : null,
        children: [
          // Title
          Text(
            recipe.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: themeController.currentFont,
            ),
          ),
          SizedBox(height: 16),

          // Description
          if (recipe.description.isNotEmpty) ...[
            Text(
              recipe.description,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontFamily: themeController.currentFont,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 16),
          ],

          // Recipe Info Cards
          RecipeInfoCard(
            prepTimeFormatted: recipe.prepTimeFormatted,
            cookTimeFormatted: recipe.cookTimeFormatted,
            servings: recipe.servings,
          ),
          SizedBox(height: 24),

          // Tags Section
          if (recipe.tags.isNotEmpty) ...[
            Text(
              'Tags',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: themeController.currentFont,
              ),
            ),
            SizedBox(height: 8),
            _buildTagsSection(themeController, isDarkMode),
            SizedBox(height: 24),
          ],

          // Ingredients Section
          Text(
            'Ingredients',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: themeController.currentFont,
            ),
          ),
          SizedBox(height: 8),
          _buildIngredientsSection(themeController),
          SizedBox(height: 24),

          // Instructions Section
          Text(
            'Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: themeController.currentFont,
            ),
          ),
          SizedBox(height: 8),
          _buildInstructionsSection(themeController),
          SizedBox(height: 40),

          // Create Shopping List Button
          Center(
            child: ElevatedButton.icon(
              onPressed: isDisabled ? null : onCreateShoppingList,
              icon: isCreatingShoppingList
                  ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Icon(Icons.shopping_basket),
              label: Text(
                isCreatingShoppingList ? 'Creating list...' : 'Create Shopping List from Recipe',
                style: TextStyle(
                  fontFamily: themeController.currentFont,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.blueAccent.withOpacity(0.6),
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  // Build tags section widget
  Widget _buildTagsSection(ThemeController themeController, bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recipe.tags.map((tag) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.blueAccent.withOpacity(0.2)
                : Colors.blue.shade50,
            border: Border.all(
              color: isDarkMode
                  ? Colors.blueAccent.withOpacity(0.5)
                  : Colors.blue.shade200,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontFamily: themeController.currentFont,
              color: isDarkMode ? Colors.white : Colors.blue.shade900,
            ),
          ),
        );
      }).toList(),
    );
  }

  // Build ingredients section widget
  Widget _buildIngredientsSection(ThemeController themeController) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: recipe.ingredients.map((ingredient) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      ingredient,
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Build instructions section widget
  Widget _buildInstructionsSection(ThemeController themeController) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: recipe.steps.length,
          itemBuilder: (context, index) {
            final step = recipe.steps[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    radius: 12,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}