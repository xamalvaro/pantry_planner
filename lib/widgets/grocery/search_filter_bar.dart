// widgets/grocery/search_filter_bar.dart
import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final Function(String) onSearchChanged;
  final VoidCallback onFilterPressed;
  final String? selectedTag;

  const SearchFilterBar({
    Key? key,
    required this.onSearchChanged,
    required this.onFilterPressed,
    required this.selectedTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDarkMode ? Colors.black : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search lists...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: selectedTag != null ? Colors.blueAccent : null,
            ),
            onPressed: onFilterPressed,
          ),
        ],
      ),
    );
  }
}