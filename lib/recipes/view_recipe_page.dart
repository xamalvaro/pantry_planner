// view_recipe_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pantry_pal/service_locator.dart';
import 'package:pantry_pal/recipes/recipe_to_list.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';
import 'package:pantry_pal/widgets/recipe/recipe_display.dart';

class ViewRecipePage extends StatefulWidget {
  final String recipeTitle;

  const ViewRecipePage({Key? key, required this.recipeTitle}) : super(key: key);

  @override
  _ViewRecipePageState createState() => _ViewRecipePageState();
}

class _ViewRecipePageState extends State<ViewRecipePage> {
  Recipe? _recipe;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isSharing = false;
  bool _isCreatingShoppingList = false;

  @override
  void initState() {
    super.initState();
    // Load recipe data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecipe();
    });
  }

  Future<void> _loadRecipe() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Get the recipe box using service locator
      final recipeBox = await serviceLocator.getBox('recipes');
      final recipeData = recipeBox.get(widget.recipeTitle);

      if (recipeData != null) {
        // Process the recipe data
        final recipe = Recipe.fromMap(recipeData);

        if (mounted) {
          setState(() {
            _recipe = recipe;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading recipe: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteRecipe() async {
    if (_isDeleting || _recipe == null) return;

    setState(() => _isDeleting = true);

    try {
      // Get the recipe box
      final recipeBox = await serviceLocator.getBox('recipes');

      // Delete recipe
      await recipeBox.delete(widget.recipeTitle);

      // Return to previous screen
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error deleting recipe: $e');
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting recipe: $e')),
        );
      }
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Recipe?'),
          content: Text('Are you sure you want to delete "${widget.recipeTitle}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteRecipe();
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareRecipe() async {
    if (_isSharing || _recipe == null) return;

    setState(() => _isSharing = true);

    try {
      // Share the recipe as text directly
      await _shareAsText(_recipe!);

      if (mounted) {
        setState(() => _isSharing = false);
      }
    } catch (e) {
      print('Error sharing recipe: $e');
      if (mounted) {
        setState(() => _isSharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing recipe: $e')),
        );
      }
    }
  }

  // Share recipe as formatted text
  Future<void> _shareAsText(Recipe recipe) async {
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

  Future<void> _createShoppingList() async {
    if (_isCreatingShoppingList || _recipe == null) return;

    setState(() => _isCreatingShoppingList = true);

    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeToListConverter(recipe: _recipe!),
        ),
      );

      if (mounted) {
        setState(() => _isCreatingShoppingList = false);
      }
    } catch (e) {
      print('Error creating shopping list: $e');
      if (mounted) {
        setState(() => _isCreatingShoppingList = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating shopping list: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Recipe Not Found')),
        body: Center(
          child: Text(
            'Recipe "${widget.recipeTitle}" not found.',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_recipe!.title),
        actions: [
          // Share button
          IconButton(
            icon: _isSharing
                ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
                : Icon(Icons.share),
            onPressed: _isSharing || _isDeleting ? null : _shareRecipe,
          ),
          // Delete button
          IconButton(
            icon: _isDeleting
                ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
                : Icon(Icons.delete),
            onPressed: _isDeleting || _isSharing ? null : _showDeleteConfirmation,
          ),
        ],
      ),
      body: RecipeDisplay(
        recipe: _recipe!,
        isDisabled: _isDeleting,
        onCreateShoppingList: _createShoppingList,
        isCreatingShoppingList: _isCreatingShoppingList,
      ),
    );
  }
}