/// Decision Companion - Custom AppBar
/// Clean, modern app bar component

import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = false,
    this.onBackPressed,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.elevation = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: elevation,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor ?? AppColors.background,
      centerTitle: centerTitle,
      leading: _buildLeading(context),
      title: titleWidget ?? (title != null ? _buildTitle() : null),
      actions: actions != null
          ? [
              ...actions!,
              const SizedBox(width: AppSpacing.xs),
            ]
          : null,
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;
    if (!showBackButton) return null;

    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: IconButton(
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title!,
      style: AppTypography.h3,
    );
  }
}

/// AppBar with Search
class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final bool showBackButton;

  const SearchAppBar({
    super.key,
    this.hintText = 'Search...',
    this.controller,
    this.onChanged,
    this.onClear,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 16);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: AppColors.background,
      automaticallyImplyLeading: showBackButton,
      title: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
            ),
            suffixIcon: controller?.text.isNotEmpty == true
                ? IconButton(
                    onPressed: () {
                      controller?.clear();
                      onClear?.call();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        ),
      ),
    );
  }
}
