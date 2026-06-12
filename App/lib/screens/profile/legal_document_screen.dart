import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';

class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.content,
  });

  static const termsOfService = LegalDocumentScreen(
    title: 'Terms of Service',
    content: '''
Last updated: June 2026

By using Decision Companion, you agree to these terms.

1. Service
Decision Companion helps you structure decisions, compare options, and review AI-assisted recommendations. Recommendations are informational only and are not professional advice.

2. Your content
You retain ownership of the decisions and notes you create. You grant us a limited license to store and process that content so the app can function.

3. Acceptable use
Do not misuse the service, attempt unauthorized access, or upload unlawful content.

4. Availability
We may update or discontinue features. We will try to provide reasonable notice for material changes.

5. Liability
The app is provided "as is" to the extent permitted by law. We are not liable for outcomes of decisions you make using the app.

6. Contact
Questions about these terms can be sent through Help & Support in the app.
''',
  );

  static const privacyPolicy = LegalDocumentScreen(
    title: 'Privacy Policy',
    content: '''
Last updated: June 2026

Decision Companion respects your privacy.

Data we collect
- Account information such as name and email
- Decision data you create (titles, options, factors, ratings, reflections)
- Optional feedback you submit
- Anonymous usage analytics if you enable it in Privacy settings

How we use data
- To provide and improve the app
- To sync your decisions across sessions
- To respond to support requests

Your controls
- Export or delete local app data from Privacy settings
- Toggle analytics, backup, biometric login, and auto-lock preferences
- Delete your account from My Account

Sharing
We do not sell your personal decision data. We may use service providers for hosting and analytics under contractual safeguards.

Security
We use industry-standard measures to protect data in transit and at rest.

Contact
Use Help & Support to reach us about privacy questions.
''',
  );

  static const openSourceLicenses = LegalDocumentScreen(
    title: 'Open Source Licenses',
    content: '''
Decision Companion uses the following open source packages:

Flutter SDK — BSD 3-Clause License
Provider — MIT License
Google Fonts — SIL Open Font License / Apache 2.0
fl_chart — MIT License
intl — BSD 3-Clause License
shared_preferences — BSD 3-Clause License
uuid — MIT License
http — BSD 3-Clause License
cached_network_image — MIT License
flutter_svg — MIT License
go_router — BSD 3-Clause License

Full license texts are available in the project repository under each package's LICENSE file.
''',
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: title,
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Text(
          content.trim(),
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}
