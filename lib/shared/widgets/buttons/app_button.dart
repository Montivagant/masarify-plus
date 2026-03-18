import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

enum AppButtonVariant { primary, secondary, danger, ghost }

/// Masarify standard button with 4 visual variants.
/// Always 48dp minimum height for accessibility.
/// Includes a subtle scale-down animation on press (E5).
class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final child = widget.isLoading
        ? SizedBox(
            height: AppSizes.spinnerSize,
            width: AppSizes.spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.spinnerStrokeWidth,
              color: _foregroundColor(context),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: AppSizes.iconSm),
                const SizedBox(width: AppSizes.sm),
              ],
              Text(widget.label),
            ],
          );

    final button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: widget.isLoading ? null : _onTap(widget.onPressed),
          style: FilledButton.styleFrom(
            minimumSize:
                const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          ),
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: widget.isLoading ? null : _onTap(widget.onPressed),
          style: OutlinedButton.styleFrom(
            minimumSize:
                const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          ),
          child: child,
        ),
      AppButtonVariant.danger => FilledButton(
          onPressed: widget.isLoading ? null : _onTap(widget.onPressed),
          style: FilledButton.styleFrom(
            minimumSize:
                const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
            backgroundColor: context.colors.error,
            foregroundColor: context.colors.onError,
          ),
          child: child,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: widget.isLoading ? null : _onTap(widget.onPressed),
          style: TextButton.styleFrom(
            minimumSize:
                const Size(AppSizes.minTapTarget, AppSizes.minTapTarget),
          ),
          child: child,
        ),
    };

    final sized = widget.isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;

    // E5: Wrap in GestureDetector + AnimatedScale for press feedback.
    // Skip animation when user prefers reduced motion or button is disabled.
    final bool enableScale =
        !context.reduceMotion && widget.onPressed != null && !widget.isLoading;

    final animated = enableScale
        ? GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            behavior: HitTestBehavior.translucent,
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1.0,
              duration: _isPressed
                  ? AppDurations.microPress
                  : AppDurations.microRelease,
              curve: Curves.easeOutCubic,
              child: sized,
            ),
          )
        : sized;

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      button: true,
      enabled: widget.onPressed != null && !widget.isLoading,
      child: animated,
    );
  }

  Color _foregroundColor(BuildContext context) {
    final cs = context.colors;
    return switch (widget.variant) {
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
