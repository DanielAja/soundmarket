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
  NetworkException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Authentication-related exceptions
class AuthException extends AppException {
  AuthException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Server-related exceptions
class ServerException extends AppException {
  final int? statusCode;

  ServerException(String message, {this.statusCode, String? code, dynamic details})
      : super(message, code: code, details: details);

  @override
  String toString() => 'ServerException: $message (Status: $statusCode, Code: $code)';
}

/// Data-related exceptions
class DataException extends AppException {
  DataException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Cache-related exceptions
class CacheException extends AppException {
  CacheException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(String message, {this.fieldErrors, String? code, dynamic details})
      : super(message, code: code, details: details);

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
  BusinessException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Permission-related exceptions
class PermissionException extends AppException {
  PermissionException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Resource not found exceptions
class NotFoundException extends AppException {
  NotFoundException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

/// Timeout exceptions
class TimeoutException extends AppException {
  TimeoutException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}
