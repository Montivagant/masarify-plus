import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

/// Masarify standard button with 4 visual variants.
/// Always 48dp minimum height for accessibility.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: AppSizes.spinnerSize,
            width: AppSizes.spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _foregroundColor(context),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconSm),
                const SizedBox(width: AppSizes.sm),
              ],
              Text(label),
            ],
          );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : _onTap(onPressed),
          style: FilledButton.styleFrom(
            minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: isLoading ? null : _onTap(onPressed),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          ),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: isLoading ? null : _onTap(onPressed),
          style: FilledButton.styleFrom(
            minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: isLoading ? null : _onTap(onPressed),
          style: TextButton.styleFrom(
            minimumSize: const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          ),
          child: child,
        ),
    };

    final sized = isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;

    return Semantics(
      label: semanticLabel ?? label,
      button: true,
      enabled: onPressed != null && !isLoading,
      child: sized,
    );
  }

  Color _foregroundColor(BuildContext context) {
    final cs = context.colors;
    return switch (variant) {
      AppButtonVariant.primary => cs.onPrimary,
      AppButtonVariant.secondary => cs.primary,
      AppButtonVariant.danger => cs.onError,
      AppButtonVariant.ghost => cs.primary,
    };
  }

  VoidCallback? _onTap(VoidCallback? cb) {
    if (cb == null) return null;
    return () {
      HapticFeedback.lightImpact();
      cb();
    };
  }
}
