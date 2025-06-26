import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundmarket/core/error/error_handler.dart';
import 'package:soundmarket/core/error/exceptions.dart';

void main() {
  group('ErrorHandler Tests', () {
    late ErrorHandler errorHandler;
    List<String> capturedErrors = [];
    List<bool> capturedToastFlags = [];

    setUp(() {
      errorHandler = ErrorHandler();
      capturedErrors.clear();
      capturedToastFlags.clear();
      
      // Initialize with a test callback
      errorHandler.initialize((message, {bool isToast = false}) {
        capturedErrors.add(message);
        capturedToastFlags.add(isToast);
      });
    });

    test('should be a singleton', () {
      final instance1 = ErrorHandler();
      final instance2 = ErrorHandler();
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize with error callback', () {
      String? capturedMessage;
      bool? capturedToastFlag;

      final handler = ErrorHandler();
      handler.initialize((message, {bool isToast = false}) {
        capturedMessage = message;
        capturedToastFlag = isToast;
      });

      handler.handleException(Exception('Test error'));

      expect(capturedMessage, isNotNull);
      expect(capturedToastFlag, isTrue);
    });

    group('handleException', () {
      test('should handle AppException correctly', () {
        final exception = DataException('Custom data error', code: 'DATA_001');
        
        final result = errorHandler.handleException(exception);

        expect(result, equals('Custom data error'));
        expect(capturedErrors, contains('Custom data error'));
        expect(capturedToastFlags.last, isTrue);
      });

      test('should handle SocketException as network error', () {
        final exception = SocketException('Connection failed');
        
        final result = errorHandler.handleException(exception);

        expect(result, equals('Network connection error. Please check your internet connection.'));
        expect(capturedErrors, contains('Network connection error. Please check your internet connection.'));
      });

      test('should handle TimeoutException as network error', () {
        final exception = TimeoutException('Request timeout');
        
        final result = errorHandler.handleException(exception);

        expect(result, equals('Network connection error. Please check your internet connection.'));
        expect(capturedErrors, contains('Network connection error. Please check your internet connection.'));
      });

      test('should handle FormatException correctly', () {
        final exception = FormatException('Invalid JSON format');
        
        final result = errorHandler.handleException(exception);

        expect(result, equals('Invalid data format'));
        expect(capturedErrors, contains('Invalid data format'));
      });

      test('should handle generic exceptions', () {
        final exception = Exception('Unknown error');
        
        final result = errorHandler.handleException(exception);

        expect(result, equals('An unexpected error occurred. Please try again.'));
        expect(capturedErrors, contains('An unexpected error occurred. Please try again.'));
      });

      test('should handle non-exception objects', () {
        final errorObject = 'String error';
        
        final result = errorHandler.handleException(errorObject);

        expect(result, equals('An unexpected error occurred. Please try again.'));
        expect(capturedErrors, contains('An unexpected error occurred. Please try again.'));
      });

      test('should handle null exception', () {
        final result = errorHandler.handleException(null);

        expect(result, equals('An unexpected error occurred. Please try again.'));
      });

      test('should include stack trace in debug output', () {
        final exception = Exception('Test with stack trace');
        StackTrace? stackTrace;
        
        try {
          throw exception;
        } catch (e, s) {
          stackTrace = s;
        }

        final result = errorHandler.handleException(exception, stackTrace);

        expect(result, equals('An unexpected error occurred. Please try again.'));
        // In a real test environment, you might want to verify debug print output
      });
    });

    group('handleApiError', () {
      test('should handle 400 Bad Request', () {
        final result = errorHandler.handleApiError(400, 'Invalid request data');

        expect(result, equals('Invalid request data'));
        expect(capturedErrors, contains('Invalid request data'));
      });

      test('should handle 400 with default message', () {
        final result = errorHandler.handleApiError(400, null);

        expect(result, equals('Bad request'));
        expect(capturedErrors, contains('Bad request'));
      });

      test('should handle 401 Unauthorized', () {
        final result = errorHandler.handleApiError(401, 'Token expired');

        expect(result, equals('Unauthorized. Please login again.'));
        expect(capturedErrors, contains('Unauthorized. Please login again.'));
      });

      test('should handle 403 Forbidden', () {
        final result = errorHandler.handleApiError(403, 'Access denied');

        expect(result, equals('Access denied'));
        expect(capturedErrors, contains('Access denied'));
      });

      test('should handle 404 Not Found', () {
        final result = errorHandler.handleApiError(404, 'Resource not found');

        expect(result, equals('Resource not found'));
        expect(capturedErrors, contains('Resource not found'));
      });

      test('should handle 500 Internal Server Error', () {
        final result = errorHandler.handleApiError(500, 'Server crashed');

        expect(result, equals('Server error. Please try again later.'));
        expect(capturedErrors, contains('Server error. Please try again later.'));
      });

      test('should handle 502 Bad Gateway', () {
        final result = errorHandler.handleApiError(502, null);

        expect(result, equals('Server error. Please try again later.'));
      });

      test('should handle 503 Service Unavailable', () {
        final result = errorHandler.handleApiError(503, null);

        expect(result, equals('Server error. Please try again later.'));
      });

      test('should handle unknown status codes', () {
        final result = errorHandler.handleApiError(418, 'I am a teapot');

        expect(result, equals('I am a teapot'));
        expect(capturedErrors, contains('I am a teapot'));
      });

      test('should handle unknown status codes with no message', () {
        final result = errorHandler.handleApiError(418, null);

        expect(result, equals('An unexpected error occurred. Please try again.'));
      });
    });

    group('showErrorDialog', () {
      testWidgets('should show error dialog with message', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.showErrorDialog(context, 'Test error message');
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        );

        // Tap the button to show dialog
        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        // Verify dialog is shown
        expect(find.text('Error'), findsOneWidget);
        expect(find.text('Test error message'), findsOneWidget);
        expect(find.text('OK'), findsOneWidget);

        // Tap OK to dismiss
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Verify dialog is dismissed
        expect(find.text('Error'), findsNothing);
      });

      testWidgets('should handle long error messages', (WidgetTester tester) async {
        final longMessage = 'This is a very long error message that should be scrollable. ' * 10;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    errorHandler.showErrorDialog(context, longMessage);
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Show Error'));
        await tester.pumpAndSettle();

        expect(find.text('Error'), findsOneWidget);
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('runWithErrorHandling', () {
      test('should return result on success', () async {
        final result = await errorHandler.runWithErrorHandling<String>(() async {
          return 'Success result';
        });

        expect(result, equals('Success result'));
      });

      test('should handle exception and return null', () async {
        String? capturedError;

        final result = await errorHandler.runWithErrorHandling<String>(
          () async {
            throw Exception('Test exception');
          },
          onError: (error) {
            capturedError = error;
          },
        );

        expect(result, isNull);
        expect(capturedError, equals('An unexpected error occurred. Please try again.'));
      });

      test('should handle AppException correctly', () async {
        String? capturedError;

        final result = await errorHandler.runWithErrorHandling<int>(
          () async {
            throw ValidationException('Validation failed', code: 'VAL_001');
          },
          onError: (error) {
            capturedError = error;
          },
        );

        expect(result, isNull);
        expect(capturedError, equals('Validation failed'));
      });

      test('should handle network exceptions', () async {
        String? capturedError;

        final result = await errorHandler.runWithErrorHandling<bool>(
          () async {
            throw SocketException('Network error');
          },
          onError: (error) {
            capturedError = error;
          },
        );

        expect(result, isNull);
        expect(capturedError, equals('Network connection error. Please check your internet connection.'));
      });

      test('should work without onError callback', () async {
        final result = await errorHandler.runWithErrorHandling<String>(() async {
          throw Exception('Test exception');
        });

        expect(result, isNull);
        // Should still call the global error callback
        expect(capturedErrors, isNotEmpty);
      });

      test('should handle async exceptions', () async {
        String? capturedError;

        final result = await errorHandler.runWithErrorHandling<String>(
          () async {
            await Future.delayed(const Duration(milliseconds: 10));
            throw Exception('Async exception');
          },
          onError: (error) {
            capturedError = error;
          },
        );

        expect(result, isNull);
        expect(capturedError, isNotNull);
      });
    });

    group('Error callback integration', () {
      test('should work without initialization', () {
        final uninitializedHandler = ErrorHandler();
        
        // Should not throw exception even without initialization
        final result = uninitializedHandler.handleException(Exception('Test'));
        expect(result, isNotNull);
      });

      test('should handle multiple error callbacks', () {
        final errors1 = <String>[];
        final errors2 = <String>[];

        // Initialize first time
        errorHandler.initialize((message, {bool isToast = false}) {
          errors1.add(message);
        });

        errorHandler.handleException(Exception('First error'));

        // Re-initialize with different callback
        errorHandler.initialize((message, {bool isToast = false}) {
          errors2.add(message);
        });

        errorHandler.handleException(Exception('Second error'));

        expect(errors1.length, equals(1));
        expect(errors2.length, equals(1));
      });
    });
  });
}