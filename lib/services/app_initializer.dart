// services/app_initializer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/services/hive_manager.dart';
import 'package:pantry_pal/expiry/expiry_service.dart';

/// Class to manage app initialization process
class AppInitializer {
  // Stream controllers for different initialization stages
  static final _settingsReadyController = StreamController<Box>.broadcast();
  static final _allServicesReadyController = StreamController<bool>.broadcast();

  // Streams to listen to
  static Stream<Box> get onSettingsReady => _settingsReadyController.stream;
  static Stream<bool> get onAllServicesReady => _allServicesReadyController.stream;

  // Methods to update status
  static void settingsReady(Box settingsBox) {
    _settingsReadyController.add(settingsBox);
  }

  static void allServicesReady() {
    _allServicesReadyController.add(true);
  }

  // Cleanup
  static void dispose() {
    _settingsReadyController.close();
    _allServicesReadyController.close();
  }

  /// Initialize the app in stages
  static Future<void> initializeApp() async {
    try {
      // Stage 1: Open essential box
      Box? settingsBox;

      // Use our manager to open the settings box
      settingsBox = await hiveManager.openBox('settings');

      if (settingsBox != null) {
        AppInitializer.settingsReady(settingsBox);
        print('Settings ready notification sent');
      } else {
        print('Warning: settingsBox is null, cannot notify app');
      }

      // Stage 2: Background initialize remaining boxes with delay
      // This delay gives the UI time to render smoothly
      Future.delayed(Duration(milliseconds: 300), () async {
        try {
          // Open remaining boxes through our manager
          await hiveManager.openBox('groceryLists');
          await hiveManager.openBox('recipes');
          await hiveManager.openBox('pantryItems');

          // Initialize the expiry service
          try {
            final expiryService = ExpiryService();
            await expiryService.init();
            print('Expiry service initialized');
          } catch (e) {
            print('Error initializing expiry service: $e');
          }

          // Notify app that everything is ready
          AppInitializer.allServicesReady();
          print('All services ready notification sent');

        } catch (e) {
          print('Error initializing remaining services: $e');
        }
      });
    } catch (e) {
      print('Error during app initialization: $e');
    }
  }
}