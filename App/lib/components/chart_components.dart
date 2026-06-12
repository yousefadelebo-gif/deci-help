/// Decision Companion - Chart Components
/// Radar and Bar charts using fl_chart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_tokens.dart';

/// Radar Chart for option comparison
class OptionRadarChart extends StatelessWidget {
  final List<String> factors;
  final Map<String, List<double>> optionScores;
  final List<String> options;

  const OptionRadarChart({
    super.key,
    required this.factors,
    required this.optionScores,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.2,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          radarBorderData: const BorderSide(color: AppColors.border, width: 1),
          gridBorderData: const BorderSide(color: AppColors.borderLight, width: 1),
          tickBorderData: const BorderSide(color: Colors.transparent),
          tickCount: 5,
          ticksTextStyle: const TextStyle(color: Colors.transparent, fontSize: 0),
          titleTextStyle: AppTypography.labelSmall,
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, _) {
            if (index < factors.length) {
              return RadarChartTitle(
                text: factors[index],
                angle: 0,
              );
            }
            return const RadarChartTitle(text: '');
          },
          dataSets: _buildDataSets(),
        ),
      ),
    );
  }

  List<RadarDataSet> _buildDataSets() {
    final datasets = <RadarDataSet>[];
    
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      final scores = optionScores[option] ?? [];
      final color = AppColors.chartColors[i % AppColors.chartColors.length];
      
      datasets.add(
        RadarDataSet(
          fillColor: color.withOpacity(0.2),
          borderColor: color,
          borderWidth: 2,
          entryRadius: 4,
          dataEntries: scores.map((score) => RadarEntry(value: score)).toList(),
        ),
      );
    }
    
    return datasets;
  }
}

/// Bar Chart for score comparison
class OptionBarChart extends StatelessWidget {
  final List<String> options;
  final List<double> scores;
  final int? highlightIndex;

  const OptionBarChart({
    super.key,
    required this.options,
    required this.scores,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          minY: 0,
          groupsSpace: 16,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: AppColors.textPrimary,
              tooltipRoundedRadius: AppSpacing.radiusSm,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${options[groupIndex]}\n${rod.toY.toInt()}%',
                  AppTypography.labelSmall.copyWith(color: AppColors.textOnPrimary),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < options.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        options[index],
                        style: AppTypography.labelSmall,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: AppTypography.caption,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.borderLight,
                strokeWidth: 1,
              );
            },
          ),
          barGroups: _buildBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return List.generate(options.length, (index) {
      final isHighlighted = highlightIndex == index;
      final color = isHighlighted
          ? AppColors.primary
          : AppColors.chartColors[index % AppColors.chartColors.length];
      
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: scores[index],
            color: color,
            width: 32,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSm),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 100,
              color: AppColors.surfaceVariant,
            ),
          ),
        ],
      );
    });
  }
}

/// Confidence Indicator
class ConfidenceIndicator extends StatelessWidget {
  final double confidence; // 0-100
  final double size;

  const ConfidenceIndicator({
    super.key,
    required this.confidence,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 75
        ? AppColors.success
        : confidence >= 50
            ? AppColors.warning
            : AppColors.error;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: confidence / 100,
              strokeWidth: 8,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${confidence.toInt()}%',
                style: AppTypography.h2.copyWith(color: color),
              ),
              Text(
                'Confidence',
                style: AppTypography.caption,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Progress Bar
class AppProgressBar extends StatelessWidget {
  final double value; // 0-1
  final Color? color;
  final double height;

  const AppProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: color ?? AppColors.primary,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

/// Line Chart for analytics
class AnalyticsLineChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final Color? lineColor;

  const AnalyticsLineChart({
    super.key,
    required this.values,
    required this.labels,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.borderLight,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < labels.length && index % 2 == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        labels[index],
                        style: AppTypography.caption,
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}',
                    style: AppTypography.caption,
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                values.length,
                (index) => FlSpot(index.toDouble(), values[index]),
              ),
              isCurved: true,
              color: lineColor ?? AppColors.primary,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.surface,
                    strokeWidth: 2,
                    strokeColor: lineColor ?? AppColors.primary,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: (lineColor ?? AppColors.primary).withOpacity(0.1),
              ),
            ),
          ],
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }
}

/// Pie Chart for distribution
class DistributionPieChart extends StatelessWidget {
  final Map<String, double> data;

  const DistributionPieChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList();
    
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(entries.length, (index) {
                  final color = AppColors.chartColors[index % AppColors.chartColors.length];
                  return PieChartSectionData(
                    value: entries[index].value,
                    color: color,
                    radius: 30,
                    showTitle: false,
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(entries.length, (index) {
              final color = AppColors.chartColors[index % AppColors.chartColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        entries[index].key,
                        style: AppTypography.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${entries[index].value.toInt()}%',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
