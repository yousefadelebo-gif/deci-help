import '../../../../core/errors/result.dart';
import '../entities/entities.dart';

/// Auth Repository Interface - Domain Layer
abstract class AuthRepository {
  /// Check if user is logged in (from local storage)
  Future<bool> isLoggedIn();

  /// Get cached user data
  Future<UserEntity?> getCachedUser();

  /// Register new user
  Future<Result<UserEntity>> register({
    required String email,
    required String password,
    required String name,
  });

  /// Login user
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  });

  /// Logout user
  Future<Result<void>> logout();

  /// Get current user profile from server
  Future<Result<UserEntity>> getProfile();

  /// Update user profile
  Future<Result<UserEntity>> updateProfile({
    String? name,
    String? avatar,
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? emailNotifications,
  });

  /// Change password
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted();

  /// Set onboarding as completed
  Future<void> setOnboardingCompleted();
}
