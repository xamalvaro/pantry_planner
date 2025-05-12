// services/app_initializer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/services/hive_manager.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/firebase_initializer.dart';
import 'package:pantry_pal/services/firebase_expiry_service.dart';
import 'package:pantry_pal/services/user_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../expiry/expiry_service.dart';

// Add this logging function
void _logInit(String message) {
  print("INIT: $message");
  try {
    FirebaseCrashlytics.instance.log("INIT: $message");
  } catch (e) {
    // Ignore if Crashlytics isn't initialized
  }
}

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
      _logInit("Starting initializeApp()");

      // Stage 1: Initialize Hive for settings
      _logInit("Stage 1: Initializing Hive");
      Box? settingsBox;
      final hiveInitialized = await hiveManager.initializeHive();
      _logInit("Hive initialized: $hiveInitialized");

      if (hiveInitialized) {
        // Open essential box
        _logInit("Opening settings box");
        settingsBox = await hiveManager.openBox('settings');
        _logInit("Settings box opened: ${settingsBox != null}");

        if (settingsBox != null) {
          AppInitializer.settingsReady(settingsBox);
          _logInit("Settings ready notification sent");
        } else {
          _logInit("Warning: settingsBox is null, cannot notify app");
        }
      } else {
        _logInit("Warning: Hive initialization failed");
      }

      // Stage 2: Initialize Firebase
      _logInit("Stage 2: Initializing Firebase");
      bool firebaseInitialized = false;
      try {
        firebaseInitialized = await firebaseService.initializeFirebase();
        _logInit("Firebase initialized: $firebaseInitialized");
        if (firebaseInitialized) {
          AppInitializer.firebaseReady();
          _logInit("Firebase ready notification sent");
        }
      } catch (e) {
        _logInit("Firebase initialization error: $e");
        // Continue with local storage only if Firebase fails
        firebaseInitialized = false;
      }

      // Continue with initialization even if Firebase fails
      _logInit("Sending auth ready notification");
      AppInitializer.authReady();
      _logInit("Auth ready notification sent");

      // Complete initialization regardless of Firebase status
      _logInit("Sending all services ready notification");
      AppInitializer.allServicesReady();
      _logInit("All services ready notification sent");

      _logInit("App initialization completed successfully");
    } catch (e, stack) {
      _logInit("Error during app initialization: $e");
      _logInit("Stack trace: ${stack.toString()}");

      try {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'App initialization failed');
      } catch (_) {}

      // Signal completion even on error to prevent app from hanging
      AppInitializer.allServicesReady();

      throw e; // Rethrow to maintain existing behavior
    }
  }
}