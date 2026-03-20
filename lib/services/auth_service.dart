// ============================================================================
// AUTH SERVICE - Firebase Authentication
// NOTE: 'light' removed from default control states on signup —
//       no physical LED hardware in the system.
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService extends ChangeNotifier {
  // ============================================================================
  // PROPERTIES
  // ============================================================================

  // Firebase Auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Firebase Database instance
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Current user
  User? _user;
  User? get user => _user;

  // User info
  String get userName => _user?.displayName ?? 'User';
  String get userEmail => _user?.email ?? '';
  String get userId => _user?.uid ?? '';
  bool get isLoggedIn => _user != null;

  // ============================================================================
  // CONSTRUCTOR - Listen to auth state changes
  // ============================================================================

  AuthService() {
    // Listen to authentication state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // ============================================================================
  // SIGN UP - Create new account
  // ============================================================================

  Future<String?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Save user data to database
      await _database.child('users/${userCredential.user!.uid}').set({
        'name': name,
        'email': email,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      // Initialize default control states
      // 'light' removed — no physical LED hardware in the system
      await _database.child('controls/${userCredential.user!.uid}').set({
        'pump': false,
        'window': false,
      });

      _user = userCredential.user;
      notifyListeners();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      // Handle specific errors
      switch (e.code) {
        case 'weak-password':
          return 'Password is too weak';
        case 'email-already-in-use':
          return 'An account already exists for this email';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return 'Signup failed: ${e.message}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // ============================================================================
  // LOGIN - Sign in existing user
  // ============================================================================

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      // Sign in user
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential.user;
      notifyListeners();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      // Handle specific errors
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        default:
          return 'Login failed: ${e.message}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  // ============================================================================
  // LOGOUT - Sign out user
  // ============================================================================

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  // ============================================================================
  // RESET PASSWORD - Send password reset email
  // ============================================================================

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return 'Failed to send reset email: ${e.message}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }
}