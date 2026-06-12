/// Decision Companion - Factor Components
/// Factor chips, cards, and editable factor widgets

import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Factor Template - predefined factors
class FactorTemplate {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const FactorTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<FactorTemplate> templates = [
    FactorTemplate(
        id: 'price',
        name: 'Price',
        icon: Icons.attach_money_rounded,
        color: Color(0xFF10B981)),
    FactorTemplate(
        id: 'quality',
        name: 'Quality',
        icon: Icons.star_rounded,
        color: Color(0xFFF59E0B)),
    FactorTemplate(
        id: 'time',
        name: 'Time Required',
        icon: Icons.schedule_rounded,
        color: Color(0xFF3B82F6)),
    FactorTemplate(
        id: 'risk',
        name: 'Risk Level',
        icon: Icons.warning_rounded,
        color: Color(0xFFEF4444)),
    FactorTemplate(
        id: 'difficulty',
        name: 'Difficulty',
        icon: Icons.fitness_center_rounded,
        color: Color(0xFF8B5CF6)),
    FactorTemplate(
        id: 'convenience',
        name: 'Convenience',
        icon: Icons.thumb_up_rounded,
        color: Color(0xFF0D9488)),
    FactorTemplate(
        id: 'longterm',
        name: 'Long-term Benefit',
        icon: Icons.trending_up_rounded,
        color: Color(0xFF6366F1)),
    FactorTemplate(
        id: 'preference',
        name: 'Personal Preference',
        icon: Icons.favorite_rounded,
        color: Color(0xFFEC4899)),
  ];
}

/// Factor Chip - small selectable chip
class FactorChip extends StatelessWidget {
  final FactorTemplate factor;
  final bool isSelected;
  final VoidCallback? onTap;

  const FactorChip({
    super.key,
    required this.factor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? factor.color.withOpacity(0.15)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? factor.color : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              factor.icon,
              size: 16,
              color: isSelected ? factor.color : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              factor.name,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? factor.color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: AppSpacing.xxs),
              Icon(
                Icons.check_rounded,
                size: 14,
                color: factor.color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Editable Factor Card - expanded factor with weight and scores
class EditableFactorCard extends StatelessWidget {
  final FactorTemplate factor;
  final double weight;
  final List<String> options;
  final Map<String, int> scores;
  final ValueChanged<double>? onWeightChanged;
  final Function(String option, int score)? onScoreChanged;
  final VoidCallback? onRemove;

  const EditableFactorCard({
    super.key,
    required this.factor,
    required this.weight,
    required this.options,
    required this.scores,
    this.onWeightChanged,
    this.onScoreChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: factor.color.withOpacity(0.3)),
        boxShadow: AppElevation.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: factor.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  factor.icon,
                  size: 18,
                  color: factor.color,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  factor.name,
                  style: AppTypography.h4,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Weight Slider
          Row(
            children: [
              Text(
                'Weight:',
                style: AppTypography.labelMedium,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: factor.color,
                    thumbColor: factor.color,
                    overlayColor: factor.color.withOpacity(0.1),
                  ),
                  child: Slider(
                    value: weight,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: onWeightChanged,
                  ),
                ),
              ),
              Container(
                width: 36,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: factor.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  weight.toInt().toString(),
                  style: AppTypography.labelMedium.copyWith(
                    color: factor.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Option Scores
          Text(
            'Scores:',
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...options.map((option) => _buildOptionScore(context, option)),
        ],
      ),
    );
  }

  Widget _buildOptionScore(BuildContext context, String option) {
    final score = scores[option] ?? 5;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              option,
              style: AppTypography.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(10, (index) {
                  final isSelected = index < score;
                  return GestureDetector(
                    onTap: () => onScoreChanged?.call(option, index + 1),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? factor.color.withOpacity(0.2 + (index * 0.08))
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? factor.color
                                : AppColors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AI Suggested Factor Card
class SuggestedFactorCard extends StatelessWidget {
  final String name;
  final String reason;
  final bool isIncluded;
  final ValueChanged<bool>? onToggle;

  const SuggestedFactorCard({
    super.key,
    required this.name,
    required this.reason,
    this.isIncluded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isIncluded ? AppColors.primarySurface : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isIncluded ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 16,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  reason,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          Switch(
            value: isIncluded,
            onChanged: onToggle,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
