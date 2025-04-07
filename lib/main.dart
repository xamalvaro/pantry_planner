// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pantry_pal/app/app.dart';
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

  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // First, run the app with initialization flag
  runApp(MyApp(isInitialized: false));

  // After app is visible, initialize services
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Start initialization
    AppInitializer.initializeApp();

    // Add a timeout to prevent app from getting stuck
    Future.delayed(Duration(seconds: 5), () {
      // If app is still not initialized after 5 seconds, force it to continue
      AppInitializer.allServicesReady();
    });
  });
}