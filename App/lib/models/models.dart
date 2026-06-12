/// Decision Companion - Data Models
/// Core data models for the application

import 'package:flutter/material.dart';

/// User Model
class User {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime createdAt;
  final bool isGuest;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.createdAt,
    this.isGuest = false,
  });

  factory User.guest() {
    return User(
      id: 'guest',
      name: 'Guest User',
      email: '',
      createdAt: DateTime.now(),
      isGuest: true,
    );
  }
}

/// Decision Model
class Decision {
  final String id;
  final String title;
  final String? description;
  final List<DecisionOption> options;
  final List<DecisionFactor> factors;
  final DecisionResult? result;
  final DateTime createdAt;
  final DateTime? completedAt;
  final double? satisfaction;
  final String? notes;
  final DecisionStatus status;

  const Decision({
    required this.id,
    required this.title,
    this.description,
    required this.options,
    required this.factors,
    this.result,
    required this.createdAt,
    this.completedAt,
    this.satisfaction,
    this.notes,
    this.status = DecisionStatus.draft,
  });

  Decision copyWith({
    String? id,
    String? title,
    String? description,
    List<DecisionOption>? options,
    List<DecisionFactor>? factors,
    DecisionResult? result,
    DateTime? createdAt,
    DateTime? completedAt,
    double? satisfaction,
    String? notes,
    DecisionStatus? status,
  }) {
    return Decision(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      options: options ?? this.options,
      factors: factors ?? this.factors,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      satisfaction: satisfaction ?? this.satisfaction,
      notes: notes ?? this.notes,
      status: status ?? this.status,
    );
  }
}

enum DecisionStatus {
  draft,
  analyzing,
  completed,
  archived,
}

/// Decision Option Model
class DecisionOption {
  final String id;
  final String title;
  final String? description;
  final Map<String, int> factorScores; // factorId -> score (1-10)

  const DecisionOption({
    required this.id,
    required this.title,
    this.description,
    this.factorScores = const {},
  });

  DecisionOption copyWith({
    String? id,
    String? title,
    String? description,
    Map<String, int>? factorScores,
  }) {
    return DecisionOption(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      factorScores: factorScores ?? this.factorScores,
    );
  }
}

/// Decision Factor Model
class DecisionFactor {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final double weight; // 1-10
  final bool isAiSuggested;

  const DecisionFactor({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.weight = 5,
    this.isAiSuggested = false,
  });

  DecisionFactor copyWith({
    String? id,
    String? name,
    IconData? icon,
    Color? color,
    double? weight,
    bool? isAiSuggested,
  }) {
    return DecisionFactor(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      isAiSuggested: isAiSuggested ?? this.isAiSuggested,
    );
  }
}

/// Decision Result Model
class DecisionResult {
  final String recommendedOptionId;
  final double confidence; // 0-100
  final Map<String, double> optionScores; // optionId -> weighted score (0-100)
  final String explanation;
  final List<String> insights;
  final DateTime analyzedAt;

  const DecisionResult({
    required this.recommendedOptionId,
    required this.confidence,
    required this.optionScores,
    required this.explanation,
    required this.insights,
    required this.analyzedAt,
  });
}

/// AI Suggestion Model
class AiSuggestion {
  final String id;
  final String name;
  final String reason;
  final bool isIncluded;

  const AiSuggestion({
    required this.id,
    required this.name,
    required this.reason,
    this.isIncluded = false,
  });

  AiSuggestion copyWith({bool? isIncluded}) {
    return AiSuggestion(
      id: id,
      name: name,
      reason: reason,
      isIncluded: isIncluded ?? this.isIncluded,
    );
  }
}

/// User Feedback Model
class UserFeedback {
  final String id;
  final String? decisionId;
  final double rating; // 1-5
  final String? comment;
  final DateTime createdAt;

  const UserFeedback({
    required this.id,
    this.decisionId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
}

/// Journal Entry Model
class JournalEntry {
  final String id;
  final Decision decision;
  final String? reflection;
  final double? satisfaction;
  final DateTime entryDate;

  const JournalEntry({
    required this.id,
    required this.decision,
    this.reflection,
    this.satisfaction,
    required this.entryDate,
  });
}

/// Notification Model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });
}

enum NotificationType {
  decision,
  reminder,
  insight,
  system,
}

/// Analytics Data Model
class AnalyticsData {
  final int totalDecisions;
  final int completedDecisions;
  final double averageConfidence;
  final double averageSatisfaction;
  final Map<String, int> factorUsage;
  final List<DecisionTrend> trends;

  const AnalyticsData({
    required this.totalDecisions,
    required this.completedDecisions,
    required this.averageConfidence,
    required this.averageSatisfaction,
    required this.factorUsage,
    required this.trends,
  });
}

/// Decision Trend Model
class DecisionTrend {
  final DateTime date;
  final int count;
  final double averageConfidence;

  const DecisionTrend({
    required this.date,
    required this.count,
    required this.averageConfidence,
  });
}

/// Admin User Model
class AdminUser {
  final String id;
  final String name;
  final String email;
  final DateTime lastActive;
  final int totalDecisions;
  final bool isActive;

  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.lastActive,
    required this.totalDecisions,
    this.isActive = true,
  });
}
