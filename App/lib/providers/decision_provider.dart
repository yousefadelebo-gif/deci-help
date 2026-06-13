import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Decision state management provider
class DecisionProvider extends ChangeNotifier {
  bool _isLoading = false;
  List<Map<String, dynamic>> _decisions = [];
  List<Map<String, dynamic>> _recentDecisions = [];
  Map<String, dynamic>? _currentDecision;
  Map<String, dynamic>? _analytics;
  String? _error;

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get decisions => _decisions;
  List<Map<String, dynamic>> get recentDecisions => _recentDecisions;
  Map<String, dynamic>? get currentDecision => _currentDecision;
  Map<String, dynamic>? get analytics => _analytics;
  String? get error => _error;

  // Fetch all decisions
  Future<void> fetchDecisions({
    String? status,
    String? category,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getDecisions(
      status: status,
      category: category,
      search: search,
    );

    _isLoading = false;

    if (response.isSuccess) {
      _decisions = _parseListResponse(response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  Future<void> fetchRecentDecisions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getRecentDecisions();

    _isLoading = false;
    if (response.isSuccess) {
      _recentDecisions = _parseListResponse(response.data);
    } else {
      _error = response.error;
    }
    notifyListeners();
  }

  // Fetch single decision
  Future<void> fetchDecision(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getDecision(id);

    _isLoading = false;

    if (response.isSuccess) {
      _currentDecision = Map<String, dynamic>.from(response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  // Create decision
  Future<String?> createDecision(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.createDecision(data);

    _isLoading = false;

    if (response.isSuccess) {
      final newDecision = Map<String, dynamic>.from(response.data);
      _decisions.insert(0, newDecision);
      _recentDecisions.insert(0, newDecision);
      if (_recentDecisions.length > 5) {
        _recentDecisions = _recentDecisions.take(5).toList();
      }
      _currentDecision = newDecision;
      notifyListeners();
      return newDecision['id'];
    } else {
      _error = response.error;
      notifyListeners();
      return null;
    }
  }

  // Update decision
  Future<bool> updateDecision(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.updateDecision(id, data);

    _isLoading = false;

    if (response.isSuccess) {
      final updated = Map<String, dynamic>.from(response.data);
      final index = _decisions.indexWhere((d) => d['id'] == id);
      if (index != -1) {
        _decisions[index] = updated;
      }
      final recentIndex = _recentDecisions.indexWhere((d) => d['id'] == id);
      if (recentIndex != -1) {
        _recentDecisions[recentIndex] = updated;
      }
      if (_currentDecision?['id'] == id) {
        _currentDecision = updated;
      }
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  // Delete decision
  Future<bool> deleteDecision(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.deleteDecision(id);

    _isLoading = false;

    if (response.isSuccess) {
      _decisions.removeWhere((d) => d['id'] == id);
      _recentDecisions.removeWhere((d) => d['id'] == id);
      if (_currentDecision?['id'] == id) {
        _currentDecision = null;
      }
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  // Add option to decision
  Future<Map<String, dynamic>?> addOption(
      String decisionId, Map<String, dynamic> data,
      {bool refresh = false}) async {
    final response = await ApiService.addOption(decisionId, data);

    if (response.isSuccess) {
      if (refresh) {
        await fetchDecision(decisionId);
      }
      return Map<String, dynamic>.from(response.data);
    } else {
      _error = response.error;
      notifyListeners();
      return null;
    }
  }

  // Add factor to decision
  Future<Map<String, dynamic>?> addFactor(
      String decisionId, Map<String, dynamic> data,
      {bool refresh = false}) async {
    final response = await ApiService.addFactor(decisionId, data);

    if (response.isSuccess) {
      if (refresh) {
        await fetchDecision(decisionId);
      }
      return Map<String, dynamic>.from(response.data);
    } else {
      _error = response.error;
      notifyListeners();
      return null;
    }
  }

  // Save factor ratings
  Future<bool> saveRatings(
      String decisionId, List<Map<String, dynamic>> ratings) async {
    final response = await ApiService.saveRatings(decisionId, ratings);

    if (response.isSuccess) {
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  // Choose option
  Future<bool> chooseOption(String decisionId, String optionId) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.chooseOption(decisionId, optionId);

    _isLoading = false;

    if (response.isSuccess) {
      _currentDecision = Map<String, dynamic>.from(response.data['decision']);
      final index = _decisions.indexWhere((d) => d['id'] == decisionId);
      if (index != -1) {
        _decisions[index]['status'] = 'completed';
      }
      final recentIndex =
          _recentDecisions.indexWhere((d) => d['id'] == decisionId);
      if (recentIndex != -1) {
        _recentDecisions[recentIndex]['status'] = 'completed';
      }
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  // AI Analysis
  Future<bool> analyzeWithAI(String decisionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.analyzeDecision(decisionId);

    _isLoading = false;

    if (response.isSuccess) {
      final payload = Map<String, dynamic>.from(response.data);
      final decision = Map<String, dynamic>.from(payload['decision'] ?? <String, dynamic>{});
      decision['factor_breakdown'] = payload['factor_breakdown'] ?? [];
      decision['scores'] = payload['scores'] ?? [];
      decision['percentages'] = payload['percentages'] ?? [];
      decision['weights'] = payload['weights'] ?? [];
      decision['winner'] = payload['winner'];
      decision['recommendation_payload'] = payload['recommendation'];
      _currentDecision = decision;
      debugPrint(
        'analyzeWithAI decision=$decisionId scores=${(decision['scores'] as List?)?.length ?? 0} factors=${(decision['factor_breakdown'] as List?)?.length ?? 0}',
      );
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  // Fetch analytics
  Future<void> fetchAnalytics() async {
    final response = await ApiService.getDecisionAnalytics();

    if (response.isSuccess) {
      _analytics = Map<String, dynamic>.from(response.data);
      notifyListeners();
    }
  }

  // Save satisfaction rating for a decision
  Future<bool> saveSatisfaction(String decisionId, double satisfaction,
      {String? comment}) async {
    final response = await ApiService.saveSatisfaction(
      decisionId,
      satisfaction,
      comment: comment,
    );

    if (response.isSuccess) {
      // Refresh analytics to update dashboard stats
      await fetchAnalytics();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  // Clear current decision
  void clearCurrentDecision() {
    _currentDecision = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Map<String, dynamic>> _parseListResponse(dynamic data) {
    final rawItems = data is Map
        ? data['results']
        : data;
    if (rawItems is! List) return [];
    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
