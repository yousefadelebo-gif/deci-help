/// Decision Companion - Journal Detail Screen
/// Detailed view of a past decision

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_cards.dart';
import '../../components/rating_components.dart';
import '../../models/models.dart';

class JournalDetailScreen extends StatelessWidget {
  final Decision decision;

  const JournalDetailScreen({
    super.key,
    required this.decision,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Decision Details',
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit feature coming soon!')),
              );
            },
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: () => _showDeleteDialog(context),
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status
            Row(
              children: [
                Expanded(
                  child: Text(
                    decision.title,
                    style: AppTypography.h2,
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormat('MMMM d, yyyy • h:mm a').format(decision.createdAt),
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Chosen Option (if completed)
            if (decision.result != null) ...[
              _buildChosenOption(),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Options
            const Text('Options Considered', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            ...decision.options.map((option) {
              final isChosen =
                  decision.result?.recommendedOptionId == option.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: OptionCard(
                  title: option.title,
                  index: decision.options.indexOf(option),
                  isSelected: isChosen,
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),

            // Factors
            if (decision.factors.isNotEmpty) ...[
              const Text('Factors', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: decision.factors.map((factor) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: factor.color.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(factor.icon, size: 14, color: factor.color),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${factor.name} (${factor.weight.toInt()})',
                          style: AppTypography.labelSmall.copyWith(
                            color: factor.color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Confidence and Score (if completed)
            if (decision.result != null) ...[
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.insights_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${decision.result!.confidence.toInt()}%',
                            style: AppTypography.h2,
                          ),
                          const Text('Confidence',
                              style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: AppColors.warning,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            decision.satisfaction?.toString() ?? '--',
                            style: AppTypography.h2,
                          ),
                          const Text('Satisfaction',
                              style: AppTypography.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // AI Explanation (if completed)
            if (decision.result?.explanation != null) ...[
              const Text('AI Analysis', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              InsightCard(
                title: 'Recommendation Reason',
                description: decision.result!.explanation,
                icon: Icons.auto_awesome_rounded,
                color: AppColors.accent,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Notes/Reflection
            const Text('Notes & Reflection', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: decision.notes?.isNotEmpty == true
                  ? Text(
                      decision.notes!,
                      style: AppTypography.bodyMedium,
                    )
                  : Row(
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 20,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Add a reflection',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Satisfaction Rating
            if (decision.status == DecisionStatus.completed &&
                decision.satisfaction == null) ...[
              AppButton(
                text: 'Rate This Decision',
                variant: AppButtonVariant.outline,
                icon: Icons.star_outline_rounded,
                onPressed: () => _showRatingSheet(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    String text;
    IconData icon;

    switch (decision.status) {
      case DecisionStatus.completed:
        color = AppColors.success;
        text = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      case DecisionStatus.draft:
        color = AppColors.warning;
        text = 'Pending';
        icon = Icons.pending_rounded;
        break;
      case DecisionStatus.analyzing:
        color = AppColors.primary;
        text = 'Analyzing';
        icon = Icons.auto_awesome_rounded;
        break;
      case DecisionStatus.archived:
        color = AppColors.textTertiary;
        text = 'Archived';
        icon = Icons.archive_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildChosenOption() {
    final chosenOption = decision.options.firstWhere(
      (o) => o.id == decision.result!.recommendedOptionId,
      orElse: () => decision.options.first,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chosen Option',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  chosenOption.title,
                  style: AppTypography.h4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Decision'),
        content: const Text(
          'Are you sure you want to delete this decision? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('How satisfied are you?', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.lg),
            const InteractiveStarRating(size: 48),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Submit',
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
