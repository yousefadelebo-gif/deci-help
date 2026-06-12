import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../services/local_storage_service.dart';

/// HTTP Client wrapper with authentication handling
class HttpClient {
  final LocalStorageService _storage;
  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 10);

  HttpClient({
    required LocalStorageService storage,
    http.Client? client,
  })  : _storage = storage,
        _client = client ?? http.Client();

  // ==================== Headers ====================

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<bool> _refreshAccessToken() async {
    final refresh = _storage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.tokenRefresh}'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh': refresh}),
          )
          .timeout(_timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      final access = decoded['access'];
      final newRefresh = decoded['refresh'];
      if (access is! String || access.isEmpty) return false;

      await _storage.saveTokens(
        accessToken: access,
        refreshToken: (newRefresh is String && newRefresh.isNotEmpty) ? newRefresh : refresh,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _requestWithRefresh(
    Future<http.Response> Function() send,
  ) async {
    final firstResponse = await send();
    if (firstResponse.statusCode != 401) {
      return _handleResponse(firstResponse);
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed) {
      return _handleResponse(firstResponse);
    }

    final retryResponse = await send();
    return _handleResponse(retryResponse);
  }

  // ==================== HTTP Methods ====================

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      return await _requestWithRefresh(() {
        return _client
            .get(
              Uri.parse('${ApiConstants.baseUrl}$endpoint'),
              headers: _headers,
            )
            .timeout(_timeout);
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _requestWithRefresh(() {
        return _client
            .post(
              Uri.parse('${ApiConstants.baseUrl}$endpoint'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(_timeout);
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _requestWithRefresh(() {
        return _client
            .put(
              Uri.parse('${ApiConstants.baseUrl}$endpoint'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(_timeout);
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      return await _requestWithRefresh(() {
        return _client
            .patch(
              Uri.parse('${ApiConstants.baseUrl}$endpoint'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(_timeout);
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      return await _requestWithRefresh(() {
        return _client
            .delete(
              Uri.parse('${ApiConstants.baseUrl}$endpoint'),
              headers: _headers,
            )
            .timeout(_timeout);
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Response Handling ====================

  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = <String, dynamic>{};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        }
      } catch (_) {
        throw ServerException('Invalid server response', statusCode: response.statusCode);
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    switch (response.statusCode) {
      case 400:
        throw ValidationException(
          body['detail'] ?? body['message'] ?? 'Validation error',
          errors: body['errors'] as Map<String, dynamic>?,
        );
      case 401:
        throw UnauthorizedException(
          body['detail'] ?? 'Unauthorized. Please login again.',
        );
      case 403:
        throw AppException('Access denied', code: 'FORBIDDEN');
      case 404:
        throw NotFoundException(body['detail'] ?? 'Resource not found');
      case 500:
      case 502:
      case 503:
        throw ServerException(
          body['detail'] ?? 'Server error. Please try again later.',
          statusCode: response.statusCode,
        );
      default:
        throw ServerException(
          body['detail'] ?? 'An error occurred',
          statusCode: response.statusCode,
        );
    }
  }

  AppException _handleError(dynamic error) {
    if (error is AppException) return error;
    return NetworkException('Connection failed. Please check your internet.');
  }

  void dispose() {
    _client.close();
  }
}
