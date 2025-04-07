// services/firebase_initializer.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pantry_pal/services/firebase_service.dart';
import 'package:pantry_pal/services/firebase_expiry_service.dart';
import 'package:pantry_pal/services/user_service.dart';

/// Class to manage Firebase initialization process
class FirebaseInitializer {
  // Stream controllers for different initialization stages
  static final _firebaseReadyController = StreamController<bool>.broadcast();
  static final _authReadyController = StreamController<bool>.broadcast();
  static final _allServicesReadyController = StreamController<bool>.broadcast();

  // Streams to listen to
  static Stream<bool> get onFirebaseReady => _firebaseReadyController.stream;
  static Stream<bool> get onAuthReady => _authReadyController.stream;
  static Stream<bool> get onAllServicesReady => _allServicesReadyController.stream;

  // Methods to update status
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
    _firebaseReadyController.close();
    _authReadyController.close();
    _allServicesReadyController.close();
  }

  /// Initialize Firebase in stages
  static Future<void> initializeFirebase() async {
    try {
      // Stage 1: Initialize Firebase core
      final firebaseInitialized = await firebaseService.initializeFirebase();

      if (firebaseInitialized) {
        FirebaseInitializer.firebaseReady();
        print('Firebase ready notification sent');
      } else {
        print('Warning: Firebase initialization failed');
        return;
      }

      // Stage 2: Check authentication state
      final user = await userService.getCurrentUser();
      FirebaseInitializer.authReady();
      print('Auth ready notification sent');

      // Stage 3: Initialize remaining services with delay
      // This delay gives the UI time to render smoothly
      Future.delayed(Duration(milliseconds: 300), () async {
        try {
          // Initialize the expiry service
          try {
            await firebaseExpiryService.init();
            print('Expiry service initialized');
          } catch (e) {
            print('Error initializing expiry service: $e');
          }

          // Notify app that everything is ready
          FirebaseInitializer.allServicesReady();
          print('All services ready notification sent');

        } catch (e) {
          print('Error initializing remaining services: $e');
        }
      });
    } catch (e) {
      print('Error during Firebase initialization: $e');
    }
  }
}