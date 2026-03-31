import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme_extension.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';

/// Global key wired to MaterialApp.router's scaffoldMessengerKey.
/// This ensures snackbars always render at the root level — above the
/// bottom nav bar — regardless of which nested Scaffold triggers them.
final rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
      semanticColor: context.appTheme.incomeColor,
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
      semanticColor: context.appTheme.expenseColor,
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
      semanticColor: context.colors.primary,
      action: action,
      duration: duration,
    );
  }

  /// Show a success SnackBar and return its [ScaffoldFeatureController].
  ///
  /// Use when you need the `.closed` future (e.g. undo-then-record patterns).
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showSuccessAndReturn(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarDefault,
  }) {
    final messenger = _messengerOrNull ?? ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      _buildSnackBar(
        context,
        message: message,
        icon: AppIcons.checkCircle,
        semanticColor: context.appTheme.incomeColor,
        action: action,
        duration: duration,
      ),
    );
  }

  /// Show an info SnackBar and return its [ScaffoldFeatureController].
  ///
  /// Use when you need the `.closed` future.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showInfoAndReturn(
    BuildContext context,
    String message, {
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarDefault,
  }) {
    final messenger = _messengerOrNull ?? ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      _buildSnackBar(
        context,
        message: message,
        icon: AppIcons.infoFilled,
        semanticColor: context.colors.primary,
        action: action,
        duration: duration,
      ),
    );
  }

  /// Root ScaffoldMessenger — bypasses nested Scaffolds.
  /// Returns null if called before MaterialApp mounts (graceful no-op).
  static ScaffoldMessengerState? get _messengerOrNull =>
      rootMessengerKey.currentState;

  static SnackBar _buildSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color semanticColor,
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarDefault,
  }) {
    final theme = context.appTheme;
    final cs = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Glassmorphic surface: theme-tinted translucent background
    final bgColor = isDark
        ? theme.glassCardSurface
        : Color.alphaBlend(
            semanticColor.withValues(alpha: AppSizes.opacitySubtle),
            theme.glassCardSurface,
          );

    final textColor = cs.onSurface;
    final iconColor = semanticColor;

    return SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.xs),
            decoration: BoxDecoration(
              color: semanticColor.withValues(alpha: AppSizes.opacityLight2),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: Icon(icon, color: iconColor, size: AppSizes.iconSm),
          ),
          const SizedBox(width: AppSizes.sm),
          Flexible(
            child: Text(
              message,
              style: context.textStyles.bodyMedium?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
        side: BorderSide(color: theme.glassCardBorder),
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
      action: action != null
          ? SnackBarAction(
              label: action.label,
              onPressed: action.onPressed,
              textColor: semanticColor,
            )
          : null,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color semanticColor,
    SnackBarAction? action,
    required Duration duration,
  }) {
    final messenger = _messengerOrNull;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      _buildSnackBar(
        context,
        message: message,
        icon: icon,
        semanticColor: semanticColor,
        action: action,
        duration: duration,
      ),
    );
  }
}
