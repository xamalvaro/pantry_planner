// create_recipe_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/service_locator.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';
import 'package:pantry_pal/widgets/recipe/servings_time_section.dart';
import 'package:pantry_pal/widgets/recipe/tags_section.dart';
import 'package:pantry_pal/widgets/recipe/ingredients_section.dart';
import 'package:pantry_pal/widgets/recipe/steps_section.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/firebase_recipe_service.dart';

class CreateRecipePage extends StatefulWidget {
  @override
  _CreateRecipePageState createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  // Text controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _stepController = TextEditingController();
  final _tagController = TextEditingController();

  // Recipe data
  final List<String> _ingredients = [];
  final List<String> _steps = [];
  final List<String> _tags = [];

  // Default values for servings and time
  int _servings = 2;
  int _prepTimeMinutes = 10;
  int _cookTimeMinutes = 20;

  // Loading states
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Reduce potential jank by loading boxes in the background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _preloadRecipeBox();
      }
    });
  }

  // Preload the recipe box to avoid jank when saving
  Future<void> _preloadRecipeBox() async {
    try {
      await serviceLocator.getBox('recipes');
    } catch (e) {
      print('Error preloading recipe box: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ingredientController.dispose();
    _stepController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addIngredient(String ingredient) {
    setState(() {
      if (ingredient.trim().isNotEmpty) {
        _ingredients.add(ingredient);
      }
    });
    _ingredientController.clear();
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addStep(String step) {
    setState(() {
      if (step.trim().isNotEmpty) {
        _steps.add(step);
      }
    });
    _stepController.clear();
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _addTag(String tag) {
    setState(() {
      if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
        _tags.add(tag.trim());
      }
    });
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _saveRecipe() async {
    // Validate inputs first before any heavy processing
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showErrorSnackBar('Please enter a recipe title');
      return;
    }

    if (_ingredients.isEmpty) {
      _showErrorSnackBar('Please add at least one ingredient');
      return;
    }

    if (_steps.isEmpty) {
      _showErrorSnackBar('Please add at least one step');
      return;
    }

    // Now start the saving process
    setState(() {
      _isSaving = true;
    });

    try {
      // Get the recipe box using service locator
      final recipeBox = await serviceLocator.getBox('recipes');

      // Use compute for creating recipe map to avoid UI jank
      final recipeData = await compute(_createRecipeMap, {
        'title': title,
        'description': _descriptionController.text.trim(),
        'ingredients': _ingredients,
        'steps': _steps,
        'servings': _servings,
        'prepTimeMinutes': _prepTimeMinutes,
        'cookTimeMinutes': _cookTimeMinutes,
        'tags': _tags,
      });

      // Save to Hive
      await recipeBox.put(title, recipeData);

      // Sync to Firestore if the user is logged in
      if (firebaseService.isLoggedIn) {
        try {
          // Create Recipe object
          final recipe = Recipe(
            title: title,
            description: _descriptionController.text.trim(),
            ingredients: _ingredients,
            steps: _steps,
            servings: _servings,
            prepTimeMinutes: _prepTimeMinutes,
            cookTimeMinutes: _cookTimeMinutes,
            tags: _tags,
          );

          await firebaseRecipeService.saveRecipe(recipe);
        } catch (e) {
          print('Error syncing recipe to Firestore: $e');
          // We still show success because local save worked
        }
      }

      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      print('Error saving recipe: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving recipe: $e');
      }
    }
  }

  // Static method for compute
  static Map<String, dynamic> _createRecipeMap(Map<String, dynamic> params) {
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Recipe'),
      ),
      body: Stack(
        children: [
          // Scrollable content with bottom padding for the fixed button
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 80.0, // Add padding at bottom for the button
              ),
              child: ListView(
                // Disable physics while saving to prevent user interaction
                physics: _isSaving ? NeverScrollableScrollPhysics() : null,
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Recipe Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                    enabled: !_isSaving,
                  ),
                  SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'A brief description of your recipe',
                    ),
                    maxLines: 3,
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                    ),
                    enabled: !_isSaving,
                  ),
                  SizedBox(height: 24),

                  // Servings and Time Section
                  ServingsTimeSection(
                    servings: _servings,
                    prepTimeMinutes: _prepTimeMinutes,
                    cookTimeMinutes: _cookTimeMinutes,
                    onDecreaseServings: () {
                      setState(() {
                        if (_servings > 1) _servings--;
                      });
                    },
                    onIncreaseServings: () {
                      setState(() {
                        _servings++;
                      });
                    },
                    onDecreasePrepTime: () {
                      setState(() {
                        if (_prepTimeMinutes > 0) _prepTimeMinutes -= 5;
                      });
                    },
                    onIncreasePrepTime: () {
                      setState(() {
                        _prepTimeMinutes += 5;
                      });
                    },
                    onDecreaseCookTime: () {
                      setState(() {
                        if (_cookTimeMinutes > 0) _cookTimeMinutes -= 5;
                      });
                    },
                    onIncreaseCookTime: () {
                      setState(() {
                        _cookTimeMinutes += 5;
                      });
                    },
                    isDisabled: _isSaving,
                  ),
                  SizedBox(height: 24),

                  // Tags Section
                  TagsSection(
                    tags: _tags,
                    tagController: _tagController,
                    onAddTag: _addTag,
                    onRemoveTag: _removeTag,
                    isDisabled: _isSaving,
                  ),
                  SizedBox(height: 24),

                  // Ingredients Section
                  IngredientsSection(
                    ingredients: _ingredients,
                    ingredientController: _ingredientController,
                    onAddIngredient: _addIngredient,
                    onRemoveIngredient: _removeIngredient,
                    isDisabled: _isSaving,
                  ),
                  SizedBox(height: 24),

                  // Steps Section
                  StepsSection(
                    steps: _steps,
                    stepController: _stepController,
                    onAddStep: _addStep,
                    onRemoveStep: _removeStep,
                    isDisabled: _isSaving,
                  ),
                ],
              ),
            ),
          ),

          // Fixed bottom button
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveRecipe,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: _isSaving
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Saving...',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  ],
                )
                    : Text(
                  'Create Recipe',
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
                disabledBackgroundColor: Colors.blueAccent.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}