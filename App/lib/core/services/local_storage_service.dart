import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// Local storage service using SharedPreferences
/// Handles all local data persistence
class LocalStorageService {
  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ==================== Token Management ====================

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _prefs?.setString(AppConstants.accessTokenKey, accessToken);
    await _prefs?.setString(AppConstants.refreshTokenKey, refreshToken);
  }

  String? getAccessToken() {
    return _prefs?.getString(AppConstants.accessTokenKey);
  }

  String? getRefreshToken() {
    return _prefs?.getString(AppConstants.refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _prefs?.remove(AppConstants.accessTokenKey);
    await _prefs?.remove(AppConstants.refreshTokenKey);
  }

  bool hasValidTokens() {
    final accessToken = getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // ==================== User Data Management ====================

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _prefs?.setString(AppConstants.userDataKey, jsonString);
    await _prefs?.setBool(AppConstants.isLoggedInKey, true);
  }

  Map<String, dynamic>? getUserData() {
    final jsonString = _prefs?.getString(AppConstants.userDataKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUserData() async {
    await _prefs?.remove(AppConstants.userDataKey);
    await _prefs?.setBool(AppConstants.isLoggedInKey, false);
  }

  bool isLoggedIn() {
    return _prefs?.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  // ==================== App Settings ====================

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs?.setBool(AppConstants.onboardingCompletedKey, completed);
  }

  bool isOnboardingCompleted() {
    return _prefs?.getBool(AppConstants.onboardingCompletedKey) ?? false;
  }

  Future<void> setThemeMode(String theme) async {
    await _prefs?.setString(AppConstants.themeKey, theme);
  }

  String getThemeMode() {
    return _prefs?.getString(AppConstants.themeKey) ?? 'system';
  }

  Future<void> setLanguage(String language) async {
    await _prefs?.setString(AppConstants.languageKey, language);
  }

  String getLanguage() {
    return _prefs?.getString(AppConstants.languageKey) ?? 'en';
  }

  // ==================== Generic Methods ====================

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  // ==================== Full Logout ====================

  Future<void> logout() async {
    await clearTokens();
    await clearUserData();
  }
}
