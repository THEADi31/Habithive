import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Service managing Firebase Authentication (Email & Password), user session,
/// and friendly error handling.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth? _authInstance;

  FirebaseAuth get _auth {
    _authInstance ??= FirebaseAuth.instance;
    return _authInstance!;
  }

  /// Stream of user authentication state changes.
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      debugPrint('[AuthService] authStateChanges fallback: $e');
      return Stream<User?>.value(null);
    }
  }

  /// Current signed-in user or null.
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Whether a user is currently signed in.
  bool get isSignedIn => currentUser != null;

  /// Sign in with email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await AnalyticsService.setUserId(credential.user!.uid);
        await AnalyticsService.logLogin(method: 'email');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Sign-in error: ${e.code} - ${e.message}');
      throw _parseAuthException(e);
    }
  }

  /// Register a new account with email and password.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      if (credential.user != null) {
        await AnalyticsService.setUserId(credential.user!.uid);
        await AnalyticsService.logSignUp(method: 'email');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] Sign-up error: ${e.code} - ${e.message}');
      throw _parseAuthException(e);
    }
  }

  /// Sign out current user.
  Future<void> signOut() async {
    try {
      await AnalyticsService.logLogout();
      await _auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] Sign-out error: $e');
    }
  }

  /// Translates Firebase auth codes into human-friendly messages.
  String _parseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'weak-password':
        return 'The password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network connection error. Check your internet.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

