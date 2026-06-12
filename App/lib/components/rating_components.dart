/// Decision Companion - Rating Components
/// Star rating and satisfaction widgets

import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

/// Star Rating Widget
class StarRating extends StatelessWidget {
  final double rating;
  final int maxRating;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;
  final ValueChanged<double>? onRatingChanged;
  final bool allowHalf;

  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 32,
    this.activeColor,
    this.inactiveColor,
    this.onRatingChanged,
    this.allowHalf = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating, (index) {
        final starValue = index + 1;
        final isActive = rating >= starValue;
        final isHalf = allowHalf && rating >= starValue - 0.5 && rating < starValue;

        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!(starValue.toDouble())
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              isActive
                  ? Icons.star_rounded
                  : isHalf
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded,
              size: size,
              color: isActive || isHalf
                  ? (activeColor ?? AppColors.warning)
                  : (inactiveColor ?? AppColors.border),
            ),
          ),
        );
      }),
    );
  }
}

/// Interactive Star Rating
class InteractiveStarRating extends StatefulWidget {
  final double initialRating;
  final int maxRating;
  final double size;
  final ValueChanged<double>? onRatingChanged;

  const InteractiveStarRating({
    super.key,
    this.initialRating = 0,
    this.maxRating = 5,
    this.size = 40,
    this.onRatingChanged,
  });

  @override
  State<InteractiveStarRating> createState() => _InteractiveStarRatingState();
}

class _InteractiveStarRatingState extends State<InteractiveStarRating> {
  late double _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxRating, (index) {
        final starValue = index + 1;
        final isActive = _rating >= starValue;

        return GestureDetector(
          onTap: () {
            setState(() {
              _rating = starValue.toDouble();
            });
            widget.onRatingChanged?.call(_rating);
          },
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.all(4),
            child: Icon(
              isActive ? Icons.star_rounded : Icons.star_outline_rounded,
              size: widget.size,
              color: isActive ? AppColors.warning : AppColors.border,
            ),
          ),
        );
      }),
    );
  }
}

/// Satisfaction Badge
class SatisfactionBadge extends StatelessWidget {
  final double satisfaction; // 1-5

  const SatisfactionBadge({
    super.key,
    required this.satisfaction,
  });

  @override
  Widget build(BuildContext context) {
    final label = _getLabel();
    final color = _getColor();
    final icon = _getIcon();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel() {
    if (satisfaction >= 4.5) return 'Excellent';
    if (satisfaction >= 3.5) return 'Good';
    if (satisfaction >= 2.5) return 'Fair';
    if (satisfaction >= 1.5) return 'Poor';
    return 'Very Poor';
  }

  Color _getColor() {
    if (satisfaction >= 4.5) return AppColors.success;
    if (satisfaction >= 3.5) return AppColors.secondary;
    if (satisfaction >= 2.5) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getIcon() {
    if (satisfaction >= 4.5) return Icons.sentiment_very_satisfied_rounded;
    if (satisfaction >= 3.5) return Icons.sentiment_satisfied_rounded;
    if (satisfaction >= 2.5) return Icons.sentiment_neutral_rounded;
    if (satisfaction >= 1.5) return Icons.sentiment_dissatisfied_rounded;
    return Icons.sentiment_very_dissatisfied_rounded;
  }
}
