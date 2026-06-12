import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decision_companion/core/constants/api_constants.dart';

/// API Service for connecting to Django Backend
class ApiService {
  // Base URL configuration
  static String get baseUrl => ApiConstants.baseUrl;

  // Request timeout for faster failure detection
  static const Duration _timeout = Duration(seconds: 10);
  // Longer timeout for AI operations (Claude API can take 30-60s)
  static const Duration _aiTimeout = Duration(seconds: 60);

  // Persistent HTTP client for connection pooling
  static final http.Client _client = http.Client();

  static String? _accessToken;
  static String? _refreshToken;

  // Token management
  static Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
  }

  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    _accessToken = access;
    _refreshToken = refresh;
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
  }

  static bool get isLoggedIn => _accessToken != null;

  // HTTP Headers
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  static bool _isAuthEndpoint(String endpoint) {
    return endpoint.contains('/auth/login/') ||
        endpoint.contains('/auth/register/') ||
        endpoint.contains('/auth/token/refresh/') ||
        endpoint.contains('/auth/logout/');
  }

  static Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${ApiConstants.tokenRefresh}'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'refresh': _refreshToken}),
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await clearTokens();
        return false;
      }
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      final access = body['access'];
      final refresh = body['refresh'] ?? _refreshToken;
      if (access is! String || access.isEmpty) {
        await clearTokens();
        return false;
      }
      await saveTokens(access, refresh is String ? refresh : _refreshToken!);
      return true;
    } catch (_) {
      await clearTokens();
      return false;
    }
  }

  static Future<ApiResponse> _requestWithRefresh(
    Future<http.Response> Function() send,
    String endpoint,
  ) async {
    final response = await send();
    if (response.statusCode != 401 || _isAuthEndpoint(endpoint)) {
      return _handleResponse(response);
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed) {
      return _handleResponse(response);
    }

    final retryResponse = await send();
    return _handleResponse(retryResponse);
  }

  // Generic request methods with timeout
  static Future<ApiResponse> get(String endpoint) async {
    try {
      return await _requestWithRefresh(
        () => _client
            .get(
              Uri.parse('$baseUrl$endpoint'),
              headers: _headers,
            )
            .timeout(_timeout),
        endpoint,
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed');
    } on Exception {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  static Future<ApiResponse> post(
      String endpoint, Map<String, dynamic> data) async {
    try {
      return await _requestWithRefresh(
        () => _client
            .post(
              Uri.parse('$baseUrl$endpoint'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(_timeout),
        endpoint,
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed');
    } on Exception {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  static Future<ApiResponse> put(
      String endpoint, Map<String, dynamic> data) async {
    try {
      return await _requestWithRefresh(
        () => _client
            .put(
              Uri.parse('$baseUrl$endpoint'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(_timeout),
        endpoint,
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed');
    } on Exception {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  static Future<ApiResponse> patch(
      String endpoint, Map<String, dynamic> data) async {
    try {
      return await _requestWithRefresh(
        () => _client
            .patch(
              Uri.parse('$baseUrl$endpoint'),
              headers: _headers,
              body: jsonEncode(data),
            )
            .timeout(_timeout),
        endpoint,
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed');
    } on Exception {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  static Future<ApiResponse> delete(String endpoint) async {
    try {
      return await _requestWithRefresh(
        () => _client
            .delete(
              Uri.parse('$baseUrl$endpoint'),
              headers: _headers,
            )
            .timeout(_timeout),
        endpoint,
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed');
    } on Exception {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  static ApiResponse _handleResponse(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse.success(body);
    } else if (response.statusCode == 401) {
      // Token expired - could implement refresh here
      return ApiResponse.error('Unauthorized. Please login again.',
          statusCode: 401);
    } else {
      final message = body['detail'] ?? body['error'] ?? 'Request failed';
      return ApiResponse.error(message, statusCode: response.statusCode);
    }
  }

  // ==================== AUTH ENDPOINTS ====================

  static Future<ApiResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await post('/auth/register/', {
      'email': email,
      'password': password,
      'password2': password,
      'first_name': firstName,
      'last_name': lastName,
    });

    if (response.isSuccess && response.data['tokens'] != null) {
      await saveTokens(
        response.data['tokens']['access'],
        response.data['tokens']['refresh'],
      );
    }

    return response;
  }

  static Future<ApiResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await post('/auth/login/', {
      'email': email,
      'password': password,
    });

    if (response.isSuccess && response.data != null) {
      // Handle both token structures: {access, refresh} or {tokens: {access, refresh}}
      final tokens = response.data['tokens'] ?? response.data;
      if (tokens['access'] != null && tokens['refresh'] != null) {
        await saveTokens(tokens['access'], tokens['refresh']);
      }
    }

    return response;
  }

  static Future<ApiResponse> logout() async {
    if (_refreshToken != null) {
      await post('/auth/logout/', {'refresh': _refreshToken});
    }
    await clearTokens();
    return ApiResponse.success({'message': 'Logged out'});
  }

  static Future<ApiResponse> getProfile() async {
    return get('/auth/profile/');
  }

  static Future<ApiResponse> updateProfile(Map<String, dynamic> data) async {
    return patch('/auth/profile/', data);
  }

  static Future<ApiResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return post('/auth/change-password/', {
      'old_password': oldPassword,
      'new_password': newPassword,
      'new_password2': newPassword,
    });
  }

  // ==================== ADMIN ENDPOINTS ====================

  static Future<ApiResponse> getAdminStats() async {
    return get('/auth/admin/stats/');
  }

  static Future<ApiResponse> getAdminUsers(
      {String? search, String? status}) async {
    String query = '';
    if (search != null && search.isNotEmpty) query += 'search=$search&';
    if (status != null && status.isNotEmpty) query += 'status=$status&';
    return get('/auth/admin/users/${query.isNotEmpty ? '?$query' : ''}');
  }

  static Future<ApiResponse> getAdminFeedback() async {
    return get('/feedback/admin/list/');
  }

  static Future<ApiResponse> getFeedbackStats() async {
    return get('/feedback/admin/stats/');
  }

  // ==================== DECISIONS ENDPOINTS ====================

  static Future<ApiResponse> getDecisions({
    String? status,
    String? category,
    String? search,
  }) async {
    String query = '';
    if (status != null) query += 'status=$status&';
    if (category != null) query += 'category=$category&';
    if (search != null) query += 'search=$search&';

    return get('/decisions/${query.isNotEmpty ? '?$query' : ''}');
  }

  static Future<ApiResponse> getDecision(String id) async {
    return get('/decisions/$id/');
  }

  static Future<ApiResponse> createDecision(Map<String, dynamic> data) async {
    return post('/decisions/', data);
  }

  static Future<ApiResponse> updateDecision(
      String id, Map<String, dynamic> data) async {
    return patch('/decisions/$id/', data);
  }

  static Future<ApiResponse> deleteDecision(String id) async {
    return delete('/decisions/$id/');
  }

  static Future<ApiResponse> getRecentDecisions() async {
    return get('/decisions/recent/');
  }

  static Future<ApiResponse> getDecisionAnalytics() async {
    return get('/decisions/analytics/');
  }

  // Decision Options
  static Future<ApiResponse> addOption(
      String decisionId, Map<String, dynamic> data) async {
    return post('/decisions/$decisionId/options/', data);
  }

  static Future<ApiResponse> updateOption(
      String decisionId, String optionId, Map<String, dynamic> data) async {
    return patch('/decisions/$decisionId/options/$optionId/', data);
  }

  static Future<ApiResponse> deleteOption(
      String decisionId, String optionId) async {
    return delete('/decisions/$decisionId/options/$optionId/');
  }

  // Decision Factors
  static Future<ApiResponse> addFactor(
      String decisionId, Map<String, dynamic> data) async {
    return post('/decisions/$decisionId/factors/', data);
  }

  static Future<ApiResponse> updateFactor(
      String decisionId, String factorId, Map<String, dynamic> data) async {
    return patch('/decisions/$decisionId/factors/$factorId/', data);
  }

  static Future<ApiResponse> deleteFactor(
      String decisionId, String factorId) async {
    return delete('/decisions/$decisionId/factors/$factorId/');
  }

  // Factor Ratings
  static Future<ApiResponse> saveRatings(
      String decisionId, List<Map<String, dynamic>> ratings) async {
    return post('/decisions/$decisionId/ratings/', {'ratings': ratings});
  }

  // Choose Option
  static Future<ApiResponse> chooseOption(
      String decisionId, String optionId) async {
    return post('/decisions/$decisionId/choose/', {'option_id': optionId});
  }

  // Journal
  static Future<ApiResponse> getJournalEntry(String decisionId) async {
    return get('/decisions/$decisionId/journal/');
  }

  static Future<ApiResponse> saveJournalEntry(
      String decisionId, Map<String, dynamic> data) async {
    return post('/decisions/$decisionId/journal/', data);
  }

  static Future<ApiResponse> updateJournalEntry(
      String decisionId, Map<String, dynamic> data) async {
    return patch('/decisions/$decisionId/journal/', data);
  }

  // ==================== FACTORS ENDPOINTS ====================

  static Future<ApiResponse> getFactorCategories() async {
    return get('/factors/categories/');
  }

  static Future<ApiResponse> getFactorCategory(String id) async {
    return get('/factors/categories/$id/');
  }

  static Future<ApiResponse> getFactorTemplates(
      {String? categoryId, String? search}) async {
    String query = '';
    if (categoryId != null) query += 'category=$categoryId&';
    if (search != null) query += 'search=$search&';

    return get('/factors/templates/${query.isNotEmpty ? '?$query' : ''}');
  }

  static Future<ApiResponse> getSuggestedFactors(
      String decisionCategory) async {
    return get('/factors/suggested/?category=$decisionCategory');
  }

  static Future<ApiResponse> getPopularFactors() async {
    return get('/factors/popular/');
  }

  static Future<ApiResponse> getUserCustomFactors() async {
    return get('/factors/custom/');
  }

  static Future<ApiResponse> createCustomFactor(
      Map<String, dynamic> data) async {
    return post('/factors/custom/', data);
  }

  // ==================== AI ENDPOINTS ====================

  static Future<ApiResponse> checkAIStatus() async {
    return get('/ai/status/');
  }

  static Future<ApiResponse> analyzeDecision(String decisionId) async {
    // Use longer timeout for AI analysis
    try {
      return await _requestWithRefresh(
        () => _client
            .post(
              Uri.parse('$baseUrl/ai/analyze/$decisionId/'),
              headers: _headers,
              body: jsonEncode({}),
            )
            .timeout(_aiTimeout),
        '/ai/analyze/$decisionId/',
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed');
    } on Exception {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  static Future<ApiResponse> quickAnalyze(
      Map<String, dynamic> decisionData) async {
    // Use longer timeout for AI operations
    try {
      return await _requestWithRefresh(
        () => _client
            .post(
              Uri.parse('$baseUrl/ai/quick-analyze/'),
              headers: _headers,
              body: jsonEncode(decisionData),
            )
            .timeout(_aiTimeout),
        '/ai/quick-analyze/',
      );
    } on http.ClientException {
      return ApiResponse.error('Connection failed');
    } on Exception {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  static Future<ApiResponse> suggestFactors(String decisionId) async {
    return post('/ai/suggest-factors/$decisionId/', {});
  }

  static Future<ApiResponse> generateProsCons(
      String decisionId, String optionId) async {
    return post('/ai/generate-pros-cons/$decisionId/$optionId/', {});
  }

  static Future<ApiResponse> getAIInsights(String decisionId) async {
    return get('/ai/insights/$decisionId/');
  }

  // ==================== FEEDBACK ENDPOINTS ====================

  static Future<ApiResponse> submitFeedback(Map<String, dynamic> data) async {
    return post('/feedback/', data);
  }

  static Future<ApiResponse> getUserFeedback() async {
    return get('/feedback/');
  }

  static Future<ApiResponse> rateApp(int rating, {String? review}) async {
    return post('/feedback/rating/', {
      'rating': rating,
      if (review != null) 'review': review,
    });
  }

  static Future<ApiResponse> submitAIFeedback(
      String decisionId, Map<String, dynamic> data) async {
    return post('/feedback/ai/decision/$decisionId/', data);
  }

  // Save satisfaction rating for a decision
  static Future<ApiResponse> saveSatisfaction(
      String decisionId, double satisfaction,
      {String? comment}) async {
    return post('/decisions/$decisionId/satisfaction/', {
      'satisfaction': satisfaction,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}

/// API Response wrapper
class ApiResponse {
  final bool isSuccess;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse._(isSuccess: true, data: data);
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse._(
      isSuccess: false,
      error: message,
      statusCode: statusCode,
    );
  }
}
