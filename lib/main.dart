// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pantry_pal/app/app.dart';
import 'package:pantry_pal/services/hive_manager.dart';
import 'package:pantry_pal/services/app_initializer.dart';

void main() async {
  // Catch Flutter initialization errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      // In release mode, log to a service like Firebase Crashlytics
      // FirebaseCrashlytics.instance.recordFlutterError(details);
    }
  };

  // Do minimal initialization
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive using our manager
  final initialized = await hiveManager.initializeHive();
  if (!initialized) {
    print('Failed to initialize Hive, app may not function correctly');
  }

  // First, show the app with a splash screen
  runApp(MyApp(isInitialized: false));

  // After app is visible, initialize remaining services
  WidgetsBinding.instance.addPostFrameCallback((_) {
    AppInitializer.initializeApp();
  });
}