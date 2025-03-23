import 'package:flutter/material.dart';
import 'package:pantry_pal/create_list_page.dart';
import 'package:pantry_pal/recipes/create_recipe_page.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class CreatePageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // AppBar-like header
        Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            right: 16,
            bottom: 16,
          ),
          color: Theme.of(context).appBarTheme.backgroundColor,
          child: Row(
            children: [
              Text(
                'Create New',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: themeController.currentFont,
                  color: Theme.of(context).appBarTheme.foregroundColor,
                ),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What would you like to create?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                SizedBox(height: 40),
                // List Option
                _buildCreateOption(
                  context: context,
                  icon: Icons.shopping_basket,
                  title: 'Shopping List',
                  description: 'Create a new grocery or shopping list organized by categories.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateListPage()),
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
                SizedBox(height: 24),
                // Recipe Option
                _buildCreateOption(
                  context: context,
                  icon: Icons.restaurant_menu,
                  title: 'Recipe',
                  description: 'Add a new recipe with ingredients, instructions, and cooking time.',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreateRecipePage()),
                    );
                  },
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    final themeController = Provider.of<ThemeController>(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey.shade800
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.grey.shade700
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.blueAccent.withOpacity(0.2)
                    : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: Colors.blueAccent,
              ),
            ),
            SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }
}