/// Decision Companion - Profile Screen
/// User profile with navigation to sub-screens

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../providers/decision_provider.dart';
import '../../theme/app_tokens.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    // Check if user is admin by email pattern (can be customized)
    final email = user?.email ?? '';
    final isAdmin = email.contains('admin') || email.endsWith('@admin.com');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Profile Header with Stats
            _buildGradientHeader(
                context, user?.name ?? 'Guest', user?.email ?? ''),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Settings Section Title
                  const Text('Settings', style: AppTypography.h4),
                  const SizedBox(height: AppSpacing.sm),

                  // Settings Menu
                  _buildSettingsItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFF6366F1),
                    iconBgColor: const Color(0xFFEEF2FF),
                    title: 'My Account',
                    onTap: () => Navigator.pushNamed(context, '/my-account'),
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.bookmark_outline_rounded,
                    iconColor: const Color(0xFF0D9488),
                    iconBgColor: const Color(0xFFF0FDFA),
                    title: 'Saved Recommendations',
                    onTap: () =>
                        Navigator.pushNamed(context, '/saved-recommendations'),
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.notifications_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    iconBgColor: const Color(0xFFFEF3C7),
                    title: 'Notifications',
                    onTap: () => Navigator.pushNamed(context, '/notifications'),
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.settings_outlined,
                    iconColor: const Color(0xFF64748B),
                    iconBgColor: const Color(0xFFF1F5F9),
                    title: 'App Settings',
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.lock_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBgColor: const Color(0xFFD1FAE5),
                    title: 'Privacy & Security',
                    onTap: () => Navigator.pushNamed(context, '/privacy'),
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    iconBgColor: const Color(0xFFDBEAFE),
                    title: 'Help & Support',
                    onTap: () => Navigator.pushNamed(context, '/help'),
                  ),

                  // Admin Section
                  if (isAdmin) ...[
                    const SizedBox(height: AppSpacing.lg),
                    const Text('Advanced', style: AppTypography.h4),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSettingsItem(
                      context,
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: const Color(0xFFEF4444),
                      iconBgColor: const Color(0xFFFEE2E2),
                      title: 'Admin Panel',
                      onTap: () => Navigator.pushNamed(context, '/admin'),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),

                  // Logout Button
                  _buildLogoutButton(context),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientHeader(BuildContext context, String name, String email) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  size: 48,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                name.isEmpty ? 'Guest' : name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Decision Maker',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Stats Row
              Consumer<DecisionProvider>(
                builder: (context, provider, _) {
                  final analytics = provider.analytics;
                  final totalDecisions = analytics?['total_decisions'] ?? 12;
                  final avgConfidence = analytics?['average_confidence'] ?? 85;
                  final avgSatisfaction =
                      analytics?['average_satisfaction'] ?? 4.5;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHeaderStat('$totalDecisions', 'Total Decisions'),
                      _buildHeaderStat(
                          '${avgConfidence is num ? avgConfidence.round() : avgConfidence}%',
                          'Avg Confidence'),
                      _buildHeaderStat(
                        avgSatisfaction is num
                            ? '${avgSatisfaction.toStringAsFixed(1)}/5'
                            : '$avgSatisfaction/5',
                        'Satisfaction',
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
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

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title, style: AppTypography.bodyLarge),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: const Icon(Icons.logout_rounded,
              color: AppColors.error, size: 22),
        ),
        title: Text(
          'Logout',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
        ),
        onTap: () => _showLogoutDialog(context),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
