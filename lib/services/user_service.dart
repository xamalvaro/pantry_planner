// services/user_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pantry_pal/services/firebase_service.dart';

/// User model to store user data
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.preferences,
  });

  // Create from Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  // Create from Firestore Document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      preferences: data['preferences'],
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'preferences': preferences,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: this.uid,
      email: this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      preferences: preferences ?? this.preferences,
    );
  }
}

/// Service to manage user data and authentication
class UserService {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Reference to Firebase service
  final FirebaseService _firebase = firebaseService;

  // Current user data
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Stream of user data
  Stream<UserModel?> getUserStream() {
    if (!_firebase.isLoggedIn) return Stream.value(null);

    return _firebase.getUserDocument().snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromDocument(snapshot);
      }
      return null;
    });
  }

  /// Sign in with email and password
  Future<UserModel?> signIn(String email, String password) async {
    try {
      final userCredential = await _firebase.signInWithEmailPassword(email, password);
      final user = userCredential.user;

      if (user != null) {
        // Get user data from Firestore
        final docSnapshot = await _firebase.getUserDocument().get();

        if (docSnapshot.exists) {
          _currentUser = UserModel.fromDocument(docSnapshot);
        } else {
          // Create user profile if it doesn't exist
          _currentUser = UserModel.fromFirebaseUser(user);
          await _saveUserToFirestore(_currentUser!);
        }

        return _currentUser;
      }
      return null;
    } catch (e) {
      print('UserService: Error signing in: $e');
      rethrow;
    }
  }

  /// Create a new user account and sign in
  Future<UserModel?> register(String email, String password, String displayName) async {
    try {
      final userCredential = await _firebase.createUserWithEmailPassword(email, password);
      final user = userCredential.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create user profile
        _currentUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
        );

        // Save to Firestore
        await _saveUserToFirestore(_currentUser!);

        return _currentUser;
      }
      return null;
    } catch (e) {
      print('UserService: Error registering: $e');
      rethrow;
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _firebase.signOut();
      _currentUser = null;
    } catch (e) {
      print('UserService: Error signing out: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<UserModel?> updateProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      if (!_firebase.isLoggedIn || _currentUser == null)
        throw Exception('Not logged in');

      // Update Firebase Auth display name if provided
      if (displayName != null) {
        await _firebase.auth.currentUser!.updateDisplayName(displayName);
      }

      // Update profile photo URL if provided
      if (photoURL != null) {
        await _firebase.auth.currentUser!.updatePhotoURL(photoURL);
      }

      // Update user model
      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        photoURL: photoURL,
        preferences: preferences,
      );

      // Save to Firestore
      await _saveUserToFirestore(updatedUser);

      _currentUser = updatedUser;
      return _currentUser;
    } catch (e) {
      print('UserService: Error updating profile: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebase.resetPassword(email);
    } catch (e) {
      print('UserService: Error resetting password: $e');
      rethrow;
    }
  }

  /// Save user data to Firestore
  Future<void> _saveUserToFirestore(UserModel user) async {
    await _firebase.getUserDocument().set(
      user.toMap(),
      SetOptions(merge: true),
    );
  }

  /// Check if a user is currently authenticated
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebase.currentUser;
    if (firebaseUser == null) return null;

    try {
      final docSnapshot = await _firebase.getUserDocument().get();

      if (docSnapshot.exists) {
        _currentUser = UserModel.fromDocument(docSnapshot);
      } else {
        // Create user document if it doesn't exist
        _currentUser = UserModel.fromFirebaseUser(firebaseUser);
        await _saveUserToFirestore(_currentUser!);
      }

      return _currentUser;
    } catch (e) {
      print('UserService: Error getting current user: $e');
      return null;
    }
  }
  /// Sign in as guest (local only)
  Future<UserModel?> signInAsGuest() async {
    try {
      // Start guest mode in Firebase service
      await _firebase.startGuestMode();

      // Create a basic guest user model (only stored locally)
      _currentUser = UserModel(
        uid: 'guest-${DateTime.now().millisecondsSinceEpoch}',
        email: 'guest@local',
        displayName: 'Guest User',
      );

      return _currentUser;
    } catch (e) {
      print('UserService: Error signing in as guest: $e');
      return null;
    }
  }
}

// Global instance
final userService = UserService();