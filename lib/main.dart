// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pantry_pal/app/app.dart';
import 'package:pantry_pal/services/app_initializer.dart';
import 'package:pantry_pal/services/firebase_sync_service.dart';
import 'package:pantry_pal/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:pantry_pal/firebase_options.dart';

// Simple global log collection to ensure we capture everything
List<String> _debugLogs = [];
void _logDebug(String message) {
  final timestamp = DateTime.now().toString();
  final entry = "$timestamp: $message";
  _debugLogs.add(entry);
  print("DEBUG: $entry");

  // Keep last 200 logs
  if (_debugLogs.length > 200) {
    _debugLogs.removeAt(0);
  }
}

void main() async {
  _logDebug("Application starting");

  // Ensure Flutter binding is initialized first
  WidgetsFlutterBinding.ensureInitialized();
  _logDebug("Flutter binding initialized");

  // Flag to control forced initialization
  bool initCompleted = false;

  // Catch Flutter initialization errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logDebug("FLUTTER ERROR: ${details.exception}");
    _logDebug("STACK TRACE: ${details.stack}");
  };

  try {
    // Initialize Firebase Core first
    _logDebug("Initializing Firebase Core");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _logDebug("Firebase Core initialized successfully");

    // Enable Crashlytics (fixed - doesn't return a boolean)
    _logDebug("Enabling Crashlytics collection");
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    _logDebug("Crashlytics collection enabled");

    // Send initial startup log
    FirebaseCrashlytics.instance.log("App startup initiated");

  } catch (e, stack) {
    _logDebug("Firebase initialization error: $e");
    _logDebug("Stack trace: $stack");
    // Continue without Firebase
  }

  try {
    // Initialize notifications
    _logDebug("Initializing notification service");
    await NotificationService().initialize();
    _logDebug("Notification service initialized successfully");
  } catch (e, stack) {
    _logDebug("Notification initialization error: $e");
    _logDebug("Stack trace: $stack");
    // Continue even if notifications fail
  }

  // First, run the app with initialization flag
  _logDebug("Rendering initial app UI");
  runApp(MyApp(isInitialized: false));

  // After app is visible, initialize services with timeouts and fallbacks
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    _logDebug("Starting post-frame initialization");

    // Start a timeout to force completion
    Future.delayed(Duration(seconds: 10), () {
      if (!initCompleted) {
        _logDebug("TIMEOUT: Forcing initialization completion after 10 seconds");
        try {
          AppInitializer.allServicesReady();
          FirebaseCrashlytics.instance.log("Initialization was forced by timeout");
        } catch (e) {
          _logDebug("Error during forced initialization: $e");
        }
      }
    });

    try {
      // Initialize app services
      _logDebug("Starting AppInitializer.initializeApp()");
      await AppInitializer.initializeApp();
      _logDebug("AppInitializer.initializeApp() completed successfully");

      try {
        // Initialize Firebase Sync Service
        _logDebug("Starting firebaseSyncService.initialize()");
        await firebaseSyncService.initialize();
        _logDebug("firebaseSyncService.initialize() completed successfully");
      } catch (e, stack) {
        _logDebug("Firebase Sync Service initialization error: $e");
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Firebase Sync initialization failed');
      }

      // Mark initialization as complete
      initCompleted = true;
      _logDebug("All initialization completed successfully");

    } catch (e, stack) {
      _logDebug("App initialization error: $e");
      _logDebug("Stack trace: $stack");

      try {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'App initialization failed');
      } catch (e2) {
        _logDebug("Failed to record error to Crashlytics: $e2");
      }

      // Force completion to get user out of splash screen
      _logDebug("Forcing AppInitializer.allServicesReady() after error");
      AppInitializer.allServicesReady();
    }

    // Record logs to Crashlytics
    FirebaseCrashlytics.instance.log("DEBUG LOGS: ${_debugLogs.join(' | ')}");
  });
}