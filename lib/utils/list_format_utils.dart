// utils/list_format_utils.dart

/// Utility functions for formatting grocery list data
class ListFormatUtils {
  /// Convert data to display format with quantity
  static Map<String, List<dynamic>> convertToDisplayFormat(dynamic data) {
    try {
      if (data is Map) {
        final result = <String, List<dynamic>>{};

        data.forEach((key, value) {
          final categoryKey = key.toString();
          result[categoryKey] = [];

          if (value is List) {
            for (final item in value) {
              if (item is Map) {
                result[categoryKey]!.add(item);
              } else {
                result[categoryKey]!.add({
                  'name': item.toString(),
                  'quantity': '1'
                });
              }
            }
          }
        });

        return result;
      }
      return {};
    } catch (e) {
      print('Error converting data to display format: $e');
      return {};
    }
  }

  /// Filter list keys based on search query and tag
  static List<String> getFilteredKeys(
      dynamic box,
      String searchQuery,
      String? selectedTag
      ) {
    try {
      final keys = box.keys.toList();
      return keys.where((key) {
        try {
          final listData = box.get(key);
          if (listData == null) return false;

          final tags = listData['tags'] as List<dynamic>? ?? [];
          final matchesSearch = key.toString().toLowerCase().contains(searchQuery.toLowerCase());
          final matchesTag = selectedTag == null || tags.contains(selectedTag);
          return matchesSearch && matchesTag;
        } catch (e) {
          print('Error filtering key $key: $e');
          return false;
        }
      }).cast<String>().toList();
    } catch (e) {
      print('Error getting filtered keys: $e');
      return [];
    }
  }

  /// Get all unique tags from all lists
  static List<String> getAllTags(dynamic box) {
    try {
      if (box == null) return [];

      final keys = box.keys.toList();
      final Set<String> tags = {};
      for (final key in keys) {
        try {
          final listData = box.get(key);
          if (listData != null) {
            final listTags = listData['tags'] as List<dynamic>? ?? [];
            for (var tag in listTags) {
              tags.add(tag.toString());
            }
          }
        } catch (e) {
          print('Error getting tags from list $key: $e');
        }
      }
      return tags.toList();
    } catch (e) {
      print('Error getting all tags: $e');
      return [];
    }
  }
}