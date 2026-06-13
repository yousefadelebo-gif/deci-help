import 'package:flutter/foundation.dart';

// API Constants
class ApiConstants {
  ApiConstants._();

  /// PC LAN IP running Django. Override: --dart-define=DEV_API_HOST=192.168.x.x
  static const String devApiHost = String.fromEnvironment(
    'DEV_API_HOST',
    defaultValue: '192.168.1.6',
  );

  /// Android emulator only: --dart-define=USE_EMULATOR_HOST=true
  static const bool useEmulatorHost = bool.fromEnvironment(
    'USE_EMULATOR_HOST',
    defaultValue: false,
  );

  // Base URLs - physical Android uses LAN IP; emulator uses 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final host = useEmulatorHost ? '10.0.2.2' : devApiHost;
        return 'http://$host:8000/api/v1';
      default:
        return 'http://localhost:8000/api/v1';
    }
  }
  // static const String baseUrl = 'https://your-domain.com/api/v1'; // Production

  // Auth endpoints
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String logout = '/auth/logout/';
  static const String profile = '/auth/profile/';
  static const String changePassword = '/auth/change-password/';
  static const String tokenRefresh = '/auth/token/refresh/';

  // Decision endpoints
  static const String decisions = '/decisions/';
  static const String recentDecisions = '/decisions/recent/';
  static const String decisionAnalytics = '/decisions/analytics/';

  // Factor endpoints
  static const String factorCategories = '/factors/categories/';
  static const String factorTemplates = '/factors/templates/';
  static const String suggestedFactors = '/factors/suggested/';
  static const String popularFactors = '/factors/popular/';
  static const String customFactors = '/factors/custom/';

  // AI endpoints
  static const String aiStatus = '/ai/status/';
  static const String aiAnalyze = '/ai/analyze/';
  static const String aiQuickAnalyze = '/ai/quick-analyze/';
  static const String aiSuggestFactors = '/ai/suggest-factors/';
  static const String aiGenerateProsCons = '/ai/generate-pros-cons/';
  static const String aiInsights = '/ai/insights/';

  // Feedback endpoints
  static const String feedback = '/feedback/';
  static const String appRating = '/feedback/rating/';
  static const String aiFeedback = '/feedback/ai/';
}
