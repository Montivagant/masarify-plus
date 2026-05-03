import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '_bloom_painter.dart';

/// Cool pastel gradient page background with two or three radial blooms.
///
/// Wraps [child] in a `Stack` that paints the gradient + blooms first,
/// then layers `child` on top. Wrapped in `RepaintBoundary` so dashboard
/// rebuilds (filter changes, scroll, refresh) do not repaint the
/// gradient layer.
///
/// Pairs with `Scaffold(backgroundColor: Colors.transparent)` so the
/// gradient is visible through scaffolds.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  static const _lightBlooms = <BloomSpec>[
    BloomSpec(
      alignment: Alignment(-0.65, -0.85),
      radiusFraction: 0.85,
      color: AppColors.bloomAquaLight,
    ),
    BloomSpec(
      alignment: Alignment(0.75, -0.65),
      radiusFraction: 0.75,
      color: AppColors.bloomMintLight,
    ),
    BloomSpec(
      alignment: Alignment(0.0, 0.85),
      radiusFraction: 0.95,
      color: AppColors.bloomWhiteLight,
    ),
  ];

  static const _darkBlooms = <BloomSpec>[
    BloomSpec(
      alignment: Alignment(-0.65, -0.85),
      radiusFraction: 0.85,
      color: AppColors.bloomMintDark,
    ),
    BloomSpec(
      alignment: Alignment(0.75, -0.65),
      radiusFraction: 0.75,
      color: AppColors.bloomTealDark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blooms = isDark ? _darkBlooms : _lightBlooms;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? AppColors.gradientDarkStops
                        : AppColors.gradientLightStops,
                    stops: AppColors.gradientStops,
                  ),
                ),
              ),
              CustomPaint(painter: BloomPainter(blooms)),
            ],
          ),
        ),
        child,
      ],
    );
  }
}
