// create_list_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/widgets/category_section.dart';
import 'package:pantry_pal/widgets/tag_manager.dart';

class CreateListPage extends StatefulWidget {
  @override
  _CreateListPageState createState() => _CreateListPageState();
}

class _CreateListPageState extends State<CreateListPage> {
  final _listNameController = TextEditingController();
  final _tagController = TextEditingController();
  final Map<String, List<Map<String, dynamic>>> _categories = {
    'Fruits': [],
    'Vegetables': [],
    'Grains': [],
    'Protein': [],
    'Dairy': [],
  };
  final List<String> _tags = []; // List of tags for the current list

  // Text controllers for adding items
  final Map<String, TextEditingController> _itemControllers = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  // Track which categories are expanded
  Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    // Initialize all categories as expanded by default
    for (final category in _categories.keys) {
      _expandedCategories[category] = true;
      _itemControllers[category] = TextEditingController();
      _quantityControllers[category] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _listNameController.dispose();
    _tagController.dispose();

    // Dispose all item and quantity controllers
    _itemControllers.forEach((_, controller) => controller.dispose());
    _quantityControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
  }

  void _addItem(String category, String item, String quantity) {
    setState(() {
      _categories[category]!.add({
        'name': item,
        'quantity': quantity.isNotEmpty ? quantity : '1',
      });
    });

    // Clear text fields after adding
    _itemControllers[category]!.clear();
    _quantityControllers[category]!.clear();
  }

  void _addTag(String tag) {
    setState(() {
      if (!_tags.contains(tag)) {
        _tags.add(tag);
      }
    });
    _tagController.clear(); // Clear the text field after adding
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // Toggle a category's expanded state
  void _toggleCategory(String category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? true);
    });
  }

  void _saveList() async {
    final listName = _listNameController.text.trim();
    if (listName.isNotEmpty) {
      // Create a local copy of the data to save
      final Map<String, dynamic> listData = {
        'categories': Map<String, List<Map<String, dynamic>>>.from(_categories),
        'tags': List<String>.from(_tags), // Save tags with the list
      };

      // Save data first and wait for it to complete
      final groceryBox = Hive.box('groceryLists');
      await groceryBox.put(listName, listData);

      // Use Future.delayed to ensure the UI has time to process state changes
      Future.delayed(Duration.zero, () {
        // Only navigate if context is still valid
        if (mounted) {
          Navigator.pop(context); // Go back to the home page
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Create New List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // List Name input
            TextField(
              controller: _listNameController,
              decoration: InputDecoration(
                labelText: 'List Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Tag management section
            TagManager(
              tags: _tags,
              tagController: _tagController,
              onAddTag: _addTag,
              onRemoveTag: _removeTag,
            ),

            SizedBox(height: 16),

            // Categories section
            Expanded(
              child: ListView(
                children: _categories.keys.map((category) {
                  return CategorySection(
                    category: category,
                    items: _categories[category]!,
                    isExpanded: _expandedCategories[category] ?? true,
                    onToggleExpanded: () => _toggleCategory(category),
                    onRemoveItem: (index) {
                      setState(() {
                        _categories[category]!.removeAt(index);
                      });
                    },
                    itemController: _itemControllers[category]!,
                    quantityController: _quantityControllers[category]!,
                    onAddItem: _addItem,
                  );
                }).toList(),
              ),
            ),

            // Create List button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _saveList();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Create List',
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
      ),
    );
  }
}