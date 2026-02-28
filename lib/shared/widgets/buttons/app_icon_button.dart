import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_sizes.dart';

/// Icon-only button with guaranteed 48×48dp tap target.
/// Always wrap icon-only actions in this instead of raw IconButton.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color,
    this.size = AppSizes.iconMd,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: tooltip,
      button: true,
      child: SizedBox(
        width: AppSizes.minTapTarget,
        height: AppSizes.minTapTarget,
        child: IconButton(
          icon: Icon(icon, size: size, color: color),
          onPressed: onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          tooltip: tooltip,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}
