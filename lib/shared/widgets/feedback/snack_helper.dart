import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme_extension.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';

/// Centralised SnackBar helpers.
/// Usage: SnackHelper.showSuccess(context, 'Transaction saved');
abstract final class SnackHelper {
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarDefault,
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.checkCircle,
      color: context.appTheme.incomeColor,
      onColor: AppColors.white,
      action: action,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarError,
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.errorCircle,
      color: context.appTheme.expenseColor,
      onColor: AppColors.white,
      action: action,
      duration: duration,
    );
  }

  /// Convenience: haptic feedback + success snackbar in one call.
  /// Replaces the repeated `HapticFeedback.heavyImpact(); showSuccess(...)` pattern.
  static void showSuccessWithHaptic(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarDefault,
  }) {
    HapticFeedback.heavyImpact();
    showSuccess(context, message, action: action, duration: duration);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarDefault,
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.infoFilled,
      color: context.colors.primary,
      onColor: context.colors.onPrimary,
      action: action,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    required Color onColor,
    SnackBarAction? action,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: onColor, size: AppSizes.iconSm),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(
                    color: onColor,
                    fontSize: AppSizes.snackTextSize,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.snackBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.snackVerticalPadding,
          ),
          margin: const EdgeInsets.only(
            left: AppSizes.snackHorizontalMargin,
            right: AppSizes.snackHorizontalMargin,
            bottom: AppSizes.snackbarBottomMargin,
          ),
          elevation: AppSizes.snackElevation,
          duration: duration,
          dismissDirection: DismissDirection.horizontal,
          action: action,
        ),
      );
  }
}
