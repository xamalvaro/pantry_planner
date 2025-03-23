import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the theme controller
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Theme Toggle Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: themeController.currentFont,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Switch(
                        value: themeController.isDarkMode,
                        activeColor: Colors.blueAccent,
                        onChanged: (value) {
                          themeController.toggleTheme();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Font Selection Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Text',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Font Family',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    value: themeController.currentFont,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        themeController.setFont(newValue);
                      }
                    },
                    items: ThemeController.availableFonts
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: value,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // App Info Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: themeController.currentFont,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'PantryPal',
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontFamily: themeController.currentFont,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}