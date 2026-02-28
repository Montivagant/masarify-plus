import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// A reusable glassmorphism card using BackdropFilter + blur.
///
/// Used sparingly: balance card glass inset, insight cards.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.md),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final radius =
        borderRadius ?? BorderRadius.circular(AppSizes.borderRadiusMd);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.glassBlurSigma,
          sigmaY: AppSizes.glassBlurSigma,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: theme.glassSurface,
            borderRadius: radius,
            border: Border.all(
              color: theme.glassBorder,
              // ignore: avoid_redundant_argument_values
              width: AppSizes.glassBorderWidth,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
