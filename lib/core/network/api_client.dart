import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../exceptions/app_exception.dart';
import '../services/storage_service.dart';

/// HTTP client wrapper that handles:
/// - Automatic JWT token injection
/// - Base URL configuration
/// - Error handling and response parsing
/// - Request/response logging
class ApiClient {
  final StorageService _storageService;
  final http.Client _httpClient;

  ApiClient({
    required StorageService storageService,
    http.Client? httpClient,
  })  : _storageService = storageService,
        _httpClient = httpClient ?? http.Client();

  /// Build the full URL for an endpoint
  Uri _buildUrl(String endpoint, [Map<String, dynamic>? queryParams]) {
    final url = '${ApiConstants.baseUrl}$endpoint';
    if (queryParams != null && queryParams.isNotEmpty) {
      final queryString = queryParams.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      return Uri.parse('$url?$queryString');
    }
    return Uri.parse(url);
  }

  /// Get default headers including auth token if available
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'accept': '*/*',
    };

    if (includeAuth) {
      final token = _storageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Parse API response and handle errors
  dynamic _parseResponse(http.Response response) {
    final statusCode = response.statusCode;
    dynamic body;

    try {
      body = jsonDecode(response.body);
    } catch (e) {
      body = response.body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      // Success response
      if (body is Map<String, dynamic>) {
        // Check for API-level error (some APIs return 200 with error in body)
        if (body['statusCode'] == 400 || body['succeeded'] == false) {
          throw ApiException(
            body['message'] ?? 'Request failed',
            statusCode: 400,
            code: body['statusCode']?.toString(),
          );
        }
        return body;
      }
      return body;
    } else if (statusCode == 401) {
      throw AuthException('Session expired. Please login again.');
    } else if (statusCode == 404) {
      throw ApiException('Resource not found', statusCode: statusCode);
    } else if (statusCode >= 500) {
      throw ApiException(
        'Server error. Please try again later.',
        statusCode: statusCode,
      );
    } else {
      final message = body is Map ? body['message'] : 'Request failed';
      throw ApiException(
        message ?? 'Something went wrong',
        statusCode: statusCode,
      );
    }
  }

  /// Make a GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams);
      final response = await _httpClient.get(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
      );
      return _parseResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('Network error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Unexpected error: $e', originalException: e);
    }
  }

  /// Make a POST request
  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams);
      final response = await _httpClient.post(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('Network error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Unexpected error: $e', originalException: e);
    }
  }

  /// Make a PUT request
  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams);
      final response = await _httpClient.put(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('Network error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Unexpected error: $e', originalException: e);
    }
  }

  /// Make a DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint, queryParams);
      final response = await _httpClient.delete(
        url,
        headers: _getHeaders(includeAuth: includeAuth),
      );
      return _parseResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('Network error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Unexpected error: $e', originalException: e);
    }
  }

  /// Upload a file with multipart request
  Future<dynamic> uploadFile(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, String>? fields,
    bool includeAuth = true,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final request = http.MultipartRequest('POST', url);

      // Add auth header if needed
      if (includeAuth) {
        final token = _storageService.getAuthToken();
        if (token != null && token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      // Add the file
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));

      // Add any additional fields
      if (fields != null) {
        request.fields.addAll(fields);
      }

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    } on SocketException {
      throw NetworkException('No internet connection');
    } on HttpException {
      throw NetworkException('Network error occurred');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException('Unexpected error: $e', originalException: e);
    }
  }

  /// Dispose the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
