import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Authentication state management provider
class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;
  String get userFullName =>
      '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}'.trim();
  String get userEmail => _user?['email'] ?? '';

  AuthProvider() {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await ApiService.loadTokens();
    if (ApiService.isLoggedIn) {
      await fetchProfile();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.login(email: email, password: password);

    _isLoading = false;

    if (response.isSuccess) {
      _isAuthenticated = true;
      _user = response.data['user'];
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.register(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    _isLoading = false;

    if (response.isSuccess) {
      _isAuthenticated = true;
      _user = response.data['user'];
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await ApiService.logout();

    _isAuthenticated = false;
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    final response = await ApiService.getProfile();

    if (response.isSuccess) {
      _isAuthenticated = true;
      _user = response.data;
      notifyListeners();
    } else {
      // Token might be expired
      _isAuthenticated = false;
      _user = null;
      await ApiService.clearTokens();
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.updateProfile(data);

    _isLoading = false;

    if (response.isSuccess) {
      _user = response.data;
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    _isLoading = false;

    if (response.isSuccess) {
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
