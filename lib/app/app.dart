// app/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pantry_pal/theme_controller.dart';
import 'package:pantry_pal/app/home_page.dart';
import 'package:pantry_pal/calendar/calendar_page.dart';
import 'package:pantry_pal/splash_screen.dart';
import 'package:pantry_pal/services/app_initializer.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/auth/auth_wrapper.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MyApp extends StatefulWidget {
  final bool isInitialized;

  const MyApp({Key? key, this.isInitialized = false}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _settingsLoaded = false;
  bool _firebaseLoaded = false;
  bool _allServicesLoaded = false;
  Box? _settingsBox;

  @override
  void initState() {
    super.initState();

    // Listen for settings to be ready
    AppInitializer.onSettingsReady.listen((box) {
      print('Settings box received in MyApp');
      setState(() {
        _settingsBox = box;
        _settingsLoaded = true;
      });
    });

    // Listen for Firebase to be ready
    AppInitializer.onFirebaseReady.listen((_) {
      print('Firebase ready notification received in MyApp');
      setState(() {
        _firebaseLoaded = true;
      });
    });

    // Listen for all services to be ready
    AppInitializer.onAllServicesReady.listen((_) {
      print('All services ready notification received in MyApp');
      setState(() {
        _allServicesLoaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // If settings aren't loaded yet, show minimal app with splash screen
    if (!_settingsLoaded) {
      print('Showing splash screen - settings not loaded yet');
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PantryPal',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
        ),
        home: SplashScreen(),
      );
    }

    // Once settings are loaded, we can use ThemeController
    print('Settings loaded, using ThemeController');
    return ChangeNotifierProvider(
      create: (context) => ThemeController(
        settingsBox: _settingsBox!,
      ),
      child: Consumer<ThemeController>(
        builder: (context, themeController, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'PantryPal',
            theme: themeController.getTheme(),
            home: DeepLinkHandler(
              child: AuthWrapper(isInitialized: _firebaseLoaded && _settingsLoaded),
            ),
            routes: {
              '/calendar': (context) => CalendarPage(),
            },
          );
        },
      ),
    );
  }
}