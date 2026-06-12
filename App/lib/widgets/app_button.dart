/// Decision Companion - Modern Button System
/// Reusable button components with multiple variants

import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

enum AppButtonSize { small, medium, large }

enum AppButtonVariant { primary, secondary, outline, ghost, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool iconLeading;
  final bool isLoading;
  final bool fullWidth;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconLeading = true,
    this.isLoading = false,
    this.fullWidth = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = fullWidth
            ? (constraints.maxWidth.isFinite ? constraints.maxWidth : null)
            : width;
        return SizedBox(
          width: effectiveWidth,
          height: _getHeight(),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              boxShadow: _shouldShowShadow() ? AppElevation.buttonShadow : null,
            ),
            child: _buildButton(),
          ),
        );
      },
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return AppSpacing.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppSpacing.buttonHeightMedium;
      case AppButtonSize.large:
        return AppSpacing.buttonHeight;
    }
  }

  bool _shouldShowShadow() {
    return variant == AppButtonVariant.primary &&
        onPressed != null &&
        !isLoading;
  }

  Widget _buildButton() {
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimaryButton();
      case AppButtonVariant.secondary:
        return _buildSecondaryButton();
      case AppButtonVariant.outline:
        return _buildOutlineButton();
      case AppButtonVariant.ghost:
        return _buildGhostButton();
      case AppButtonVariant.danger:
        return _buildDangerButton();
    }
  }

  Widget _buildPrimaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: _buildContent(AppColors.textOnPrimary),
    );
  }

  Widget _buildSecondaryButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.textOnSecondary,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: _buildContent(AppColors.textOnSecondary),
    );
  }

  Widget _buildOutlineButton() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        elevation: 0,
        padding: _getPadding(),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: _buildContent(AppColors.primary),
    );
  }

  Widget _buildGhostButton() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: _buildContent(AppColors.textSecondary),
    );
  }

  Widget _buildDangerButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: _buildContent(AppColors.textOnPrimary),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.sm);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.md);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: AppSpacing.lg);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall;
      case AppButtonSize.medium:
        return AppTypography.buttonMedium;
      case AppButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: _getIconSize() + 4,
        height: _getIconSize() + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: _getTextStyle().copyWith(color: color),
    );

    if (icon == null) {
      return textWidget;
    }

    final iconWidget = Icon(icon, size: _getIconSize(), color: color);
    final spacing = SizedBox(width: AppSpacing.xs);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: iconLeading
          ? [iconWidget, spacing, textWidget]
          : [textWidget, spacing, iconWidget],
    );
  }
}

/// Icon Button with background
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final double iconSize;

  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: AppElevation.shadowXs,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular Icon Button
class AppCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const AppCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: AppElevation.shadowMd,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(
              icon,
              size: size * 0.5,
              color: iconColor ?? AppColors.textOnPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
