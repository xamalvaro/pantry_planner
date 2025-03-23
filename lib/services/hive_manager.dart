import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// A singleton class to manage Hive initialization and box access throughout the app
class HiveManager {
  static final HiveManager _instance = HiveManager._internal();
  factory HiveManager() => _instance;
  HiveManager._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Map to store opened boxes
  final Map<String, Box> _boxes = {};

  // Initialize Hive
  Future<bool> initializeHive() async {
    if (_isInitialized) return true;

    try {
      await Hive.initFlutter();
      _isInitialized = true;
      print('HiveManager: Hive initialized successfully');
      return true;
    } catch (e) {
      print('HiveManager: Error initializing Hive: $e');
      return false;
    }
  }

  // Get or open a box
  Future<Box?> openBox(String boxName) async {
    // Make sure Hive is initialized
    if (!_isInitialized) {
      final initSuccess = await initializeHive();
      if (!initSuccess) {
        print('HiveManager: Failed to initialize Hive when opening box $boxName');
        return null;
      }
    }

    // Return box if already opened and cached
    if (_boxes.containsKey(boxName)) {
      print('HiveManager: Returning cached box $boxName');
      return _boxes[boxName];
    }

    // Return box if already opened by Hive but not cached
    if (Hive.isBoxOpen(boxName)) {
      _boxes[boxName] = Hive.box(boxName);
      print('HiveManager: Box $boxName already open, adding to cache');
      return _boxes[boxName];
    }

    // Open the box
    try {
      final box = await Hive.openBox(boxName);
      _boxes[boxName] = box;
      print('HiveManager: Successfully opened box $boxName');
      return box;
    } catch (e) {
      print('HiveManager: Error opening box $boxName: $e');
      return null;
    }
  }

  // Get an already opened box or null
  Box? getOpenBox(String boxName) {
    if (_boxes.containsKey(boxName)) {
      return _boxes[boxName];
    }

    if (Hive.isBoxOpen(boxName)) {
      _boxes[boxName] = Hive.box(boxName);
      return _boxes[boxName];
    }

    return null;
  }

  // Close a specific box
  Future<void> closeBox(String boxName) async {
    if (_boxes.containsKey(boxName)) {
      await _boxes[boxName]!.close();
      _boxes.remove(boxName);
      print('HiveManager: Closed box $boxName');
    } else if (Hive.isBoxOpen(boxName)) {
      await Hive.box(boxName).close();
      print('HiveManager: Closed box $boxName (not in cache)');
    }
  }

  // Close all boxes
  Future<void> closeAllBoxes() async {
    try {
      await Hive.close();
      _boxes.clear();
      print('HiveManager: Closed all boxes');
    } catch (e) {
      print('HiveManager: Error closing all boxes: $e');
    }
  }
}

// Global instance for easy access
final hiveManager = HiveManager();