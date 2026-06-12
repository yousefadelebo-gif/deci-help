/// Decision Companion - Privacy & Security Screen
/// Data and privacy settings

import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Privacy & Security',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data Privacy Section
            Text(
              'Data Privacy',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.analytics_outlined,
                    title: 'Usage Analytics',
                    subtitle:
                        'Help improve the app by sharing anonymous usage data',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildSettingTile(
                    icon: Icons.cloud_outlined,
                    title: 'Cloud Backup',
                    subtitle: 'Automatically back up your decisions',
                    trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Security Section
            Text(
              'Security',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric Login',
                    subtitle: 'Use fingerprint or face to unlock',
                    trailing: Switch(
                      value: false,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildSettingTile(
                    icon: Icons.lock_clock_rounded,
                    title: 'Auto-Lock',
                    subtitle: 'Lock app after 5 minutes of inactivity',
                    trailing: Switch(
                      value: false,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Data Management
            Text(
              'Data Management',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: const Text('Export Data',
                        style: AppTypography.bodyLarge),
                    subtitle: Text(
                      'Download all your decision data',
                      style: AppTypography.caption,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        Icons.delete_sweep_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Clear All Data',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.error),
                    ),
                    subtitle: Text(
                      'Permanently delete all local data',
                      style: AppTypography.caption,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textTertiary,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xxs,
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
      trailing: trailing,
    );
  }
}
