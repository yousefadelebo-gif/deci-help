/// Decision Companion - Factor Templates Screen
/// Admin view for managing decision factor templates

import 'package:flutter/material.dart';
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

  final List<_FactorCategory> _categories = [
    _FactorCategory(
      name: 'Career',
      icon: Icons.work_rounded,
      color: AppColors.primary,
      factors: [
        _FactorTemplate(
            name: 'Salary', icon: Icons.attach_money_rounded, usageCount: 2847),
        _FactorTemplate(
            name: 'Work-Life Balance',
            icon: Icons.balance_rounded,
            usageCount: 2341),
        _FactorTemplate(
            name: 'Growth Potential',
            icon: Icons.trending_up_rounded,
            usageCount: 1923),
        _FactorTemplate(
            name: 'Location',
            icon: Icons.location_on_rounded,
            usageCount: 1756),
        _FactorTemplate(
            name: 'Company Culture',
            icon: Icons.people_rounded,
            usageCount: 1542),
      ],
    ),
    _FactorCategory(
      name: 'Finance',
      icon: Icons.account_balance_rounded,
      color: AppColors.success,
      factors: [
        _FactorTemplate(
            name: 'Return on Investment',
            icon: Icons.show_chart_rounded,
            usageCount: 1876),
        _FactorTemplate(
            name: 'Risk Level', icon: Icons.warning_rounded, usageCount: 1654),
        _FactorTemplate(
            name: 'Liquidity', icon: Icons.water_drop_rounded, usageCount: 987),
        _FactorTemplate(
            name: 'Time Horizon',
            icon: Icons.schedule_rounded,
            usageCount: 876),
      ],
    ),
    _FactorCategory(
      name: 'Health',
      icon: Icons.favorite_rounded,
      color: AppColors.error,
      factors: [
        _FactorTemplate(
            name: 'Physical Health Impact',
            icon: Icons.fitness_center_rounded,
            usageCount: 1234),
        _FactorTemplate(
            name: 'Mental Well-being',
            icon: Icons.psychology_rounded,
            usageCount: 1198),
        _FactorTemplate(
            name: 'Long-term Effects',
            icon: Icons.timeline_rounded,
            usageCount: 876),
      ],
    ),
    _FactorCategory(
      name: 'Relationships',
      icon: Icons.people_rounded,
      color: AppColors.secondary,
      factors: [
        _FactorTemplate(
            name: 'Family Impact',
            icon: Icons.family_restroom_rounded,
            usageCount: 1543),
        _FactorTemplate(
            name: 'Social Circle', icon: Icons.groups_rounded, usageCount: 987),
        _FactorTemplate(
            name: 'Partner Preferences',
            icon: Icons.favorite_border_rounded,
            usageCount: 765),
      ],
    ),
    _FactorCategory(
      name: 'Education',
      icon: Icons.school_rounded,
      color: AppColors.info,
      factors: [
        _FactorTemplate(
            name: 'Learning Opportunity',
            icon: Icons.auto_stories_rounded,
            usageCount: 1234),
        _FactorTemplate(
            name: 'Accreditation',
            icon: Icons.verified_rounded,
            usageCount: 876),
        _FactorTemplate(
            name: 'Cost', icon: Icons.payments_rounded, usageCount: 2341),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddCategoryDialog(),
          ),
        ],
      ),
      body: Column(
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
                    '28.4K',
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
              tabs: _categories.map((category) {
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
              children: _categories.map((category) {
                return _buildFactorList(category);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFactorDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Factor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: category.factors.length,
      itemBuilder: (context, index) {
        final factor = category.factors[index];
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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => _showEditFactorDialog(factor),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.error,
                  onPressed: () => _showDeleteConfirmation(factor),
                ),
              ],
            ),
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

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    IconData selectedIcon = Icons.category_rounded;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: nameController,
              label: 'Category Name',
              hint: 'Enter category name',
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Select Icon', style: AppTypography.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                Icons.work_rounded,
                Icons.account_balance_rounded,
                Icons.favorite_rounded,
                Icons.school_rounded,
                Icons.home_rounded,
                Icons.flight_rounded,
                Icons.restaurant_rounded,
                Icons.sports_esports_rounded,
              ].map((icon) {
                return InkWell(
                  onTap: () {
                    selectedIcon = icon;
                    (context as Element).markNeedsBuild();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: selectedIcon == icon
                          ? AppColors.primarySurface
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      icon,
                      color: selectedIcon == icon
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                _categories.add(
                  _FactorCategory(
                    name: name,
                    icon: selectedIcon,
                    color: AppColors.primary,
                    factors: [],
                  ),
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Category "$name" added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddFactorDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    // ignore: unused_local_variable
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Factor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: nameController,
                label: 'Factor Name',
                hint: 'Enter factor name',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: descriptionController,
                label: 'Description',
                hint: 'Enter factor description',
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Category', style: AppTypography.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                hint: const Text('Select category'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.name,
                    child: Row(
                      children: [
                        Icon(cat.icon, size: 18, color: cat.color),
                        const SizedBox(width: AppSpacing.sm),
                        Text(cat.name),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) => selectedCategory = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty || selectedCategory == null) return;
              setState(() {
                final category = _categories.firstWhere(
                  (c) => c.name == selectedCategory,
                );
                category.factors.add(
                  _FactorTemplate(
                    name: name,
                    icon: Icons.label_outline_rounded,
                    usageCount: 0,
                  ),
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Factor "$name" added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditFactorDialog(_FactorTemplate factor) {
    final nameController = TextEditingController(text: factor.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Factor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: nameController,
              label: 'Factor Name',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              setState(() {
                for (final category in _categories) {
                  final index = category.factors.indexOf(factor);
                  if (index != -1) {
                    category.factors[index] = _FactorTemplate(
                      name: name,
                      icon: factor.icon,
                      usageCount: factor.usageCount,
                    );
                  }
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Factor updated')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(_FactorTemplate factor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Factor?'),
        content: Text(
          'Are you sure you want to delete "${factor.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (final category in _categories) {
                  category.factors.remove(factor);
                }
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${factor.name}" deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
}
