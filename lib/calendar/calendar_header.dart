import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class CalendarHeader extends StatelessWidget {
  final bool isListView;
  final bool isLoadingSuggestions;
  final VoidCallback onToggleView;
  final VoidCallback onShowSuggestions;
  final VoidCallback onAddItem;

  const CalendarHeader({
    Key? key,
    required this.isListView,
    required this.isLoadingSuggestions,
    required this.onToggleView,
    required this.onShowSuggestions,
    required this.onAddItem,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 8,
        bottom: 12,
      ),
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Row(
        children: [
          // Title
          Expanded(
            child: Text(
              'Expiry Calendar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: themeController.currentFont,
                color: Theme.of(context).appBarTheme.foregroundColor,
              ),
            ),
          ),

          // View toggle (list/calendar)
          IconButton(
            icon: Icon(
              isListView ? Icons.calendar_month : Icons.search,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: onToggleView,
            tooltip: isListView ? 'Calendar View' : 'Search View',
          ),

          // Recipe suggestions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isLoadingSuggestions ? null : onShowSuggestions,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Suggestions',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: themeController.currentFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Add item button
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
            onPressed: onAddItem,
            tooltip: 'Add Item',
          ),
        ],
      ),
    );
  }
}