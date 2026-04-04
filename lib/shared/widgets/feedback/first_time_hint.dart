import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// A one-time hint overlay that shows a message with dismiss.
/// Displays as a floating tooltip near the target area.
class FirstTimeHint extends StatelessWidget {
  const FirstTimeHint({
    super.key,
    required this.message,
    required this.icon,
    required this.onDismiss,
    this.alignment = Alignment.center,
  });

  final String message;
  final IconData icon;
  final VoidCallback onDismiss;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.translucent,
      child: Container(
        color: AppColors.black.withValues(alpha: AppSizes.opacityLight2),
        child: Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.all(AppSizes.xl),
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: AppSizes.opacityXLight),
                  blurRadius: AppSizes.fabShadowBlur,
                  offset: const Offset(0, AppSizes.fabShadowOffsetY),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: cs.primary, size: AppSizes.iconMd),
                const SizedBox(width: AppSizes.sm),
                Flexible(
                  child: Text(
                    message,
                    style: context.textStyles.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Icon(AppIcons.close, color: cs.outline, size: AppSizes.iconXs),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
