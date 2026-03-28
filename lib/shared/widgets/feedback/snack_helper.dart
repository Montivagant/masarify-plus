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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      buildSnackBar(
        message: message,
        icon: AppIcons.checkCircle,
        color: context.appTheme.incomeColor,
        onColor: AppColors.white,
        action: action,
        duration: duration,
        bottomMargin: _adaptiveBottomMargin(context),
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      buildSnackBar(
        message: message,
        icon: AppIcons.infoFilled,
        color: context.colors.primary,
        onColor: context.colors.onPrimary,
        action: action,
        duration: duration,
        bottomMargin: _adaptiveBottomMargin(context),
      ),
    );
  }

  /// Build a styled [SnackBar] without showing it.
  ///
  /// Used by callers that need the [ScaffoldFeatureController] returned
  /// by [ScaffoldMessengerState.showSnackBar] (e.g. for `.closed` callback).
  static SnackBar buildSnackBar({
    required String message,
    required IconData icon,
    required Color color,
    required Color onColor,
    SnackBarAction? action,
    Duration duration = AppDurations.snackbarDefault,
    double bottomMargin = AppSizes.snackbarBottomMargin,
  }) {
    return SnackBar(
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
      margin: EdgeInsets.only(
        left: AppSizes.snackHorizontalMargin,
        right: AppSizes.snackHorizontalMargin,
        bottom: bottomMargin,
      ),
      elevation: AppSizes.snackElevation,
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      action: action,
    );
  }

  /// Bottom margin adapts to keyboard state: small when keyboard is visible
  /// (form screens), full 72dp when hidden (clears the floating nav bar).
  static double _adaptiveBottomMargin(BuildContext context) {
    final keyboardUp = MediaQuery.viewInsetsOf(context).bottom > 0;
    return keyboardUp ? AppSizes.sm : AppSizes.snackbarBottomMargin;
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      buildSnackBar(
        message: message,
        icon: icon,
        color: color,
        onColor: onColor,
        action: action,
        duration: duration,
        bottomMargin: _adaptiveBottomMargin(context),
      ),
    );
  }
}
