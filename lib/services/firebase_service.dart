// services/firebase_service.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pantry_pal/firebase_options.dart'; // You'll need to generate this

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

  /// Initialize Firebase
  Future<bool> initializeFirebase() async {
    if (_isInitialized) return true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;

      _isInitialized = true;
      print('FirebaseService: Firebase initialized successfully');
      return true;
    } catch (e) {
      print('FirebaseService: Error initializing Firebase: $e');
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
    if (uid == null) throw Exception('User not logged in');
    return firestore.collection('users').doc(uid).collection('groceryLists');
  }

  /// Get a collection reference for the current user's recipes
  CollectionReference getUserRecipes() {
    if (uid == null) throw Exception('User not logged in');
    return firestore.collection('users').doc(uid).collection('recipes');
  }

  /// Get a collection reference for the current user's pantry items
  CollectionReference getUserPantryItems() {
    if (uid == null) throw Exception('User not logged in');
    return firestore.collection('users').doc(uid).collection('pantryItems');
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }
}

// Global instance for easy access
final firebaseService = FirebaseService();