/// Decision Companion - Help & Support Screen
/// FAQ and contact support

import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_cards.dart';
import '../../widgets/app_text_field.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Help & Support',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search
            const AppSearchField(hint: 'Search help articles...'),
            const SizedBox(height: AppSpacing.lg),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat',
                    onTap: () => _showChatSheet(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Email',
                    onTap: () => _showEmailSheet(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _buildQuickAction(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Call',
                    onTap: () => _showCallSheet(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // FAQ Section
            const Text('Frequently Asked Questions', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.md),
            _buildFAQItem(
              'How do I create a new decision?',
              'Tap the "+" button on the dashboard or navigate to the "New Decision" tab. Enter a title for your decision, add at least 2 options to compare, and select the factors that matter most to you.',
            ),
            _buildFAQItem(
              'How does the AI recommendation work?',
              'Our AI analyzes your options against the factors you\'ve selected, weighted by importance. It calculates a score for each option and provides a recommendation with a confidence level.',
            ),
            _buildFAQItem(
              'Can I edit a decision after analysis?',
              'Yes! You can edit any decision from the Journal. Tap on a decision, then use the edit button to modify options, factors, or weights. Re-analyze to get updated recommendations.',
            ),
            _buildFAQItem(
              'What data does the app collect?',
              'We only collect the data you provide (decisions, options, factors). We don\'t share your personal decision data with third parties. See our Privacy Policy for details.',
            ),
            _buildFAQItem(
              'How do I delete my account?',
              'Go to Profile > My Account > Delete Account. This will permanently delete all your data including decision history.',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Still need help
            AppCard(
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Still need help?',
                    style: AppTypography.h4,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Our support team is here to help',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: 'Contact Support',
                    size: AppButtonSize.medium,
                    onPressed: () => _showEmailSheet(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTypography.labelMedium),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: AppTypography.bodyLarge),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          answer,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showChatSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _SupportAgentSheet(),
    );
  }

  void _showEmailSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
            const Text('Contact Support', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.lg),
            const AppTextField(
              label: 'Subject',
              hint: 'Brief description of your issue',
            ),
            const SizedBox(height: AppSpacing.md),
            const AppTextArea(
              label: 'Message',
              hint: 'Describe your issue in detail...',
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Send Message',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message sent! We\'ll respond within 24 hours.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCallSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: SafeArea(
          top: false,
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
              const Text('Support Options', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Phone support is not connected yet. Use the instant agent or send feedback so the app keeps moving.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Open Support Agent',
                onPressed: () {
                  Navigator.pop(context);
                  _showChatSheet(context);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                text: 'Send Feedback',
                variant: AppButtonVariant.outline,
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushNamed('/feedback');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportMessage {
  final String text;
  final bool fromAgent;
  final List<_SupportCta> ctas;

  const _SupportMessage({
    required this.text,
    required this.fromAgent,
    this.ctas = const [],
  });
}

class _SupportCta {
  final String label;
  final IconData icon;
  final String? routeName;
  final String? prompt;

  const _SupportCta({
    required this.label,
    required this.icon,
    this.routeName,
    this.prompt,
  });
}

class _SupportAgentSheet extends StatefulWidget {
  const _SupportAgentSheet();

  @override
  State<_SupportAgentSheet> createState() => _SupportAgentSheetState();
}

class _SupportAgentSheetState extends State<_SupportAgentSheet> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final List<_SupportMessage> _messages;

  static const _homeCtas = [
    _SupportCta(
      label: 'Start Decision',
      icon: Icons.add_circle_outline_rounded,
      routeName: '/new-decision',
    ),
    _SupportCta(
      label: 'View Journal',
      icon: Icons.bookmark_border_rounded,
      routeName: '/journal',
    ),
    _SupportCta(
      label: 'Past Decisions',
      icon: Icons.history_rounded,
      routeName: '/history',
    ),
    _SupportCta(
      label: 'Send Feedback',
      icon: Icons.rate_review_outlined,
      routeName: '/feedback',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _messages = const [
      _SupportMessage(
        fromAgent: true,
        text:
            'Hi, I am your in-app decision assistant. I can help you create a decision, fix AI analysis, find saved decisions, manage your account, or send feedback.',
        ctas: _homeCtas,
      ),
      _SupportMessage(
        fromAgent: true,
        text: 'Choose a quick action below or type what is not working.',
        ctas: [
          _SupportCta(
            label: 'AI not working',
            icon: Icons.auto_awesome,
            prompt: 'AI analysis is not working',
          ),
          _SupportCta(
            label: 'How to decide',
            icon: Icons.route_rounded,
            prompt: 'How do I make a decision?',
          ),
          _SupportCta(
            label: 'Account help',
            icon: Icons.person_outline_rounded,
            prompt: 'I need account help',
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendText([String? value]) {
    final text = (value ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_SupportMessage(text: text, fromAgent: false));
      _messages.add(_buildAgentReply(text));
      _controller.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  _SupportMessage _buildAgentReply(String input) {
    final text = input.toLowerCase();

    if (text.contains('ai') ||
        text.contains('analysis') ||
        text.contains('analy') ||
        text.contains('recommend') ||
        text.contains('chart')) {
      return const _SupportMessage(
        fromAgent: true,
        text:
            'For AI analysis, the app needs: a title, at least 2 options, selected factors, then Review. I can take you straight to the decision flow. If charts look empty, create a fresh analysis so the app generates real factor ratings.',
        ctas: [
          _SupportCta(
            label: 'Open Decision Flow',
            icon: Icons.add_circle_outline_rounded,
            routeName: '/new-decision',
          ),
          _SupportCta(
            label: 'Check Past Results',
            icon: Icons.history_rounded,
            routeName: '/history',
          ),
          _SupportCta(
            label: 'Send AI Issue',
            icon: Icons.bug_report_outlined,
            routeName: '/feedback',
          ),
        ],
      );
    }

    if (text.contains('decision') ||
        text.contains('option') ||
        text.contains('factor') ||
        text.contains('flow') ||
        text.contains('start')) {
      return const _SupportMessage(
        fromAgent: true,
        text:
            'The best flow is: 1. Write the decision title. 2. Add or accept AI options. 3. Open AI and select suggested factors. 4. Review and analyze. I can open the right screen now.',
        ctas: [
          _SupportCta(
            label: 'Start New Decision',
            icon: Icons.route_rounded,
            routeName: '/new-decision',
          ),
          _SupportCta(
            label: 'Dashboard',
            icon: Icons.dashboard_outlined,
            routeName: '/dashboard',
          ),
        ],
      );
    }

    if (text.contains('journal') ||
        text.contains('history') ||
        text.contains('saved') ||
        text.contains('old')) {
      return const _SupportMessage(
        fromAgent: true,
        text:
            'You can find previous decisions in Journal and Past Decisions. Use these to reopen results, review recommendations, or track outcomes.',
        ctas: [
          _SupportCta(
            label: 'Open Journal',
            icon: Icons.bookmark_border_rounded,
            routeName: '/journal',
          ),
          _SupportCta(
            label: 'Past Decisions',
            icon: Icons.history_rounded,
            routeName: '/history',
          ),
        ],
      );
    }

    if (text.contains('account') ||
        text.contains('login') ||
        text.contains('password') ||
        text.contains('profile') ||
        text.contains('privacy')) {
      return const _SupportMessage(
        fromAgent: true,
        text:
            'For account and privacy help, go to Profile, My Account, or Privacy. If something still fails, send feedback with details.',
        ctas: [
          _SupportCta(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            routeName: '/profile',
          ),
          _SupportCta(
            label: 'My Account',
            icon: Icons.manage_accounts_outlined,
            routeName: '/my-account',
          ),
          _SupportCta(
            label: 'Privacy',
            icon: Icons.privacy_tip_outlined,
            routeName: '/privacy',
          ),
        ],
      );
    }

    return const _SupportMessage(
      fromAgent: true,
      text:
          'I can help with the main app flows. Pick one action and I will take you there, or describe what screen is stuck.',
      ctas: _homeCtas,
    );
  }

  void _handleCta(_SupportCta cta) {
    if (cta.prompt != null) {
      _sendText(cta.prompt);
      return;
    }

    final routeName = cta.routeName;
    if (routeName == null) return;
    Navigator.pop(context);
    Navigator.of(context).pushNamed(routeName);
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.86,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.md),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryLight, AppColors.accent],
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Support Agent', style: AppTypography.h3),
                      Text('Replies instantly with app actions',
                          style: AppTypography.caption),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
                vertical: AppSpacing.sm,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessage(_SupportMessage message) {
    final alignment =
        message.fromAgent ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final bubbleColor =
        message.fromAgent ? AppColors.surfaceVariant : AppColors.primary;
    final textColor = message.fromAgent ? AppColors.textPrimary : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Text(
              message.text,
              style: AppTypography.bodyMedium.copyWith(color: textColor),
            ),
          ),
          if (message.ctas.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: message.ctas.map(_buildCtaChip).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCtaChip(_SupportCta cta) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      onTap: () => _handleCta(cta),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cta.icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              cta.label,
              style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.sm,
          AppSpacing.screenPadding,
          AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendText,
                decoration: InputDecoration(
                  hintText: 'Ask about AI, decisions, account...',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: _sendText,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.accent],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
