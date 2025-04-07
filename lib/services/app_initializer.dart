// services/app_initializer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/services/hive_manager.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/firebase_initializer.dart';
import 'package:pantry_pal/services/firebase_expiry_service.dart';
import 'package:pantry_pal/services/user_service.dart';

import '../expiry/expiry_service.dart';

/// Class to manage app initialization process
class AppInitializer {
  // Stream controllers for different initialization stages
  static final _settingsReadyController = StreamController<Box>.broadcast();
  static final _firebaseReadyController = StreamController<bool>.broadcast();
  static final _authReadyController = StreamController<bool>.broadcast();
  static final _allServicesReadyController = StreamController<bool>.broadcast();

  // Streams to listen to
  static Stream<Box> get onSettingsReady => _settingsReadyController.stream;
  static Stream<bool> get onFirebaseReady => _firebaseReadyController.stream;
  static Stream<bool> get onAuthReady => _authReadyController.stream;
  static Stream<bool> get onAllServicesReady => _allServicesReadyController.stream;

  // Methods to update status
  static void settingsReady(Box settingsBox) {
    _settingsReadyController.add(settingsBox);
  }

  static void firebaseReady() {
    _firebaseReadyController.add(true);
  }

  static void authReady() {
    _authReadyController.add(true);
  }

  static void allServicesReady() {
    _allServicesReadyController.add(true);
  }

  // Cleanup
  static void dispose() {
    _settingsReadyController.close();
    _firebaseReadyController.close();
    _authReadyController.close();
    _allServicesReadyController.close();
  }

  /// Initialize the app in stages
  static Future<void> initializeApp() async {
    try {
      // Stage 1: Initialize Hive for settings
      Box? settingsBox;
      final hiveInitialized = await hiveManager.initializeHive();

      if (hiveInitialized) {
        // Open essential box
        settingsBox = await hiveManager.openBox('settings');

        if (settingsBox != null) {
          AppInitializer.settingsReady(settingsBox);
          print('Settings ready notification sent');
        } else {
          print('Warning: settingsBox is null, cannot notify app');
        }
      } else {
        print('Warning: Hive initialization failed');
      }

      // Stage 2: Initialize Firebase
      bool firebaseInitialized = false;
      try {
        firebaseInitialized = await firebaseService.initializeFirebase();
        if (firebaseInitialized) {
          AppInitializer.firebaseReady();
          print('Firebase ready notification sent');
        }
      } catch (e) {
        print('Firebase initialization error: $e');
        // Continue with local storage only if Firebase fails
        firebaseInitialized = false;
      }

      // Continue with initialization even if Firebase fails
      AppInitializer.authReady();
      print('Auth ready notification sent');

      // Complete initialization regardless of Firebase status
      AppInitializer.allServicesReady();
      print('All services ready notification sent');
    } catch (e) {
      print('Error during app initialization: $e');
      // Signal completion even on error to prevent app from hanging
      AppInitializer.allServicesReady();
    }
  }
}