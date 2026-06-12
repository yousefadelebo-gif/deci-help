import '../../../../core/services/local_storage_service.dart';
import '../models/user_model.dart';

/// Local Data Source for Auth
/// Handles all local storage operations for auth data
class AuthLocalDataSource {
  final LocalStorageService _storage;

  AuthLocalDataSource({required LocalStorageService storage})
      : _storage = storage;

  // ==================== Token Management ====================

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  String? getAccessToken() {
    return _storage.getAccessToken();
  }

  String? getRefreshToken() {
    return _storage.getRefreshToken();
  }

  Future<void> clearTokens() async {
    await _storage.clearTokens();
  }

  bool hasValidTokens() {
    return _storage.hasValidTokens();
  }

  // ==================== User Data ====================

  Future<void> saveUser(UserModel user) async {
    await _storage.saveUserData(user.toJson());
  }

  UserModel? getUser() {
    final userData = _storage.getUserData();
    if (userData == null) return null;
    return UserModel.fromJson(userData);
  }

  Future<void> clearUser() async {
    await _storage.clearUserData();
  }

  bool isLoggedIn() {
    return _storage.isLoggedIn();
  }

  // ==================== Onboarding ====================

  bool isOnboardingCompleted() {
    return _storage.isOnboardingCompleted();
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _storage.setOnboardingCompleted(completed);
  }

  // ==================== Full Logout ====================

  Future<void> logout() async {
    await _storage.logout();
  }
}
