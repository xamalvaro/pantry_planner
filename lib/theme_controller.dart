import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeController extends ChangeNotifier {
  // Box to store settings
  final Box settingsBox;

  // Available font options
  static const List<String> availableFonts = [
    'Roboto', // Default
    'OpenSans',
    'Lato',
    'Montserrat',
    'Poppins',
  ];

  ThemeController({required this.settingsBox}) {
    // Initialize with stored values or defaults
    _isDarkMode = settingsBox.get('isDarkMode', defaultValue: false);
    _currentFont = settingsBox.get('fontFamily', defaultValue: 'Roboto');
  }

  // Dark mode state
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Font selection
  String _currentFont = 'Roboto';
  String get currentFont => _currentFont;

  // Toggle theme mode
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    settingsBox.put('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  // Set font
  void setFont(String fontFamily) {
    if (availableFonts.contains(fontFamily)) {
      _currentFont = fontFamily;
      settingsBox.put('fontFamily', fontFamily);
      notifyListeners();
    }
  }

  // Get the current theme data
  ThemeData getTheme() {
    return _isDarkMode ? _getDarkTheme() : _getLightTheme();
  }

  // Helper to get the right Google Font
  TextStyle _getGoogleFont({
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    switch (_currentFont) {
      case 'OpenSans':
        return GoogleFonts.openSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      case 'Lato':
        return GoogleFonts.lato(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      case 'Montserrat':
        return GoogleFonts.montserrat(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      case 'Poppins':
        return GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
      case 'Roboto':
      default:
        return GoogleFonts.roboto(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        );
    }
  }

  // Apply font to entire text theme
  TextTheme _getTextTheme(TextTheme baseTheme) {
    return TextTheme(
      displayLarge: _getGoogleFont(fontSize: 96, fontWeight: FontWeight.w300),
      displayMedium: _getGoogleFont(fontSize: 60, fontWeight: FontWeight.w400),
      displaySmall: _getGoogleFont(fontSize: 48, fontWeight: FontWeight.w400),
      headlineLarge: _getGoogleFont(fontSize: 40, fontWeight: FontWeight.w500),
      headlineMedium: _getGoogleFont(fontSize: 34, fontWeight: FontWeight.w400),
      headlineSmall: _getGoogleFont(fontSize: 24, fontWeight: FontWeight.w400),
      titleLarge: _getGoogleFont(fontSize: 20, fontWeight: FontWeight.w500),
      titleMedium: _getGoogleFont(fontSize: 16, fontWeight: FontWeight.w400),
      titleSmall: _getGoogleFont(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: _getGoogleFont(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: _getGoogleFont(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: _getGoogleFont(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: _getGoogleFont(fontSize: 14, fontWeight: FontWeight.w500),
      labelMedium: _getGoogleFont(fontSize: 12, fontWeight: FontWeight.w400),
      labelSmall: _getGoogleFont(fontSize: 10, fontWeight: FontWeight.w400),
    );
  }

  // Light theme
  ThemeData _getLightTheme() {
    final baseTheme = ThemeData.light();
    final colorScheme = ColorScheme.light(
      primary: Colors.blueAccent,
      onPrimary: Colors.white,
      secondary: Colors.blueAccent,
      onSecondary: Colors.white,
    );

    return baseTheme.copyWith(
      brightness: Brightness.light,
      primaryColor: Colors.blueAccent,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      canvasColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.blueGrey,
      ),
      textTheme: _getTextTheme(baseTheme.textTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      colorScheme: colorScheme,
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.black87),
        hintStyle: TextStyle(color: Colors.black54),
        suffixIconColor: Colors.black87,
        iconColor: Colors.black87,
        prefixIconColor: Colors.black87,
      ),
    );
  }

  // Dark theme
  ThemeData _getDarkTheme() {
    final baseTheme = ThemeData.dark();
    final colorScheme = ColorScheme.dark(
      primary: Colors.blueAccent,
      onPrimary: Colors.white,
      secondary: Colors.blueAccent,
      onSecondary: Colors.white,
      surface: Colors.grey[850]!,
    );

    return baseTheme.copyWith(
      brightness: Brightness.dark,
      primaryColor: Colors.blueAccent,
      scaffoldBackgroundColor: Colors.grey[900],
      cardColor: Colors.grey[850],
      canvasColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: Colors.grey[800],
        labelStyle: TextStyle(color: Colors.grey[300]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      textTheme: _getTextTheme(baseTheme.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: colorScheme,
    );
  }
}