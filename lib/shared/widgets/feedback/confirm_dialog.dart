import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';
import '../buttons/app_button.dart';

/// Shared confirmation dialog to avoid repeating the same
/// AlertDialog pattern across 10+ screens.
///
/// Uses frosted glass styling when the device supports it.
abstract final class ConfirmDialog {
  /// Shows a confirmation dialog with cancel/confirm buttons.
  ///
  /// Returns `true` if confirmed, `false` otherwise.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    bool destructive = false,
  }) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.barrierScrim,
      builder: (ctx) {
        final theme = ctx.appTheme;
        final useBlur = GlassConfig.shouldBlur(ctx);
        final radius = BorderRadius.circular(AppSizes.borderRadiusLg);

        Widget dialog = AlertDialog(
          backgroundColor: theme.glassSheetSurface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: theme.glassSheetBorder),
          ),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: Text(l10n.common_cancel),
            ),
            if (destructive)
              AppButton(
                label: confirmLabel ?? l10n.common_delete,
                variant: AppButtonVariant.danger,
                isFullWidth: false,
                onPressed: () => ctx.pop(true),
              )
            else
              TextButton(
                onPressed: () => ctx.pop(true),
                child: Text(confirmLabel ?? l10n.common_confirm),
              ),
          ],
        );

        if (useBlur) {
          dialog = ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppSizes.glassBlurBackground,
                sigmaY: AppSizes.glassBlurBackground,
              ),
              child: dialog,
            ),
          );
        }

        return dialog;
      },
    );
    return result ?? false;
  }

  /// Shows a delete confirmation dialog with danger-styled confirm button.
  static Future<bool> confirmDelete(
    BuildContext context, {
    required String title,
    required String message,
  }) =>
      show(
        context,
        title: title,
        message: message,
        confirmLabel: context.l10n.common_delete,
        destructive: true,
      );
}
