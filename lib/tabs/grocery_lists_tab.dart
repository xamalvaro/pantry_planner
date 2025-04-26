// lib/tabs/grocery_lists_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/view_list_page.dart';
import 'package:pantry_pal/services/hive_manager.dart';
import 'package:pantry_pal/utils/list_format_utils.dart';

// Import widgets
import 'package:pantry_pal/widgets/grocery/search_filter_bar.dart';
import 'package:pantry_pal/widgets/grocery/list_item_card.dart';
import 'package:pantry_pal/widgets/grocery/tag_filter_modal.dart';
import 'package:pantry_pal/widgets/grocery/state_views.dart';

class GroceryListsTab extends StatefulWidget {
  final String searchQuery;
  final String? selectedTag;
  final Function(String) onSearchChanged;
  final Function(String?) onTagSelected;

  const GroceryListsTab({
    Key? key,
    required this.searchQuery,
    required this.selectedTag,
    required this.onSearchChanged,
    required this.onTagSelected,
  }) : super(key: key);

  @override
  _GroceryListsTabState createState() => _GroceryListsTabState();
}

class _GroceryListsTabState extends State<GroceryListsTab> with AutomaticKeepAliveClientMixin {
  Box? _groceryBox;
  bool _isLoading = true;
  Set<String> _expandedLists = {};
  // Add a local searchQuery to ensure state updates correctly
  late String _localSearchQuery;
  String? _localSelectedTag;

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _localSearchQuery = widget.searchQuery;
    _localSelectedTag = widget.selectedTag;

    // Defer box opening to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openGroceryBox();
    });
  }

  @override
  void didUpdateWidget(GroceryListsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when widget properties change
    if (widget.searchQuery != oldWidget.searchQuery) {
      _localSearchQuery = widget.searchQuery;
    }
    if (widget.selectedTag != oldWidget.selectedTag) {
      _localSelectedTag = widget.selectedTag;
    }
  }

  // Open grocery box using HiveManager
  Future<void> _openGroceryBox() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Use our HiveManager to get the box
      _groceryBox = await hiveManager.openBox('groceryLists');
      print('GroceryListsTab: groceryLists box opened: ${_groceryBox != null}');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('GroceryListsTab: Error opening groceryLists box: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Navigate to view list page
  void _navigateToViewListPage(BuildContext context, String listName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewListPage(listName: listName),
      ),
    ).then((_) {
      // Refresh the UI after returning from the view page
      setState(() {});
    });
  }

  // Delete a list
  void _deleteList(String listName) {
    try {
      final box = _groceryBox;
      if (box == null) return;

      setState(() {
        box.delete(listName);
        _expandedLists.remove(listName);
      });
    } catch (e) {
      print('Error deleting list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting list. Please try again.')),
      );
    }
  }

  // Toggle list expansion
  void _toggleListExpanded(String listName) {
    setState(() {
      if (_expandedLists.contains(listName)) {
        _expandedLists.remove(listName);
      } else {
        _expandedLists.add(listName);
      }
    });
  }

  // Handle search query changes
  void _handleSearchChanged(String query) {
    setState(() {
      _localSearchQuery = query;
    });
    widget.onSearchChanged(query);
  }

  // Handle tag selection
  void _handleTagSelected(String? tag) {
    setState(() {
      _localSelectedTag = tag;
    });
    widget.onTagSelected(tag);
  }

  // Show tag filter modal
  void _showTagFilterModal(BuildContext context) async {
    final allTags = ListFormatUtils.getAllTags(_groceryBox);

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return TagFilterModal(
          allTags: allTags,
          selectedTag: _localSelectedTag,
          onTagSelected: _handleTagSelected,
        );
      },
    );
  }

  // Get filtered keys directly (not using ListFormatUtils for immediate feedback)
  List<String> _getFilteredKeys(Box box) {
    final keys = box.keys.toList();
    return keys.where((key) {
      try {
        final listData = box.get(key);
        if (listData == null) return false;

        // Check if the list name contains the search query
        final matchesSearch = _localSearchQuery.isEmpty ||
            key.toString().toLowerCase().contains(_localSearchQuery.toLowerCase());

        // Check if the list has the selected tag
        final tags = List<String>.from(listData['tags'] ?? []);
        final matchesTag = _localSelectedTag == null || tags.contains(_localSelectedTag);

        // Both conditions must be true
        return matchesSearch && matchesTag;
      } catch (e) {
        print('Error filtering key $key: $e');
        return false;
      }
    }).cast<String>().toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Handle loading state
    if (_isLoading) {
      return LoadingView(themeController: themeController);
    }

    // Handle case when box isn't open
    if (_groceryBox == null) {
      return ErrorView(
          themeController: themeController,
          onRetry: _openGroceryBox
      );
    }

    return Column(
      children: [
        // Search and Tag Filter Bar
        SearchFilterBar(
          onSearchChanged: _handleSearchChanged,
          onFilterPressed: () => _showTagFilterModal(context),
          selectedTag: _localSelectedTag,
        ),

        // Lists Section
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: _groceryBox!.listenable(),
            builder: (context, Box box, _) {
              // Get filtered keys using local state
              final List<String> filteredKeys = _getFilteredKeys(box);

              // Show empty state if no lists match
              if (filteredKeys.isEmpty) {
                return EmptyListView(
                  themeController: themeController,
                  isDarkMode: isDarkMode,
                  searchQuery: _localSearchQuery,
                  selectedTag: _localSelectedTag,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filteredKeys.length,
                itemBuilder: (context, index) {
                  final listName = filteredKeys[index];
                  return _buildListItem(box, listName);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Build a single list item
  Widget _buildListItem(Box box, String listName) {
    try {
      final listData = box.get(listName);
      final categoriesData = ListFormatUtils.convertToDisplayFormat(listData['categories']);
      final tags = List<String>.from(listData['tags'] ?? []);
      final isExpanded = _expandedLists.contains(listName);

      return ListItemCard(
        listName: listName,
        categoriesData: categoriesData,
        tags: tags,
        isExpanded: isExpanded,
        onToggleExpand: () => _toggleListExpanded(listName),
        onNavigateToView: _navigateToViewListPage,
        onDelete: _deleteList,
      );
    } catch (e) {
      print('Error building list item: $e');
      return Card(
        margin: EdgeInsets.only(bottom: 16),
        color: Colors.red.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading this list',
            style: TextStyle(color: Colors.red.shade900),
          ),
        ),
      );
    }
  }
}