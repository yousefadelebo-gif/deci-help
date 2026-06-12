import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/decision_provider.dart';
import '../services/api_service.dart';
import '../theme/app_tokens.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Shows a bottom sheet to edit a decision's title and reflection notes.
Future<bool?> showDecisionEditSheet(
  BuildContext context, {
  required String decisionId,
  required String initialTitle,
  String? initialReflection,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _DecisionEditSheet(
      decisionId: decisionId,
      initialTitle: initialTitle,
      initialReflection: initialReflection ?? '',
    ),
  );
}

class _DecisionEditSheet extends StatefulWidget {
  final String decisionId;
  final String initialTitle;
  final String initialReflection;

  const _DecisionEditSheet({
    required this.decisionId,
    required this.initialTitle,
    required this.initialReflection,
  });

  @override
  State<_DecisionEditSheet> createState() => _DecisionEditSheetState();
}

class _DecisionEditSheetState extends State<_DecisionEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _reflectionController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _reflectionController =
        TextEditingController(text: widget.initialReflection);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final provider = context.read<DecisionProvider>();
    final titleOk = await provider.updateDecision(
      widget.decisionId,
      {'title': title},
    );

    var reflectionOk = true;
    final reflection = _reflectionController.text.trim();
    if (reflection.isNotEmpty) {
      final journalResponse = await ApiService.updateJournalEntry(
        widget.decisionId,
        {'reflection': reflection},
      );
      reflectionOk = journalResponse.isSuccess;
      if (!journalResponse.isSuccess) {
        final createResponse = await ApiService.saveJournalEntry(
          widget.decisionId,
          {'reflection': reflection},
        );
        reflectionOk = createResponse.isSuccess;
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (titleOk && reflectionOk) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Decision updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to save changes'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.md,
        AppSpacing.screenPadding,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
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
          const Text('Edit Decision', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _titleController,
            label: 'Title',
            hint: 'Decision title',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextArea(
            controller: _reflectionController,
            label: 'Reflection',
            hint: 'Notes about this decision...',
            maxLines: 4,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: _isSaving ? 'Saving...' : 'Save Changes',
            onPressed: _isSaving ? null : _save,
          ),
        ],
      ),
    );
  }
}
