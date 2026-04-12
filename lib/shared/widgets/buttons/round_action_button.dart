import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// Circular outline button with an active/inactive filled variant.
///
/// Use for approve/skip/toggle affordances on compact card rows.
/// Guarantees [AppSizes.minTapTarget] (48×48) hit region while
/// rendering a visually smaller [AppSizes.iconContainerMd] (40×40) circle.
class RoundActionButton extends StatelessWidget {
  const RoundActionButton({
    super.key,
    required this.icon,
    required this.color,
    required this.active,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool active;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: SizedBox(
          width: AppSizes.minTapTarget,
          height: AppSizes.minTapTarget,
          child: InkResponse(
            onTap: onTap,
            radius: AppSizes.minTapTarget / 2,
            child: Center(
              child: Container(
                width: AppSizes.iconContainerMd,
                height: AppSizes.iconContainerMd,
                decoration: BoxDecoration(
                  color: active
                      ? color.withValues(alpha: AppSizes.opacityLight2)
                      : null,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: active
                        ? AppSizes.borderWidthSelected
                        : AppSizes.glassBorderWidth,
                  ),
                ),
                child: Icon(icon, color: color, size: AppSizes.iconSm),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
