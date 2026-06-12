import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_tokens.dart';

/// Maps API decision payloads to UI [Decision] models.
class DecisionMapper {
  static Decision fromApiMap(Map<String, dynamic> data) {
    final status = _parseStatus(data['status'] as String?);
    final createdAt = DateTime.tryParse(data['created_at']?.toString() ?? '') ??
        DateTime.now();

    final optionsRaw = data['options'] as List? ?? [];
    final options = optionsRaw.map((o) {
      final map = Map<String, dynamic>.from(o as Map);
      return DecisionOption(
        id: map['id']?.toString() ?? '',
        title: map['name']?.toString() ?? map['title']?.toString() ?? 'Option',
        description: map['description']?.toString(),
      );
    }).toList();

    final factorsRaw =
        data['decision_factors'] as List? ?? data['factors'] as List? ?? [];
    final factors = factorsRaw.map((f) {
      final map = Map<String, dynamic>.from(f as Map);
      return DecisionFactor(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Factor',
        weight: ((map['weight'] as num?)?.toDouble() ?? 0.5) * 10,
        icon: Icons.adjust_rounded,
        color: AppColors.primary,
      );
    }).toList();

    DecisionResult? result;
    final aiRec = data['ai_recommendation'];
    final chosen = data['chosen_option'];
    final recId = (aiRec is Map ? aiRec['id'] : null) ??
        (chosen is Map ? chosen['id'] : null);
    final confidence = (data['ai_confidence'] as num?)?.toDouble();
    if (recId != null || confidence != null) {
      result = DecisionResult(
        recommendedOptionId: recId?.toString() ?? options.firstOrNull?.id ?? '',
        confidence: confidence ?? 0,
        optionScores: const {},
        explanation: data['ai_explanation']?.toString() ?? '',
        insights: const [],
        analyzedAt: DateTime.tryParse(data['analyzed_at']?.toString() ?? '') ??
            createdAt,
      );
    }

    final journal = data['journal_entry'];
    String? notes;
    double? satisfaction = (data['satisfaction'] as num?)?.toDouble();
    if (journal is Map) {
      notes = journal['reflection']?.toString();
      satisfaction ??= (journal['satisfaction'] as num?)?.toDouble();
    }

    return Decision(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Untitled',
      description: data['description']?.toString(),
      options: options,
      factors: factors,
      result: result,
      createdAt: createdAt,
      completedAt: data['chosen_at'] != null
          ? DateTime.tryParse(data['chosen_at'].toString())
          : null,
      satisfaction: satisfaction,
      notes: notes,
      status: status,
    );
  }

  static DecisionStatus _parseStatus(String? status) {
    switch (status) {
      case 'completed':
        return DecisionStatus.completed;
      case 'analyzing':
      case 'in_progress':
        return DecisionStatus.analyzing;
      case 'archived':
        return DecisionStatus.archived;
      default:
        return DecisionStatus.draft;
    }
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
