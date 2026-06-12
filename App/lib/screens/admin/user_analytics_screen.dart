/// Decision Companion - User Analytics Screen
/// Admin view for user statistics and behavior analytics

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'User Analytics',
        showBackButton: true,
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
                    '428',
                    '+18%',
                    Icons.person_add_rounded,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    'Active Users',
                    '1,247',
                    '+5%',
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
                    '73%',
                    '+2%',
                    Icons.repeat_rounded,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildMetricCard(
                    'Avg. Session',
                    '8.5 min',
                    '+1.2',
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
                            final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            if (value.toInt() >= 0 && value.toInt() < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  days[value.toInt()],
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
                        spots: const [
                          FlSpot(0, 180),
                          FlSpot(1, 220),
                          FlSpot(2, 195),
                          FlSpot(3, 280),
                          FlSpot(4, 310),
                          FlSpot(5, 260),
                          FlSpot(6, 340),
                        ],
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
                    maxY: 400,
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
                    barGroups: List.generate(12, (index) {
                      final values = [30, 20, 15, 10, 25, 45, 80, 95, 85, 70, 55, 40];
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: values[index].toDouble(),
                            color: index == 7 || index == 8
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.4),
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
                            final hours = ['6a', '8a', '10a', '12p', '2p', '4p', '6p', '8p', '10p', '12a', '2a', '4a'];
                            if (value.toInt() >= 0 && value.toInt() < hours.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  hours[value.toInt()],
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

            // User Demographics
            const Text('User Demographics', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildDemographicRow('18-24', 0.15, '15%'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDemographicRow('25-34', 0.35, '35%'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDemographicRow('35-44', 0.28, '28%'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDemographicRow('45-54', 0.14, '14%'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildDemographicRow('55+', 0.08, '8%'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Top Decision Categories
            const Text('Popular Decision Categories', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildCategoryRow('Career', 892, Icons.work_rounded),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRow('Finance', 756, Icons.account_balance_rounded),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRow('Health', 634, Icons.favorite_rounded),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRow('Education', 521, Icons.school_rounded),
                  const Divider(height: AppSpacing.lg),
                  _buildCategoryRow('Relationships', 489, Icons.people_rounded),
                ],
              ),
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

  Widget _buildDemographicRow(String label, double percentage, String percentText) {
    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: AppTypography.labelMedium,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 40,
          child: Text(
            percentText,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
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
}
