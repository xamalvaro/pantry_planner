// lib/widgets/grocery/tag_filter_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class TagFilterModal extends StatelessWidget {
  final List<String> allTags;
  final String? selectedTag;
  final Function(String?) onTagSelected;

  const TagFilterModal({
    Key? key,
    required this.allTags,
    required this.selectedTag,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
                if (selectedTag != null)
                  TextButton(
                    onPressed: () {
                      onTagSelected(null);
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
                  final isSelected = tag == selectedTag;
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
                      onTagSelected(tag);
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
  }
}