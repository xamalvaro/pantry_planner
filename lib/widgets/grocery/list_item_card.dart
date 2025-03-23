// widgets/grocery/list_item_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/utils/export_utils.dart';

class ListItemCard extends StatelessWidget {
  final String listName;
  final Map<String, List<dynamic>> categoriesData;
  final List<String> tags;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final Function(BuildContext, String) onNavigateToView;
  final Function(String) onDelete;

  const ListItemCard({
    Key? key,
    required this.listName,
    required this.categoriesData,
    required this.tags,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onNavigateToView,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use a key for better list performance
    return Card(
      key: ValueKey(listName),
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onToggleExpand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // List header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      listName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: themeController.currentFont,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),

            // Only show content if expanded
            if (isExpanded) _buildExpandedContent(
                context,
                themeController,
                isDarkMode
            ),
          ],
        ),
      ),
    );
  }

  // Expanded content for a list item
  Widget _buildExpandedContent(
      BuildContext context,
      ThemeController themeController,
      bool isDarkMode,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tags
        if (tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
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
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                      fontSize: 13,
                      color: isDarkMode ? Colors.white : Colors.blue.shade900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Divider
        if (tags.isNotEmpty)
          Divider(height: 1, thickness: 1),

        // Categories and items
        ...categoriesData.keys.map((category) {
          final items = categoriesData[category] ?? [];
          if (items.isEmpty) return SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category heading
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                SizedBox(height: 8),

                // Items (limited to first 3 for performance)
                ...items.take(3).map((item) {
                  String itemName = '';
                  String itemQuantity = '1';

                  if (item is Map) {
                    itemName = item['name']?.toString() ?? '';
                    itemQuantity = item['quantity']?.toString() ?? '1';
                  } else {
                    itemName = item.toString();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 10),
                        if (itemQuantity != '1')
                          Container(
                            margin: EdgeInsets.only(right: 8),
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
                  );
                }).toList(),

                // Show "more items" indicator if there are more than 3
                if (items.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                    child: Text(
                      '+ ${items.length - 3} more items',
                      style: TextStyle(
                        fontFamily: themeController.currentFont,
                        fontSize: 12,
                        color: Colors.blueAccent,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),

        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: Icon(Icons.edit, size: 18),
                label: Text('Edit'),
                onPressed: () => onNavigateToView(context, listName),
              ),
              SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(Icons.share, size: 18),
                label: Text('Share'),
                onPressed: () {
                  try {
                    final oldFormatCategories = _convertToOldFormat(categoriesData);
                    ExportUtils.showExportOptions(
                        context,
                        listName,
                        oldFormatCategories,
                        tags
                    );
                  } catch (e) {
                    print('Error sharing list: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error sharing list. Please try again.')),
                    );
                  }
                },
              ),
              SizedBox(width: 8),
              TextButton.icon(
                icon: Icon(Icons.delete, size: 18, color: Colors.red),
                label: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => onDelete(listName),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Convert to old format for ExportUtils
  Map<String, List<String>> _convertToOldFormat(Map<String, List<dynamic>> data) {
    try {
      final result = <String, List<String>>{};

      data.forEach((category, items) {
        result[category] = [];

        for (final item in items) {
          if (item is Map) {
            String name = item['name']?.toString() ?? '';
            String quantity = item['quantity']?.toString() ?? '1';

            if (quantity != '1') {
              result[category]!.add("$quantity × $name");
            } else {
              result[category]!.add(name);
            }
          } else {
            result[category]!.add(item.toString());
          }
        }
      });

      return result;
    } catch (e) {
      print('Error converting to old format: $e');
      return {};
    }
  }
}