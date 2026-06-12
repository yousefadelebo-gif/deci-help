/// App Constants
class AppConstants {
  AppConstants._();

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String isLoggedInKey = 'is_logged_in';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String privacyAnalyticsKey = 'privacy_analytics';
  static const String privacyCloudBackupKey = 'privacy_cloud_backup';
  static const String privacyBiometricKey = 'privacy_biometric';
  static const String privacyAutoLockKey = 'privacy_auto_lock';

  // App Info
  static const String appName = 'Decision Companion';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;
}
