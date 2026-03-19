import 'package:flutter/material.dart';

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
      action: action,
      duration: duration,
    );
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
      action: action,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color color,
    SnackBarAction? action,
    required Duration duration,
  }) {
    final cs = context.colors;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: cs.onPrimary, size: AppSizes.iconMd),
              const SizedBox(width: AppSizes.sm),
              Flexible(
                child: Text(
                  message,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: cs.onPrimary,
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
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
          margin: const EdgeInsets.only(
            bottom: AppSizes.bottomScrollPadding,
            left: AppSizes.md,
            right: AppSizes.md,
          ),
          duration: duration,
          action: action,
        ),
      );
  }
}
