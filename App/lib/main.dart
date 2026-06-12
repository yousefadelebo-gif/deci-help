/// Decision Companion - Main Application Entry Point
/// AI-Powered Decision Making App

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Dependency Injection
import 'injection_container.dart';

// Theme
import 'theme/app_theme.dart';

// Auth Provider
import 'features/auth/presentation/providers/auth_provider.dart';

// Providers
import 'providers/decision_provider.dart';
import 'providers/factor_provider.dart';
import 'providers/feedback_provider.dart';

// Screens - Splash & Onboarding
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

// Screens - Main App
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/decision/new_decision_screen.dart';
import 'screens/decision/recommendation_screen.dart';
import 'screens/journal/journal_screen.dart';
import 'screens/journal/journal_detail_screen.dart';

// Screens - Profile
import 'screens/profile/profile_screen.dart';
import 'screens/profile/my_account_screen.dart';
import 'screens/profile/past_decisions_screen.dart';
import 'screens/profile/saved_recommendations_screen.dart';
import 'screens/profile/privacy_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/profile/notifications_screen.dart';
import 'screens/profile/help_screen.dart';

// Screens - Feedback
import 'screens/feedback/feedback_screen.dart';

// Screens - Admin
import 'screens/admin/admin_dashboard.dart';
import 'screens/admin/user_analytics_screen.dart';
import 'screens/admin/manage_users_screen.dart';
import 'screens/admin/feedback_analytics_screen.dart';
import 'screens/admin/factor_templates_screen.dart';
import 'screens/admin/ai_parameters_screen.dart';

// Widgets
import 'widgets/bottom_navigation.dart';
import 'theme/app_tokens.dart';
import 'models/models.dart';
import 'utils/decision_mapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    await setupDependencies();
  } catch (error) {
    runApp(_StartupErrorApp(message: error.toString()));
    return;
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DecisionCompanionApp());
}

class _StartupErrorApp extends StatelessWidget {
  final String message;

  const _StartupErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                const Text(
                  'Failed to start app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DecisionCompanionApp extends StatelessWidget {
  const DecisionCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: sl.get<AuthProvider>(),
        ),
        ChangeNotifierProvider<DecisionProvider>.value(
          value: sl.get<DecisionProvider>(),
        ),
        ChangeNotifierProvider<FactorProvider>.value(
          value: sl.get<FactorProvider>(),
        ),
        ChangeNotifierProvider<FeedbackProvider>.value(
          value: sl.get<FeedbackProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'Decision Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/', // Start with Splash Screen
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Splash Screen
      case '/':
        return _buildRoute(const SplashScreen(), settings);

      // Onboarding & Auth
      case '/onboarding':
        return _buildRoute(const OnboardingScreen(), settings);
      case '/login':
        return _buildRoute(const LoginScreen(), settings);
      case '/signup':
        return _buildRoute(const SignupScreen(), settings);

      // Main App (with bottom navigation)
      case '/home':
        return _buildRoute(const MainNavigationScreen(), settings);
      case '/dashboard':
        return _buildRoute(
            const MainNavigationScreen(initialIndex: 0), settings);
      case '/new-decision':
        return _buildRoute(
            const MainNavigationScreen(initialIndex: 1), settings);
      case '/journal':
        return _buildRoute(
            const MainNavigationScreen(initialIndex: 2), settings);
      case '/profile':
        return _buildRoute(
            const MainNavigationScreen(initialIndex: 3), settings);

      // Decision Flow
      case '/recommendation':
        return _buildRoute(
          const RecommendationScreen(),
          settings,
        );
      case '/decision-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null) {
          return _buildRoute(
            RecommendationScreen(key: ValueKey(args['id']?.toString() ?? 'decision-detail')),
            RouteSettings(name: settings.name, arguments: args),
          );
        }
        return _buildRoute(const MainNavigationScreen(initialIndex: 0), settings);
      case '/history':
        return _buildRoute(const PastDecisionsScreen(), settings);

      // Journal
      case '/journal-detail':
        final args = settings.arguments as Map<String, dynamic>?;
        final raw = args?['decision'];
        Decision? decision;
        if (raw is Decision) {
          decision = raw;
        } else if (raw is Map<String, dynamic>) {
          decision = DecisionMapper.fromApiMap(raw);
        }
        if (decision != null) {
          return _buildRoute(
            JournalDetailScreen(decision: decision),
            settings,
          );
        }
        return _buildRoute(
            const MainNavigationScreen(initialIndex: 2), settings);

      // Profile Sub-screens
      case '/my-account':
        return _buildRoute(const MyAccountScreen(), settings);
      case '/past-decisions':
        return _buildRoute(const PastDecisionsScreen(), settings);
      case '/saved-recommendations':
        return _buildRoute(const SavedRecommendationsScreen(), settings);
      case '/privacy':
        return _buildRoute(const PrivacyScreen(), settings);
      case '/settings':
        return _buildRoute(const SettingsScreen(), settings);
      case '/notifications':
        return _buildRoute(const NotificationsScreen(), settings);
      case '/help':
        return _buildRoute(const HelpScreen(), settings);

      // Feedback
      case '/feedback':
        return _buildRoute(const FeedbackScreen(), settings);

      // Admin Panel
      case '/admin':
        return _buildRoute(const AdminDashboard(), settings);
      case '/admin/analytics':
        return _buildRoute(const UserAnalyticsScreen(), settings);
      case '/admin/users':
        return _buildRoute(const ManageUsersScreen(), settings);
      case '/admin/feedback':
        return _buildRoute(const FeedbackAnalyticsScreen(), settings);
      case '/admin/factors':
        return _buildRoute(const FactorTemplatesScreen(), settings);
      case '/admin/ai':
        return _buildRoute(const AIParametersScreen(), settings);

      default:
        return _buildRoute(const MainNavigationScreen(), settings);
    }
  }

  MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => page,
      settings: settings,
    );
  }
}

/// Main Navigation Screen with Bottom Navigation Bar
class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  /// Switch bottom-nav tab from a child screen without stacking routes.
  static void switchToTab(BuildContext context, int index) {
    _MainNavigationScreenState.of(context)?.switchToTab(index);
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  static _MainNavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainNavigationScreenState>();
  }

  void switchToTab(int index) {
    if (index < 0 || index > 3) return;
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = const [
    DashboardScreen(),
    NewDecisionScreen(),
    JournalScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
