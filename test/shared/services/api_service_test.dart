import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:soundmarket/shared/services/api_service.dart';
import 'package:soundmarket/core/error/exceptions.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockRequest extends Mock implements http.Request {}

class MockStreamedResponse extends Mock implements http.StreamedResponse {}

void main() {
  group('ApiService Tests', () {
    late MockHttpClient mockHttpClient;
    late ApiService apiService;

    setUp(() {
      mockHttpClient = MockHttpClient();
      apiService = ApiService(client: mockHttpClient, timeout: const Duration(seconds: 5));
    });

    tearDown(() {
      apiService.dispose();
    });

    group('GET Requests', () {
      test('should make successful GET request', () async {
        // Arrange
        final responseBody = {'message': 'success', 'data': []};
        final response = http.Response(json.encode(responseBody), 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.get('/test');

        // Assert
        expect(result, equals(responseBody));
        verify(() => mockHttpClient.send(any())).called(1);
      });

      test('should make GET request with query parameters', () async {
        // Arrange
        final responseBody = {'filtered': 'data'};
        final response = http.Response(json.encode(responseBody), 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.get(
          '/test',
          queryParameters: {'page': '1', 'limit': '10'},
        );

        // Assert
        expect(result, equals(responseBody));
        
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.url.queryParameters['page'], equals('1'));
        expect(capturedRequest.url.queryParameters['limit'], equals('10'));
      });

      test('should make GET request with custom headers', () async {
        // Arrange
        final responseBody = {'authenticated': 'data'};
        final response = http.Response(json.encode(responseBody), 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.get(
          '/test',
          headers: {'Authorization': 'Bearer token123'},
        );

        // Assert
        expect(result, equals(responseBody));
        
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.headers['Authorization'], equals('Bearer token123'));
      });
    });

    group('POST Requests', () {
      test('should make successful POST request with body', () async {
        // Arrange
        final requestBody = {'name': 'Test', 'value': 123};
        final responseBody = {'id': 'created-id', 'status': 'created'};
        final response = http.Response(json.encode(responseBody), 201);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          201,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.post('/test', body: requestBody);

        // Assert
        expect(result, equals(responseBody));
        
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.method, equals('POST'));
        expect(json.decode(capturedRequest.body), equals(requestBody));
      });

      test('should make POST request without body', () async {
        // Arrange
        final responseBody = {'message': 'no body'};
        final response = http.Response(json.encode(responseBody), 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.post('/test');

        // Assert
        expect(result, equals(responseBody));
        
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.body, isEmpty);
      });
    });

    group('PUT, PATCH, DELETE Requests', () {
      test('should make successful PUT request', () async {
        // Arrange
        final requestBody = {'name': 'Updated'};
        final responseBody = {'updated': true};
        final response = http.Response(json.encode(responseBody), 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.put('/test/1', body: requestBody);

        // Assert
        expect(result, equals(responseBody));
        
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.method, equals('PUT'));
      });

      test('should make successful PATCH request', () async {
        // Arrange
        final requestBody = {'status': 'active'};
        final responseBody = {'patched': true};
        final response = http.Response(json.encode(responseBody), 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.patch('/test/1', body: requestBody);

        // Assert
        expect(result, equals(responseBody));
        
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.method, equals('PATCH'));
      });

      test('should make successful DELETE request', () async {
        // Arrange
        final response = http.Response('', 204);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          204,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.delete('/test/1');

        // Assert
        expect(result, isNull);
        
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.method, equals('DELETE'));
      });
    });

    group('Error Handling', () {
      test('should throw NetworkException on SocketException', () async {
        // Arrange
        when(() => mockHttpClient.send(any())).thenThrow(const SocketException('No internet'));

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<NetworkException>().having(
            (e) => e.message,
            'message',
            'No internet connection',
          )),
        );
      });

      test('should throw TimeoutException on timeout', () async {
        // Arrange
        when(() => mockHttpClient.send(any())).thenThrow(TimeoutException('Timeout', const Duration(seconds: 5)));

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should throw DataException on 400 Bad Request', () async {
        // Arrange
        final errorBody = {'message': 'Bad request', 'code': 'INVALID_DATA'};
        final response = http.Response(json.encode(errorBody), 400);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          400,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<DataException>()
              .having((e) => e.message, 'message', 'Bad request')
              .having((e) => e.code, 'code', 'INVALID_DATA')),
        );
      });

      test('should throw AuthException on 401 Unauthorized', () async {
        // Arrange
        final errorBody = {'message': 'Unauthorized'};
        final response = http.Response(json.encode(errorBody), 401);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          401,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Unauthorized',
          )),
        );
      });

      test('should throw PermissionException on 403 Forbidden', () async {
        // Arrange
        final response = http.Response('{"message": "Forbidden"}', 403);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          403,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<PermissionException>()),
        );
      });

      test('should throw NotFoundException on 404 Not Found', () async {
        // Arrange
        final response = http.Response('{"message": "Not found"}', 404);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          404,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('should throw ValidationException on 422 Unprocessable Entity', () async {
        // Arrange
        final errorBody = {'message': 'Validation failed', 'errors': ['Field required']};
        final response = http.Response(json.encode(errorBody), 422);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          422,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<ValidationException>().having(
            (e) => e.message,
            'message',
            'Validation failed',
          )),
        );
      });

      test('should throw ServerException on 500 Internal Server Error', () async {
        // Arrange
        final response = http.Response('{"message": "Internal server error"}', 500);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          500,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            500,
          )),
        );
      });

      test('should throw AppException on unknown status code', () async {
        // Arrange
        final response = http.Response('{"message": "Unknown error"}', 418);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          418,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<AppException>()),
        );
      });

      test('should handle empty response body', () async {
        // Arrange
        final response = http.Response('', 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        final result = await apiService.get('/test');

        // Assert
        expect(result, isNull);
      });

      test('should handle invalid JSON in error response', () async {
        // Arrange
        final response = http.Response('invalid json', 400);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          400,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act & Assert
        expect(
          () => apiService.get('/test'),
          throwsA(isA<DataException>().having(
            (e) => e.message,
            'message',
            'Bad request',
          )),
        );
      });
    });

    group('Headers and Content Type', () {
      test('should set default headers correctly', () async {
        // Arrange
        final response = http.Response('{}', 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        await apiService.get('/test');

        // Assert
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.headers['Content-Type'], equals('application/json'));
        expect(capturedRequest.headers['Accept'], equals('application/json'));
      });

      test('should merge custom headers with default headers', () async {
        // Arrange
        final response = http.Response('{}', 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        await apiService.get('/test', headers: {
          'Authorization': 'Bearer token',
          'X-Custom-Header': 'custom-value',
        });

        // Assert
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.headers['Content-Type'], equals('application/json'));
        expect(capturedRequest.headers['Accept'], equals('application/json'));
        expect(capturedRequest.headers['Authorization'], equals('Bearer token'));
        expect(capturedRequest.headers['X-Custom-Header'], equals('custom-value'));
      });

      test('should override default headers with custom headers', () async {
        // Arrange
        final response = http.Response('{}', 200);
        final streamedResponse = http.StreamedResponse(
          Stream.value(response.bodyBytes),
          200,
          headers: response.headers,
        );

        when(() => mockHttpClient.send(any())).thenAnswer((_) async => streamedResponse);

        // Act
        await apiService.get('/test', headers: {
          'Content-Type': 'application/xml',
        });

        // Assert
        final capturedRequest = verify(() => mockHttpClient.send(captureAny())).captured.single as http.Request;
        expect(capturedRequest.headers['Content-Type'], equals('application/xml'));
      });
    });
  });
}