// category_section.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/widgets/category_item_widget.dart';

class CategorySection extends StatelessWidget {
  final String category;
  final List<Map<String, dynamic>> items;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final Function(int) onRemoveItem;
  final TextEditingController itemController;
  final TextEditingController quantityController;
  final Function(String, String, String) onAddItem;

  const CategorySection({
    Key? key,
    required this.category,
    required this.items,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onRemoveItem,
    required this.itemController,
    required this.quantityController,
    required this.onAddItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header with expand/collapse button
          InkWell(
            onTap: onToggleExpanded,
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
            if (items.isNotEmpty)
              ...items.asMap().entries.map((entry) {
                return CategoryItemWidget(
                  item: entry.value,
                  onDelete: () => onRemoveItem(entry.key),
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
                      controller: quantityController,
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
                      controller: itemController,
                      decoration: InputDecoration(
                        labelText: 'Add an item to $category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        isDense: true,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            final item = itemController.text.trim();
                            final quantity = quantityController.text.trim();
                            if (item.isNotEmpty) {
                              onAddItem(category, item, quantity);
                            }
                          },
                        ),
                      ),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          final quantity = quantityController.text.trim();
                          onAddItem(category, value.trim(), quantity);
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
  }
}