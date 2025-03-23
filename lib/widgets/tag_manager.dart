// tag_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class TagManager extends StatelessWidget {
  final List<String> tags;
  final TextEditingController tagController;
  final Function(String) onAddTag;
  final Function(String) onRemoveTag;

  const TagManager({
    Key? key,
    required this.tags,
    required this.tagController,
    required this.onAddTag,
    required this.onRemoveTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag input field
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tagController,
                decoration: InputDecoration(
                  labelText: 'Add a tag',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (tagController.text.trim().isNotEmpty) {
                        onAddTag(tagController.text.trim());
                      }
                    },
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    onAddTag(value.trim());
                  }
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Tag chips
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
                        onTap: () => onRemoveTag(tag),
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
      ],
    );
  }
}