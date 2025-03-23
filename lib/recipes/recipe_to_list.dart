import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';

class RecipeToListConverter extends StatefulWidget {
  final Recipe recipe;

  RecipeToListConverter({required this.recipe});

  @override
  _RecipeToListConverterState createState() => _RecipeToListConverterState();
}

class _RecipeToListConverterState extends State<RecipeToListConverter> {
  // Controller for list name field
  final TextEditingController _listNameController = TextEditingController();

  // Track which ingredients to include
  late List<bool> _selectedIngredients;

  // Map ingredients to their categories
  Map<String, List<Map<String, dynamic>>> _categorizedIngredients = {
    'Fruits': [],
    'Vegetables': [],
    'Grains': [],
    'Protein': [],
    'Dairy': [],
    'Other': []
  };

  // Categories for ingredients
  final Map<String, List<String>> _categoryKeywords = {
    'Fruits': [
      'apple', 'orange', 'banana', 'berries', 'strawberry', 'blueberry', 'raspberry',
      'grape', 'melon', 'watermelon', 'kiwi', 'peach', 'pear', 'plum', 'cherry', 'lemon',
      'lime', 'pineapple', 'mango', 'fruit'
    ],
    'Vegetables': [
      'onion', 'garlic', 'carrot', 'potato', 'tomato', 'pepper', 'lettuce', 'spinach',
      'kale', 'cabbage', 'broccoli', 'celery', 'cucumber', 'zucchini', 'eggplant',
      'mushroom', 'asparagus', 'corn', 'peas', 'bean', 'vegetable'
    ],
    'Grains': [
      'flour', 'rice', 'pasta', 'noodle', 'bread', 'oat', 'cereal', 'grain', 'wheat',
      'barley', 'cornmeal', 'quinoa', 'couscous', 'tortilla', 'pancake', 'baking'
    ],
    'Protein': [
      'chicken', 'beef', 'pork', 'turkey', 'fish', 'shrimp', 'tofu', 'legume',
      'sausage', 'bacon', 'ham', 'meat', 'steak', 'protein', 'nut', 'seed', 'lentil'
    ],
    'Dairy': [
      'milk', 'cheese', 'yogurt', 'cream', 'butter', 'egg', 'dairy'
    ]
  };

  @override
  void initState() {
    super.initState();

    // Initialize list name with recipe title
    _listNameController.text = "${widget.recipe.title} Shopping List";

    // Initialize all ingredients as selected
    _selectedIngredients = List.generate(
        widget.recipe.ingredients.length,
            (_) => true
    );

    // Categorize ingredients
    _categorizeIngredients();
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  // Categorize ingredients based on keywords
  void _categorizeIngredients() {
    // Reset categorized ingredients
    for (var category in _categorizedIngredients.keys) {
      _categorizedIngredients[category] = [];
    }

    // Go through each ingredient
    for (int i = 0; i < widget.recipe.ingredients.length; i++) {
      final ingredient = widget.recipe.ingredients[i];
      bool categorized = false;

      // Process the ingredient text to extract quantity and name
      Map<String, dynamic> processedIngredient = _processIngredientText(ingredient);

      // Check if the ingredient matches any category keywords
      for (var category in _categoryKeywords.keys) {
        for (var keyword in _categoryKeywords[category]!) {
          if (processedIngredient['name'].toLowerCase().contains(keyword.toLowerCase())) {
            _categorizedIngredients[category]!.add({
              'index': i,
              'name': processedIngredient['name'],
              'quantity': processedIngredient['quantity']
            });
            categorized = true;
            break;
          }
        }
        if (categorized) break;
      }

      // If no category matched, put in 'Other'
      if (!categorized) {
        _categorizedIngredients['Other']!.add({
          'index': i,
          'name': processedIngredient['name'],
          'quantity': processedIngredient['quantity']
        });
      }
    }
  }

  // Process ingredient text to extract quantity and name
  Map<String, dynamic> _processIngredientText(String ingredient) {
    // Common patterns for quantities in recipes
    final quantityPatterns = [
      RegExp(r'^\s*(\d+[\./]?\d*)\s*(cup|cups|tbsp|tsp|tablespoon|teaspoon|oz|ounce|pound|lb|g|gram|ml|liter|L|pinch|handful|clove|cloves|slice|slices|piece|pieces)\s+of\s+(.+)$'),
      RegExp(r'^\s*(\d+[\./]?\d*)\s*(cup|cups|tbsp|tsp|tablespoon|teaspoon|oz|ounce|pound|lb|g|gram|ml|liter|L|pinch|handful|clove|cloves|slice|slices|piece|pieces)\s+(.+)$'),
      RegExp(r'^\s*(\d+[\./]?\d*)\s+(.+)$'),
    ];

    for (var pattern in quantityPatterns) {
      final match = pattern.firstMatch(ingredient);
      if (match != null) {
        String quantity = match.group(1) ?? "";
        String unit = match.groupCount >= 3 ? (match.group(2) ?? "") : "";
        String name = match.groupCount >= 3 ?
        (match.group(3) ?? "") :
        (match.group(2) ?? "");

        // Format the quantity with unit
        String formattedQuantity = quantity;
        if (unit.isNotEmpty) {
          formattedQuantity = "$quantity $unit";
        }

        return {
          'name': name.trim(),
          'quantity': formattedQuantity.trim()
        };
      }
    }

    // If no pattern matches, return the whole string as the name
    return {
      'name': ingredient,
      'quantity': '1'
    };
  }

  // Create a shopping list from selected ingredients
  void _createShoppingList() async {
    final listName = _listNameController.text.trim();
    if (listName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a list name')),
      );
      return;
    }

    // Prepare the categories map for the shopping list
    Map<String, List<Map<String, dynamic>>> categories = {};

    // Add selected ingredients to their categories
    for (var category in _categorizedIngredients.keys) {
      if (_categorizedIngredients[category]!.isNotEmpty) {
        categories[category] = [];

        for (var ingredient in _categorizedIngredients[category]!) {
          final index = ingredient['index'] as int;
          if (_selectedIngredients[index]) {
            categories[category]!.add({
              'name': ingredient['name'],
              'quantity': ingredient['quantity'],
            });
          }
        }

        // If no ingredients were added to this category, remove it
        if (categories[category]!.isEmpty) {
          categories.remove(category);
        }
      }
    }

    // Add tags from the recipe
    final tags = [...widget.recipe.tags];
    if (!tags.contains('Recipe')) {
      tags.add('Recipe'); // Add Recipe tag to identify lists created from recipes
    }

    // Save the list to Hive
    final groceryBox = await Hive.openBox('groceryLists');
    groceryBox.put(listName, {
      'categories': categories,
      'tags': tags,
    });

    // Show success message and pop twice to go back to recipe view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Shopping list created successfully!')),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Shopping List'),
      ),
      body: Stack(
        children: [
          // Scrollable content with bottom padding for the fixed button
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 80.0, // Add padding at bottom for the button
            ),
            child: ListView(
              children: [
                // List name field
                TextField(
                  controller: _listNameController,
                  decoration: InputDecoration(
                    labelText: 'List Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                SizedBox(height: 24),

                // Info text
                Text(
                  'Select ingredients to add to your shopping list:',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                SizedBox(height: 16),

                // Selection header with select all
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedIngredients = List.generate(
                                  widget.recipe.ingredients.length,
                                      (_) => true
                              );
                            });
                          },
                          child: Text('Select All'),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedIngredients = List.generate(
                                  widget.recipe.ingredients.length,
                                      (_) => false
                              );
                            });
                          },
                          child: Text('Deselect All'),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Categorized ingredient lists
                ..._categorizedIngredients.entries.map((entry) {
                  final category = entry.key;
                  final ingredients = entry.value;

                  if (ingredients.isEmpty) {
                    return SizedBox.shrink();
                  }

                  return Card(
                    margin: EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: themeController.currentFont,
                            ),
                          ),
                        ),
                        Divider(height: 1),

                        // Ingredients in this category
                        ...ingredients.map((ingredient) {
                          final index = ingredient['index'] as int;
                          final name = ingredient['name'] as String;
                          final quantity = ingredient['quantity'] as String;

                          return CheckboxListTile(
                            title: Row(
                              children: [
                                if (quantity != '1')
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.blueAccent.withOpacity(0.2)
                                          : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      quantity,
                                      style: TextStyle(
                                        fontFamily: themeController.currentFont,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: themeController.currentFont,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            value: _selectedIngredients[index],
                            activeColor: Colors.blueAccent,
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedIngredients[index] = value;
                                });
                              }
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          // Fixed bottom button
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _createShoppingList,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Create Shopping List',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: themeController.currentFont,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}