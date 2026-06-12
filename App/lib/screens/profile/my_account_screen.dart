/// Decision Companion - My Account Screen
/// User account management

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_cards.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../providers/decision_provider.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _nameController = TextEditingController(text: authProvider.userName);
    _emailController = TextEditingController(text: authProvider.userEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final decisionProvider = context.watch<DecisionProvider>();
    final analytics = decisionProvider.analytics;
    final totalDecisions = analytics?['total_decisions'] ?? 0;

    // Compute initials from real user name
    final name = user?.name ?? 'User';
    final initials = name
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0] : '')
        .take(2)
        .join()
        .toUpperCase();

    // Format member since date
    final memberSince = user?.createdAt != null
        ? DateFormat('MMMM yyyy').format(user!.createdAt!)
        : 'N/A';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'My Account',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            child: Text(
              _isEditing ? 'Cancel' : 'Edit',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppElevation.shadowMd,
                    ),
                    child: Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Form Fields
            AppTextField(
              label: 'Full Name',
              controller: _nameController,
              enabled: _isEditing,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
            const SizedBox(height: AppSpacing.md),

            AppTextField(
              label: 'Email',
              controller: _emailController,
              enabled: _isEditing,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Account Info
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Information',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildInfoRow('Member Since', memberSince),
                  const Divider(height: AppSpacing.lg),
                  _buildInfoRow('Account Type',
                      user?.isVerified == true ? 'Pro Member' : 'Free'),
                  const Divider(height: AppSpacing.lg),
                  _buildInfoRow('Decisions Made', '$totalDecisions'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Save Button (when editing)
            if (_isEditing) ...[
              AppButton(
                text: 'Save Changes',
                isLoading: _isSaving,
                onPressed: () async {
                  setState(() => _isSaving = true);
                  final success =
                      await context.read<AuthProvider>().updateProfile(
                            name: _nameController.text,
                          );
                  setState(() {
                    _isSaving = false;
                    if (success) _isEditing = false;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success
                            ? 'Profile updated'
                            : (context.read<AuthProvider>().error ??
                                'Failed to update')),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Change Password
            AppCard(
              onTap: () => _showChangePasswordSheet(context),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child:
                        Text('Change Password', style: AppTypography.bodyLarge),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Delete Account
            AppButton(
              text: 'Delete Account',
              variant: AppButtonVariant.danger,
              icon: Icons.delete_outline_rounded,
              onPressed: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final currentPwdController = TextEditingController();
    final newPwdController = TextEditingController();
    final confirmPwdController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          bool isLoading = false;

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
              MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.lg,
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
                const Text('Change Password', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: 'Current Password',
                  hint: 'Enter current password',
                  obscureText: true,
                  showPasswordToggle: true,
                  controller: currentPwdController,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'New Password',
                  hint: 'Enter new password',
                  obscureText: true,
                  showPasswordToggle: true,
                  controller: newPwdController,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm new password',
                  obscureText: true,
                  showPasswordToggle: true,
                  controller: confirmPwdController,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  text: 'Update Password',
                  isLoading: isLoading,
                  onPressed: () async {
                    if (newPwdController.text != confirmPwdController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Passwords do not match')),
                      );
                      return;
                    }
                    if (newPwdController.text.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Password must be at least 8 characters')),
                      );
                      return;
                    }

                    setSheetState(() => isLoading = true);
                    final success =
                        await context.read<AuthProvider>().changePassword(
                              oldPassword: currentPwdController.text,
                              newPassword: newPwdController.text,
                            );
                    setSheetState(() => isLoading = false);

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Password updated successfully'
                              : (context.read<AuthProvider>().error ??
                                  'Failed to update password')),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
