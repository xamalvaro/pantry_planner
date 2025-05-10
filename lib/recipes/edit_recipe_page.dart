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
import 'package:hive_flutter/hive_flutter.dart';

class EditRecipePage extends StatefulWidget {
  final Recipe recipe;

  const EditRecipePage({Key? key, required this.recipe}) : super(key: key);

  @override
  _EditRecipePageState createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  // Text controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final _ingredientController = TextEditingController();
  final _stepController = TextEditingController();
  final _tagController = TextEditingController();

  // Recipe data
  late List<String> _ingredients;
  late List<String> _steps;
  late List<String> _tags;

  // Values for servings and time
  late int _servings;
  late int _prepTimeMinutes;
  late int _cookTimeMinutes;

  // Loading states
  bool _isSaving = false;

  // Store original title for updating the key
  late String _originalTitle;

  @override
  void initState() {
    super.initState();

    // Initialize with existing recipe data
    _originalTitle = widget.recipe.title;
    _titleController = TextEditingController(text: widget.recipe.title);
    _descriptionController = TextEditingController(text: widget.recipe.description);

    _ingredients = List.from(widget.recipe.ingredients);
    _steps = List.from(widget.recipe.steps);
    _tags = List.from(widget.recipe.tags);

    _servings = widget.recipe.servings;
    _prepTimeMinutes = widget.recipe.prepTimeMinutes;
    _cookTimeMinutes = widget.recipe.cookTimeMinutes;
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
    // Validate inputs
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

    setState(() {
      _isSaving = true;
    });

    try {
      // Get the recipe box
      final recipeBox = await serviceLocator.getBox('recipes');

      // Create recipe data
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

      // If title changed, delete old entry
      if (title != _originalTitle) {
        await recipeBox.delete(_originalTitle);
      }

      // Save with new title as key
      await recipeBox.put(title, recipeData);

      // Sync to Firestore if logged in
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

          // If title changed, delete old document
          if (title != _originalTitle) {
            final oldDocId = _originalTitle.trim()
                .replaceAll(RegExp(r'[^\w\s]'), '')
                .replaceAll(' ', '_')
                .toLowerCase();
            await firebaseRecipeService.deleteRecipe(oldDocId);
          }

          await firebaseRecipeService.saveRecipe(recipe);
        } catch (e) {
          print('Error syncing recipe to Firestore: $e');
        }
      }

      // Return to previous screen with updated title
      Navigator.pop(context, title);
    } catch (e) {
      print('Error updating recipe: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error updating recipe: $e');
      }
    }
  }

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

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Recipe'),
      ),
      body: Stack(
        children: [
          // Scrollable content
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                top: 16.0,
                bottom: 80.0,
              ),
              child: ListView(
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
                  'Save Changes',
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