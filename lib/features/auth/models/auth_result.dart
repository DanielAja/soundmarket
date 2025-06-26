import 'user.dart';

enum AuthStatus { authenticated, unauthenticated, verificationRequired, error }

class AuthResult {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, dynamic>? additionalData;

  const AuthResult({
    required this.status,
    this.user,
    this.errorMessage,
    this.errorCode,
    this.additionalData,
  });

  bool get isSuccess => status == AuthStatus.authenticated;
  bool get isError => status == AuthStatus.error;
  bool get requiresVerification => status == AuthStatus.verificationRequired;

  factory AuthResult.success(User user) {
    return AuthResult(status: AuthStatus.authenticated, user: user);
  }

  factory AuthResult.error(String message, {String? code}) {
    return AuthResult(
      status: AuthStatus.error,
      errorMessage: message,
      errorCode: code,
    );
  }

  factory AuthResult.verificationRequired(User user) {
    return AuthResult(status: AuthStatus.verificationRequired, user: user);
  }

  factory AuthResult.unauthenticated() {
    return const AuthResult(status: AuthStatus.unauthenticated);
  }
}

class AuthException implements Exception {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const AuthException(this.message, {this.code, this.details});

  @override
  String toString() =>
      'AuthException: $message${code != null ? ' (Code: $code)' : ''}';
}

class EmailNotVerifiedException extends AuthException {
  const EmailNotVerifiedException()
    : super('Email address is not verified', code: 'email-not-verified');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
    : super('Password is too weak', code: 'weak-password');
}

class EmailAlreadyInUseException extends AuthException {
  const EmailAlreadyInUseException()
    : super('Email address is already in use', code: 'email-already-in-use');
}

class UserNotFoundException extends AuthException {
  const UserNotFoundException()
    : super('No user found with this email', code: 'user-not-found');
}

class WrongPasswordException extends AuthException {
  const WrongPasswordException()
    : super('Incorrect password', code: 'wrong-password');
}

class TooManyRequestsException extends AuthException {
  const TooManyRequestsException()
    : super(
        'Too many requests. Please try again later',
        code: 'too-many-requests',
      );
}

class NetworkException extends AuthException {
  const NetworkException()
    : super(
        'Network error. Please check your connection',
        code: 'network-error',
      );
}
