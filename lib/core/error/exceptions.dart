/// Custom exception classes
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.details});
}

/// Server-related exceptions
class ServerException extends AppException {
  final int? statusCode;

  ServerException(super.message, {this.statusCode, super.code, super.details});

  @override
  String toString() =>
      'ServerException: $message (Status: $statusCode, Code: $code)';
}

/// Data-related exceptions
class DataException extends AppException {
  DataException(super.message, {super.code, super.details});
}

/// Cache-related exceptions
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.details});
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.details,
  });

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      return 'ValidationException: $message - Fields: $fieldErrors (Code: $code)';
    }
    return 'ValidationException: $message (Code: $code)';
  }
}

/// Business logic exceptions
class BusinessException extends AppException {
  BusinessException(super.message, {super.code, super.details});
}

/// Permission-related exceptions
class PermissionException extends AppException {
  PermissionException(super.message, {super.code, super.details});
}

/// Resource not found exceptions
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.details});
}

/// Timeout exceptions
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.details});
}
