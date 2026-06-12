/// Decision Companion - Saved Recommendations Screen
/// View saved AI recommendation results

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/decision_provider.dart';

class SavedRecommendationsScreen extends StatefulWidget {
  const SavedRecommendationsScreen({super.key});

  @override
  State<SavedRecommendationsScreen> createState() =>
      _SavedRecommendationsScreenState();
}

class _SavedRecommendationsScreenState
    extends State<SavedRecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DecisionProvider>().fetchDecisions();
    });
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hours ago';
      if (diff.inDays < 7) return '${diff.inDays} days ago';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Saved Recommendations',
        showBackButton: true,
      ),
      body: Consumer<DecisionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.decisions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter decisions with AI recommendations
          final recommendations = provider.decisions.where((d) {
            return d['ai_recommendation'] != null ||
                d['ai_confidence'] != null ||
                d['status'] == 'completed';
          }).toList();

          if (recommendations.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchDecisions(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final decision = recommendations[index];
                final aiRecommendation = decision['ai_recommendation'];
                final recommendedOption = aiRecommendation != null
                    ? aiRecommendation['name'] ?? 'AI Recommendation'
                    : decision['chosen_option']?['name'] ?? 'View Details';
                final confidence = decision['ai_confidence'];

                return _buildRecommendationCard(
                  title: decision['title'] ?? 'Untitled Decision',
                  recommendation: recommendedOption,
                  confidence: confidence?.toInt(),
                  time: _formatTime(
                      decision['analyzed_at'] ?? decision['created_at']),
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/decision-detail',
                      arguments: decision,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_outline_rounded,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No saved recommendations',
            style: AppTypography.h4.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'AI recommendations you save will appear here',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard({
    required String title,
    required String recommendation,
    int? confidence,
    required String time,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // AI Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Recommended: ',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: AppTypography.bodyMedium.copyWith(
                                color: const Color(0xFF0D9488),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          if (confidence != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
                              ),
                              child: Text(
                                '$confidence% match',
                                style: AppTypography.caption.copyWith(
                                  color: const Color(0xFF16A34A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Text(
                            time,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
