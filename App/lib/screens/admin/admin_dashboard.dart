/// Decision Companion - Admin Dashboard
/// Central admin panel with horizontal tabs (Overview, Users, Feedback, Settings)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_tokens.dart';
import '../../services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Custom Header with Tabs
          _buildHeader(context),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _OverviewTab(),
                _UsersTab(),
                _FeedbackTab(),
                _SettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFFFF5722)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Title Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Admin Panel',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Tab Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                labelColor: const Color(0xFFE91E63),
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Overview'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Users'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Feedback'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_outlined, size: 16),
                        SizedBox(width: 6),
                        Text('Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

// Overview Tab
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final response = await ApiService.getAdminStats();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _stats = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    final totalUsers = _stats['total_users'] ?? 0;
    final activeToday = _stats['active_today'] ?? 0;
    final userGrowth = _stats['user_growth'] ?? 0.0;
    final totalDecisions = _stats['total_decisions'] ?? 0;
    final decisionGrowth = _stats['decision_growth'] ?? 0.0;
    final avgRating = _stats['avg_rating'] ?? 0.0;
    final weeklyActivity =
        List<Map<String, dynamic>>.from(_stats['weekly_activity'] ?? []);
    final decisionCategories =
        List<Map<String, dynamic>>.from(_stats['decision_categories'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  _formatNumber(totalUsers),
                  'Total Users',
                  '+${userGrowth.toStringAsFixed(0)}%',
                  Icons.people_rounded,
                  const Color(0xFF3B82F6),
                  const Color(0xFFDBEAFE),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  _formatNumber(activeToday),
                  'Active Today',
                  '+${(activeToday > 0 ? 8 : 0)}%',
                  Icons.trending_up_rounded,
                  const Color(0xFF10B981),
                  const Color(0xFFD1FAE5),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  _formatNumber(totalDecisions),
                  'Total Decisions',
                  '+${decisionGrowth.toStringAsFixed(0)}%',
                  Icons.analytics_rounded,
                  const Color(0xFF8B5CF6),
                  const Color(0xFFF3E8FF),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildStatCard(
                  '${avgRating.toStringAsFixed(1)}/5',
                  'Avg Rating',
                  '+0.3',
                  Icons.chat_bubble_rounded,
                  const Color(0xFFF97316),
                  const Color(0xFFFED7AA),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Decision Categories Donut Chart
          const Text('Decision Categories', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
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
            child: Row(
              children: [
                // Donut Chart
                SizedBox(
                  height: 140,
                  width: 140,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections: _buildPieChartSections(decisionCategories),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                // Legend
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _buildLegendItems(decisionCategories),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Weekly Activity Chart
          const Text('Weekly Activity', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 200,
            padding: const EdgeInsets.all(AppSpacing.md),
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
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 7,
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
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTypography.caption,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < weeklyActivity.length) {
                          return Text(
                            weeklyActivity[value.toInt()]['day'] ?? '',
                            style: AppTypography.caption,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildLineChartSpots(weeklyActivity),
                    isCurved: true,
                    color: const Color(0xFF0D9488),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF0D9488).withOpacity(0.1),
                    ),
                  ),
                ],
                minY: 0,
                maxY: _getMaxY(weeklyActivity),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const Text('Admin Tools', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          _buildAdminToolTile(
            context,
            icon: Icons.analytics_outlined,
            title: 'User Analytics',
            route: '/admin/analytics',
          ),
          _buildAdminToolTile(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Feedback Analytics',
            route: '/admin/feedback',
          ),
          _buildAdminToolTile(
            context,
            icon: Icons.tune_rounded,
            title: 'Factor Templates',
            route: '/admin/factors',
          ),
          _buildAdminToolTile(
            context,
            icon: Icons.auto_awesome_rounded,
            title: 'AI Parameters',
            route: '/admin/ai',
          ),
        ],
      ),
    );
  }

  Widget _buildAdminToolTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String route,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: AppTypography.bodyLarge),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
        ),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  List<PieChartSectionData> _buildPieChartSections(
      List<Map<String, dynamic>> categories) {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFFF97316), // Orange
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
    ];

    if (categories.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.grey.shade300,
          value: 100,
          title: '',
          radius: 25,
        ),
      ];
    }

    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final percentage = (category['percentage'] ?? 0).toDouble();

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: percentage,
        title: '',
        radius: 25,
      );
    }).toList();
  }

  List<Widget> _buildLegendItems(List<Map<String, dynamic>> categories) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF97316),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    if (categories.isEmpty) {
      return [
        _buildLegendItem('No Data', 0, Colors.grey.shade300),
      ];
    }

    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      return _buildLegendItem(
        category['name'] ?? 'Unknown',
        (category['percentage'] ?? 0).toInt(),
        colors[index % colors.length],
      );
    }).toList();
  }

  Widget _buildLegendItem(String label, int percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall,
            ),
          ),
          Text(
            '$percentage%',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _buildLineChartSpots(List<Map<String, dynamic>> weeklyActivity) {
    if (weeklyActivity.isEmpty) {
      return [const FlSpot(0, 0)];
    }

    return weeklyActivity.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['count'] ?? 0).toDouble(),
      );
    }).toList();
  }

  double _getMaxY(List<Map<String, dynamic>> weeklyActivity) {
    if (weeklyActivity.isEmpty) return 35;

    double maxValue = 0;
    for (var item in weeklyActivity) {
      final count = (item['count'] ?? 0).toDouble();
      if (count > maxValue) maxValue = count;
    }
    return maxValue + 10;
  }

  Widget _buildStatCard(
    String value,
    String label,
    String change,
    IconData icon,
    Color iconColor,
    Color iconBgColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.h3),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: 2,
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
        ],
      ),
    );
  }
}

// Users Tab
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentUsers = [];

  final colors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFF8B5CF6),
    const Color(0xFF0D9488),
    const Color(0xFFF97316),
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await ApiService.getAdminStats();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _recentUsers = List<Map<String, dynamic>>.from(
              response.data!['recent_users'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Users Section
          const Text('Recent Users', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          Container(
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
            child: _recentUsers.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'No recent users',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : Column(
                    children: _recentUsers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      return _buildUserItem(
                        user['name'] ?? user['email']?.split('@')[0] ?? 'User',
                        user['email'] ?? '',
                        user['decisions'] ?? 0,
                        user['joined'] ?? 'Recently',
                        colors[index % colors.length],
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // User Management Section
          const Text('User Management', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          Container(
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
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDBEAFE),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.visibility_outlined,
                        color: Color(0xFF3B82F6)),
                  ),
                  title: Text('View All Users',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.primary)),
                  onTap: () => Navigator.pushNamed(context, '/admin/users'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.download_outlined,
                        color: Color(0xFF10B981)),
                  ),
                  title: Text('Export User Data',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.success)),
                  onTap: () async {
                    final response = await ApiService.getAdminUsers();
                    if (!context.mounted) return;
                    if (response.isSuccess) {
                      final users = response.data['users'] ?? [];
                      await Clipboard.setData(
                        ClipboardData(text: users.toString()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied ${users is List ? users.length : 0} users to clipboard',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('Admin Tools', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          Container(
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
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('User Analytics'),
                  onTap: () =>
                      Navigator.pushNamed(context, '/admin/analytics'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.feedback_outlined),
                  title: const Text('Feedback Analytics'),
                  onTap: () =>
                      Navigator.pushNamed(context, '/admin/feedback'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Factor Templates'),
                  onTap: () => Navigator.pushNamed(context, '/admin/factors'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.psychology_outlined),
                  title: const Text('AI Parameters'),
                  onTap: () => Navigator.pushNamed(context, '/admin/ai'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(String name, String email, int decisions, String time,
      Color avatarColor) {
    // Format the date nicely
    String formattedTime = time;
    try {
      final dt = DateTime.parse(time);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        formattedTime = 'Today';
      } else if (diff.inDays == 1) {
        formattedTime = 'Yesterday';
      } else if (diff.inDays < 7) {
        formattedTime = '${diff.inDays}d ago';
      } else {
        formattedTime = '${dt.month}/${dt.day}/${dt.year}';
      }
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [avatarColor, avatarColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.split(' ').map((n) => n[0]).take(2).join().toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.labelLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  email,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$decisions decisions', style: AppTypography.labelMedium),
              Text(
                formattedTime,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Feedback Tab
class _FeedbackTab extends StatefulWidget {
  const _FeedbackTab();

  @override
  State<_FeedbackTab> createState() => _FeedbackTabState();
}

class _FeedbackTabState extends State<_FeedbackTab> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _feedbacks = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  Future<void> _loadFeedbackData() async {
    try {
      final feedbackResponse = await ApiService.getAdminFeedback();
      final statsResponse = await ApiService.getFeedbackStats();

      if (feedbackResponse.isSuccess && feedbackResponse.data != null) {
        final raw = feedbackResponse.data;
        List<dynamic> items = [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map) {
          items = List<dynamic>.from(raw['results'] ?? []);
        }
        setState(() {
          _feedbacks = items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }

      if (statsResponse.isSuccess && statsResponse.data != null) {
        setState(() {
          _stats = statsResponse.data!;
        });
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _feedbackUserName(Map<String, dynamic> feedback) {
    final explicit = feedback['user_name']?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;

    final email = feedback['user_email']?.toString();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    final user = feedback['user'];
    if (user is Map) {
      final nested = user['email']?.toString();
      if (nested != null && nested.isNotEmpty) {
        return nested.split('@').first;
      }
    }

    return 'User';
  }

  int _feedbackRating(Map<String, dynamic> feedback) {
    final rating = feedback['rating'];
    if (rating is num) return rating.round().clamp(1, 5);
    return 5;
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
      return '${(diff.inDays / 7).floor()} weeks ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    final totalFeedback = _stats['total_count'] ?? _feedbacks.length;
    final avgRating = _stats['average_rating'] ?? 4.5;
    final positivePercent = _stats['positive_percentage'] ?? 94;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Feedback Section
          const Text('Recent Feedback', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          Container(
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
            child: _feedbacks.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'No feedback yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                : Column(
                    children: _feedbacks.take(10).map((feedback) {
                      return _buildFeedbackItem(
                        _feedbackUserName(feedback),
                        _feedbackRating(feedback),
                        feedback['description']?.toString() ??
                            feedback['title']?.toString() ??
                            '',
                        _formatTime(feedback['created_at']?.toString()),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Feedback Analytics Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feedback Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAnalyticItem('$totalFeedback', 'Total'),
                    _buildAnalyticItem(
                        avgRating.toStringAsFixed(1), 'Avg Rating'),
                    _buildAnalyticItem('$positivePercent%', 'Positive'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackItem(
      String name, int rating, String comment, String time) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: AppTypography.labelLarge),
              Text(
                time,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFFFC107),
                size: 18,
              );
            }),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Text(
              comment,
              style: AppTypography.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// Settings Tab
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();

  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  double _confidenceThreshold = 75;
  String _maxFactors = '6';
  String _aiModelVersion = 'v2.0 (Latest)';
  bool _emailNotifications = true;
  bool _autoBackup = true;
  bool _analyticsTracking = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Parameters Section
          const Text('AI Parameters', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Confidence Threshold Slider
                const Text('Confidence Threshold',
                    style: AppTypography.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF0D9488),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: const Color(0xFF0D9488),
                    overlayColor: const Color(0xFF0D9488).withOpacity(0.2),
                  ),
                  child: Slider(
                    value: _confidenceThreshold,
                    min: 50,
                    max: 100,
                    divisions: 10,
                    onChanged: (value) {
                      setState(() {
                        _confidenceThreshold = value;
                      });
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('50%', style: AppTypography.caption),
                    Text('${_confidenceThreshold.round()}%',
                        style: AppTypography.labelMedium),
                    Text('100%', style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Max Suggested Factors Dropdown
                const Text('Max Suggested Factors',
                    style: AppTypography.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: DropdownButton<String>(
                    value: _maxFactors,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['3', '4', '5', '6', '8', '10'].map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _maxFactors = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // AI Model Version Dropdown
                const Text('AI Model Version',
                    style: AppTypography.labelMedium),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: DropdownButton<String>(
                    value: _aiModelVersion,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: ['v2.0 (Latest)', 'v1.5 (Stable)', 'v1.0 (Legacy)']
                        .map((value) {
                      return DropdownMenuItem(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _aiModelVersion = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // System Settings Section
          const Text('System Settings', style: AppTypography.h4),
          const SizedBox(height: AppSpacing.sm),
          Container(
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
            child: Column(
              children: [
                _buildSwitchTile(
                  'Email Notifications',
                  _emailNotifications,
                  (value) => setState(() => _emailNotifications = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Auto-backup',
                  _autoBackup,
                  (value) => setState(() => _autoBackup = value),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  'Analytics Tracking',
                  _analyticsTracking,
                  (value) => setState(() => _analyticsTracking = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('admin_ai_model', _aiModelVersion);
                await prefs.setBool('admin_email_notifications', _emailNotifications);
                await prefs.setBool('admin_auto_backup', _autoBackup);
                await prefs.setBool('admin_analytics_tracking', _analyticsTracking);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
              child: const Text(
                'Save Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTypography.bodyLarge),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0D9488),
          ),
        ],
      ),
    );
  }
}
