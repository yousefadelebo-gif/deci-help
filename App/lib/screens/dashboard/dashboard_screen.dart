/// Decision Companion - Dashboard Screen
/// Home screen with greeting, cards, and recent decisions

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_cards.dart';
import '../../main.dart' show MainNavigationScreen;
import '../../providers/decision_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch decisions and analytics when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final decisionProvider = context.read<DecisionProvider>();
      decisionProvider.fetchDecisions();
      decisionProvider.fetchAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: _buildHeader(context),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding),
                child: _buildQuickActions(context),
              ),
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                child: _buildStatsSection(),
              ),
            ),

            // Recent Decisions Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  0,
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Decisions', style: AppTypography.h3),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/history'),
                      child: Text(
                        'View All',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Decisions List
            Consumer<DecisionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.decisions.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (provider.decisions.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.psychology_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No decisions yet',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Start your first decision!',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final decisions = provider.decisions.take(5).toList();
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final decision = decisions[index];
                        final options = List<Map<String, dynamic>>.from(
                            decision['options'] ?? []);
                        final chosenOption = decision['chosen_option'];
                        final aiRecommendation = decision['ai_recommendation'];

                        String? outcome;
                        if (chosenOption != null) {
                          outcome = chosenOption['name'];
                        } else if (aiRecommendation != null) {
                          outcome = aiRecommendation['name'];
                        } else if (options.isNotEmpty) {
                          outcome = options.first['name'];
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: DecisionCard(
                            title: decision['title'] ?? 'Untitled',
                            date: decision['created_at'] != null
                                ? DateFormat('MMM d, yyyy').format(
                                    DateTime.parse(decision['created_at']))
                                : '',
                            outcome: outcome,
                            satisfaction: decision['satisfaction']?.toDouble(),
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                '/decision-detail',
                                arguments: decision,
                              );
                            },
                          ),
                        );
                      },
                      childCount: decisions.length,
                    ),
                  ),
                );
              },
            ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => MainNavigationScreen.switchToTab(context, 1),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Decision'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final greeting = _getGreeting();
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.userName.split(' ').first.isNotEmpty
        ? authProvider.userName.split(' ').first
        : 'User';

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Welcome back, $userName',
                style: AppTypography.h2,
              ),
            ],
          ),
        ),
        // Notification bell
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/notifications'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget _buildQuickActions(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.textOnPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start New Decision',
                  style: AppTypography.h4,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Let AI help you make the best choice',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
      onTap: () => MainNavigationScreen.switchToTab(context, 1),
    );
  }

  Widget _buildStatsSection() {
    return Consumer<DecisionProvider>(
      builder: (context, provider, _) {
        final analytics = provider.analytics;
        final totalDecisions = analytics?['total_decisions'] ?? 0;
        final avgConfidence = analytics?['average_confidence'] ?? 0;
        final avgSatisfaction = analytics?['average_satisfaction'] ?? 0.0;
        final pendingCount = analytics?['pending_count'] ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Insights', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    label: 'Decisions Made',
                    value: '$totalDecisions',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatsCard(
                    label: 'Avg. Confidence',
                    value: '${avgConfidence.round()}%',
                    icon: Icons.insights_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: StatsCard(
                    label: 'Satisfaction',
                    value: avgSatisfaction.toStringAsFixed(1),
                    icon: Icons.star_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatsCard(
                    label: 'Pending',
                    value: '$pendingCount',
                    icon: Icons.pending_outlined,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
