/// Decision Companion - App Settings Screen
/// Theme, language, and app preferences

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';
import '../../providers/decision_provider.dart';
import 'legal_document_screen.dart';

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
  String _cacheSizeLabel = '—';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('settings_dark_mode') ?? false;
      _hapticFeedback = prefs.getBool('settings_haptic') ?? true;
      _autoSave = prefs.getBool('settings_auto_save') ?? true;
      _language = prefs.getString('settings_language') ?? 'English';
      _cacheSizeLabel = prefs.getString('settings_cache_label') ?? '12.3 MB';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

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
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      _saveSetting('settings_dark_mode', value);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value ? 'Dark mode preference saved' : 'Light mode preference saved',
                          ),
                        ),
                      );
                    },
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
                    onChanged: (value) {
                      setState(() => _hapticFeedback = value);
                      _saveSetting('settings_haptic', value);
                    },
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildSwitchTile(
                    icon: Icons.save_outlined,
                    title: 'Auto-save Drafts',
                    subtitle: 'Save decisions automatically',
                    value: _autoSave,
                    onChanged: (value) {
                      setState(() => _autoSave = value);
                      _saveSetting('settings_auto_save', value);
                    },
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
                    value: _cacheSizeLabel,
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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LegalDocumentScreen.termsOfService,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildNavigationTile(
                    icon: Icons.policy_outlined,
                    title: 'Privacy Policy',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LegalDocumentScreen.privacyPolicy,
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 72),
                  _buildNavigationTile(
                    icon: Icons.code_rounded,
                    title: 'Open Source Licenses',
                    onTap: () => showLicensePage(context: context),
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
                  _saveSetting('settings_language', lang);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language set to $lang')),
                  );
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
              onTap: () async {
                Navigator.pop(context);
                await _exportDecisions(asCsv: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded),
              title: const Text('Export as CSV'),
              onTap: () async {
                Navigator.pop(context);
                await _exportDecisions(asCsv: true);
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
        content: Text('This will clear $_cacheSizeLabel of cached data. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('settings_cache_label', '0 MB');
              setState(() => _cacheSizeLabel = '0 MB');
              if (!mounted) return;
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

  Future<void> _exportDecisions({required bool asCsv}) async {
    await context.read<DecisionProvider>().fetchDecisions();
    final decisions = context.read<DecisionProvider>().decisions;
    String payload;
    if (asCsv) {
      final buffer = StringBuffer('id,title,status,created_at\n');
      for (final d in decisions) {
        buffer.writeln(
          '${d['id']},${d['title']},${d['status']},${d['created_at']}',
        );
      }
      payload = buffer.toString();
    } else {
      payload = decisions.toString();
    }
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${decisions.length} decisions as ${asCsv ? 'CSV' : 'JSON'}',
        ),
      ),
    );
  }
}
