/// Decision Companion - AI Parameters Screen
/// Admin view for configuring AI recommendation settings

import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_button.dart';

class AIParametersScreen extends StatefulWidget {
  const AIParametersScreen({super.key});

  @override
  State<AIParametersScreen> createState() => _AIParametersScreenState();
}

class _AIParametersScreenState extends State<AIParametersScreen> {
  // AI Model Settings
  String _selectedModel = 'GPT-4';
  double _temperature = 0.7;
  double _confidenceThreshold = 0.75;
  int _maxTokens = 2048;

  // Feature Toggles
  bool _enableContextAwareness = true;
  bool _enablePersonalization = true;
  bool _enableFactorWeighting = true;
  bool _enableHistoricalAnalysis = true;
  bool _enableRiskAssessment = true;

  // Recommendation Settings
  int _maxOptions = 5;
  int _maxFactors = 10;
  double _diversityScore = 0.5;

  bool _hasChanges = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'AI Parameters',
        showBackButton: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _resetToDefaults,
              child: Text(
                'Reset',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI System Status',
                            style: AppTypography.labelLarge),
                        Text(
                          'All systems operational',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      'v2.3.1',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Model Selection
            const Text('AI Model', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildModelOption(
                    'GPT-4',
                    'Most capable model for complex decisions',
                    Icons.auto_awesome_rounded,
                    AppColors.primary,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildModelOption(
                    'GPT-3.5',
                    'Fast and efficient for simple decisions',
                    Icons.flash_on_rounded,
                    AppColors.warning,
                  ),
                  const Divider(height: AppSpacing.lg),
                  _buildModelOption(
                    'Claude',
                    'Great for nuanced analysis',
                    Icons.psychology_rounded,
                    AppColors.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Model Parameters
            const Text('Model Parameters', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildSliderSetting(
                    'Temperature',
                    'Controls randomness in responses',
                    _temperature,
                    0.0,
                    1.0,
                    (value) => setState(() {
                      _temperature = value;
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSliderSetting(
                    'Confidence Threshold',
                    'Minimum confidence for recommendations',
                    _confidenceThreshold,
                    0.5,
                    1.0,
                    (value) => setState(() {
                      _confidenceThreshold = value;
                      _hasChanges = true;
                    }),
                    showPercentage: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildNumberSetting(
                    'Max Tokens',
                    'Maximum response length',
                    _maxTokens,
                    [512, 1024, 2048, 4096],
                    (value) => setState(() {
                      _maxTokens = value;
                      _hasChanges = true;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Feature Toggles
            const Text('AI Features', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildFeatureToggle(
                    'Context Awareness',
                    'Considers user history and preferences',
                    Icons.history_rounded,
                    _enableContextAwareness,
                    (value) => setState(() {
                      _enableContextAwareness = value;
                      _hasChanges = true;
                    }),
                  ),
                  const Divider(height: 1),
                  _buildFeatureToggle(
                    'Personalization',
                    'Tailors recommendations to user behavior',
                    Icons.person_rounded,
                    _enablePersonalization,
                    (value) => setState(() {
                      _enablePersonalization = value;
                      _hasChanges = true;
                    }),
                  ),
                  const Divider(height: 1),
                  _buildFeatureToggle(
                    'Factor Weighting',
                    'Adjusts factor importance dynamically',
                    Icons.tune_rounded,
                    _enableFactorWeighting,
                    (value) => setState(() {
                      _enableFactorWeighting = value;
                      _hasChanges = true;
                    }),
                  ),
                  const Divider(height: 1),
                  _buildFeatureToggle(
                    'Historical Analysis',
                    'Learns from past decision outcomes',
                    Icons.analytics_rounded,
                    _enableHistoricalAnalysis,
                    (value) => setState(() {
                      _enableHistoricalAnalysis = value;
                      _hasChanges = true;
                    }),
                  ),
                  const Divider(height: 1),
                  _buildFeatureToggle(
                    'Risk Assessment',
                    'Evaluates potential risks of options',
                    Icons.warning_rounded,
                    _enableRiskAssessment,
                    (value) => setState(() {
                      _enableRiskAssessment = value;
                      _hasChanges = true;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Recommendation Limits
            const Text('Recommendation Limits', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildNumberSetting(
                    'Max Options',
                    'Maximum options to analyze',
                    _maxOptions,
                    [3, 5, 7, 10],
                    (value) => setState(() {
                      _maxOptions = value;
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildNumberSetting(
                    'Max Factors',
                    'Maximum factors per decision',
                    _maxFactors,
                    [5, 10, 15, 20],
                    (value) => setState(() {
                      _maxFactors = value;
                      _hasChanges = true;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSliderSetting(
                    'Diversity Score',
                    'How varied the recommendations should be',
                    _diversityScore,
                    0.0,
                    1.0,
                    (value) => setState(() {
                      _diversityScore = value;
                      _hasChanges = true;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Advanced Settings
            const Text('Advanced', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.code_rounded,
                          color: AppColors.primary),
                    ),
                    title: const Text('API Configuration'),
                    subtitle: const Text('Manage API keys and endpoints'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.warningLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.bug_report_rounded,
                          color: AppColors.warning),
                    ),
                    title: const Text('Debug Mode'),
                    subtitle: const Text('Enable detailed logging'),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {},
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: AppColors.error),
                    ),
                    title: const Text('Retrain Model'),
                    subtitle: const Text('Update with latest user data'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _showRetrainDialog(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Save Button
            if (_hasChanges)
              AppButton(
                text: 'Save Changes',
                onPressed: _saveChanges,
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOption(
    String name,
    String description,
    IconData icon,
    Color color,
  ) {
    return InkWell(
      onTap: () => setState(() {
        _selectedModel = name;
        _hasChanges = true;
      }),
      child: Row(
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
                Text(name, style: AppTypography.labelLarge),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Radio<String>(
            value: name,
            groupValue: _selectedModel,
            onChanged: (value) => setState(() {
              _selectedModel = value!;
              _hasChanges = true;
            }),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    String description,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool showPercentage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.labelMedium),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                showPercentage
                    ? '${(value * 100).toInt()}%'
                    : value.toStringAsFixed(2),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        Text(
          description,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceVariant,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildNumberSetting(
    String label,
    String description,
    int value,
    List<int> options,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        Text(
          description,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: options.map((option) {
            final isSelected = value == option;
            return ChoiceChip(
              label: Text(option.toString()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) onChanged(option);
              },
              backgroundColor: AppColors.surfaceVariant,
              selectedColor: AppColors.primarySurface,
              labelStyle: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureToggle(
    String label,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTypography.labelMedium),
      subtitle: Text(
        description,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
          'This will reset all AI parameters to their default values. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedModel = 'GPT-4';
                _temperature = 0.7;
                _confidenceThreshold = 0.75;
                _maxTokens = 2048;
                _enableContextAwareness = true;
                _enablePersonalization = true;
                _enableFactorWeighting = true;
                _enableHistoricalAnalysis = true;
                _enableRiskAssessment = true;
                _maxOptions = 5;
                _maxFactors = 10;
                _diversityScore = 0.5;
                _hasChanges = false;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Parameters reset to defaults')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    setState(() => _hasChanges = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parameters saved successfully!')),
    );
  }

  void _showRetrainDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retrain AI Model?'),
        content: const Text(
          'This will retrain the AI model with the latest user data. This process may take several minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Model retraining started...')),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}
