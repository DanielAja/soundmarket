import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import '../../core/config/environment_config.dart';
import '../../core/error/exceptions.dart';
import '../../core/constants/api_constants.dart';

/// Base API service with common functionality
class ApiService {
  final http.Client _client;
  final Duration _timeout;
  
  ApiService({
    http.Client? client,
    Duration? timeout,
  }) : 
    _client = client ?? http.Client(),
    _timeout = timeout ?? Duration(seconds: AppConfig.apiTimeoutSeconds);
  
  // Get the base URL from environment config
  String get baseUrl => EnvironmentConfig.apiBaseUrl;
  
  // Get request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _sendRequest(
      'GET',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
    );
  }
  
  // Post request
  Future<dynamic> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    return _sendRequest(
      'POST',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }
  
  // Put request
  Future<dynamic> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    return _sendRequest(
      'PUT',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }
  
  // Patch request
  Future<dynamic> patch(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    return _sendRequest(
      'PATCH',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }
  
  // Delete request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    return _sendRequest(
      'DELETE',
      endpoint,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
  }
  
  // Send request
  Future<dynamic> _sendRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) async {
    try {
      // Build URL
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters,
      );
      
      // Build headers
      final requestHeaders = {
        ApiConstants.contentTypeHeader: ApiConstants.jsonContentType,
        ApiConstants.acceptHeader: ApiConstants.jsonContentType,
        ...?headers,
      };
      
      // Build request
      final request = http.Request(method, uri);
      request.headers.addAll(requestHeaders);
      
      // Add body if provided
      if (body != null) {
        request.body = json.encode(body);
      }
      
      // Send request
      final streamedResponse = await _client
          .send(request)
          .timeout(_timeout);
      
      // Get response
      final response = await http.Response.fromStream(streamedResponse);
      
      // Handle response
      return _handleResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on TimeoutException {
      throw TimeoutException('Request timed out');
    } catch (e) {
      throw AppException('An error occurred: $e');
    }
  }
  
  // Handle response
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final responseBody = response.body.isNotEmpty ? json.decode(response.body) : null;
    
    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } else {
      switch (statusCode) {
        case 400:
          throw DataException(
            responseBody?['message'] ?? 'Bad request',
            code: responseBody?['code'],
            details: responseBody,
          );
        case 401:
          throw AuthException(
            responseBody?['message'] ?? 'Unauthorized',
            code: responseBody?['code'],
            details: responseBody,
          );
        case 403:
          throw PermissionException(
            responseBody?['message'] ?? 'Forbidden',
            code: responseBody?['code'],
            details: responseBody,
          );
        case 404:
          throw NotFoundException(
            responseBody?['message'] ?? 'Not found',
            code: responseBody?['code'],
            details: responseBody,
          );
        case 422:
          throw ValidationException(
            responseBody?['message'] ?? 'Validation error',
            code: responseBody?['code'],
            details: responseBody,
          );
        case 500:
        case 502:
        case 503:
          throw ServerException(
            responseBody?['message'] ?? 'Server error',
            statusCode: statusCode,
            code: responseBody?['code'],
            details: responseBody,
          );
        default:
          throw AppException(
            responseBody?['message'] ?? 'Unknown error',
            code: responseBody?['code'],
            details: responseBody,
          );
      }
    }
  }
  
  // Close client
  void dispose() {
    _client.close();
  }
}
