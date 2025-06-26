import 'package:flutter_test/flutter_test.dart';
import 'package:soundmarket/features/auth/models/auth_result.dart';
import 'package:soundmarket/features/auth/models/user.dart';

void main() {
  group('AuthResult Tests', () {
    final testUser = User(
      id: 'test-id',
      email: 'test@example.com',
      displayName: 'Test User',
      isEmailVerified: true,
      createdAt: DateTime(2024, 1, 1),
    );

    test('should create success result correctly', () {
      final result = AuthResult.success(testUser);

      expect(result.status, equals(AuthStatus.authenticated));
      expect(result.user, equals(testUser));
      expect(result.errorMessage, isNull);
      expect(result.errorCode, isNull);
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
      expect(result.requiresVerification, isFalse);
    });

    test('should create error result correctly', () {
      final result = AuthResult.error('Test error', code: 'test-code');

      expect(result.status, equals(AuthStatus.error));
      expect(result.user, isNull);
      expect(result.errorMessage, equals('Test error'));
      expect(result.errorCode, equals('test-code'));
      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
      expect(result.requiresVerification, isFalse);
    });

    test('should create error result without code', () {
      final result = AuthResult.error('Test error');

      expect(result.status, equals(AuthStatus.error));
      expect(result.errorMessage, equals('Test error'));
      expect(result.errorCode, isNull);
    });

    test('should create verification required result correctly', () {
      final result = AuthResult.verificationRequired(testUser);

      expect(result.status, equals(AuthStatus.verificationRequired));
      expect(result.user, equals(testUser));
      expect(result.errorMessage, isNull);
      expect(result.errorCode, isNull);
      expect(result.isSuccess, isFalse);
      expect(result.isError, isFalse);
      expect(result.requiresVerification, isTrue);
    });

    test('should create unauthenticated result correctly', () {
      final result = AuthResult.unauthenticated();

      expect(result.status, equals(AuthStatus.unauthenticated));
      expect(result.user, isNull);
      expect(result.errorMessage, isNull);
      expect(result.errorCode, isNull);
      expect(result.isSuccess, isFalse);
      expect(result.isError, isFalse);
      expect(result.requiresVerification, isFalse);
    });

    test('should create result with additional data', () {
      final additionalData = {'key': 'value', 'count': 42};
      final result = AuthResult(
        status: AuthStatus.authenticated,
        user: testUser,
        additionalData: additionalData,
      );

      expect(result.additionalData, equals(additionalData));
    });
  });

  group('AuthException Tests', () {
    test('should create basic AuthException', () {
      final exception = AuthException('Test message');

      expect(exception.message, equals('Test message'));
      expect(exception.code, isNull);
      expect(exception.details, isNull);
      expect(exception.toString(), equals('AuthException: Test message'));
    });

    test('should create AuthException with code', () {
      final exception = AuthException('Test message', code: 'test-code');

      expect(exception.message, equals('Test message'));
      expect(exception.code, equals('test-code'));
      expect(exception.toString(), equals('AuthException: Test message (Code: test-code)'));
    });

    test('should create AuthException with details', () {
      final details = {'field': 'value'};
      final exception = AuthException(
        'Test message',
        code: 'test-code',
        details: details,
      );

      expect(exception.details, equals(details));
    });

    test('EmailNotVerifiedException should have correct properties', () {
      const exception = EmailNotVerifiedException();

      expect(exception.message, equals('Email address is not verified'));
      expect(exception.code, equals('email-not-verified'));
    });

    test('WeakPasswordException should have correct properties', () {
      const exception = WeakPasswordException();

      expect(exception.message, equals('Password is too weak'));
      expect(exception.code, equals('weak-password'));
    });

    test('EmailAlreadyInUseException should have correct properties', () {
      const exception = EmailAlreadyInUseException();

      expect(exception.message, equals('Email address is already in use'));
      expect(exception.code, equals('email-already-in-use'));
    });

    test('UserNotFoundException should have correct properties', () {
      const exception = UserNotFoundException();

      expect(exception.message, equals('No user found with this email'));
      expect(exception.code, equals('user-not-found'));
    });

    test('WrongPasswordException should have correct properties', () {
      const exception = WrongPasswordException();

      expect(exception.message, equals('Incorrect password'));
      expect(exception.code, equals('wrong-password'));
    });

    test('TooManyRequestsException should have correct properties', () {
      const exception = TooManyRequestsException();

      expect(exception.message, equals('Too many requests. Please try again later'));
      expect(exception.code, equals('too-many-requests'));
    });

    test('NetworkException should have correct properties', () {
      const exception = NetworkException();

      expect(exception.message, equals('Network error. Please check your connection'));
      expect(exception.code, equals('network-error'));
    });
  });
}