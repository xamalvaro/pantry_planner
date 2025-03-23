// widgets/grocery/state_views.dart
import 'package:flutter/material.dart';
import 'package:pantry_pal/theme_controller.dart';

/// Widget to display when lists are loading
class LoadingView extends StatelessWidget {
  final ThemeController themeController;

  const LoadingView({
    Key? key,
    required this.themeController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading lists...',
            style: TextStyle(
              fontSize: 16,
              fontFamily: themeController.currentFont,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget to display when there's an error loading lists
class ErrorView extends StatelessWidget {
  final ThemeController themeController;
  final VoidCallback onRetry;

  const ErrorView({
    Key? key,
    required this.themeController,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          Text(
            'Unable to access lists',
            style: TextStyle(
              fontSize: 16,
              fontFamily: themeController.currentFont,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Widget to display when there are no lists
class EmptyListView extends StatelessWidget {
  final ThemeController themeController;
  final bool isDarkMode;
  final String searchQuery;
  final String? selectedTag;

  const EmptyListView({
    Key? key,
    required this.themeController,
    required this.isDarkMode,
    required this.searchQuery,
    required this.selectedTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_basket,
            size: 64,
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
          SizedBox(height: 16),
          Text(
            searchQuery.isEmpty && selectedTag == null
                ? 'No lists yet. Create your first list!'
                : 'No lists match your search criteria.',
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
}