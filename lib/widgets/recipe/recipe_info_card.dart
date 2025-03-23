// widgets/recipe/recipe_info_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class RecipeInfoCard extends StatelessWidget {
  final String prepTimeFormatted;
  final String cookTimeFormatted;
  final int servings;

  const RecipeInfoCard({
    Key? key,
    required this.prepTimeFormatted,
    required this.cookTimeFormatted,
    required this.servings,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Prep Time
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Prep Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    prepTimeFormatted,
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            VerticalDivider(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              thickness: 1,
              width: 32,
            ),

            // Cook Time
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.microwave,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cook Time',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    cookTimeFormatted,
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                ],
              ),
            ),

            // Divider
            VerticalDivider(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
              thickness: 1,
              width: 32,
            ),

            // Servings
            Expanded(
              child: Column(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Servings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$servings',
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}