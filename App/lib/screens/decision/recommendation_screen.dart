/// Decision Companion - AI Recommendation Screen
/// Shows analysis results with charts and recommendations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
// Theme tokens handled by widgets
import '../../components/rating_components.dart';
import '../../providers/decision_provider.dart';
import '../../providers/feedback_provider.dart';
import '../../services/api_service.dart';
import '../../main.dart' show MainNavigationScreen;

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  // Parsed from route arguments / provider
  String _decisionTitle = '';
  List<String> _options = [];
  List<String> _factors = [];
  List<double> _scores = [];
  int _recommendedIndex = 0;
  double _confidence = 0;
  String _explanation = '';
  Map<String, List<double>> _radarData = {};
  List<Map<String, dynamic>> _factorBreakdown = [];
  List<double> _normalizedPercentages = [];
  String? _decisionId;
  String? _loadedForDecisionId;

  // AI-generated insights from backend
  List<String> _insights = [];
  List<String> _considerations = [];
  List<String> _potentialRisks = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDecisionData();
  }

  void _loadDecisionData() {
    final args = ModalRoute.of(context)?.settings.arguments;
    Map<String, dynamic>? decision;

    if (args is Map<String, dynamic>) {
      decision = args;
    }

    decision ??= context.read<DecisionProvider>().currentDecision;

    final incomingId = decision?['id']?.toString();
    if (incomingId != null && incomingId == _loadedForDecisionId) {
      return;
    }

    _decisionTitle = '';
    _options = [];
    _factors = [];
    _scores = [];
    _normalizedPercentages = [];
    _recommendedIndex = 0;
    _confidence = 0;
    _explanation = '';
    _radarData = {};
    _factorBreakdown = [];
    _insights = [];
    _considerations = [];
    _potentialRisks = [];

    if (decision != null) {
      _decisionId = decision['id']?.toString();
      _decisionTitle = decision['title']?.toString() ?? '';

      final optionsList =
          List<Map<String, dynamic>>.from(decision['options'] ?? []);
      final factorsList =
          List<Map<String, dynamic>>.from(decision['decision_factors'] ?? []);

      _options =
          optionsList.map((o) => o['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
      _factors =
          factorsList.map((f) => f['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
      _factorBreakdown = List<Map<String, dynamic>>.from(
        decision['factor_breakdown'] ?? [],
      );
      final apiScores = List<Map<String, dynamic>>.from(decision['scores'] ?? []);
      final apiPercentages =
          List<Map<String, dynamic>>.from(decision['percentages'] ?? []);
      debugPrint(
        'Recommendation data decision=$_decisionId options=${optionsList.length} factors=${factorsList.length} scores=${apiScores.length} percentages=${apiPercentages.length} factorBreakdown=${_factorBreakdown.length}',
      );

      // AI confidence is returned as decimal (0.75 = 75%), convert to percentage
      final aiConfidence = decision['ai_confidence'];
      if (aiConfidence is num) {
        _confidence = aiConfidence <= 1
            ? (aiConfidence * 100).toDouble()
            : aiConfidence.toDouble();
      }
      _explanation = decision['ai_explanation']?.toString() ?? '';

      // Parse AI insights from backend
      final aiInsights = decision['ai_insights'];
      if (aiInsights is Map<String, dynamic>) {
        _insights = List<String>.from(aiInsights['insights'] ?? []);
        _considerations = List<String>.from(aiInsights['considerations'] ?? []);
        _potentialRisks =
            List<String>.from(aiInsights['potential_risks'] ?? []);
      }

      final aiRecommendation = decision['ai_recommendation_data'];
      _scores = List.filled(_options.length, 0.0);
      _normalizedPercentages = List.filled(_options.length, 0.0);

      if (apiScores.isNotEmpty) {
        for (int i = 0; i < _options.length; i++) {
          final row = apiScores.firstWhere(
            (s) => s['option_name']?.toString() == _options[i],
            orElse: () => <String, dynamic>{},
          );
          final raw = (row['score'] as num?)?.toDouble();
          if (raw != null) {
            _scores[i] = (raw * 10).clamp(0, 10).toDouble();
          }
          final pctRow = apiPercentages.firstWhere(
            (p) => p['option_name']?.toString() == _options[i],
            orElse: () => <String, dynamic>{},
          );
          final pct = (pctRow['percentage'] as num?)?.toDouble();
          if (pct != null) {
            _normalizedPercentages[i] = pct.clamp(0, 100).toDouble();
          } else if (raw != null) {
            _normalizedPercentages[i] = (raw * 100).clamp(0, 100).toDouble();
          }
        }
      } else if (_factorBreakdown.isNotEmpty) {
        for (int i = 0; i < _options.length; i++) {
          final optionName = _options[i];
          final breakdown = _factorBreakdown.firstWhere(
            (b) => b['option_name']?.toString() == optionName,
            orElse: () => <String, dynamic>{},
          );
          final weighted = (breakdown['weighted_score'] as num?)?.toDouble();
          if (weighted != null) {
            _scores[i] = (weighted * 10).clamp(0, 10).toDouble();
            _normalizedPercentages[i] =
                (weighted * 100).clamp(0, 100).toDouble();
          }
        }
      } else {
        _scores = optionsList.map<double>((o) {
          final score = o['ai_score'];
          if (score is num) {
            return score <= 1 ? (score * 10).toDouble() : score.toDouble();
          }
          return 0.0;
        }).toList();
        _normalizedPercentages =
            _scores.map<double>((s) => ((s / 10) * 100).clamp(0, 100).toDouble()).toList();
      }

      if (aiRecommendation != null) {
        final recId = aiRecommendation['id']?.toString();
        _recommendedIndex =
            optionsList.indexWhere((o) => o['id']?.toString() == recId);
        if (_recommendedIndex < 0) _recommendedIndex = 0;
      } else if (_scores.isNotEmpty) {
        _recommendedIndex =
            _scores.indexOf(_scores.reduce((a, b) => a > b ? a : b));
      }

      if (_factors.isEmpty && _factorBreakdown.isNotEmpty) {
        final nested = _factorBreakdown.first['factors'];
        if (nested is List && nested.isNotEmpty) {
          _factors = nested
              .map((f) => (f as Map)['factor_name']?.toString() ?? '')
              .where((n) => n.isNotEmpty)
              .cast<String>()
              .toList();
        }
      }

      if (_factorBreakdown.isNotEmpty) {
        for (final breakdown in _factorBreakdown) {
          final optionName = breakdown['option_name']?.toString() ?? '';
          if (optionName.isEmpty) continue;
          final factors = List<Map<String, dynamic>>.from(breakdown['factors'] ?? []);
          _radarData[optionName] = _factors.map<double>((factorName) {
            final factor = factors.firstWhere(
              (f) => f['factor_name']?.toString() == factorName,
              orElse: () => <String, dynamic>{},
            );
            final raw = (factor['raw_score'] as num?)?.toDouble();
            return (raw ?? 0).clamp(0, 10).toDouble();
          }).toList();
        }
      } else {
        for (final option in optionsList) {
          final optionName = option['name']?.toString() ?? '';
          if (optionName.isEmpty) continue;
          final ratings =
              List<Map<String, dynamic>>.from(option['factor_ratings'] ?? []);
          _radarData[optionName] = _factors.map<double>((factorName) {
            final rating = ratings.firstWhere(
              (r) => r['decision_factor_name']?.toString() == factorName,
              orElse: () => <String, dynamic>{},
            );
            final score = (rating['score'] as num?)?.toDouble();
            return (score ?? 0).clamp(0, 10).toDouble();
          }).toList();
        }
      }

      _loadedForDecisionId = incomingId;
      debugPrint(
        'Recommendation charts resolved scores=${_scores.length} radar=${_radarData.length} detailed=${_normalizedPercentages.length} factors=${_factors.length}',
      );

      if (mounted) setState(() {});
    }
  }

  Future<void> _saveToJournal() async {
    final id = _decisionId ??
        context.read<DecisionProvider>().currentDecision?['id']?.toString();
    if (id != null) {
      await ApiService.saveJournalEntry(id, {
        'reflection': _explanation,
        'outcome_notes': 'Saved from AI recommendation',
      });
      await context.read<DecisionProvider>().updateDecision(id, {
        'status': 'completed',
      });
    }
    if (!mounted) return;
    MainNavigationScreen.switchToTab(context, 2);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to journal')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: Color(0xFF1A1A2E), size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'AI Recommendation',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A2E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // Decision Title
            Text(
              _decisionTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Recommended Choice Card
            _buildRecommendedChoiceCard(),
            const SizedBox(height: 20),

            // AI Analysis Card
            _buildAIAnalysisCard(),
            const SizedBox(height: 20),

            // Score Comparison Chart
            if (_scores.isNotEmpty) _buildScoreComparisonCard(),
            const SizedBox(height: 20),

            // Factor Analysis Radar Chart
            if (_radarData.isNotEmpty && _factors.isNotEmpty)
              _buildFactorAnalysisCard(),
            const SizedBox(height: 20),

            // Detailed Scores
            if (_normalizedPercentages.isNotEmpty) _buildDetailedScoresCard(),
            const SizedBox(height: 24),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // Save to Journal Button
                  GestureDetector(
                    onTap: _saveToJournal,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00897B), Color(0xFF0288D1)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Save to Journal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rate This Recommendation Button
                  GestureDetector(
                    onTap: _showRatingSheet,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_outline,
                              color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Rate This Recommendation',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedChoiceCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00897B), Color(0xFF0288D1)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Recommended Choice',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Option Name
          Text(
            _options.isNotEmpty ? _options[_recommendedIndex] : 'N/A',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Confidence Level
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence Level',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              Text(
                '${_confidence.toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: (_confidence / 100).clamp(0, 1),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Factors analyzed
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.white.withOpacity(0.9),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Based on ${_factors.length} factors analyzed',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[600],
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Analysis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _explanation,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey[700],
            ),
          ),

          // Show insights if available
          if (_insights.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInsightSection(
              'Key Insights',
              Icons.psychology_rounded,
              const Color(0xFF6366F1),
              _insights,
            ),
          ],

          // Show considerations if available
          if (_considerations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInsightSection(
              'Things to Consider',
              Icons.pending_actions_rounded,
              const Color(0xFF0EA5E9),
              _considerations,
            ),
          ],

          // Show risks if available
          if (_potentialRisks.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInsightSection(
              'Potential Risks',
              Icons.warning_amber_rounded,
              const Color(0xFFF59E0B),
              _potentialRisks,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightSection(
      String title, IconData icon, Color color, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildScoreComparisonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Comparison',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 10,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${_options[groupIndex]}\nscore : ${rod.toY.toStringAsFixed(1)}',
                        const TextStyle(
                          color: Color(0xFF1A1A2E),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
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
                        if (value.toInt() < _options.length) {
                          return SizedBox(
                            width: 60,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _options[value.toInt()],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
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
                      reservedSize: 30,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(_options.length, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _scores[index],
                        width: 40,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00BCD4), Color(0xFF00897B)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 10,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorAnalysisCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Factor Analysis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBackgroundColor: Colors.transparent,
                borderData: FlBorderData(show: false),
                radarBorderData: const BorderSide(color: Colors.transparent),
                titlePositionPercentageOffset: 0.2,
                titleTextStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                getTitle: (index, angle) {
                  if (index < _factors.length) {
                    final name = _factors[index].length > 15
                        ? '${_factors[index].substring(0, 12)}...'
                        : _factors[index];
                    return RadarChartTitle(text: name);
                  }
                  return const RadarChartTitle(text: '');
                },
                dataSets: _buildRadarDataSets(),
                tickCount: 4,
                ticksTextStyle: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                ),
                tickBorderData: BorderSide(color: Colors.grey[300]!),
                gridBorderData: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(_options.length, (index) {
              final colors = [
                const Color(0xFF80DEEA),
                const Color(0xFF1565C0),
                const Color(0xFF4CAF50),
                const Color(0xFFFF9800),
                const Color(0xFF9C27B0),
                const Color(0xFFE91E63),
                const Color(0xFF3F51B5),
                const Color(0xFF009688),
              ];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _options[index].length > 20
                        ? '${_options[index].substring(0, 17)}...'
                        : _options[index],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  List<RadarDataSet> _buildRadarDataSets() {
    final palette = <Color>[
      const Color(0xFF80DEEA),
      const Color(0xFF1565C0),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF3F51B5),
      const Color(0xFF009688),
    ];

    final datasets = <RadarDataSet>[];
    int colorIndex = 0;

    for (final entry in _radarData.entries) {
      final color = palette[colorIndex % palette.length];
      datasets.add(
        RadarDataSet(
          fillColor: color.withOpacity(0.25),
          borderColor: color,
          borderWidth: 2,
          entryRadius: 3,
          dataEntries: entry.value.map((v) => RadarEntry(value: v)).toList(),
        ),
      );
      colorIndex++;
    }

    return datasets;
  }

  Widget _buildDetailedScoresCard() {
    // Sort options by score (descending)
    final sortedIndices = List.generate(_options.length, (i) => i);
    sortedIndices.sort((a, b) {
      final scoreA = _normalizedPercentages.length > a ? _normalizedPercentages[a] : 0;
      final scoreB = _normalizedPercentages.length > b ? _normalizedPercentages[b] : 0;
      return scoreB.compareTo(scoreA);
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Scores',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 16),
          ...sortedIndices.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final optionIndex = entry.value;
            final optionName = _options[optionIndex];
            final score = _normalizedPercentages[optionIndex];
            final isFirst = rank == 1;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xFF0288D1)
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            rank.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isFirst ? Colors.white : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          optionName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${score.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF00897B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (score / 100).clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF7043)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showRatingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RatingBottomSheet(
        onSubmit: (rating, comment) {
          Navigator.pop(context);
          if (_decisionId != null) {
            context.read<FeedbackProvider>().submitAIFeedback(
                  decisionId: _decisionId!,
                  wasHelpful: rating >= 3,
                  accuracy: rating.round(),
                  comments: comment.isNotEmpty ? comment : null,
                );
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }
}

class _RatingBottomSheet extends StatefulWidget {
  final Function(double rating, String comment) onSubmit;

  const _RatingBottomSheet({required this.onSubmit});

  @override
  State<_RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<_RatingBottomSheet> {
  double _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Rate This Recommendation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve our AI suggestions',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          InteractiveStarRating(
            initialRating: _rating,
            size: 48,
            onRatingChanged: (rating) {
              setState(() => _rating = rating);
            },
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Add a comment (optional)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF00897B)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _rating > 0
                ? () => widget.onSubmit(_rating, _commentController.text)
                : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _rating > 0
                    ? const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF0288D1)],
                      )
                    : null,
                color: _rating <= 0 ? Colors.grey[200] : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _rating > 0 ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
