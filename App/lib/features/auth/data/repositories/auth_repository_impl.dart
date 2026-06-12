import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/result.dart';
import '../../../../services/api_service.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/datasources.dart';
import '../models/user_model.dart';

/// Auth Repository Implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  @override
  Future<bool> isLoggedIn() async {
    return _localDataSource.isLoggedIn() && _localDataSource.hasValidTokens();
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    return _localDataSource.getUser();
  }

  @override
  Future<Result<UserEntity>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _remoteDataSource.register(
        email: email,
        password: password,
        name: name,
      );

      // Save tokens
      final tokens = response['tokens'] as Map<String, dynamic>?;
      if (tokens != null) {
        await _localDataSource.saveTokens(
          accessToken: tokens['access'] ?? '',
          refreshToken: tokens['refresh'] ?? '',
        );
        // Sync tokens with ApiService for direct API calls
        await ApiService.loadTokens();
      }

      // Parse and save user
      final userData = response['user'] as Map<String, dynamic>?;
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        await _localDataSource.saveUser(user);
        return Success(user);
      }

      return const Failure('Registration failed: No user data received');
    } on AppException catch (e) {
      return Failure(e.message, code: e.code);
    } catch (e) {
      return Failure('Registration failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      // Save tokens
      final accessToken = response['access'] ?? '';
      final refreshToken = response['refresh'] ?? '';
      await _localDataSource.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      // Sync tokens with ApiService for direct API calls
      await ApiService.loadTokens();

      // Parse and save user
      final userData = response['user'] as Map<String, dynamic>?;
      if (userData != null) {
        final user = UserModel.fromJson(userData);
        await _localDataSource.saveUser(user);
        return Success(user);
      }

      // If no user data in response, fetch profile
      return await getProfile();
    } on AppException catch (e) {
      return Failure(e.message, code: e.code);
    } catch (e) {
      return Failure('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      final refreshToken = _localDataSource.getRefreshToken();
      if (refreshToken != null) {
        try {
          await _remoteDataSource.logout(refreshToken);
        } catch (_) {
          // Ignore server errors during logout
        }
      }

      // Always clear local data
      await _localDataSource.logout();
      await ApiService.clearTokens();
      return const Success(null);
    } catch (e) {
      // Still clear local data even if server logout fails
      await _localDataSource.logout();
      await ApiService.clearTokens();
      return const Success(null);
    }
  }

  @override
  Future<Result<UserEntity>> getProfile() async {
    try {
      final user = await _remoteDataSource.getProfile();
      await _localDataSource.saveUser(user);
      return Success(user);
    } on AppException catch (e) {
      // Return cached user if available
      final cachedUser = _localDataSource.getUser();
      if (cachedUser != null) {
        return Success(cachedUser);
      }
      return Failure(e.message, code: e.code);
    } catch (e) {
      final cachedUser = _localDataSource.getUser();
      if (cachedUser != null) {
        return Success(cachedUser);
      }
      return Failure('Failed to get profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<UserEntity>> updateProfile({
    String? name,
    String? avatar,
    String? theme,
    String? language,
    bool? notificationsEnabled,
    bool? emailNotifications,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (avatar != null) data['avatar'] = avatar;
      if (theme != null) data['theme'] = theme;
      if (language != null) data['language'] = language;
      if (notificationsEnabled != null) {
        data['notifications_enabled'] = notificationsEnabled;
      }
      if (emailNotifications != null) {
        data['email_notifications'] = emailNotifications;
      }

      final user = await _remoteDataSource.updateProfile(data);
      await _localDataSource.saveUser(user);
      return Success(user);
    } on AppException catch (e) {
      return Failure(e.message, code: e.code);
    } catch (e) {
      return Failure('Failed to update profile: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _remoteDataSource.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return const Success(null);
    } on AppException catch (e) {
      return Failure(e.message, code: e.code);
    } catch (e) {
      return Failure('Failed to change password: ${e.toString()}');
    }
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    return _localDataSource.isOnboardingCompleted();
  }

  @override
  Future<void> setOnboardingCompleted() async {
    await _localDataSource.setOnboardingCompleted(true);
  }
}
