import 'core/services/local_storage_service.dart';
import 'core/network/http_client.dart';
import 'features/auth/data/datasources/datasources.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'providers/decision_provider.dart';
import 'providers/factor_provider.dart';
import 'providers/feedback_provider.dart';
import 'services/api_service.dart';

/// Simple Service Locator for Dependency Injection
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._();
  factory ServiceLocator() => _instance;
  ServiceLocator._();

  final Map<Type, dynamic> _services = {};

  T get<T>() {
    final service = _services[T];
    if (service == null) {
      throw Exception('Service $T not registered');
    }
    return service as T;
  }

  void register<T>(T service) {
    _services[T] = service;
  }

  bool isRegistered<T>() {
    return _services.containsKey(T);
  }

  void reset() {
    _services.clear();
  }
}

/// Initialize all dependencies
Future<void> setupDependencies() async {
  final sl = ServiceLocator();

  // Core Services
  final localStorage = await LocalStorageService.getInstance();
  sl.register<LocalStorageService>(localStorage);

  // Network
  final httpClient = HttpClient(storage: localStorage);
  sl.register<HttpClient>(httpClient);

  // Auth Feature
  final authRemoteDataSource = AuthRemoteDataSource(client: httpClient);
  sl.register<AuthRemoteDataSource>(authRemoteDataSource);

  final authLocalDataSource = AuthLocalDataSource(storage: localStorage);
  sl.register<AuthLocalDataSource>(authLocalDataSource);

  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );
  sl.register<AuthRepository>(authRepository);

  final authProvider = AuthProvider(repository: authRepository);
  sl.register<AuthProvider>(authProvider);

  // Load API tokens
  await ApiService.loadTokens();

  // Decision Provider
  final decisionProvider = DecisionProvider();
  sl.register<DecisionProvider>(decisionProvider);

  // Factor Provider
  final factorProvider = FactorProvider();
  sl.register<FactorProvider>(factorProvider);

  // Feedback Provider
  final feedbackProvider = FeedbackProvider();
  sl.register<FeedbackProvider>(feedbackProvider);
}

/// Get service locator instance
final sl = ServiceLocator();
