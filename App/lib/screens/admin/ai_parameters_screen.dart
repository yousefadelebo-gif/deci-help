/// Decision Companion - AI Parameters Screen
/// Admin view for configuring AI recommendation settings

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_cards.dart';

class AIParametersScreen extends StatefulWidget {
  const AIParametersScreen({super.key});

  @override
  State<AIParametersScreen> createState() => _AIParametersScreenState();
}

class _AIParametersScreenState extends State<AIParametersScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _status = {};
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final responses = await Future.wait([
      ApiService.checkAIStatus(),
      ApiService.getAdminStats(),
    ]);
    if (!mounted) return;
    if (responses.first.isSuccess && responses.last.isSuccess) {
      setState(() {
        _status = Map<String, dynamic>.from(responses.first.data);
        _stats = Map<String, dynamic>.from(responses.last.data);
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = responses.first.error ??
            responses.last.error ??
            'Failed to load AI analytics';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'AI Parameters',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
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
                      color: _isAvailable
                          ? AppColors.successLight
                          : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: _isAvailable ? AppColors.success : AppColors.error,
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
                          _isAvailable ? 'Available' : 'Unavailable',
                          style: AppTypography.bodySmall.copyWith(
                            color: _isAvailable
                                ? AppColors.success
                                : AppColors.error,
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
                      _modelName,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            const Text('AI Usage', style: AppTypography.h4),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _buildMetricTile('AI Analyses', '${_stats['ai_analyses'] ?? 0}',
                      Icons.auto_awesome_rounded, AppColors.primary),
                  const Divider(height: AppSpacing.lg),
                  _buildMetricTile('AI Requests', '${_stats['ai_requests'] ?? 0}',
                      Icons.api_rounded, AppColors.secondary),
                  const Divider(height: AppSpacing.lg),
                  _buildMetricTile(
                      'AI Success Rate',
                      '${_asDouble(_stats['ai_success_rate']).toStringAsFixed(1)}%',
                      Icons.check_circle_rounded,
                      AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  bool get _isAvailable => _status['available'] == true;

  String get _modelName => _status['model']?.toString() ?? 'No model';

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
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
          child: Text(
            label,
            style: AppTypography.labelLarge,
          ),
        ),
        Text(
          value,
          style: AppTypography.h4.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }
}
