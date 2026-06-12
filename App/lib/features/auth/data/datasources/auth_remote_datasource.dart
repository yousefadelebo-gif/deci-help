import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/http_client.dart';
import '../models/user_model.dart';

/// Remote Data Source for Auth
/// Handles all API calls related to authentication
class AuthRemoteDataSource {
  final HttpClient _client;

  AuthRemoteDataSource({required HttpClient client}) : _client = client;

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.post(ApiConstants.register, {
      'email': email,
      'password': password,
      'password_confirm': password,
      'name': name,
    });
    return response;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(ApiConstants.login, {
      'email': email,
      'password': password,
    });
    return response;
  }

  Future<void> logout(String refreshToken) async {
    await _client.post(ApiConstants.logout, {
      'refresh': refreshToken,
    });
  }

  Future<UserModel> getProfile() async {
    final response = await _client.get(ApiConstants.profile);
    return UserModel.fromJson(response);
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.patch(ApiConstants.profile, data);
    return UserModel.fromJson(response);
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _client.post(ApiConstants.changePassword, {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _client.post(ApiConstants.tokenRefresh, {
      'refresh': refreshToken,
    });
    return response;
  }
}
