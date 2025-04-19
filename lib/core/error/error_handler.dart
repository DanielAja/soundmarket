import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'exceptions.dart';
import '../constants/string_constants.dart';

/// Centralized error handling logic
class ErrorHandler {
  // Singleton pattern
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Error callback
  Function(String, {bool isToast})? _onError;

  // Initialize with error callback
  void initialize(Function(String, {bool isToast}) onError) {
    _onError = onError;
  }

  // Handle exceptions and return user-friendly messages
  String handleException(dynamic exception, [StackTrace? stackTrace]) {
    String errorMessage = StringConstants.errorOccurred;

    if (exception is AppException) {
      errorMessage = exception.message;
    } else if (exception is SocketException || exception is TimeoutException) {
      errorMessage = StringConstants.networkError;
    } else if (exception is FormatException) {
      errorMessage = 'Invalid data format';
    }

    // Log the error (in a real app, this would use a proper logging system)
    debugPrint('ERROR: $errorMessage');
    debugPrint('EXCEPTION: $exception');
    if (stackTrace != null) {
      debugPrint('STACK TRACE: $stackTrace');
    }

    // Call the error callback if provided
    _onError?.call(errorMessage, isToast: true);

    return errorMessage;
  }

  // Handle API errors based on status code
  String handleApiError(int statusCode, String? message) {
    String errorMessage;

    switch (statusCode) {
      case 400:
        errorMessage = message ?? 'Bad request';
        break;
      case 401:
        errorMessage = 'Unauthorized. Please login again.';
        break;
      case 403:
        errorMessage = 'Access denied';
        break;
      case 404:
        errorMessage = 'Resource not found';
        break;
      case 500:
      case 502:
      case 503:
        errorMessage = 'Server error. Please try again later.';
        break;
      default:
        errorMessage = message ?? StringConstants.errorOccurred;
    }

    // Call the error callback if provided
    _onError?.call(errorMessage, isToast: true);

    return errorMessage;
  }

  // Show error dialog
  Future<void> showErrorDialog(BuildContext context, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: SingleChildScrollView(child: Text(message)),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Run a function with error handling
  Future<T?> runWithErrorHandling<T>(
    Future<T> Function() function, {
    Function(String)? onError,
  }) async {
    try {
      return await function();
    } catch (e, stackTrace) {
      final errorMessage = handleException(e, stackTrace);
      onError?.call(errorMessage);
      return null;
    }
  }
}
