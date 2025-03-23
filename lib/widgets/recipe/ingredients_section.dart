// widgets/recipe/ingredients_section.dart
import 'package:flutter/material.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:provider/provider.dart';

class IngredientsSection extends StatelessWidget {
  final List<String> ingredients;
  final TextEditingController ingredientController;
  final Function(String) onAddIngredient;
  final Function(int) onRemoveIngredient;
  final bool isDisabled;

  const IngredientsSection({
    Key? key,
    required this.ingredients,
    required this.ingredientController,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: themeController.currentFont,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: ingredientController,
                decoration: InputDecoration(
                  labelText: 'Add an ingredient',
                  hintText: 'e.g. 2 cups flour',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: isDisabled ? null : () {
                      if (ingredientController.text.trim().isNotEmpty) {
                        onAddIngredient(ingredientController.text.trim());
                      }
                    },
                  ),
                ),
                onSubmitted: isDisabled ? null : (value) {
                  if (value.trim().isNotEmpty) {
                    onAddIngredient(value.trim());
                  }
                },
                enabled: !isDisabled,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        if (ingredients.isNotEmpty)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: ingredients.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
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
                  title: Text(
                    ingredients[index],
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                    onPressed: isDisabled ? null : () => onRemoveIngredient(index),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}