import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  final bool showProgress;

  const SplashScreen({Key? key, this.showProgress = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              SizedBox(
                width: 120,
                height: 120,
                child: Hero(
                  tag: 'app_logo',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.kitchen,
                      size: 64,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // App name
              Text(
                'PantryPal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),

              SizedBox(height: 8),

              // Tagline
              Text(
                'Your kitchen companion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),

              SizedBox(height: 48),

              // Loading indicator
              if (showProgress) ...[
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      // Linear progress indicator for better UX
                      LinearProgressIndicator(
                        backgroundColor: Colors.blue.shade100,
                        color: Colors.blueAccent,
                      ),

                      SizedBox(height: 16),

                      Text(
                        'Loading your data...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark version of the splash screen that respects system theme
class DarkSplashScreen extends StatelessWidget {
  final bool showProgress;

  const DarkSplashScreen({Key? key, this.showProgress = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              SizedBox(
                width: 120,
                height: 120,
                child: Hero(
                  tag: 'app_logo',
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(16),
                    child: Icon(
                      Icons.kitchen,
                      size: 64,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 32),

              // App name
              Text(
                'PantryPal',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),

              SizedBox(height: 8),

              // Tagline
              Text(
                'Your kitchen companion',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                ),
              ),

              SizedBox(height: 48),

              // Loading indicator
              if (showProgress) ...[
                SizedBox(
                  width: 200,
                  child: Column(
                    children: [
                      // Linear progress indicator for better UX
                      LinearProgressIndicator(
                        backgroundColor: Colors.grey.shade800,
                        color: Colors.blueAccent,
                      ),

                      SizedBox(height: 16),

                      Text(
                        'Loading your data...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Theme-aware splash screen that automatically switches between light and dark
class AdaptiveSplashScreen extends StatelessWidget {
  final bool showProgress;

  const AdaptiveSplashScreen({Key? key, this.showProgress = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    if (isDarkMode) {
      return DarkSplashScreen(showProgress: showProgress);
    } else {
      return SplashScreen(showProgress: showProgress);
    }
  }
}