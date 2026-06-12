import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Factor state management provider
class FactorProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _templates = [];
  List<Map<String, dynamic>> _suggestedFactors = [];
  List<Map<String, dynamic>> _popularFactors = [];
  List<Map<String, dynamic>> _customFactors = [];
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get templates => _templates;
  List<Map<String, dynamic>> get suggestedFactors => _suggestedFactors;
  List<Map<String, dynamic>> get popularFactors => _popularFactors;
  List<Map<String, dynamic>> get customFactors => _customFactors;
  String? get error => _error;

  /// Fetch all factor categories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getFactorCategories();

    _isLoading = false;

    if (response.isSuccess) {
      _categories = List<Map<String, dynamic>>.from(
          response.data['results'] ?? response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  /// Fetch factor templates, optionally filtered by category
  Future<void> fetchTemplates({String? categoryId, String? search}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getFactorTemplates(
      categoryId: categoryId,
      search: search,
    );

    _isLoading = false;

    if (response.isSuccess) {
      _templates = List<Map<String, dynamic>>.from(
          response.data['results'] ?? response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  /// Fetch AI suggested factors for a decision category
  Future<void> fetchSuggestedFactors(String decisionCategory) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getSuggestedFactors(decisionCategory);

    _isLoading = false;

    if (response.isSuccess) {
      _suggestedFactors = List<Map<String, dynamic>>.from(
          response.data['results'] ?? response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  /// Fetch popular factors
  Future<void> fetchPopularFactors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getPopularFactors();

    _isLoading = false;

    if (response.isSuccess) {
      _popularFactors = List<Map<String, dynamic>>.from(
          response.data['results'] ?? response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  /// Fetch user's custom factors
  Future<void> fetchCustomFactors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getUserCustomFactors();

    _isLoading = false;

    if (response.isSuccess) {
      _customFactors = List<Map<String, dynamic>>.from(
          response.data['results'] ?? response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  /// Create a custom factor
  Future<Map<String, dynamic>?> createCustomFactor(
      Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.createCustomFactor(data);

    _isLoading = false;

    if (response.isSuccess) {
      final newFactor = Map<String, dynamic>.from(response.data);
      _customFactors.insert(0, newFactor);
      notifyListeners();
      return newFactor;
    } else {
      _error = response.error;
      notifyListeners();
      return null;
    }
  }

  /// Initialize - load all factor data
  Future<void> initialize() async {
    await Future.wait([
      fetchCategories(),
      fetchPopularFactors(),
      fetchCustomFactors(),
    ]);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
