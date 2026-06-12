/// Decision Companion - Feedback Analytics Screen
/// Admin view for analyzing user feedback and ratings

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_tokens.dart';
import '../../utils/export_helpers.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';
import '../../components/rating_components.dart';

class FeedbackAnalyticsScreen extends StatefulWidget {
  const FeedbackAnalyticsScreen({super.key});

  @override
  State<FeedbackAnalyticsScreen> createState() =>
      _FeedbackAnalyticsScreenState();
}

class _FeedbackAnalyticsScreenState extends State<FeedbackAnalyticsScreen> {
  String _selectedPeriod = '30 days';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Feedback Analytics',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () async {
              await ExportHelpers.copyJsonToClipboard([
                {
                  'period': _selectedPeriod,
                  'exported_at': DateTime.now().toIso8601String(),
                  'summary': 'Feedback analytics snapshot',
                },
              ]);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report summary copied to clipboard'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    ['7 days', '30 days', '90 days', 'All time'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(period),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedPeriod = period);
                        }
                      },
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primarySurface,
                      labelStyle: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Overall Rating Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '4.6',
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '/5',
                          style: AppTypography.h3.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const StarRating(rating: 4.6, size: 32),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Based on 1,247 reviews',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.trending_up_rounded,
                            size: 16, color: AppColors.success),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '+0.3 from last period',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Rating Distribution
            const Text('Rating Distribution', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildRatingBar(5, 0.65, 812),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRatingBar(4, 0.22, 275),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRatingBar(3, 0.08, 100),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRatingBar(2, 0.03, 37),
                  const SizedBox(height: AppSpacing.sm),
                  _buildRatingBar(1, 0.02, 23),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Feedback Trends Chart
            const Text('Feedback Trends', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value >= 1 && value <= 5) {
                              return Text(
                                value.toInt().toString(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final weeks = ['W1', 'W2', 'W3', 'W4'];
                            if (value.toInt() >= 0 &&
                                value.toInt() < weeks.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  weeks[value.toInt()],
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 4.3),
                          FlSpot(1, 4.4),
                          FlSpot(2, 4.5),
                          FlSpot(3, 4.6),
                        ],
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: 1,
                    maxY: 5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Category Breakdown
            const Text('Feedback by Category', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildCategoryRating('General Feedback', 4.7, 523),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRating('AI Suggestions', 4.5, 312),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRating('User Interface', 4.6, 256),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRating('Feature Requests', 4.2, 98),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRating('Bug Reports', 3.8, 58),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recent Feedback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Feedback', style: AppTypography.h4),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._buildRecentFeedback(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int stars, double percentage, int count) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            '$stars',
            style: AppTypography.labelMedium,
          ),
        ),
        const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.warning),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 50,
          child: Text(
            '($count)',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRating(String category, double rating, int count) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category, style: AppTypography.labelMedium),
              Text(
                '$count reviews',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              rating.toString(),
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildRecentFeedback() {
    final feedback = [
      _FeedbackItem(
        name: 'Sarah J.',
        rating: 5,
        comment:
            'Love the AI recommendations! They\'ve helped me make better decisions.',
        date: '2 hours ago',
        category: 'AI Suggestions',
      ),
      _FeedbackItem(
        name: 'Michael C.',
        rating: 4,
        comment: 'Great app overall. Would love to see more factor templates.',
        date: '5 hours ago',
        category: 'Feature Request',
      ),
      _FeedbackItem(
        name: 'Emma W.',
        rating: 5,
        comment:
            'The journal feature is fantastic for tracking my past decisions.',
        date: '1 day ago',
        category: 'General',
      ),
    ];

    return feedback.map((item) => _buildFeedbackCard(item)).toList();
  }

  Widget _buildFeedbackCard(_FeedbackItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primarySurface,
                  child: Text(
                    item.name[0],
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: AppTypography.labelMedium),
                      StarRating(rating: item.rating.toDouble(), size: 14),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    item.category,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.comment,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.date,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackItem {
  final String name;
  final int rating;
  final String comment;
  final String date;
  final String category;

  _FeedbackItem({
    required this.name,
    required this.rating,
    required this.comment,
    required this.date,
    required this.category,
  });
}
