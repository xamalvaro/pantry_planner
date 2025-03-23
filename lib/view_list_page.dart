import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/utils/export_utils.dart';

class ViewListPage extends StatefulWidget {
  final String listName;

  ViewListPage({required this.listName});

  @override
  _ViewListPageState createState() => _ViewListPageState();
}

class _ViewListPageState extends State<ViewListPage> {
  final groceryBox = Hive.box('groceryLists');
  late Map<String, List<dynamic>> categories;
  late List<String> tags;
  final TextEditingController _tagController = TextEditingController();

  // Controllers for adding items with quantities
  final Map<String, TextEditingController> _itemControllers = {};
  final Map<String, TextEditingController> _quantityControllers = {};

  // Track which categories are expanded
  Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    final dynamic data = groceryBox.get(widget.listName, defaultValue: {});

    // Handle data format - convert old format to new if needed
    if (data['categories'] is Map) {
      final oldCategories = data['categories'] as Map;
      categories = {};

      oldCategories.forEach((key, value) {
        final categoryKey = key.toString();
        categories[categoryKey] = [];

        if (value is List) {
          // Check if it's the old format (list of strings) or new format (list of maps)
          for (final item in value) {
            if (item is String) {
              // Convert from old format (strings)
              categories[categoryKey]!.add({
                'name': item,
                'quantity': '1'
              });
            } else if (item is Map) {
              // Already in new format (maps)
              categories[categoryKey]!.add(item);
            }
          }
        }
      });
    } else {
      categories = {}; // Fallback to empty
    }

    tags = List<String>.from(data['tags'] ?? []);

    // Initialize controllers for each category
    for (final category in categories.keys) {
      _expandedCategories[category] = true;
      _itemControllers[category] = TextEditingController();
      _quantityControllers[category] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _tagController.dispose();

    // Dispose item and quantity controllers
    _itemControllers.forEach((_, controller) => controller.dispose());
    _quantityControllers.forEach((_, controller) => controller.dispose());

    super.dispose();
  }

  void _addItem(String category, String item, String quantity) {
    setState(() {
      categories[category]!.add({
        'name': item,
        'quantity': quantity.isNotEmpty ? quantity : '1',
      });
    });
    _saveList();

    // Clear the input fields
    _itemControllers[category]!.clear();
    _quantityControllers[category]!.clear();
  }

  void _removeItem(String category, int index) {
    setState(() {
      categories[category]!.removeAt(index);
    });
    _saveList();
  }

  void _addTag(String tag) {
    setState(() {
      if (!tags.contains(tag)) {
        tags.add(tag);
      }
    });
    _saveList();
    _tagController.clear(); // Clear the text field after adding
  }

  void _removeTag(String tag) {
    setState(() {
      tags.remove(tag);
    });
    _saveList();
  }

  // Toggle a category's expanded state
  void _toggleCategory(String category) {
    setState(() {
      _expandedCategories[category] = !(_expandedCategories[category] ?? true);
    });
  }

  void _saveList() {
    groceryBox.put(widget.listName, {
      'categories': categories,
      'tags': tags,
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.listName),
        actions: [
          // Add share button
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              ExportUtils.showExportOptions(context, widget.listName, _convertToOldFormat(), tags);
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              groceryBox.delete(widget.listName); // Delete the list
              Navigator.pop(context); // Go back to the home page
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Tag section with improved UI
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      labelText: 'Add a tag',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (_tagController.text.trim().isNotEmpty) {
                            _addTag(_tagController.text.trim());
                          }
                        },
                      ),
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _addTag(value.trim());
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (tags.isNotEmpty)
              Container(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              fontFamily: themeController.currentFont,
                              color: isDarkMode ? Colors.white : Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(width: 4),
                          InkWell(
                            onTap: () => _removeTag(tag),
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: isDarkMode ? Colors.white70 : Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: 16),
            // Display items in the list with collapsible categories
            Expanded(
              child: ListView(
                children: categories.keys.map((category) {
                  // Get expanded state for this category (default to true if not set)
                  bool isExpanded = _expandedCategories[category] ?? true;

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category header with expand/collapse button
                        InkWell(
                          onTap: () => _toggleCategory(category),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: themeController.currentFont,
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Category content that appears when expanded
                        if (isExpanded) ...[
                          Divider(height: 1),

                          // Show items if any exist
                          if (categories[category]!.isNotEmpty)
                            ...categories[category]!.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              // Handle different item formats
                              String itemName = '';
                              String itemQuantity = '1';

                              if (item is Map) {
                                itemName = item['name']?.toString() ?? '';
                                itemQuantity = item['quantity']?.toString() ?? '1';
                              } else {
                                itemName = item.toString();
                              }

                              return ListTile(
                                leading: Container(
                                  margin: EdgeInsets.only(top: 8),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    // Only show quantity if it's not '1'
                                    if (itemQuantity != '1')
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDarkMode
                                              ? Colors.blueAccent.withOpacity(0.2)
                                              : Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          itemQuantity,
                                          style: TextStyle(
                                            fontFamily: themeController.currentFont,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    if (itemQuantity != '1') SizedBox(width: 8),
                                    // Item name
                                    Expanded(
                                      child: Text(
                                        itemName,
                                        style: TextStyle(
                                          fontFamily: themeController.currentFont,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () {
                                    _removeItem(category, index);
                                  },
                                ),
                              );
                            }).toList(),

                          // Add item input field with quantity
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Quantity input
                                Container(
                                  width: 60,
                                  child: TextField(
                                    controller: _quantityControllers[category],
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Qty',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Item name input
                                Expanded(
                                  child: TextField(
                                    controller: _itemControllers[category],
                                    decoration: InputDecoration(
                                      labelText: 'Add an item to $category',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      isDense: true,
                                      suffixIcon: IconButton(
                                        icon: Icon(Icons.add),
                                        onPressed: () {
                                          final item = _itemControllers[category]!.text.trim();
                                          final quantity = _quantityControllers[category]!.text.trim();
                                          if (item.isNotEmpty) {
                                            _addItem(category, item, quantity);
                                          }
                                        },
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      if (value.trim().isNotEmpty) {
                                        final quantity = _quantityControllers[category]!.text.trim();
                                        _addItem(category, value.trim(), quantity);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
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

  // Convert the new data format (with quantities) to the old format for compatibility with ExportUtils
  Map<String, List<String>> _convertToOldFormat() {
    final result = <String, List<String>>{};

    categories.forEach((category, items) {
      result[category] = items.map((item) {
        String name = '';
        String quantity = '1';

        if (item is Map) {
          // If item is a Map with name and quantity fields
          name = item['name']?.toString() ?? '';
          quantity = item['quantity']?.toString() ?? '1';
        } else {
          // If item is just a String (old format)
          name = item.toString();
        }

        // Add quantity as prefix if it's not '1'
        if (quantity != '1') {
          return '$quantity × $name';
        }
        return name;
      }).toList();
    });

    return result;
  }
}