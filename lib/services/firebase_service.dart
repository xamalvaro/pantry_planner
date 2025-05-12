// services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pantry_pal/firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// A service class to manage Firebase initialization and provide access to Firebase services
class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Flag to track initialization
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Firebase Auth instance
  FirebaseAuth? _auth;
  FirebaseAuth get auth {
    if (_auth == null) throw Exception('Firebase Auth not initialized');
    return _auth!;
  }

  // Firestore instance
  FirebaseFirestore? _firestore;
  FirebaseFirestore get firestore {
    if (_firestore == null) throw Exception('Firestore not initialized');
    return _firestore!;
  }

  // User stream for authentication state
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // Current user (may be null if not authenticated)
  User? get currentUser => auth.currentUser;

  // User ID getter with null safety
  String? get uid => currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Add this logging function
  void _logFirebase(String message) {
    print("FIREBASE: $message");
    try {
      FirebaseCrashlytics.instance.log("FIREBASE: $message");
    } catch (e) {
      // Ignore if Crashlytics isn't initialized
    }
  }

  /// Initialize Firebase
  Future<bool> initializeFirebase() async {
    if (_isInitialized) {
      _logFirebase("Firebase already initialized, returning");
      return true;
    }

    try {
      _logFirebase("Starting Firebase initialization");
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _logFirebase("Firebase.initializeApp() completed");

      _logFirebase("Setting up Firebase Auth");
      _auth = FirebaseAuth.instance;
      _logFirebase("Setting up Firestore");
      _firestore = FirebaseFirestore.instance;

      _isInitialized = true;
      _logFirebase("Firebase initialized successfully");
      return true;
    } catch (e, stack) {
      _logFirebase("Error initializing Firebase: $e");
      _logFirebase("Stack trace: ${stack.toString()}");

      try {
        FirebaseCrashlytics.instance.recordError(e, stack, reason: 'Firebase initialization failed');
      } catch (_) {}

      // Try to continue with partial initialization
      try {
        _logFirebase("Attempting to initialize Firebase Auth only");
        _auth = FirebaseAuth.instance;
        _logFirebase("Firebase Auth initialized");
      } catch (e2) {
        _logFirebase("Failed to initialize Firebase Auth: $e2");
      }

      return false;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    return await auth.signInWithEmailAndPassword(
        email: email,
        password: password
    );
  }

  /// Create a new user with email and password
  Future<UserCredential> createUserWithEmailPassword(String email, String password) async {
    return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await auth.signOut();
  }

  /// Get a document reference for the current user's data
  DocumentReference getUserDocument() {
    if (uid == null) throw Exception('User not logged in');
    return firestore.collection('users').doc(uid);
  }

  /// Get a collection reference for the current user's grocery lists
  CollectionReference getUserGroceryLists() {
    final uid = this.uid;
    if (uid == null) throw Exception('User not logged in');
    return firestore.collection('users').doc(uid).collection('groceryLists');
  }

  /// Get a collection reference for the current user's recipes
  CollectionReference getUserRecipes() {
    final uid = this.uid;
    if (uid == null) throw Exception('User not logged in');
    return firestore.collection('users').doc(uid).collection('recipes');
  }

  /// Get a collection reference for the current user's pantry items
  CollectionReference getUserPantryItems() {
    final uid = this.uid;
    if (uid == null) throw Exception('User not logged in');
    return firestore.collection('users').doc(uid).collection('pantryItems');
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  Future<bool> checkCurrentAuthState() async {
    final currentUser = auth.currentUser;
    print('Explicit Auth Check - User: $currentUser');
    return currentUser != null;
  }
  /// Flag to track if app is in guest mode
  bool _isGuestMode = false;

  /// Start guest mode (no Firebase auth)
  Future<bool> startGuestMode() async {
    try {
      _isGuestMode = true;
      print('FirebaseService: Started guest mode');
      return true;
    } catch (e) {
      print('FirebaseService: Error starting guest mode: $e');
      _isGuestMode = false;
      return false;
    }
  }

  /// Check if app is in guest mode
  bool get isGuestMode => _isGuestMode;

  /// End guest mode
  Future<void> endGuestMode() async {
    _isGuestMode = false;
    print('FirebaseService: Ended guest mode');
  }
}

// Global instance for easy access
final firebaseService = FirebaseService();