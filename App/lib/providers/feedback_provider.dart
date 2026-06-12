import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

/// Feedback state management provider
class FeedbackProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _feedbackHistory = [];
  Map<String, dynamic>? _appRating;
  String? _error;
  String? _successMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  List<Map<String, dynamic>> get feedbackHistory => _feedbackHistory;
  Map<String, dynamic>? get appRating => _appRating;
  String? get error => _error;
  String? get successMessage => _successMessage;

  /// Fetch user's feedback history
  Future<void> fetchFeedbackHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.getUserFeedback();

    _isLoading = false;

    if (response.isSuccess) {
      _feedbackHistory = List<Map<String, dynamic>>.from(
          response.data['results'] ?? response.data);
      notifyListeners();
    } else {
      _error = response.error;
      notifyListeners();
    }
  }

  /// Submit user feedback
  Future<bool> submitFeedback({
    required String category,
    required String title,
    required String description,
    int? rating,
    String? appVersion,
    Map<String, dynamic>? deviceInfo,
  }) async {
    _isSubmitting = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final response = await ApiService.submitFeedback({
      'category': category,
      'title': title,
      'description': description,
      if (rating != null) 'rating': rating,
      if (appVersion != null) 'app_version': appVersion,
      if (deviceInfo != null) 'device_info': deviceInfo,
    });

    _isSubmitting = false;

    if (response.isSuccess) {
      final newFeedback = Map<String, dynamic>.from(response.data);
      _feedbackHistory.insert(0, newFeedback);
      _successMessage = 'Thank you for your feedback!';
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  /// Rate the app
  Future<bool> rateApp({
    required int rating,
    String? review,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.rateApp(rating, review: review);

    _isSubmitting = false;

    if (response.isSuccess) {
      _appRating = Map<String, dynamic>.from(response.data);
      _successMessage = 'Thank you for rating our app!';
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  /// Submit AI feedback for a decision
  Future<bool> submitAIFeedback({
    required String decisionId,
    required bool wasHelpful,
    int? accuracy,
    String? comments,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    final response = await ApiService.submitAIFeedback(decisionId, {
      'was_helpful': wasHelpful,
      if (comments != null) 'feedback_text': comments,
    });

    _isSubmitting = false;

    if (response.isSuccess) {
      _successMessage = 'AI feedback submitted!';
      notifyListeners();
      return true;
    } else {
      _error = response.error;
      notifyListeners();
      return false;
    }
  }

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
