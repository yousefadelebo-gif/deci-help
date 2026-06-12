/// Decision Companion - Feedback Screen
/// User feedback and ratings

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_cards.dart';
import '../../components/rating_components.dart';
import '../../providers/feedback_provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  double _overallRating = 0;
  double _easeOfUse = 0;
  double _aiQuality = 0;
  final _feedbackController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General Feedback',
    'Feature Request',
    'Bug Report',
    'AI Suggestions',
    'User Interface',
    'Other',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide an overall rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Map category to API format
    String apiCategory;
    switch (_selectedCategory) {
      case 'Bug Report':
        apiCategory = 'bug';
        break;
      case 'Feature Request':
        apiCategory = 'feature';
        break;
      case 'General Feedback':
        apiCategory = 'improvement';
        break;
      case 'AI Suggestions':
        apiCategory = 'improvement';
        break;
      default:
        apiCategory = 'other';
    }

    final feedbackProvider = context.read<FeedbackProvider>();
    final success = await feedbackProvider.submitFeedback(
      category: apiCategory,
      title: _selectedCategory ?? 'General Feedback',
      description: _feedbackController.text.isNotEmpty
          ? _feedbackController.text
          : 'Rating: $_overallRating/5',
      rating: _overallRating.round(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (success) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(feedbackProvider.error ?? 'Failed to submit feedback')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Thank You!',
                style: AppTypography.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your feedback helps us improve the app for everyone.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Done',
                size: AppButtonSize.medium,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Feedback',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    ),
                    child: const Icon(
                      Icons.rate_review_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'How are we doing?',
                    style: AppTypography.h2,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Your feedback helps us improve',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Overall Rating
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Text('Overall Experience', style: AppTypography.h4),
                  const SizedBox(height: AppSpacing.md),
                  InteractiveStarRating(
                    initialRating: _overallRating,
                    size: 40,
                    onRatingChanged: (rating) {
                      setState(() => _overallRating = rating);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _getRatingLabel(_overallRating),
                    style: AppTypography.labelMedium.copyWith(
                      color: _overallRating > 0
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Specific Ratings
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildRatingRow(
                    'Ease of Use',
                    _easeOfUse,
                    (rating) => setState(() => _easeOfUse = rating),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildRatingRow(
                    'AI Recommendations',
                    _aiQuality,
                    (rating) => setState(() => _aiQuality = rating),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category Selection
            const Text('Category', style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category : null;
                    });
                  },
                  backgroundColor: AppColors.surfaceVariant,
                  selectedColor: AppColors.primarySurface,
                  labelStyle: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  checkmarkColor: AppColors.primary,
                  showCheckmark: false,
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Comments
            AppTextArea(
              label: 'Additional Comments',
              hint: 'Share your thoughts, suggestions, or report issues...',
              controller: _feedbackController,
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            AppButton(
              text: 'Submit Feedback',
              isLoading: _isSubmitting,
              onPressed: _submitFeedback,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Maybe Later',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(
    String label,
    double rating,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTypography.bodyMedium),
        ),
        StarRating(
          rating: rating,
          size: 24,
          onRatingChanged: onChanged,
        ),
      ],
    );
  }

  String _getRatingLabel(double rating) {
    if (rating == 0) return 'Tap to rate';
    if (rating <= 1) return 'Very Poor';
    if (rating <= 2) return 'Poor';
    if (rating <= 3) return 'Average';
    if (rating <= 4) return 'Good';
    return 'Excellent!';
  }
}
