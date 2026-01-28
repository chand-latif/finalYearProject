/// Custom exception classes for proper error handling throughout the app.

/// Base exception class for all app-specific exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  AppException(this.message, {this.code, this.originalException});

  @override
  String toString() => message;
}

/// Exception for network-related errors
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.originalException});
}

/// Exception for API errors (non-2xx responses)
class ApiException extends AppException {
  final int statusCode;

  ApiException(
    super.message, {
    required this.statusCode,
    super.code,
    super.originalException,
  });

  /// Check if this is an unauthorized error (token expired/invalid)
  bool get isUnauthorized => statusCode == 401;

  /// Check if this is a not found error
  bool get isNotFound => statusCode == 404;

  /// Check if this is a server error
  bool get isServerError => statusCode >= 500;
}

/// Exception for authentication-related errors
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.originalException});
}

/// Exception for validation errors
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalException,
  });
}

/// Exception for storage-related errors
class StorageException extends AppException {
  StorageException(super.message, {super.code, super.originalException});
}
