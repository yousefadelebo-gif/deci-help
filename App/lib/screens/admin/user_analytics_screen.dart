/// Decision Companion - User Analytics Screen
/// Admin view for user statistics and behavior analytics

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({super.key});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
  String _selectedPeriod = '7 days';
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final response = await ApiService.getAdminUserAnalytics();
    if (!mounted) return;
    if (response.isSuccess) {
      setState(() {
        _analytics = Map<String, dynamic>.from(response.data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Failed to load user analytics';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'User Analytics',
        showBackButton: true,
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
                children: ['24 hours', '7 days', '30 days', '90 days'].map((period) {
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
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Key Metrics
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'New Users',
                    '${_metricInt('new_users')}',
                    _changeLabel('user_growth_rate'),
                    Icons.person_add_rounded,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    'Active Users',
                    '${_metricInt('active_users')}',
                    '',
                    Icons.people_rounded,
                    AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Retention Rate',
                    '${_metricDouble('retention_rate').toStringAsFixed(0)}%',
                    '',
                    Icons.repeat_rounded,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Session',
                    '${_metricDouble('average_session_minutes').toStringAsFixed(1)} min',
                    '',
                    Icons.timer_rounded,
                    AppColors.info,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // User Growth Chart
            const Text('User Growth', style: AppTypography.h4),
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
                      horizontalInterval: 100,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _userGrowth.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _userGrowth[value.toInt()]['label']?.toString() ?? '',
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
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _userGrowthSpots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: _maxLineY(_userGrowth, 'count'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // User Activity by Time
            const Text('Activity by Hour', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: List.generate(_activityByHour.length, (index) {
                      final count =
                          _asDouble(_activityByHour[index]['count']);
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: count,
                            color: count > 0
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.2),
                            width: 16,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < _activityByHour.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _activityByHour[value.toInt()]['label']?.toString() ?? '',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textTertiary,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Top Decision Categories
            const Text('Popular Decision Categories', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: _popularCategories.isEmpty
                    ? [const Text('No decision categories yet')]
                    : _popularCategories.map((row) {
                        return Column(
                          children: [
                            _buildCategoryRow(
                              row['name']?.toString() ?? 'Other',
                              _asInt(row['count']),
                              _categoryIcon(row['name']?.toString()),
                            ),
                            const Divider(height: AppSpacing.lg),
                          ],
                        );
                      }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _userGrowth =>
      List<Map<String, dynamic>>.from(_analytics['user_growth'] ?? []);

  List<Map<String, dynamic>> get _activityByHour =>
      List<Map<String, dynamic>>.from(_analytics['activity_by_hour'] ?? []);

  List<Map<String, dynamic>> get _popularCategories =>
      List<Map<String, dynamic>>.from(_analytics['popular_categories'] ?? []);

  int _metricInt(String key) => _asInt(_analytics[key]);

  double _metricDouble(String key) =>
      _asDouble(_analytics[key]);

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _changeLabel(String key) {
    final value = _metricDouble(key);
    if (value == 0) return '';
    return '${value > 0 ? '+' : ''}${value.toStringAsFixed(0)}%';
  }

  List<FlSpot> get _userGrowthSpots {
    if (_userGrowth.isEmpty) return [const FlSpot(0, 0)];
    return _userGrowth.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        _asDouble(entry.value['count']),
      );
    }).toList();
  }

  double _maxLineY(List<Map<String, dynamic>> rows, String key) {
    final values = rows
        .map((row) => _asDouble(row[key]))
        .toList();
    if (values.isEmpty) return 1;
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue <= 0 ? 1 : maxValue + 1;
  }

  int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String change,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              if (change.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    change,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.h3),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(String label, int count, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: AppTypography.labelMedium),
        ),
        Text(
          '$count decisions',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(String? label) {
    switch ((label ?? '').toLowerCase()) {
      case 'career':
        return Icons.work_rounded;
      case 'finance':
        return Icons.account_balance_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'relationship':
      case 'relationships':
        return Icons.people_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
