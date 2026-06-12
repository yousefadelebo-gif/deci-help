/// Decision Companion - New Decision Screen
/// Decision creation with 4 horizontal tabs + AI-powered enhancements

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
// App cards import removed (unused)
import '../../components/factor_components.dart';
import '../../models/models.dart';
import '../../providers/decision_provider.dart';
import '../../services/api_service.dart';
import 'package:uuid/uuid.dart';

class NewDecisionScreen extends StatefulWidget {
  const NewDecisionScreen({super.key});

  @override
  State<NewDecisionScreen> createState() => _NewDecisionScreenState();
}

class _NewDecisionScreenState extends State<NewDecisionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();

  List<DecisionOption> _options = [];
  List<FactorTemplate> _selectedFactors = [];
  List<FactorTemplate> _customFactors = []; // User-created custom factors
  Map<String, double> _factorWeights = {};
  Map<String, Map<String, int>> _factorScores =
      {}; // factorId -> {optionId -> score}

  // API-loaded factors
  List<Map<String, dynamic>> _apiCategories = [];
  Map<String, List<Map<String, dynamic>>> _apiTemplatesByCategory = {};
  // ignore: unused_field
  bool _factorsLoading = true;

  // AI suggestions from API
  List<AiSuggestion> _aiSuggestions = [];
  // ignore: unused_field
  bool _aiSuggestionsLoading = false;

  // AI-powered option suggestions
  List<String> _aiOptionSuggestions = [];
  bool _aiOptionSuggestionsLoading = false;
  Timer? _titleDebounce;

  // AI-powered factor suggestions
  List<Map<String, dynamic>> _aiFactorSuggestions = [];
  bool _aiFactorSuggestionsLoading = false;
  bool _factorSuggestionsLoaded = false;
  String? _aiFactorSuggestionError;

  // Custom factor input
  final _customFactorController = TextEditingController();
  bool _isProFactor = true; // true = Pro, false = Con

  final Map<String, String> _factorTypes = {};

  // Animation controllers
  bool _showAIHint = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadFactorsFromAPI();
    _titleController.addListener(_onTitleChanged);

    // Show AI hint after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showAIHint = true);
    });
  }

  void _onTabChanged() {
    // When navigating to Factors/AI tabs, load AI suggestions without requiring a screen reload.
    if ((_tabController.index == 1 || _tabController.index == 2) &&
        !_factorSuggestionsLoaded &&
        _options.length >= 2 &&
        _titleController.text.trim().isNotEmpty) {
      _generateAIFactorSuggestions();
    }
  }

  Future<void> _generateAIFactorSuggestions() async {
    if (_options.isEmpty || _titleController.text.trim().isEmpty) return;
    if (_aiFactorSuggestionsLoading) return;

    setState(() {
      _aiFactorSuggestionsLoading = true;
      _aiFactorSuggestionError = null;
    });

    try {
      final response = await ApiService.quickAnalyze({
        'title': _titleController.text.trim(),
        'options': _options.map((o) => o.title).toList(),
        'request_type': 'suggest_factors',
      });

      if (response.isSuccess && response.data != null) {
        final factors = response.data['factors'] as List? ?? [];

        // Map AI factors to the Quick Add format with colors
        final colors = [
          {
            'color': const Color(0xFF4CAF50),
            'bgColor': const Color(0xFFE8F5E9)
          },
          {
            'color': const Color(0xFFD4A600),
            'bgColor': const Color(0xFFFFF9C4)
          },
          {
            'color': const Color(0xFF00897B),
            'bgColor': const Color(0xFFE0F2F1)
          },
          {
            'color': const Color(0xFFE57373),
            'bgColor': const Color(0xFFFFEBEE)
          },
          {
            'color': const Color(0xFF3B82F6),
            'bgColor': const Color(0xFFE3F2FD)
          },
          {
            'color': const Color(0xFF9C27B0),
            'bgColor': const Color(0xFFF3E5F5)
          },
        ];

        final icons = [
          Icons.attach_money_rounded,
          Icons.star_outline_rounded,
          Icons.access_time_rounded,
          Icons.warning_amber_rounded,
          Icons.trending_up_rounded,
          Icons.favorite_outline_rounded,
          Icons.speed_rounded,
          Icons.school_rounded,
        ];

        if (mounted) {
          setState(() {
            _aiFactorSuggestions = factors.asMap().entries.map((entry) {
              final i = entry.key;
              final f = entry.value as Map<String, dynamic>;
              final factorType = (f['type'] ?? 'pro').toString().toLowerCase();
              final colorSet = factorType == 'con'
                  ? {
                      'color': const Color(0xFFE57373),
                      'bgColor': const Color(0xFFFFEBEE)
                    }
                  : colors[i % colors.length];
              return {
                'name': f['name'] ?? 'Factor ${i + 1}',
                'description': f['description'] ?? '',
                'type': factorType,
                'icon': icons[i % icons.length],
                'color': colorSet['color'],
                'bgColor': colorSet['bgColor'],
                'weight': f['default_weight'] ?? f['suggested_weight'] ?? 0.5,
              };
            }).toList();
            _factorSuggestionsLoaded = true;
          });
        }
      } else if (mounted) {
        setState(() {
          _aiFactorSuggestionError =
              response.error ?? 'Could not load AI factor suggestions.';
          _factorSuggestionsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error generating AI factor suggestions: $e');
      if (mounted) {
        setState(() {
          _aiFactorSuggestionError = 'Could not load AI factor suggestions.';
          _factorSuggestionsLoaded = true;
        });
      }
    }

    if (mounted) setState(() => _aiFactorSuggestionsLoading = false);
  }

  void _onTitleChanged() {
    _titleDebounce?.cancel();
    final title = _titleController.text.trim();

    if (title.length >= 3) {
      if (_factorSuggestionsLoaded ||
          _aiFactorSuggestions.isNotEmpty ||
          _aiFactorSuggestionError != null) {
        setState(_resetAIFactorSuggestions);
      } else {
        _factorSuggestionsLoaded = false;
      }
      _titleDebounce = Timer(const Duration(milliseconds: 800), () {
        _generateAIOptionSuggestions(title);
      });
    } else {
      setState(() {
        _aiOptionSuggestions = [];
        _aiOptionSuggestionsLoading = false;
        _resetAIFactorSuggestions();
      });
    }
  }

  Future<void> _generateAIOptionSuggestions(String title) async {
    if (title.isEmpty) return;

    setState(() => _aiOptionSuggestionsLoading = true);

    try {
      // Use quick analyze endpoint to get AI-powered option suggestions
      final response = await ApiService.quickAnalyze({
        'title': title,
        'request_type': 'suggest_options',
      });

      if (response.isSuccess && response.data != null) {
        final data = response.data;
        List<String> suggestions = [];

        // Parse suggestions from response
        if (data['suggested_options'] is List) {
          suggestions = List<String>.from(data['suggested_options']);
        } else if (data['options'] is List) {
          suggestions = List<String>.from(data['options']);
        }

        if (mounted) {
          setState(() {
            _aiOptionSuggestions = suggestions.take(4).toList();
          });
        }
      } else {
        if (mounted) {
          setState(() => _aiOptionSuggestions = []);
        }
      }
    } catch (e) {
      debugPrint('Error generating AI suggestions: $e');
      if (mounted) {
        setState(() => _aiOptionSuggestions = []);
      }
    }

    if (mounted) setState(() => _aiOptionSuggestionsLoading = false);
  }

  Future<void> _loadFactorsFromAPI() async {
    setState(() => _factorsLoading = true);
    try {
      // Load categories
      final catResponse = await ApiService.getFactorCategories();
      if (catResponse.isSuccess) {
        final catList = catResponse.data is List
            ? catResponse.data
            : (catResponse.data['results'] ?? []);
        _apiCategories = List<Map<String, dynamic>>.from(catList);
      }

      // Load all templates
      final tplResponse = await ApiService.getFactorTemplates();
      if (tplResponse.isSuccess) {
        final tplList = tplResponse.data is List
            ? tplResponse.data
            : (tplResponse.data['results'] ?? []);
        final templates = List<Map<String, dynamic>>.from(tplList);

        // Group by category
        _apiTemplatesByCategory = {};
        for (final tpl in templates) {
          final catId = tpl['category']?.toString() ?? 'other';
          // Find category name
          String catName = 'Other';
          for (final cat in _apiCategories) {
            if (cat['id']?.toString() == catId) {
              catName = cat['name'] ?? 'Other';
              break;
            }
          }
          _apiTemplatesByCategory.putIfAbsent(catName, () => []);
          _apiTemplatesByCategory[catName]!.add(tpl);
        }
      }
    } catch (e) {
      debugPrint('Error loading factors: $e');
    }
    if (mounted) setState(() => _factorsLoading = false);
  }

  /// Convert API template map to a FactorTemplate for the UI
  FactorTemplate _apiToFactorTemplate(Map<String, dynamic> apiTemplate) {
    final id = apiTemplate['id']?.toString() ?? const Uuid().v4();
    final name = apiTemplate['name'] ?? 'Unknown';
    final colorHex = apiTemplate['color'] ?? '#3B82F6';
    final iconName = apiTemplate['icon'] ?? '';
    return FactorTemplate(
      id: id,
      name: name,
      icon: _iconFromName(iconName),
      color: _colorFromHex(colorHex),
    );
  }

  IconData _iconFromName(String name) {
    const iconMap = {
      'attach_money': Icons.attach_money_rounded,
      'schedule': Icons.schedule_rounded,
      'work': Icons.work_rounded,
      'person': Icons.person_rounded,
      'people': Icons.people_rounded,
      'security': Icons.security_rounded,
      'favorite': Icons.favorite_rounded,
      'star': Icons.star_rounded,
      'trending_up': Icons.trending_up_rounded,
      'school': Icons.school_rounded,
      'home': Icons.home_rounded,
      'eco': Icons.eco_rounded,
      'health_and_safety': Icons.health_and_safety_rounded,
      'fitness_center': Icons.fitness_center_rounded,
      'warning': Icons.warning_rounded,
      'thumb_up': Icons.thumb_up_rounded,
      'lightbulb': Icons.lightbulb_rounded,
      'psychology': Icons.psychology_rounded,
    };
    return iconMap[name] ?? Icons.tune_rounded;
  }

  Color _colorFromHex(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }

  /// Load AI suggestions from API
  Future<void> _loadAISuggestions() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _aiSuggestionsLoading = true);
    try {
      final response =
          await ApiService.getSuggestedFactors(_titleController.text.trim());
      if (response.isSuccess) {
        final list = response.data is List
            ? response.data
            : (response.data['results'] ?? response.data['factors'] ?? []);
        setState(() {
          _aiSuggestions = List<Map<String, dynamic>>.from(list)
              .map((f) => AiSuggestion(
                    id: f['id']?.toString() ?? const Uuid().v4(),
                    name: f['name'] ?? 'Factor',
                    reason: f['description'] ?? f['reason'] ?? '',
                  ))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading AI suggestions: $e');
    }
    if (mounted) setState(() => _aiSuggestionsLoading = false);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _titleController.dispose();
    _titleDebounce?.cancel();
    _customFactorController.dispose();
    _optionInputController.dispose();
    super.dispose();
  }

  void _addOption() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _AddOptionDialog(),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        final option = DecisionOption(
          id: const Uuid().v4(),
          title: name,
        );
        _options.add(option);
        _addOptionScoreEntries(option.id);
        _resetAIFactorSuggestions();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeGenerateAIFactorsForCurrentStep();
      });
    }
  }

  void _editOption(int index) async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) =>
          _AddOptionDialog(initialValue: _options[index].title),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        _options[index] = _options[index].copyWith(title: name);
        _resetAIFactorSuggestions();
      });
    }
  }

  void _deleteOption(int index) {
    setState(() {
      final removed = _options[index];
      _options.removeAt(index);
      for (final optionScores in _factorScores.values) {
        optionScores.remove(removed.id);
      }
      _resetAIFactorSuggestions();
    });
  }

  void _resetAIFactorSuggestions() {
    _aiFactorSuggestions = [];
    _factorSuggestionsLoaded = false;
    _aiFactorSuggestionError = null;
  }

  void _maybeGenerateAIFactorsForCurrentStep() {
    if ((_tabController.index == 1 || _tabController.index == 2) &&
        _titleController.text.trim().isNotEmpty &&
        _options.length >= 2 &&
        !_factorSuggestionsLoaded &&
        !_aiFactorSuggestionsLoading) {
      _generateAIFactorSuggestions();
    }
  }

  void _addOptionScoreEntries(String optionId) {
    for (final factor in _selectedFactors) {
      _factorScores[factor.id] ??= {};
      _factorScores[factor.id]![optionId] = 0;
    }
  }

  void _toggleFactor(FactorTemplate factor) {
    setState(() {
      if (_selectedFactors.contains(factor)) {
        _selectedFactors.remove(factor);
        _factorWeights.remove(factor.id);
        _factorScores.remove(factor.id);
        _factorTypes.remove(factor.id);
      } else {
        _selectedFactors.add(factor);
        _factorWeights[factor.id] = 5;
        _factorTypes[factor.id] = 'pro';
        _factorScores[factor.id] = {for (var option in _options) option.id: 0};
      }
    });
  }

  void _updateFactorWeight(String factorId, double weight) {
    setState(() {
      _factorWeights[factorId] = weight;
    });
  }

  void _updateScore(String factorId, String optionId, int score) {
    setState(() {
      _factorScores[factorId] ??= {};
      _factorScores[factorId]![optionId] = score;
    });
  }

  void _toggleSuggestion(int index, bool value) {
    setState(() {
      _aiSuggestions[index] = _aiSuggestions[index].copyWith(isIncluded: value);
    });
  }

  void _addCustomFactor() async {
    final result = await showDialog<FactorTemplate>(
      context: context,
      builder: (context) => const _AddCustomFactorDialog(),
    );

    if (result != null) {
      setState(() {
        _customFactors.add(result);
        // Auto-select the new custom factor
        _selectedFactors.add(result);
        _factorWeights[result.id] = 5;
        _factorTypes[result.id] = 'pro';
        _factorScores[result.id] = {for (var option in _options) option.id: 0};
      });
    }
  }

  void _deleteCustomFactor(FactorTemplate factor) {
    setState(() {
      _customFactors.remove(factor);
      _selectedFactors.remove(factor);
      _factorWeights.remove(factor.id);
      _factorScores.remove(factor.id);
      _factorTypes.remove(factor.id);
    });
  }

  void _showDeleteCustomFactorDialog(FactorTemplate factor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: factor.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(factor.icon, color: factor.color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('Delete Factor?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${factor.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCustomFactor(factor);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _analyzeWithAI() async {
    // Show AI-themed loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AIAnalyzingDialog(),
    );

    try {
      final provider = context.read<DecisionProvider>();

      // 1. Create decision
      final decisionId = await provider.createDecision({
        'title': _titleController.text,
        'status': 'analyzing',
      });

      if (decisionId == null) {
        if (mounted) Navigator.pop(context); // dismiss loading
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(provider.error ?? 'Failed to create decision')),
          );
        }
        return;
      }

      // 2. Add options
      final optionIdByLocalId = <String, String>{};
      for (final option in _options) {
        final created = await provider.addOption(decisionId, {'name': option.title});
        final backendOptionId = created?['id']?.toString();
        if (backendOptionId != null && backendOptionId.isNotEmpty) {
          optionIdByLocalId[option.id] = backendOptionId;
        }
      }

      // 3. Add factors
      final factorIdByLocalId = <String, String>{};
      for (final factor in _selectedFactors) {
        final created = await provider.addFactor(decisionId, {
          'name': factor.name,
          'weight': (_factorWeights[factor.id] ?? 5) / 10,
          'factor_type': _factorTypes[factor.id] ?? 'pro',
        });
        final backendFactorId = created?['id']?.toString();
        if (backendFactorId != null && backendFactorId.isNotEmpty) {
          factorIdByLocalId[factor.id] = backendFactorId;
        }
      }

      final expectedRatingsCount =
          optionIdByLocalId.length * factorIdByLocalId.length;

      // 4. Generate and save real AI ratings for every option x factor pair.
      final ratings = await _generateAIRatingMatrix(
        optionIdByLocalId: optionIdByLocalId,
        factorIdByLocalId: factorIdByLocalId,
      );
      debugPrint(
        'AI matrix decision=$decisionId options=${optionIdByLocalId.length} factors=${factorIdByLocalId.length} ratings=${ratings.length} expected=$expectedRatingsCount',
      );
      if (ratings.length != expectedRatingsCount) {
        throw Exception(
          'AI rating generation incomplete (${ratings.length}/$expectedRatingsCount).',
        );
      }
      final ratingsSaved = await provider.saveRatings(decisionId, ratings);
      if (!ratingsSaved) {
        throw Exception(provider.error ?? 'Failed to save AI ratings.');
      }
      debugPrint(
        'AI flow decision=$decisionId options=${_options.length} factors=${_selectedFactors.length} ratings=${ratings.length}',
      );

      // 5. Trigger AI analysis
      final analysisSuccess = await provider.analyzeWithAI(decisionId);

      if (mounted) Navigator.pop(context); // dismiss loading

      if (!analysisSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  provider.error ?? 'AI analysis failed. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // 6. Navigate to recommendation
      if (mounted) {
        final current = provider.currentDecision;
        debugPrint(
          'AI flow navigate decision=$decisionId scores=${(current?['scores'] as List?)?.length ?? 0} factorBreakdown=${(current?['factor_breakdown'] as List?)?.length ?? 0}',
        );
        Navigator.of(context)
            .pushNamed('/recommendation', arguments: provider.currentDecision);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // dismiss loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _generateAIRatingMatrix({
    required Map<String, String> optionIdByLocalId,
    required Map<String, String> factorIdByLocalId,
  }) async {
    final response = await ApiService.quickAnalyze({
      'request_type': 'generate_ratings',
      'title': _titleController.text.trim(),
      'options': _options
          .map((option) => {
                'local_id': option.id,
                'name': option.title,
              })
          .toList(),
      'factors': _selectedFactors
          .map((factor) => {
                'local_id': factor.id,
                'name': factor.name,
                'type': _factorTypes[factor.id] ?? 'pro',
                'weight': (_factorWeights[factor.id] ?? 5) / 10,
              })
          .toList(),
    });

    if (!response.isSuccess) {
      throw Exception(response.error ?? 'AI rating generation failed.');
    }

    final generated = List<Map<String, dynamic>>.from(
      response.data['ratings'] ?? [],
    );
    final ratings = <Map<String, dynamic>>[];
    for (final item in generated) {
      final optionIndex = (item['option_index'] as num?)?.toInt();
      final factorIndex = (item['factor_index'] as num?)?.toInt();
      final score = (item['score'] as num?)?.round();
      if (optionIndex == null ||
          factorIndex == null ||
          score == null ||
          optionIndex < 0 ||
          optionIndex >= _options.length ||
          factorIndex < 0 ||
          factorIndex >= _selectedFactors.length) {
        continue;
      }
      final localOptionId = _options[optionIndex].id;
      final localFactorId = _selectedFactors[factorIndex].id;
      final backendOptionId = optionIdByLocalId[localOptionId];
      final backendFactorId = factorIdByLocalId[localFactorId];
      if (backendOptionId == null || backendFactorId == null) continue;
      final clampedScore = score.clamp(1, 10).toInt();
      _factorScores[localFactorId] ??= {};
      _factorScores[localFactorId]![localOptionId] = clampedScore;
      ratings.add({
        'factor_id': backendFactorId,
        'option_id': backendOptionId,
        'score': clampedScore,
        'notes': item['reasoning']?.toString() ?? '',
      });
    }
    return ratings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'New Decision',
        showBackButton: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'save_draft') {
                // Save as draft via API
                final provider = context.read<DecisionProvider>();
                final decisionId = await provider.createDecision({
                  'title': _titleController.text.isNotEmpty
                      ? _titleController.text
                      : 'Untitled Decision',
                  'status': 'draft',
                });
                if (decisionId != null) {
                  for (final option in _options) {
                    await provider
                        .addOption(decisionId, {'name': option.title});
                  }
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Decision saved as draft')),
                  );
                  Navigator.pop(context);
                }
              } else if (value == 'clear') {
                _titleController.clear();
                setState(() {
                  _options.clear();
                  _selectedFactors.clear();
                  _customFactors.clear();
                  _factorWeights.clear();
                  _factorScores.clear();
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'save_draft', child: Text('Save as Draft')),
              const PopupMenuItem(value: 'clear', child: Text('Clear All')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Tab Bar with gradient indicator
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: [
                _buildTabItem('Overview', Icons.lightbulb_outline, 0),
                _buildTabItem('Factors', Icons.tune, 1),
                _buildTabItem('AI', Icons.auto_awesome, 2),
                _buildTabItem('Review', Icons.check_circle_outline, 3),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildFactorsTab(),
                _buildSuggestionsTab(),
                _buildReviewTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, IconData icon, int index) {
    final isSelected = _tabController.index == index;
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
          const SizedBox(width: 3),
          Text(label),
        ],
      ),
    );
  }

  // Controller for inline option input
  final _optionInputController = TextEditingController();

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI-Powered Header with gradient
          AnimatedOpacity(
            opacity: _showAIHint ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withOpacity(0.1),
                    const Color(0xFF3B82F6).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI-Powered Decision Making',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'Claude will analyze your options and provide insights',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Decision Title Section with enhanced styling
          Row(
            children: [
              const Text(
                'What decision are you making?',
                style: AppTypography.h3,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Required',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Enhanced Decision Title Input with AI indicator
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _titleController.text.isNotEmpty
                    ? const Color(0xFF3B82F6).withOpacity(0.5)
                    : AppColors.border,
                width: _titleController.text.isNotEmpty ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _titleController.text.isNotEmpty
                      ? const Color(0xFF3B82F6).withOpacity(0.1)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Choose a University Major',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 8),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: _titleController.text.isNotEmpty
                            ? const Color(0xFF3B82F6)
                            : Colors.grey[400],
                        size: 22,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 24,
                    ),
                  ),
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                // AI typing indicator
                if (_aiOptionSuggestionsLoading)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(14),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF8B5CF6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI is thinking of options...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // AI Suggested Options (appears after typing title)
          if (_aiOptionSuggestions.isNotEmpty && _options.length < 2) ...[
            _buildAISuggestedOptions(),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Your Options Section with count badge
          Row(
            children: [
              const Text(
                'Your Options',
                style: AppTypography.h3,
              ),
              if (_options.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_options.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least 2 options to compare',
            style: TextStyle(
              fontSize: 13,
              color: _options.length >= 2
                  ? const Color(0xFF10B981)
                  : Colors.grey[500],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Enhanced Inline Option Input with Add Button
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _optionInputController,
                    decoration: InputDecoration(
                      hintText: 'Enter an option',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      prefixIcon: Icon(
                        Icons.add_circle_outline,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ),
                    style: AppTypography.bodyLarge,
                    onSubmitted: (_) => _addOptionFromInput(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Enhanced Gradient Add Button with animation
              GestureDetector(
                onTap: _addOptionFromInput,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _optionInputController.text.isNotEmpty
                          ? [const Color(0xFF0D9488), const Color(0xFF3B82F6)]
                          : [Colors.grey[300]!, Colors.grey[400]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (_optionInputController.text.isNotEmpty)
                        BoxShadow(
                          color: const Color(0xFF0D9488).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Added Options List with enhanced styling
          if (_options.isNotEmpty) ...[
            ...List.generate(_options.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _buildOptionItem(_options[index], index),
              );
            }),
          ],

          // Empty state with better visual
          if (_options.isEmpty) ...[
            _buildEmptyOptionsHint(),
          ],

          // Navigation hint with enhanced styling
          if (_options.length >= 2) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildNextStepCard(
              icon: Icons.tune_rounded,
              title: 'Next: Add Factors',
              subtitle: 'Choose what matters most for your decision',
              onTap: () => _tabController.animateTo(1),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAISuggestedOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withOpacity(0.08),
            const Color(0xFF3B82F6).withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Suggested Options',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                'Tap to add',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _aiOptionSuggestions.map((suggestion) {
              final isAdded = _options.any(
                  (o) => o.title.toLowerCase() == suggestion.toLowerCase());
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: isAdded
                      ? null
                      : () {
                          setState(() {
                            final option = DecisionOption(
                              id: const Uuid().v4(),
                              title: suggestion,
                            );
                            _options.add(option);
                            _addOptionScoreEntries(option.id);
                            _resetAIFactorSuggestions();
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _maybeGenerateAIFactorsForCurrentStep();
                          });
                        },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isAdded
                          ? const Color(0xFF10B981).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isAdded
                            ? const Color(0xFF10B981)
                            : const Color(0xFF8B5CF6).withOpacity(0.3),
                        width: isAdded ? 2 : 1,
                      ),
                      boxShadow: [
                        if (!isAdded)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isAdded
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          size: 18,
                          color: isAdded
                              ? const Color(0xFF10B981)
                              : const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isAdded
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOptionsHint() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[50]!,
            Colors.grey[100]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.compare_arrows_rounded,
              size: 32,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No options yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Type a decision title above to get AI suggestions\nor manually add your options',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _addOptionFromInput() {
    final text = _optionInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        final option = DecisionOption(
          id: const Uuid().v4(),
          title: text,
        );
        _options.add(option);
        _addOptionScoreEntries(option.id);
        _resetAIFactorSuggestions();
        _optionInputController.clear();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeGenerateAIFactorsForCurrentStep();
      });
    }
  }

  Widget _buildOptionItem(DecisionOption option, int index) {
    // Generate a unique gradient based on index
    final gradients = [
      [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
      [const Color(0xFF10B981), const Color(0xFF0D9488)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
      [const Color(0xFF8B5CF6), const Color(0xFFEC4899)],
    ];
    final colors = gradients[index % gradients.length];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors[0].withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colors[0].withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gradient numbered badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Option ${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons with better styling
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _editOption(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 16,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                GestureDetector(
                  onTap: () => _deleteOption(index),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStartTemplates() {
    final templates = [
      {
        'title': 'Product Purchase',
        'icon': Icons.shopping_bag_rounded,
        'options': ['Option A', 'Option B', 'Option C']
      },
      {
        'title': 'Job Offer',
        'icon': Icons.work_rounded,
        'options': ['Company A', 'Company B']
      },
      {
        'title': 'Where to Live',
        'icon': Icons.location_city_rounded,
        'options': ['City A', 'City B']
      },
      {'title': 'Custom', 'icon': Icons.edit_rounded, 'options': <String>[]},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: templates.map((template) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                final options = template['options'] as List<String>;
                if (options.isEmpty) {
                  _addOption();
                } else {
                  setState(() {
                    _titleController.text = template['title'] as String;
                    _options = options
                        .map((name) => DecisionOption(
                              id: const Uuid().v4(),
                              title: name,
                            ))
                        .toList();
                    _factorScores
                      ..clear()
                      ..addEntries(_selectedFactors.map(
                        (factor) => MapEntry(
                          factor.id,
                          {for (final option in _options) option.id: 0},
                        ),
                      ));
                    _resetAIFactorSuggestions();
                  });
                }
              },
              child: Container(
                width: 130,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppElevation.shadowSm,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(
                        template['icon'] as IconData,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      template['title'] as String,
                      style: AppTypography.labelMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyOptionsCard() {
    return GestureDetector(
      onTap: _addOption,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.accent.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Add Your First Option',
              style: AppTypography.h4,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'What choices are you considering?\nTap here to add an option.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        AppTypography.labelLarge.copyWith(color: Colors.white),
                  ),
                  Text(
                    subtitle,
                    style:
                        AppTypography.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorsTab() {
    // Default Quick Add factor options (used as fallback)
    final defaultFactors = [
      {
        'name': 'Price',
        'icon': Icons.attach_money_rounded,
        'color': const Color(0xFF4CAF50),
        'bgColor': const Color(0xFFE8F5E9)
      },
      {
        'name': 'Quality',
        'icon': Icons.star_outline_rounded,
        'color': const Color(0xFFD4A600),
        'bgColor': const Color(0xFFFFF9C4)
      },
      {
        'name': 'Time Required',
        'icon': Icons.access_time_rounded,
        'color': const Color(0xFF00897B),
        'bgColor': const Color(0xFFE0F2F1)
      },
      {
        'name': 'Risk Level',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFE57373),
        'bgColor': const Color(0xFFFFEBEE)
      },
      {
        'name': 'Difficulty',
        'icon': Icons.track_changes_rounded,
        'color': const Color(0xFF00897B),
        'bgColor': const Color(0xFFE0F2F1)
      },
      {
        'name': 'Convenience',
        'icon': Icons.bolt_rounded,
        'color': const Color(0xFFD4A600),
        'bgColor': const Color(0xFFFFF9C4)
      },
      {
        'name': 'Long-term Benefit',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFF4CAF50),
        'bgColor': const Color(0xFFE8F5E9)
      },
      {
        'name': 'Personal Preference',
        'icon': Icons.favorite_outline_rounded,
        'color': const Color(0xFFE57373),
        'bgColor': const Color(0xFFFFEBEE)
      },
    ];

    // Use AI suggestions if available, otherwise use defaults
    final quickAddFactors =
        _aiFactorSuggestions.isNotEmpty ? _aiFactorSuggestions : defaultFactors;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Add Factors',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'What factors matter for this decision?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Add Section with AI badge
          Row(
            children: [
              if (_aiFactorSuggestions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _aiFactorSuggestions.isNotEmpty
                    ? 'AI Suggested Factors'
                    : 'Quick Add',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              if (_aiFactorSuggestionsLoading) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // Quick Add Grid - 2 columns with flexible height
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: quickAddFactors.map((factor) {
              final isSelected =
                  _selectedFactors.any((f) => f.name == factor['name']);
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 48 - 12) / 2,
                child: _buildQuickAddButton(
                  name: factor['name'] as String,
                  icon: factor['icon'] as IconData,
                  color: factor['color'] as Color,
                  bgColor: factor['bgColor'] as Color,
                  isSelected: isSelected,
                  onTap: () => _toggleQuickAddFactor(factor),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),

          // Or Create Custom Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Or Create Custom',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),

                // Custom factor input
                TextField(
                  controller: _customFactorController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Salary Potential',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF00897B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 12),

                // Pro/Con Toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isProFactor = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isProFactor
                                ? const Color(0xFF00897B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isProFactor
                                  ? const Color(0xFF00897B)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Pro',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _isProFactor
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isProFactor = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isProFactor
                                ? Colors.white
                                : const Color(0xFF00897B),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isProFactor
                                  ? Colors.grey[300]!
                                  : const Color(0xFF00897B),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Con',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _isProFactor
                                    ? Colors.grey[600]
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Add Custom Factor Button
                GestureDetector(
                  onTap: _addCustomFactorFromInput,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00897B)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Add Custom Factor',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Selected Factors Display (if any)
          if (_selectedFactors.isNotEmpty) ...[
            const Text(
              'Selected Factors',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFactors.map((factor) {
                return Chip(
                  label: Text(factor.name),
                  backgroundColor: factor.color.withOpacity(0.2),
                  labelStyle: TextStyle(
                      color: factor.color, fontWeight: FontWeight.w500),
                  deleteIcon: Icon(Icons.close, size: 18, color: factor.color),
                  onDeleted: () => _toggleFactor(factor),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddButton({
    required String name,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color, width: 2) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleQuickAddFactor(Map<String, dynamic> factorData) {
    final name = factorData['name'] as String;
    final existingIndex = _selectedFactors.indexWhere((f) => f.name == name);

    if (existingIndex >= 0) {
      // Remove if already selected
      setState(() {
        final factor = _selectedFactors[existingIndex];
        _selectedFactors.removeAt(existingIndex);
        _factorWeights.remove(factor.id);
        _factorScores.remove(factor.id);
        _factorTypes.remove(factor.id);
      });
    } else {
      // Add new factor
      final newFactor = FactorTemplate(
        id: const Uuid().v4(),
        name: name,
        icon: factorData['icon'] as IconData,
        color: factorData['color'] as Color,
      );
      setState(() {
        _selectedFactors.add(newFactor);
        final aiWeight = (factorData['weight'] as num?)?.toDouble();
        _factorWeights[newFactor.id] = ((aiWeight ?? 0.5) * 10).clamp(1, 10);
        _factorTypes[newFactor.id] =
            (factorData['type']?.toString().toLowerCase() == 'con') ? 'con' : 'pro';
        _factorScores[newFactor.id] = {
          for (var option in _options) option.id: 0
        };
      });
    }
  }

  void _addCustomFactorFromInput() {
    final name = _customFactorController.text.trim();
    if (name.isEmpty) return;

    final color =
        _isProFactor ? const Color(0xFF4CAF50) : const Color(0xFFE57373);
    final icon =
        _isProFactor ? Icons.thumb_up_outlined : Icons.thumb_down_outlined;

    final newFactor = FactorTemplate(
      id: const Uuid().v4(),
      name: name,
      icon: icon,
      color: color,
    );

    setState(() {
      _customFactors.add(newFactor);
      _selectedFactors.add(newFactor);
      _factorWeights[newFactor.id] = 5;
      _factorTypes[newFactor.id] = _isProFactor ? 'pro' : 'con';
      _factorScores[newFactor.id] = {for (var option in _options) option.id: 0};
      _customFactorController.clear();
    });
  }

  Widget _buildCategorySection(String categoryName, Color catColor,
      List<Map<String, dynamic>> templates) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: catColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                categoryName,
                style: AppTypography.h4.copyWith(color: catColor),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '(${templates.length})',
                style: AppTypography.caption
                    .copyWith(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Factor chips
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: templates.map((tpl) {
              final factorTemplate = _apiToFactorTemplate(tpl);
              // Check if selected by id
              final isSelected =
                  _selectedFactors.any((f) => f.id == factorTemplate.id);
              return FactorChip(
                factor: factorTemplate,
                isSelected: isSelected,
                onTap: () => _toggleApiTemplate(tpl),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggleApiTemplate(Map<String, dynamic> apiTemplate) {
    final factorTemplate = _apiToFactorTemplate(apiTemplate);
    setState(() {
      final existingIndex =
          _selectedFactors.indexWhere((f) => f.id == factorTemplate.id);
      if (existingIndex >= 0) {
        _selectedFactors.removeAt(existingIndex);
        _factorWeights.remove(factorTemplate.id);
        _factorScores.remove(factorTemplate.id);
        _factorTypes.remove(factorTemplate.id);
      } else {
        _selectedFactors.add(factorTemplate);
        final defaultWeight = ((apiTemplate['default_weight'] ?? 0.5) * 10)
            .clamp(1, 10)
            .toDouble();
        _factorWeights[factorTemplate.id] = defaultWeight;
        _factorTypes[factorTemplate.id] =
            (apiTemplate['factor_type']?.toString().toLowerCase() == 'con') ? 'con' : 'pro';
        _factorScores[factorTemplate.id] = {
          for (var option in _options) option.id: 0
        };
      }
    });
  }

  Widget _buildSuggestionsTab() {
    final hasBasics =
        _titleController.text.trim().isNotEmpty && _options.length >= 2;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with sparkle icon
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: const Color(0xFF00897B),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Suggested Factors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Select factors that apply to your decision',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          if (!hasBasics)
            _buildAIFlowStateCard(
              icon: Icons.route_rounded,
              title: 'Start with the basics',
              subtitle:
                  'Add a title and at least 2 options first. Then AI will suggest factors here automatically.',
              action: 'Go to Overview',
              onTap: () => _tabController.animateTo(0),
            )
          else if (_aiFactorSuggestionsLoading)
            _buildAIFlowLoadingCard()
          else if (_aiFactorSuggestionError != null)
            _buildAIFlowStateCard(
              icon: Icons.refresh_rounded,
              title: 'AI suggestions did not load',
              subtitle: _aiFactorSuggestionError!,
              action: 'Try Again',
              onTap: () {
                setState(() {
                  _factorSuggestionsLoaded = false;
                  _aiFactorSuggestionError = null;
                });
                _generateAIFactorSuggestions();
              },
            )
          else if (_aiFactorSuggestions.isEmpty)
            _buildAIFlowStateCard(
              icon: Icons.auto_awesome,
              title: 'Generate AI factors',
              subtitle:
                  'Use your title and options to create real decision factors before analysis.',
              action: 'Generate Factors',
              onTap: _generateAIFactorSuggestions,
            )
          else ...[
            ..._aiFactorSuggestions.map((factor) {
              final name = factor['name']?.toString() ?? 'Factor';
              final type =
                  factor['type']?.toString().toLowerCase() == 'con' ? 'Con' : 'Pro';
              final isSelected =
                  _selectedFactors.any((selected) => selected.name == name);
              return _buildSuggestionRow(
                name: name,
                type: type,
                isSelected: isSelected,
                onToggle: (_) => _toggleQuickAddFactor(factor),
              );
            }),
            const SizedBox(height: 12),
            _buildNextStepCard(
              icon: Icons.check_circle_outline_rounded,
              title: _selectedFactors.isEmpty
                  ? 'Select at least one factor'
                  : 'Next: Review Decision',
              subtitle: _selectedFactors.isEmpty
                  ? 'Tap the factors that matter for this decision'
                  : 'Everything is ready for final AI analysis',
              onTap: _selectedFactors.isEmpty
                  ? () {}
                  : () => _tabController.animateTo(3),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIFlowLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Generating smart factors...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI is reading your options and building the next step.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFlowStateCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                action,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow({
    required String name,
    required String type,
    required bool isSelected,
    required Function(bool) onToggle,
  }) {
    final isPro = type == 'Pro';
    final badgeColor =
        isPro ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);
    final badgeBgColor =
        isPro ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onToggle(!isSelected),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00897B)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                    color: isSelected
                        ? const Color(0xFF00897B)
                        : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                // Factor name
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ),
                // Pro/Con badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewTab() {
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final decisionTitle =
        hasTitle ? _titleController.text.trim() : 'Untitled Decision';
    final isReady = _options.length >= 2 && _selectedFactors.isNotEmpty;
    final completionPercent = _calculateCompletionPercent();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with AI branding
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ready for AI Analysis',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Claude will analyze your decision',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Completion Progress Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isReady
                    ? [
                        const Color(0xFF10B981).withOpacity(0.1),
                        const Color(0xFF10B981).withOpacity(0.05)
                      ]
                    : [
                        Colors.orange.withOpacity(0.1),
                        Colors.orange.withOpacity(0.05)
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isReady
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isReady ? Icons.check_circle : Icons.pending,
                      color: isReady ? const Color(0xFF10B981) : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isReady ? 'All Set!' : 'Almost There',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isReady
                                  ? const Color(0xFF10B981)
                                  : Colors.orange,
                            ),
                          ),
                          Text(
                            isReady
                                ? 'Your decision is ready for AI analysis'
                                : '${(completionPercent * 100).toInt()}% complete - add more details',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Circular progress indicator
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: completionPercent,
                            strokeWidth: 4,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isReady ? const Color(0xFF10B981) : Colors.orange,
                            ),
                          ),
                          Text(
                            '${(completionPercent * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isReady
                                  ? const Color(0xFF10B981)
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Summary Cards Grid
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.lightbulb_outline,
                  title: 'Decision',
                  value: hasTitle ? decisionTitle : 'Not set',
                  color: hasTitle ? const Color(0xFF3B82F6) : Colors.grey,
                  isSet: hasTitle,
                  onTap: () => _tabController.animateTo(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.compare_arrows,
                  title: 'Options',
                  value: _options.length >= 2
                      ? '${_options.length} added'
                      : '${_options.length}/2 needed',
                  color: _options.length >= 2
                      ? const Color(0xFF10B981)
                      : Colors.orange,
                  isSet: _options.length >= 2,
                  onTap: () => _tabController.animateTo(0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.tune,
                  title: 'Factors',
                  value: _selectedFactors.isNotEmpty
                      ? '${_selectedFactors.length} selected'
                      : 'None selected',
                  color: _selectedFactors.isNotEmpty
                      ? const Color(0xFF8B5CF6)
                      : Colors.grey,
                  isSet: _selectedFactors.isNotEmpty,
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.psychology,
                  title: 'AI Model',
                  value: 'Claude 3.5',
                  color: const Color(0xFF0D9488),
                  isSet: true,
                  onTap: null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Options Preview with enhanced styling
          if (_options.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'Options to Compare',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_options.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...List.generate(_options.length, (index) {
              final option = _options[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Factors Preview with enhanced styling
          if (_selectedFactors.isNotEmpty) ...[
            Row(
              children: [
                const Text(
                  'Factors to Evaluate',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedFactors.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFactors.map((factor) {
                final weight = _factorWeights[factor.id]?.toInt() ?? 5;
                // isPro check for potential future use
                final _ = factor.color == const Color(0xFF4CAF50) ||
                    factor.color.value == 0xFF4CAF50;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: factor.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: factor.color.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(factor.icon, size: 16, color: factor.color),
                      const SizedBox(width: 6),
                      Text(
                        factor.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: factor.color,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: factor.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$weight',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: factor.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Enhanced Analyze with AI Button
          _buildAnalyzeButton(isReady),
          const SizedBox(height: 16),

          // Missing items helper
          if (!isReady) _buildMissingItemsCard(hasTitle),
        ],
      ),
    );
  }

  double _calculateCompletionPercent() {
    double total = 0;
    if (_titleController.text.trim().isNotEmpty) total += 0.25;
    if (_options.length >= 2)
      total += 0.35;
    else if (_options.length == 1) total += 0.15;
    if (_selectedFactors.isNotEmpty) total += 0.40;
    return total.clamp(0.0, 1.0);
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isSet,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSet ? color.withOpacity(0.3) : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: isSet
                  ? color.withOpacity(0.1)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const Spacer(),
                if (isSet) Icon(Icons.check_circle, size: 16, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSet ? const Color(0xFF1A1A2E) : Colors.grey[400],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton(bool isReady) {
    return GestureDetector(
      onTap: isReady ? _analyzeWithAI : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isReady
              ? const LinearGradient(
                  colors: [
                    Color(0xFF8B5CF6),
                    Color(0xFF3B82F6),
                    Color(0xFF0D9488)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isReady ? null : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: isReady
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isReady ? 0.2 : 0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 22,
                color: isReady ? Colors.white : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analyze with Claude AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isReady ? Colors.white : Colors.grey[400],
                  ),
                ),
                Text(
                  isReady
                      ? 'Get personalized recommendations'
                      : 'Complete all requirements first',
                  style: TextStyle(
                    fontSize: 11,
                    color: isReady
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward_rounded,
              color: isReady ? Colors.white : Colors.grey[400],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissingItemsCard(bool hasTitle) {
    final missingItems = <Map<String, dynamic>>[];

    if (!hasTitle) {
      missingItems.add({
        'icon': Icons.lightbulb_outline,
        'text': 'Add a decision title',
        'tab': 0,
      });
    }
    if (_options.length < 2) {
      missingItems.add({
        'icon': Icons.compare_arrows,
        'text':
            'Add at least ${2 - _options.length} more option${_options.length == 1 ? '' : 's'}',
        'tab': 0,
      });
    }
    if (_selectedFactors.isEmpty) {
      missingItems.add({
        'icon': Icons.tune,
        'text': 'Select evaluation factors',
        'tab': 1,
      });
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Complete these steps:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...missingItems.map((item) {
            return GestureDetector(
              onTap: () => _tabController.animateTo(item['tab'] as int),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item['text'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(
      Map<String, double> totalScores, String? bestOptionId) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          final score = totalScores[option.id] ?? 0;
          final maxScore = _selectedFactors.length * 10.0;
          final percentage = maxScore > 0 ? (score / maxScore) : 0.0;
          final isBest = option.id == bestOptionId;

          return Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: index < _options.length - 1
                  ? Border(bottom: BorderSide(color: AppColors.border))
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      if (isBest)
                        Container(
                          padding: const EdgeInsets.all(2),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.star_rounded,
                              size: 12, color: Colors.white),
                        ),
                      Expanded(
                        child: Text(
                          option.title,
                          style: AppTypography.labelMedium.copyWith(
                            color: isBest
                                ? AppColors.success
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: AppColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isBest ? AppColors.success : AppColors.primary,
                            ),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${(percentage * 100).toInt()}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: isBest
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMissingItemCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                Text(subtitle, style: AppTypography.caption),
              ],
            ),
          ),
          TextButton(
            onPressed: onTap,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

// Add Option Dialog
class _AddOptionDialog extends StatefulWidget {
  final String? initialValue;

  const _AddOptionDialog({this.initialValue});

  @override
  State<_AddOptionDialog> createState() => _AddOptionDialogState();
}

class _AddOptionDialogState extends State<_AddOptionDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.initialValue != null ? 'Edit Option' : 'Add Option',
              style: AppTypography.h3,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              hint: 'Enter option name',
              controller: _controller,
              autofocus: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.medium,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: 'Save',
                    size: AppButtonSize.medium,
                    onPressed: () =>
                        Navigator.of(context).pop(_controller.text),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add Custom Factor Dialog
class _AddCustomFactorDialog extends StatefulWidget {
  const _AddCustomFactorDialog();

  @override
  State<_AddCustomFactorDialog> createState() => _AddCustomFactorDialogState();
}

class _AddCustomFactorDialogState extends State<_AddCustomFactorDialog> {
  final _controller = TextEditingController();
  IconData _selectedIcon = Icons.star_rounded;
  Color _selectedColor = const Color(0xFF3B82F6);

  final List<IconData> _availableIcons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.attach_money_rounded,
    Icons.schedule_rounded,
    Icons.location_on_rounded,
    Icons.people_rounded,
    Icons.eco_rounded,
    Icons.health_and_safety_rounded,
    Icons.work_rounded,
    Icons.school_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.flight_rounded,
    Icons.restaurant_rounded,
    Icons.fitness_center_rounded,
    Icons.psychology_rounded,
    Icons.emoji_emotions_rounded,
    Icons.lightbulb_rounded,
    Icons.security_rounded,
    Icons.speed_rounded,
  ];

  final List<Color> _availableColors = [
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF10B981), // Green
    const Color(0xFFF59E0B), // Amber
    const Color(0xFFEF4444), // Red
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEC4899), // Pink
    const Color(0xFF0D9488), // Teal
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFF97316), // Orange
    const Color(0xFF84CC16), // Lime
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _selectedColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      _selectedIcon,
                      color: _selectedColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      'Create Custom Factor',
                      style: AppTypography.h3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Factor Name
              AppTextField(
                label: 'Factor Name',
                hint: 'e.g., Brand Reputation, Distance, etc.',
                controller: _controller,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Icon Selection
              const Text('Choose an Icon', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _availableIcons.length,
                  itemBuilder: (context, index) {
                    final icon = _availableIcons[index];
                    final isSelected = icon == _selectedIcon;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = icon),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _selectedColor.withOpacity(0.15)
                              : AppColors.surfaceVariant,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: isSelected
                              ? Border.all(color: _selectedColor, width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? _selectedColor
                              : AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Color Selection
              const Text('Choose a Color', style: AppTypography.labelLarge),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _availableColors.map((color) {
                  final isSelected = color == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Cancel',
                      variant: AppButtonVariant.outline,
                      size: AppButtonSize.medium,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppButton(
                      text: 'Create',
                      size: AppButtonSize.medium,
                      onPressed: () {
                        if (_controller.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please enter a factor name')),
                          );
                          return;
                        }
                        final factor = FactorTemplate(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          name: _controller.text.trim(),
                          icon: _selectedIcon,
                          color: _selectedColor,
                        );
                        Navigator.of(context).pop(factor);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stunning AI Analyzing Dialog
class _AIAnalyzingDialog extends StatefulWidget {
  @override
  State<_AIAnalyzingDialog> createState() => _AIAnalyzingDialogState();
}

class _AIAnalyzingDialogState extends State<_AIAnalyzingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  int _currentStep = 0;
  final List<String> _steps = [
    'Preparing your decision...',
    'Analyzing options...',
    'Evaluating factors...',
    'Claude is thinking...',
    'Generating insights...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Update step text periodically
    _updateStep();
  }

  void _updateStep() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _steps.length;
        });
        _updateStep();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(40),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated AI Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: child,
                );
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                      Color(0xFF0D9488)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Title
            const Text(
              'Analyzing with Claude AI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),

            // Animated step text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _steps[_currentStep],
                key: ValueKey<int>(_currentStep),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Progress bar with gradient
            Container(
              height: 6,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.3 + (_controller.value * 0.5),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // AI badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Powered by Claude 3.5',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
