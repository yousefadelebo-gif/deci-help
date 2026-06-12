/// Decision Companion - App Settings Screen
/// Theme, language, and app preferences

import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _hapticFeedback = true;
  bool _autoSave = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'App Settings',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance
            _buildSectionTitle('Appearance'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Use dark theme',
                    value: _darkMode,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildNavigationTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    value: _language,
                    onTap: () => _showLanguageSheet(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // General
            _buildSectionTitle('General'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibration on actions',
                    value: _hapticFeedback,
                    onChanged: (value) => setState(() => _hapticFeedback = value),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildSwitchTile(
                    icon: Icons.save_outlined,
                    title: 'Auto-save Drafts',
                    subtitle: 'Save decisions automatically',
                    value: _autoSave,
                    onChanged: (value) => setState(() => _autoSave = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Data
            _buildSectionTitle('Data & Storage'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildNavigationTile(
                    icon: Icons.cloud_download_outlined,
                    title: 'Export Data',
                    value: 'JSON, CSV',
                    onTap: () => _showExportOptions(),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildNavigationTile(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Clear Cache',
                    value: '12.3 MB',
                    onTap: () => _showClearCacheDialog(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // About
            _buildSectionTitle('About'),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildInfoTile(
                    icon: Icons.info_outline_rounded,
                    title: 'Version',
                    value: '1.0.0',
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildNavigationTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildNavigationTile(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildNavigationTile(
                    icon: Icons.code_rounded,
                    title: 'Open Source Licenses',
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
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

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    String? value,
    required VoidCallback onTap,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
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
      trailing: Text(
        value,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final languages = ['English', 'Spanish', 'French', 'German', 'Chinese', 'Japanese'];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Select Language', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            ...languages.map((lang) {
              final isSelected = _language == lang;
              return ListTile(
                title: Text(lang),
                trailing: isSelected
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() => _language = lang);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('Export Data', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Export as JSON'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data exported as JSON')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data exported as CSV')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear 12.3 MB of cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
