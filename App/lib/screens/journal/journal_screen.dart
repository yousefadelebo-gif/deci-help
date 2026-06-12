/// Decision Companion - Journal Screen
/// Timeline list of past decisions

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';
import '../../providers/decision_provider.dart';
import '../../widgets/decision_edit_sheet.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  String _filterStatus = 'All';
  final List<String> _filters = ['All', 'Completed', 'Pending', 'Archived'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DecisionProvider>().fetchDecisions();
    });
  }

  List<Map<String, dynamic>> _getFilteredDecisions(
      List<Map<String, dynamic>> decisions) {
    if (_filterStatus == 'All') return decisions;
    if (_filterStatus == 'Completed') {
      return decisions.where((d) => d['status'] == 'completed').toList();
    }
    if (_filterStatus == 'Pending') {
      return decisions
          .where((d) => d['status'] == 'draft' || d['status'] == 'in_progress')
          .toList();
    }
    return decisions.where((d) => d['status'] == 'archived').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Decision Journal',
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _filterStatus == filter;
                return FilterChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _filterStatus = filter);
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
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Timeline List
          Expanded(
            child: Consumer<DecisionProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.decisions.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredDecisions =
                    _getFilteredDecisions(provider.decisions);

                if (filteredDecisions.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.screenPadding,
                  ),
                  itemCount: filteredDecisions.length,
                  itemBuilder: (context, index) {
                    final decision = filteredDecisions[index];
                    final createdAt =
                        DateTime.tryParse(decision['created_at'] ?? '') ??
                            DateTime.now();
                    final prevCreatedAt = index > 0
                        ? DateTime.tryParse(filteredDecisions[index - 1]
                                    ['created_at'] ??
                                '') ??
                            DateTime.now()
                        : null;

                    final showDate = index == 0 ||
                        (prevCreatedAt != null &&
                            !_isSameDay(prevCreatedAt, createdAt));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDate) ...[
                          Padding(
                            padding: EdgeInsets.only(
                              top: index == 0 ? 0 : AppSpacing.md,
                              bottom: AppSpacing.sm,
                            ),
                            child: Text(
                              _formatDate(createdAt),
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                        _buildTimelineItem(decision, index),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: const Icon(
              Icons.book_outlined,
              size: 40,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No decisions yet',
            style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start making decisions to see them here',
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> decision, int index) {
    final status = decision['status'] ?? 'draft';
    final createdAt =
        DateTime.tryParse(decision['created_at'] ?? '') ?? DateTime.now();
    final options = List<Map<String, dynamic>>.from(decision['options'] ?? []);
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

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: status == 'completed'
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 2,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.border,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: DecisionCard(
                title: decision['title'] ?? 'Untitled',
                date: DateFormat('h:mm a').format(createdAt),
                outcome: outcome,
                satisfaction: decision['satisfaction']?.toDouble(),
                onTap: () => _openDetail(decision),
                onEdit: () => _editDecision(decision),
                onDelete: () => _deleteDecision(decision),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  void _openDetail(Map<String, dynamic> decision) {
    Navigator.of(context)
        .pushNamed('/journal-detail', arguments: {'decision': decision});
  }

  Future<void> _editDecision(Map<String, dynamic> decision) async {
    final id = decision['id']?.toString();
    if (id == null || id.isEmpty) return;

    final journal = decision['journal_entry'];
    final reflection = journal is Map ? journal['reflection']?.toString() : null;

    final updated = await showDecisionEditSheet(
      context,
      decisionId: id,
      initialTitle: decision['title']?.toString() ?? 'Untitled',
      initialReflection: reflection ?? decision['notes']?.toString(),
    );

    if (updated == true && mounted) {
      await context.read<DecisionProvider>().fetchDecisions();
    }
  }

  void _deleteDecision(Map<String, dynamic> decision) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Decision'),
        content: const Text('Are you sure you want to delete this decision?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true && decision['id'] != null) {
      final success =
          await context.read<DecisionProvider>().deleteDecision(decision['id']);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Decision deleted')),
        );
      }
    }
  }
}
