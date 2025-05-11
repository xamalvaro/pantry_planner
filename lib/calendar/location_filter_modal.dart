import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class LocationFilterModal extends StatelessWidget {
  final List<String> locations;
  final String? selectedLocation;
  final Function(String?) onLocationSelected;

  const LocationFilterModal({
    Key? key,
    required this.locations,
    required this.selectedLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Storage Location',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: themeController.currentFont,
                  ),
                ),
                if (selectedLocation != null)
                  TextButton(
                    onPressed: () => onLocationSelected(null),
                    child: Text('Clear'),
                  ),
              ],
            ),
          ),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Text(
              'View items expiring in specific storage locations',
              style: TextStyle(
                fontFamily: themeController.currentFont,
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: locations.length + 1, // +1 for "All Locations" option
            itemBuilder: (context, index) {
              if (index == 0) {
                // "All Locations" option
                return ListTile(
                  leading: Icon(
                    Icons.view_list,
                    color: selectedLocation == null ? Colors.blueAccent : null,
                  ),
                  title: Text(
                    'All Locations',
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                      fontWeight: selectedLocation == null ? FontWeight.bold : FontWeight.normal,
                      color: selectedLocation == null ? Colors.blueAccent : null,
                    ),
                  ),
                  subtitle: Text(
                    'Show items from all storage areas',
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                      fontSize: 12,
                    ),
                  ),
                  selected: selectedLocation == null,
                  onTap: () => onLocationSelected(null),
                );
              }

              final location = locations[index - 1];
              final isSelected = location == selectedLocation;

              return ListTile(
                leading: Icon(
                  _getLocationIcon(location),
                  color: isSelected ? Colors.blueAccent : null,
                ),
                title: Text(
                  location,
                  style: TextStyle(
                    fontFamily: themeController.currentFont,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blueAccent : null,
                  ),
                ),
                subtitle: Text(
                  _getLocationDescription(location),
                  style: TextStyle(
                    fontFamily: themeController.currentFont,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onTap: () => onLocationSelected(location),
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
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

  String _getLocationDescription(String location) {
    switch (location.toLowerCase()) {
      case 'fridge':
        return 'Refrigerated items';
      case 'freezer':
        return 'Frozen items';
      case 'pantry':
        return 'Dry goods storage';
      case 'kitchen cabinet':
        return 'Cabinet storage';
      case 'spice rack':
        return 'Spices and seasonings';
      case 'countertop':
        return 'Room temperature items';
      default:
        return 'Storage location';
    }
  }
}