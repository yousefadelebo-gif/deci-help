/// Decision Companion - Privacy & Security Screen
/// Data and privacy settings

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/local_storage_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _usageAnalytics = true;
  bool _cloudBackup = true;
  bool _biometricLogin = false;
  bool _autoLock = false;
  bool _isLoading = true;
  LocalStorageService? _storage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = await LocalStorageService.getInstance();
    setState(() {
      _storage = storage;
      _usageAnalytics =
          storage.getBool(AppConstants.privacyAnalyticsKey) ?? true;
      _cloudBackup =
          storage.getBool(AppConstants.privacyCloudBackupKey) ?? true;
      _biometricLogin =
          storage.getBool(AppConstants.privacyBiometricKey) ?? false;
      _autoLock = storage.getBool(AppConstants.privacyAutoLockKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveBool(String key, bool value) async {
    await _storage?.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                      value: _usageAnalytics,
                      onChanged: (value) {
                        setState(() => _usageAnalytics = value);
                        _saveBool(AppConstants.privacyAnalyticsKey, value);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildSettingTile(
                    icon: Icons.cloud_outlined,
                    title: 'Cloud Backup',
                    subtitle: 'Automatically back up your decisions',
                    trailing: Switch(
                      value: _cloudBackup,
                      onChanged: (value) {
                        setState(() => _cloudBackup = value);
                        _saveBool(AppConstants.privacyCloudBackupKey, value);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

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
                      value: _biometricLogin,
                      onChanged: (value) {
                        setState(() => _biometricLogin = value);
                        _saveBool(AppConstants.privacyBiometricKey, value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Biometric login enabled'
                                  : 'Biometric login disabled',
                            ),
                          ),
                        );
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildSettingTile(
                    icon: Icons.lock_clock_rounded,
                    title: 'Auto-Lock',
                    subtitle: 'Lock app after 5 minutes of inactivity',
                    trailing: Switch(
                      value: _autoLock,
                      onChanged: (value) {
                        setState(() => _autoLock = value);
                        _saveBool(AppConstants.privacyAutoLockKey, value);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

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
                      Navigator.of(context).pushNamed('/settings');
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
                    onTap: () => _showClearDataDialog(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This removes locally stored preferences and cached data. Your account decisions on the server are not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _storage?.remove(AppConstants.privacyAnalyticsKey);
              await _storage?.remove(AppConstants.privacyCloudBackupKey);
              await _storage?.remove(AppConstants.privacyBiometricKey);
              await _storage?.remove(AppConstants.privacyAutoLockKey);
              if (!context.mounted) return;
              Navigator.pop(context);
              await _loadSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy preferences reset')),
                );
              }
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
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
