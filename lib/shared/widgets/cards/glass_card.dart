import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';

/// 3-tier glass surface hierarchy inspired by iOS Control Center.
enum GlassTier {
  /// Tier 1 — Bottom sheets, dialogs, overlays. Sigma 20, 70% surface.
  background,

  /// Tier 2 — All card widgets, section groups. Sigma 12, 87% surface.
  card,

  /// Tier 3 — Nested elements, quick actions, icon badges. Sigma 8, 15% white.
  inset,
}

/// A reusable glassmorphism card with 3-tier blur hierarchy.
///
/// Performance-aware: skips [BackdropFilter] on low-end devices or when
/// Reduce Motion is enabled, but keeps translucent surface + border.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.tier = GlassTier.card,
    this.padding = const EdgeInsets.all(AppSizes.md),
    this.borderRadius,
    this.tintColor,
    this.showBorder = true,
    this.showShadow = false,
    this.gradient,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final GlassTier tier;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  /// Optional color tint overlaid on the glass surface.
  final Color? tintColor;
  final bool showBorder;
  final bool showShadow;

  /// Optional gradient overlay on the glass surface.
  final Gradient? gradient;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final radius =
        borderRadius ?? BorderRadius.circular(AppSizes.borderRadiusMd);
    final useBlur = GlassConfig.shouldBlur(context);

    // Resolve tier-based properties.
    final double sigma;
    final Color surface;
    final Color border;
    final double borderWidth;
    switch (tier) {
      case GlassTier.background:
        sigma = AppSizes.glassBlurBackground;
        surface = theme.glassSheetSurface;
        border = theme.glassSheetBorder;
        borderWidth = AppSizes.glassBorderWidthSubtle;
      case GlassTier.card:
        sigma = AppSizes.glassBlurCard;
        surface = theme.glassCardSurface;
        border = theme.glassCardBorder;
        borderWidth = AppSizes.glassBorderWidth;
      case GlassTier.inset:
        sigma = AppSizes.glassBlurInset;
        surface = theme.glassInsetSurface;
        border = theme.glassInsetBorder;
        borderWidth = AppSizes.glassBorderWidth;
    }

    // Merge tint color with base surface if provided.
    final effectiveSurface =
        tintColor != null ? Color.alphaBlend(tintColor!, surface) : surface;

    final decoration = BoxDecoration(
      color: gradient == null ? effectiveSurface : null,
      gradient: gradient,
      borderRadius: radius,
      border: showBorder ? Border.all(color: border, width: borderWidth) : null,
      boxShadow: showShadow
          ? [
              BoxShadow(
                color: theme.glassShadow,
                blurRadius: AppSizes.cardShadowBlur,
                offset: const Offset(0, AppSizes.cardShadowOffsetY),
              ),
            ]
          : null,
    );

    Widget content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    // Wrap in BackdropFilter only for background tier (sheets/dialogs).
    // Card and inset tiers skip blur — stacking 8+ BackdropFilters causes
    // GPU compositing overload (grey overlay / frozen screen on Android).
    if (useBlur && tier == GlassTier.background) {
      content = RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: content,
          ),
        ),
      );
    } else {
      // Still clip for rounded corners without blur.
      content = ClipRRect(
        borderRadius: radius,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: content,
        ),
      );
    }

    return content;
  }
}
