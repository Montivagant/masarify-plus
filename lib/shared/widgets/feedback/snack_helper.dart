import 'package:flutter/material.dart';

import '../../../app/theme/app_theme_extension.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';

/// Centralised SnackBar helpers.
/// Usage: SnackHelper.showSuccess(context, 'Transaction saved');
abstract final class SnackHelper {
  static void showSuccess(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.checkCircle,
      color: Theme.of(context).extension<AppThemeExtension>()!.incomeColor,
      action: action,
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.errorCircle,
      color: Theme.of(context).extension<AppThemeExtension>()!.expenseColor,
      action: action,
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      icon: AppIcons.infoFilled,
      color: Theme.of(context).colorScheme.primary,
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
    final cs = Theme.of(context).colorScheme;
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
          margin: const EdgeInsets.all(AppSizes.md),
          duration: duration,
          action: action,
        ),
      );
  }
}
