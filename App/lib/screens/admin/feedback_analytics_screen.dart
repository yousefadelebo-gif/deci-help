/// Decision Companion - Feedback Analytics Screen
/// Admin view for analyzing user feedback and ratings

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
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
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  int? get _selectedDays {
    switch (_selectedPeriod) {
      case '7 days':
        return 7;
      case '30 days':
        return 30;
      case '90 days':
        return 90;
      default:
        return null;
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.getFeedbackStats(days: _selectedDays);
    if (!mounted) return;

    if (response.isSuccess) {
      setState(() {
        _stats = Map<String, dynamic>.from(response.data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Failed to load feedback analytics';
        _isLoading = false;
      });
    }
  }

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
                  'analytics': _stats,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
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
                          _loadStats();
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
                      Text(
                        _averageRating.toStringAsFixed(1),
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
                  StarRating(rating: _averageRating, size: 32),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Based on $_totalRatings ratings',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${_positivePercentage.round()}% positive ratings',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
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
                  if (_ratingDistribution.isEmpty)
                    const Text('No rating data available')
                  else
                    ..._ratingDistribution.map((row) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildRatingBar(
                            _asInt(row['stars']),
                            _asDouble(row['percentage']),
                            _asInt(row['count']),
                          ),
                        )),
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
                            if (value.toInt() >= 0 &&
                                value.toInt() < _trends.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _trends[value.toInt()]['label']?.toString() ??
                                      '',
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
                        spots: _trendSpots,
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
                  if (_categorySummary.isEmpty)
                    const Text('No feedback categories yet')
                  else
                    ..._categorySummary.map((row) => Column(
                          children: [
                            _buildCategoryRating(
                              row['label']?.toString() ?? 'Other',
                              _asDouble(row['average_rating']),
                              _asInt(row['count']),
                            ),
                            const Divider(height: AppSpacing.lg),
                          ],
                        )),
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
            if (_recentFeedback.isEmpty)
              const AppCard(
                child: Center(child: Text('No feedback yet')),
              )
            else
              ..._recentFeedback.map(_buildFeedbackCard),
          ],
        ),
      ),
    );
  }

  double get _averageRating =>
      _asDouble(_stats['average_rating']);

  int get _totalRatings => _asInt(_stats['total_app_ratings']);

  double get _positivePercentage =>
      _asDouble(_stats['positive_percentage']);

  List<Map<String, dynamic>> get _ratingDistribution =>
      List<Map<String, dynamic>>.from(_stats['rating_distribution'] ?? []);

  List<Map<String, dynamic>> get _trends =>
      List<Map<String, dynamic>>.from(_stats['trends'] ?? []);

  List<Map<String, dynamic>> get _categorySummary =>
      List<Map<String, dynamic>>.from(_stats['category_summary'] ?? []);

  List<Map<String, dynamic>> get _recentFeedback =>
      List<Map<String, dynamic>>.from(_stats['recent_feedback'] ?? []);

  List<FlSpot> get _trendSpots {
    if (_trends.isEmpty) return [const FlSpot(0, 0)];
    return _trends.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        _asDouble(entry.value['average_rating']),
      );
    }).toList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: _loadStats,
              child: const Text('Retry'),
            ),
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

  Widget _buildFeedbackCard(Map<String, dynamic> item) {
    final email = item['user_email']?.toString() ?? '';
    final name = email.isNotEmpty ? email.split('@').first : 'User';
    final rating = _asDouble(item['rating']);
    final comment = item['description']?.toString() ??
        item['title']?.toString() ??
        'No comment provided';
    final category = item['category']?.toString() ?? 'other';
    final createdAt = item['created_at']?.toString();
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
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
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
                      Text(name, style: AppTypography.labelMedium),
                      StarRating(rating: rating, size: 14),
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
                    category,
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
              comment,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _formatTime(createdAt),
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(dateStr));
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (_) {
      return '';
    }
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
