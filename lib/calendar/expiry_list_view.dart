import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/expiry/expiry_model.dart';
import 'expiry_event_card.dart';
import 'location_filter_modal.dart';

class ExpiryListView extends StatefulWidget {
  final List<PantryItem> allItems;
  final String searchQuery;
  final String? selectedLocation;
  final bool isLoading;
  final Function(String) onSearchChanged;
  final Function(String?) onLocationChanged;
  final Function(PantryItem) onItemTap;

  const ExpiryListView({
    Key? key,
    required this.allItems,
    required this.searchQuery,
    required this.selectedLocation,
    required this.isLoading,
    required this.onSearchChanged,
    required this.onLocationChanged,
    required this.onItemTap,
  }) : super(key: key);

  @override
  _ExpiryListViewState createState() => _ExpiryListViewState();
}

class _ExpiryListViewState extends State<ExpiryListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PantryItem> _getFilteredItems() {
    var items = widget.allItems;

    // Filter by search query
    if (widget.searchQuery.isNotEmpty) {
      final query = widget.searchQuery.toLowerCase();
      items = items.where((item) {
        return item.name.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query) ||
            (item.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by location
    if (widget.selectedLocation != null && widget.selectedLocation!.isNotEmpty) {
      items = items.where((item) => item.location == widget.selectedLocation).toList();
    }

    // Sort by expiry date (soonest first)
    items.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return items;
  }

  void _showLocationFilter() {
    // Get unique locations from all items
    final locations = widget.allItems
        .map((item) => item.location)
        .toSet()
        .toList()
      ..sort();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => LocationFilterModal(
        locations: locations,
        selectedLocation: widget.selectedLocation,
        onLocationSelected: (location) {
          widget.onLocationChanged(location);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar with location filter
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search items...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: widget.selectedLocation != null
                        ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () => widget.onLocationChanged(null),
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
              SizedBox(width: 8),
              // Location filter button
              IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: widget.selectedLocation != null ? Colors.blueAccent : null,
                ),
                onPressed: _showLocationFilter,
                tooltip: 'Filter by location',
              ),
            ],
          ),
        ),

        // Selected location indicator
        if (widget.selectedLocation != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Chip(
                  label: Row(
                    children: [
                      Icon(
                        _getLocationIcon(widget.selectedLocation!),
                        size: 16,
                        color: Colors.blueAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Location: ${widget.selectedLocation}',
                        style: TextStyle(
                          fontFamily: themeController.currentFont,
                        ),
                      ),
                    ],
                  ),
                  deleteIcon: Icon(Icons.close, size: 18),
                  onDeleted: () => widget.onLocationChanged(null),
                  backgroundColor: isDarkMode
                      ? Colors.blueAccent.withOpacity(0.2)
                      : Colors.blue.shade50,
                ),
              ],
            ),
          ),

        // Loading indicator
        if (widget.isLoading)
          Expanded(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),

        // Items list
        if (!widget.isLoading)
          Expanded(
            child: _getFilteredItems().isEmpty
                ? Center(
              child: Text(
                widget.searchQuery.isEmpty && widget.selectedLocation == null
                    ? 'No items to display'
                    : 'No items match your search criteria',
                style: TextStyle(
                  fontFamily: themeController.currentFont,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
              ),
            )
                : ListView.builder(
              itemCount: _getFilteredItems().length,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemBuilder: (context, index) {
                final item = _getFilteredItems()[index];
                return ExpiryEventCard(
                  item: item,
                  onTap: () => widget.onItemTap(item),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getLocationIcon(String location) {
    switch (location.toLowerCase()) {
      case 'fridge':
        return Icons.kitchen;
      case 'freezer':
        return Icons.ac_unit;
      case 'pantry':
        return Icons.shelves;
      case 'kitchen cabinet':
        return Icons.door_sliding;
      case 'spice rack':
        return Icons.grid_view;
      case 'countertop':
        return Icons.countertops;
      default:
        return Icons.place;
    }
  }
}