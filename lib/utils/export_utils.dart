import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ExportUtils {
  // Share as formatted text
  static Future<void> shareAsText(String listName, Map<String, List<String>> categories, List<String> tags) async {
    final StringBuffer buffer = StringBuffer();

    // Add title
    buffer.writeln('📝 ${listName.toUpperCase()} 📝');
    buffer.writeln();

    // Add tags
    if (tags.isNotEmpty) {
      buffer.write('Tags: ');
      buffer.writeln(tags.map((tag) => '#$tag').join(' '));
      buffer.writeln();
    }

    // Add categories and items
    for (final entry in categories.entries) {
      if (entry.value.isEmpty) continue;

      buffer.writeln('📋 ${entry.key.toUpperCase()}:');
      for (final item in entry.value) {
        buffer.writeln('  • $item');
      }
      buffer.writeln();
    }

    buffer.writeln('Created with PantryPlanner app');

    try {
      // Share the text
      await Share.share(
        buffer.toString(),
        subject: 'PantryPal: $listName',
      );
    } catch (e) {
      print('Error sharing list as text: $e');
    }
  }

  // Method to show export options (now just text)
  static void showExportOptions(BuildContext context, String listName, Map<String, List<String>> categories, List<String> tags) {
    // Directly share as text without showing options
    shareAsText(listName, categories, tags);
  }
}