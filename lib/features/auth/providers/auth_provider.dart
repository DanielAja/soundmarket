import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/auth_result.dart';
import '../services/auth_service.dart';

/// Provider for managing authentication state
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  StreamSubscription<User?>? _authStateSubscription;

  // Getters that delegate to AuthService
  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool get isInitialized => _authService.isInitialized;
  bool get isLoading => _authService.isLoading;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Listen to auth state changes
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      notifyListeners();
    });

    // Listen to loading state changes
    _authService.addListener(_onAuthServiceChange);

    // Initialize the auth service
    await _authService.initialize();
  }

  void _onAuthServiceChange() {
    notifyListeners();
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String displayName,
    required String password,
  }) async {
    return await _authService.signUpWithEmailAndPassword(
      email: email,
      displayName: displayName,
      password: password,
    );
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    return await _authService.sendEmailVerification();
  }

  /// Verify email with code
  Future<AuthResult> verifyEmail(String verificationCode) async {
    return await _authService.verifyEmail(verificationCode);
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    return await _authService.resetPassword(email);
  }

  /// Update user profile
  Future<AuthResult> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    return await _authService.updateUserProfile(
      displayName: displayName,
      avatarUrl: avatarUrl,
    );
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Delete user account
  Future<bool> deleteAccount(String password) async {
    return await _authService.deleteAccount(password);
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _authService.removeListener(_onAuthServiceChange);
    super.dispose();
  }
}
