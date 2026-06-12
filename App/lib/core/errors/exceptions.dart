/// Custom exceptions for the app
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network error occurred'])
      : super(message, code: 'NETWORK_ERROR');
}

class ServerException extends AppException {
  final int? statusCode;

  ServerException(String message, {this.statusCode})
      : super(message, code: 'SERVER_ERROR');
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized. Please login again.'])
      : super(message, code: 'UNAUTHORIZED');
}

class ValidationException extends AppException {
  final Map<String, dynamic>? errors;

  ValidationException(String message, {this.errors})
      : super(message, code: 'VALIDATION_ERROR');
}

class CacheException extends AppException {
  CacheException([String message = 'Cache error occurred'])
      : super(message, code: 'CACHE_ERROR');
}

class NotFoundException extends AppException {
  NotFoundException([String message = 'Resource not found'])
      : super(message, code: 'NOT_FOUND');
}
