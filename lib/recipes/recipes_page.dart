import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/recipes/view_recipe_page.dart';
import 'package:pantry_pal/recipes/recipe_model.dart';

class RecipesPage extends StatefulWidget {
  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  String? _selectedTag;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search and Tag Filter Bar
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: isDarkMode ? Colors.black : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search recipes...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              // Filter by tag button - when pressed, opens a modal with tag selection
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: _selectedTag != null ? Colors.blueAccent : null,
                ),
                onPressed: () {
                  _showTagFilterModal(context);
                },
              ),
            ],
          ),
        ),

        // Recipes List
        Expanded(
          child: FutureBuilder(
            future: Hive.openBox('recipes'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading recipes'),
                  );
                }

                final recipeBox = Hive.box('recipes');

                return ValueListenableBuilder(
                  valueListenable: recipeBox.listenable(),
                  builder: (context, box, widget) {
                    final allRecipes = _getAllRecipes(box);

                    // Filter recipes by search query and tag
                    final filteredRecipes = allRecipes.where((recipe) {
                      final matchesSearch = recipe.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          recipe.description.toLowerCase().contains(_searchQuery.toLowerCase());

                      final matchesTag = _selectedTag == null ||
                          (recipe.tags.isNotEmpty && recipe.tags.contains(_selectedTag));

                      return matchesSearch && matchesTag;
                    }).toList();

                    if (filteredRecipes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 64,
                              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty && _selectedTag == null
                                  ? 'No recipes yet. Create your first recipe!'
                                  : 'No recipes match your search criteria.',
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: themeController.currentFont,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(16),
                      itemCount: filteredRecipes.length,
                      itemBuilder: (context, index) {
                        final recipe = filteredRecipes[index];
                        return _buildRecipeCard(context, recipe);
                      },
                    );
                  },
                );
              } else {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(BuildContext context, Recipe recipe) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ViewRecipePage(recipeTitle: recipe.title),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                    ),
                  ),
                  SizedBox(height: 8),
                  // Description (if present)
                  if (recipe.description.isNotEmpty)
                    Text(
                      recipe.description,
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // Recipe Info Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time Info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        recipe.totalTimeFormatted,
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Servings Info
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${recipe.servings} ${recipe.servings == 1 ? 'serving' : 'servings'}',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                  // Ingredients Count
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${recipe.ingredients.length} ingredients',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tags (if present)
            if (recipe.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.tags.map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? Colors.blueAccent.withOpacity(0.2)
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.white : Colors.blue.shade900,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showTagFilterModal(BuildContext context) async {
    final allTags = _getAllTags();
    final themeController = Provider.of<ThemeController>(context, listen: false);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter by Tag',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: themeController.currentFont,
                          ),
                        ),
                        if (_selectedTag != null)
                          TextButton(
                            onPressed: () {
                              this.setState(() {
                                _selectedTag = null;
                              });
                              Navigator.pop(context);
                            },
                            child: Text('Clear Filter'),
                          ),
                      ],
                    ),
                  ),
                  Divider(height: 1),
                  Expanded(
                    child: ListView(
                      children: [
                        ...allTags.map((tag) {
                          final isSelected = tag == _selectedTag;
                          return ListTile(
                            title: Text(
                              tag,
                              style: TextStyle(
                                fontFamily: themeController.currentFont,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.blueAccent : null,
                              ),
                            ),
                            leading: Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? Colors.blueAccent : null,
                            ),
                            onTap: () {
                              this.setState(() {
                                _selectedTag = tag;
                              });
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                        if (allTags.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'No tags found',
                                style: TextStyle(
                                  fontFamily: themeController.currentFont,
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to convert all recipes from Hive to Recipe objects
  List<Recipe> _getAllRecipes(Box box) {
    final recipes = <Recipe>[];

    for (final key in box.keys) {
      final recipeData = box.get(key);
      if (recipeData != null) {
        try {
          recipes.add(Recipe.fromMap(recipeData));
        } catch (e) {
          print('Error loading recipe: $e');
        }
      }
    }

    return recipes;
  }

  // Helper method to get all unique tags from recipes
  List<String> _getAllTags() {
    final box = Hive.box('recipes');
    final Set<String> tags = {};

    for (final key in box.keys) {
      final recipeData = box.get(key);
      if (recipeData != null) {
        try {
          final recipe = Recipe.fromMap(recipeData);
          tags.addAll(recipe.tags);
        } catch (e) {
          print('Error getting tags: $e');
        }
      }
    }

    return tags.toList();
  }
}