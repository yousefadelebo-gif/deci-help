/// Decision Companion - Factor Templates Screen
/// Admin view for managing decision factor templates

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_text_field.dart';

class FactorTemplatesScreen extends StatefulWidget {
  const FactorTemplatesScreen({super.key});

  @override
  State<FactorTemplatesScreen> createState() => _FactorTemplatesScreenState();
}

class _FactorTemplatesScreenState extends State<FactorTemplatesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<_FactorCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final response = await ApiService.getFactorCategories();
    if (!mounted) return;

    if (!response.isSuccess) {
      setState(() {
        _error = response.error ?? 'Failed to load factor templates';
        _isLoading = false;
      });
      return;
    }

    final raw = response.data;
    final items = raw is List ? raw : List<dynamic>.from(raw['results'] ?? []);
    final categories = items
        .whereType<Map>()
        .map((item) => _FactorCategory.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    if (!mounted) return;
    _tabController.dispose();
    _tabController = TabController(
      length: categories.isEmpty ? 1 : categories.length,
      vsync: this,
    );
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Factor Templates',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            color: AppColors.surface,
            child: AppTextField(
              controller: _searchController,
              hint: 'Search factors...',
              prefixIcon: const Icon(Icons.search_rounded),
            ),
          ),

          // Stats Row
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Categories',
                    '${_categories.length}',
                    Icons.category_rounded,
                    AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    'Total Factors',
                    '${_categories.fold<int>(0, (sum, c) => sum + c.factors.length)}',
                    Icons.list_alt_rounded,
                    AppColors.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildStatCard(
                    'Total Usage',
                    _formatNumber(_categories.fold<int>(
                      0,
                      (sum, c) => sum + c.factors.fold<int>(
                        0,
                        (factorSum, f) => factorSum + f.usageCount,
                      ),
                    )),
                    Icons.analytics_rounded,
                    AppColors.success,
                  ),
                ),
              ],
            ),
          ),

          // Category Tabs
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: (_categories.isEmpty
                  ? [_FactorCategory.empty()]
                  : _categories).map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // Factor List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: (_categories.isEmpty
                  ? [_FactorCategory.empty()]
                  : _categories).map((category) {
                return _buildFactorList(category);
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
              onPressed: _loadCategories,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppSpacing.xxs),
          Text(value, style: AppTypography.labelLarge),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactorList(_FactorCategory category) {
    final query = _searchController.text.trim().toLowerCase();
    final factors = category.factors
        .where((factor) => query.isEmpty || factor.name.toLowerCase().contains(query))
        .toList();
    if (factors.isEmpty) {
      return const Center(child: Text('No factor templates found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: factors.length,
      itemBuilder: (context, index) {
        final factor = factors[index];
        return _buildFactorCard(factor, category.color);
      },
    );
  }

  Widget _buildFactorCard(_FactorTemplate factor, Color categoryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(factor.icon, color: categoryColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(factor.name, style: AppTypography.labelLarge),
                  Row(
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '${_formatNumber(factor.usageCount)} uses',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

}

class _FactorCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<_FactorTemplate> factors;

  _FactorCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.factors,
  });

  factory _FactorCategory.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? 'Category';
    return _FactorCategory(
      name: name,
      icon: _iconForName(name),
      color: _colorForName(name),
      factors: List<Map<String, dynamic>>.from(json['templates'] ?? [])
          .map(_FactorTemplate.fromJson)
          .toList(),
    );
  }

  factory _FactorCategory.empty() {
    return _FactorCategory(
      name: 'No Categories',
      icon: Icons.category_rounded,
      color: AppColors.textTertiary,
      factors: [],
    );
  }

  static IconData _iconForName(String name) {
    switch (name.toLowerCase()) {
      case 'career':
        return Icons.work_rounded;
      case 'finance':
        return Icons.account_balance_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'relationships':
      case 'relationship':
        return Icons.people_rounded;
      case 'education':
        return Icons.school_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  static Color _colorForName(String name) {
    switch (name.toLowerCase()) {
      case 'career':
        return AppColors.primary;
      case 'finance':
        return AppColors.success;
      case 'health':
        return AppColors.error;
      case 'relationships':
      case 'relationship':
        return AppColors.secondary;
      case 'education':
        return AppColors.info;
      default:
        return AppColors.accent;
    }
  }
}

class _FactorTemplate {
  final String name;
  final IconData icon;
  final int usageCount;

  _FactorTemplate({
    required this.name,
    required this.icon,
    required this.usageCount,
  });

  factory _FactorTemplate.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? 'Factor';
    return _FactorTemplate(
      name: name,
      icon: _iconForName(name),
      usageCount: (json['usage_count'] as num?)?.toInt() ?? 0,
    );
  }

  static IconData _iconForName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cost') || lower.contains('salary')) {
      return Icons.attach_money_rounded;
    }
    if (lower.contains('risk')) return Icons.warning_rounded;
    if (lower.contains('time')) return Icons.schedule_rounded;
    if (lower.contains('growth')) return Icons.trending_up_rounded;
    if (lower.contains('location')) return Icons.location_on_rounded;
    return Icons.label_outline_rounded;
  }
}
