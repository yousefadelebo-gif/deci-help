/// Decision Companion - Notifications Screen
/// Manage alerts and notification preferences

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/app_cards.dart';
import '../../providers/decision_provider.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _decisionReminders = true;
  bool _weeklyInsights = true;
  bool _marketingEmails = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DecisionProvider>().fetchDecisions();
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('notif_push') ?? true;
      _emailNotifications = prefs.getBool('notif_email') ?? false;
      _decisionReminders = prefs.getBool('notif_reminders') ?? true;
      _weeklyInsights = prefs.getBool('notif_weekly') ?? true;
      _marketingEmails = prefs.getBool('notif_marketing') ?? false;
    });
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          title: const Text('Notifications', style: AppTypography.h3),
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Inbox'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildInboxTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxTab() {
    final decisions = context.watch<DecisionProvider>().decisions;
    final notifications = decisions.take(20).map((d) {
      final created = DateTime.tryParse(d['created_at']?.toString() ?? '') ??
          DateTime.now();
      return _NotificationItem(
        title: d['title']?.toString() ?? 'Decision update',
        message: 'Status: ${d['status'] ?? 'draft'}',
        type: _NotificationType.decision,
        createdAt: created,
      );
    }).toList();

    if (notifications.isEmpty) {
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
                Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No notifications',
              style: AppTypography.h4.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              "You're all caught up!",
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final decisionId = decisions[index]['id']?.toString();
        return _buildNotificationCard(notification, decisionId);
      },
    );
  }

  Widget _buildNotificationCard(_NotificationItem notification, String? decisionId) {
    IconData icon = Icons.notifications_rounded;
    Color color = AppColors.textSecondary;

    switch (notification.type) {
      case _NotificationType.decision:
        icon = Icons.check_circle_rounded;
        color = AppColors.success;
        break;
      case _NotificationType.reminder:
        icon = Icons.schedule_rounded;
        color = AppColors.warning;
        break;
      case _NotificationType.insight:
        icon = Icons.lightbulb_rounded;
        color = AppColors.primary;
        break;
      case _NotificationType.system:
        icon = Icons.info_rounded;
        color = AppColors.textSecondary;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: decisionId == null
          ? null
          : () => Navigator.pushNamed(
                context,
                '/decision-detail',
                arguments: {'id': decisionId},
              ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: AppTypography.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  notification.message,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatTime(notification.createdAt),
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d').format(time);
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Push Notifications'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Push Notifications',
                  subtitle: 'Receive push notifications',
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() => _pushNotifications = value);
                    _savePref('notif_push', value);
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildSwitchTile(
                  icon: Icons.alarm_rounded,
                  title: 'Decision Reminders',
                  subtitle: 'Remind about pending decisions',
                  value: _decisionReminders,
                  onChanged: (value) {
                    setState(() => _decisionReminders = value);
                    _savePref('notif_reminders', value);
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildSwitchTile(
                  icon: Icons.insights_rounded,
                  title: 'Weekly Insights',
                  subtitle: 'Get weekly decision summaries',
                  value: _weeklyInsights,
                  onChanged: (value) {
                    setState(() => _weeklyInsights = value);
                    _savePref('notif_weekly', value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle('Email'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.email_rounded,
                  title: 'Email Notifications',
                  subtitle: 'Receive email updates',
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() => _emailNotifications = value);
                    _savePref('notif_email', value);
                  },
                ),
                const Divider(height: 1, indent: 72),
                _buildSwitchTile(
                  icon: Icons.campaign_rounded,
                  title: 'Marketing Emails',
                  subtitle: 'Product updates and offers',
                  value: _marketingEmails,
                  onChanged: (value) {
                    setState(() => _marketingEmails = value);
                    _savePref('notif_marketing', value);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: Text(subtitle, style: AppTypography.caption),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

enum _NotificationType {
  decision,
  reminder,
  insight,
  system,
}

class _NotificationItem {
  final String title;
  final String message;
  final _NotificationType type;
  final DateTime createdAt;
  final bool isRead;

  const _NotificationItem({
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
  });
}
