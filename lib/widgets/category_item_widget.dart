// widgets/category_item_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class CategoryItemWidget extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const CategoryItemWidget({
    Key? key,
    required this.item,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String itemName = item['name'] ?? '';
    final String itemQuantity = item['quantity'] ?? '1';

    return ListTile(
      leading: Icon(
        Icons.circle,
        size: 8,
        color: Colors.blueAccent,
      ),
      title: Row(
        children: [
          // Add quantity display
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
          SizedBox(width: 8),
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
        onPressed: onDelete,
      ),
    );
  }
}