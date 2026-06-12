import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';

/// Auth State
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth Provider - Presentation Layer
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({required AuthRepository repository}) : _repository = repository;

  // State
  AuthStatus _status = AuthStatus.initial;
  UserEntity? _user;
  String? _error;
  bool _isOnboardingCompleted = false;

  // Getters
  AuthStatus get status => _status;
  UserEntity? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  String get userName => _user?.name ?? '';
  String get userEmail => _user?.email ?? '';

  /// Initialize auth state - call on app start
  Future<void> initialize() async {
    _status = AuthStatus.loading;
    notifyListeners();

    _isOnboardingCompleted = await _repository.isOnboardingCompleted();

    final isLoggedIn = await _repository.isLoggedIn();
    if (isLoggedIn) {
      // Get cached user first for instant UI
      _user = await _repository.getCachedUser();
      if (_user != null) {
        _status = AuthStatus.authenticated;
        notifyListeners();
      }

      // Then sync with server
      final result = await _repository.getProfile();
      result.fold(
        onSuccess: (user) {
          _user = user;
          _status = AuthStatus.authenticated;
        },
        onFailure: (message) {
          // Keep cached user if server fails
          if (_user == null) {
            _status = AuthStatus.unauthenticated;
          }
        },
      );
    } else {
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  /// Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.register(
      email: email,
      password: password,
      name: name,
    );

    return result.fold(
      onSuccess: (user) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
      onFailure: (message) {
        _error = message;
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      },
    );
  }

  /// Login user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.login(
      email: email,
      password: password,
    );

    return result.fold(
      onSuccess: (user) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
      onFailure: (message) {
        _error = message;
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      },
    );
  }

  /// Logout user
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _repository.logout();

    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Update profile
  Future<bool> updateProfile({
    String? name,
    String? avatar,
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? emailNotifications,
  }) async {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();

    final result = await _repository.updateProfile(
      name: name,
      avatar: avatar,
      theme: theme,
      language: language,
      notificationsEnabled: notificationsEnabled,
      emailNotifications: emailNotifications,
    );

    return result.fold(
      onSuccess: (user) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      },
      onFailure: (message) {
        _error = message;
        _status = AuthStatus.authenticated; // Keep authenticated on error
        notifyListeners();
        return false;
      },
    );
  }

  /// Change password
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _error = null;

    final result = await _repository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    return result.fold(
      onSuccess: (_) => true,
      onFailure: (message) {
        _error = message;
        notifyListeners();
        return false;
      },
    );
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    await _repository.setOnboardingCompleted();
    _isOnboardingCompleted = true;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    if (_status == AuthStatus.error) {
      _status =
          _user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    }
    notifyListeners();
  }
}
