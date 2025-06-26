import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth_result.dart';

/// Authentication service for managing user authentication
class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isInitialized = false;
  bool _isLoading = false;
  Timer? _sessionTimer;

  // Stream controller for auth state changes
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Session timeout (24 hours)
  static const Duration _sessionTimeout = Duration(hours: 24);

  /// Initialize the auth service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadUserFromStorage();
      _startSessionTimer();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
    }
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String displayName,
    required String password,
  }) async {
    try {
      _setLoading(true);

      // Validate inputs
      final validationError = _validateSignUpInputs(
        email,
        displayName,
        password,
      );
      if (validationError != null) {
        return AuthResult.error(validationError);
      }

      // Check if email is already in use (simulated)
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        return AuthResult.error(
          'Email address is already in use',
          code: 'email-already-in-use',
        );
      }

      // Create new user
      final user = User(
        id: _generateUserId(),
        email: email.toLowerCase().trim(),
        displayName: displayName.trim(),
        isEmailVerified: false,
        createdAt: DateTime.now(),
        metadata: {'password': _hashPassword(password)},
      );

      // Save user to storage
      await _saveUserToStorage(user);

      // Send verification email (simulated)
      await _sendVerificationEmail(user);

      return AuthResult.verificationRequired(user);
    } catch (e) {
      return AuthResult.error('Sign up failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);

      // Validate inputs
      if (email.isEmpty || password.isEmpty) {
        return AuthResult.error('Email and password are required');
      }

      // Get user by email
      final user = await _getUserByEmail(email.toLowerCase().trim());
      if (user == null) {
        return AuthResult.error(
          'No user found with this email',
          code: 'user-not-found',
        );
      }

      // Verify password
      final storedPasswordHash = user.metadata?['password'] as String?;
      if (storedPasswordHash == null ||
          !_verifyPassword(password, storedPasswordHash)) {
        return AuthResult.error('Incorrect password', code: 'wrong-password');
      }

      // Check if email is verified
      if (!user.isEmailVerified) {
        return AuthResult.verificationRequired(user);
      }

      // Update last login
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _saveUserToStorage(updatedUser);

      // Set current user
      await _setCurrentUser(updatedUser);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error('Sign in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);

      // Clear current user
      await _setCurrentUser(null);

      // Clear stored session
      await _clearUserSession();

      _stopSessionTimer();
    } catch (e) {
      debugPrint('Error signing out: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      if (_currentUser == null || _currentUser!.isEmailVerified) {
        return false;
      }

      await _sendVerificationEmail(_currentUser!);
      return true;
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      return false;
    }
  }

  /// Verify email with code (simulated)
  Future<AuthResult> verifyEmail(String verificationCode) async {
    try {
      _setLoading(true);

      if (_currentUser == null) {
        return AuthResult.error('No user to verify');
      }

      // Simulate verification (in real app, this would be validated server-side)
      if (verificationCode.length != 6 ||
          !RegExp(r'^\d{6}$').hasMatch(verificationCode)) {
        return AuthResult.error('Invalid verification code');
      }

      // Update user as verified
      final verifiedUser = _currentUser!.copyWith(isEmailVerified: true);
      await _saveUserToStorage(verifiedUser);
      await _setCurrentUser(verifiedUser);

      return AuthResult.success(verifiedUser);
    } catch (e) {
      return AuthResult.error('Email verification failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      final user = await _getUserByEmail(email.toLowerCase().trim());
      if (user == null) {
        return false; // Don't reveal if email exists
      }

      // Send reset email (simulated)
      await _sendPasswordResetEmail(user);
      return true;
    } catch (e) {
      debugPrint('Error sending password reset: $e');
      return false;
    }
  }

  /// Update user profile
  Future<AuthResult> updateUserProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.error('No authenticated user');
      }

      final updatedUser = _currentUser!.copyWith(
        displayName: displayName,
        avatarUrl: avatarUrl,
      );

      await _saveUserToStorage(updatedUser);
      await _setCurrentUser(updatedUser);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error('Profile update failed: ${e.toString()}');
    }
  }

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) {
        return AuthResult.error('No authenticated user');
      }

      // Verify current password
      final storedPasswordHash = _currentUser!.metadata?['password'] as String?;
      if (storedPasswordHash == null ||
          !_verifyPassword(currentPassword, storedPasswordHash)) {
        return AuthResult.error('Current password is incorrect');
      }

      // Validate new password
      final passwordError = _validatePassword(newPassword);
      if (passwordError != null) {
        return AuthResult.error(passwordError);
      }

      // Update password
      final updatedMetadata = Map<String, dynamic>.from(
        _currentUser!.metadata ?? {},
      );
      updatedMetadata['password'] = _hashPassword(newPassword);

      final updatedUser = _currentUser!.copyWith(metadata: updatedMetadata);
      await _saveUserToStorage(updatedUser);
      await _setCurrentUser(updatedUser);

      return AuthResult.success(updatedUser);
    } catch (e) {
      return AuthResult.error('Password change failed: ${e.toString()}');
    }
  }

  /// Delete user account
  Future<bool> deleteAccount(String password) async {
    try {
      if (_currentUser == null) return false;

      // Verify password
      final storedPasswordHash = _currentUser!.metadata?['password'] as String?;
      if (storedPasswordHash == null ||
          !_verifyPassword(password, storedPasswordHash)) {
        return false;
      }

      // Delete user data
      await _deleteUserData(_currentUser!.id);

      // Sign out
      await signOut();

      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }

  // Private methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> _setCurrentUser(User? user) async {
    _currentUser = user;
    _authStateController.add(user);

    if (user != null) {
      await _saveUserSession(user);
    }

    notifyListeners();
  }

  String _generateUserId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(
      20,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  String _hashPassword(String password) {
    // Simple hash for demo - in production use proper password hashing like bcrypt
    return password.hashCode.toString();
  }

  bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  String? _validateSignUpInputs(
    String email,
    String displayName,
    String password,
  ) {
    if (email.isEmpty || displayName.isEmpty || password.isEmpty) {
      return 'All fields are required';
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    if (displayName.length < 2) {
      return 'Display name must be at least 2 characters';
    }

    return _validatePassword(password);
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }

    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$').hasMatch(password)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
    }

    return null;
  }

  Future<User?> _getUserByEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users') ?? [];

      for (final userJson in usersJson) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        final user = User.fromJson(userData);
        if (user.email == email) {
          return user;
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }

  Future<void> _saveUserToStorage(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users') ?? [];

      // Remove existing user with same email
      usersJson.removeWhere((userJson) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        return userData['email'] == user.email;
      });

      // Add updated user
      usersJson.add(json.encode(user.toJson()));
      await prefs.setStringList('users', usersJson);
    } catch (e) {
      debugPrint('Error saving user to storage: $e');
      throw Exception('Failed to save user data');
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('current_user');

      if (currentUserJson != null) {
        final userData = json.decode(currentUserJson) as Map<String, dynamic>;
        final sessionExpiry = DateTime.fromMillisecondsSinceEpoch(
          userData['sessionExpiry'] as int,
        );

        if (DateTime.now().isBefore(sessionExpiry)) {
          _currentUser = User.fromJson(
            userData['user'] as Map<String, dynamic>,
          );
          _authStateController.add(_currentUser);
        } else {
          await _clearUserSession();
        }
      }
    } catch (e) {
      debugPrint('Error loading user from storage: $e');
      await _clearUserSession();
    }
  }

  Future<void> _saveUserSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'user': user.toJson(),
        'sessionExpiry':
            DateTime.now().add(_sessionTimeout).millisecondsSinceEpoch,
      };
      await prefs.setString('current_user', json.encode(sessionData));
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  Future<void> _clearUserSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
    } catch (e) {
      debugPrint('Error clearing user session: $e');
    }
  }

  Future<void> _deleteUserData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users') ?? [];

      usersJson.removeWhere((userJson) {
        final userData = json.decode(userJson) as Map<String, dynamic>;
        return userData['id'] == userId;
      });

      await prefs.setStringList('users', usersJson);
    } catch (e) {
      debugPrint('Error deleting user data: $e');
    }
  }

  Future<void> _sendVerificationEmail(User user) async {
    // Simulate sending verification email
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Verification email sent to ${user.email}');
  }

  Future<void> _sendPasswordResetEmail(User user) async {
    // Simulate sending password reset email
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint('Password reset email sent to ${user.email}');
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkSessionExpiry();
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  Future<void> _checkSessionExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserJson = prefs.getString('current_user');

      if (currentUserJson != null) {
        final userData = json.decode(currentUserJson) as Map<String, dynamic>;
        final sessionExpiry = DateTime.fromMillisecondsSinceEpoch(
          userData['sessionExpiry'] as int,
        );

        if (DateTime.now().isAfter(sessionExpiry)) {
          await signOut();
        }
      }
    } catch (e) {
      debugPrint('Error checking session expiry: $e');
    }
  }

  @override
  void dispose() {
    _stopSessionTimer();
    _authStateController.close();
    super.dispose();
  }
}
