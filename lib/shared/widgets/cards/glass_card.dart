import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';

/// 4×5 colour matrix that boosts saturation by 1.6× while preserving
/// luminance. Applied via `ColorFiltered` *after* the backdrop blur so
/// the bleed-through reads as chromatic frost.
///
/// NOTE: this also tints the foreground content slightly. If that proves
/// visually wrong on real device, drop the `ColorFiltered` wrapper in
/// [GlassCard.build] and accept blur-only frost. The saturation step is
/// polish, not load-bearing.
const List<double> _kSaturate160Matrix = <double>[
  // R out
  0.213 + 0.787 * 1.6, 0.715 - 0.715 * 1.6, 0.072 - 0.072 * 1.6, 0, 0,
  // G out
  0.213 - 0.213 * 1.6, 0.715 + 0.285 * 1.6, 0.072 - 0.072 * 1.6, 0, 0,
  // B out
  0.213 - 0.213 * 1.6, 0.715 - 0.715 * 1.6, 0.072 + 0.928 * 1.6, 0, 0,
  // A out
  0, 0, 0, 1, 0,
];

/// 3-tier glass surface hierarchy inspired by iOS Control Center.
enum GlassTier {
  /// Tier 1 — Bottom sheets, dialogs, overlays. Heavy blur, owns its
  /// backdrop region by default.
  background,

  /// Tier 2 — Cards, sections. Refined low-fill glass. Does NOT own a
  /// backdrop region by default — a parent surface (hero region, list
  /// viewport, nav bar) owns it instead. Pass `useOwnBackdrop: true` to
  /// override for an isolated tier-2 card.
  card,

  /// Tier 3 — Nested elements, icon badges. Translucent fill only, no
  /// backdrop blur.
  inset,
}

/// A reusable glassmorphism surface with 3-tier blur hierarchy.
///
/// Performance-aware: skips [BackdropFilter] on low-end devices or when
/// Reduce Motion is enabled, but keeps translucent surface + border.
///
/// Backdrop policy (theme revamp v7):
/// * Tier 1 (`background`) owns its backdrop by default.
/// * Tier 2 (`card`) and tier 3 (`inset`) do NOT own a backdrop by
///   default — they paint a translucent fill and rely on a parent
///   surface to own the [BackdropFilter] region. This keeps the visible
///   filter count well under the documented 8-filter Android ceiling.
/// * Override per-instance with [useOwnBackdrop].
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
    this.useOwnBackdrop,
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

  /// Whether this card paints its own [BackdropFilter] region.
  ///
  /// `null` (default) → derived from [tier]: tier 1 owns its backdrop;
  /// tier 2 and tier 3 do NOT (a parent surface owns it).
  ///
  /// Override to `true` for an isolated tier-2 card whose parent does
  /// not own a backdrop (e.g., the dashboard insight card).
  final bool? useOwnBackdrop;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final radius =
        borderRadius ?? BorderRadius.circular(AppSizes.borderRadiusMd);
    final canBlur = GlassConfig.shouldBlur(context);

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

    // Default ownership per tier; explicit override wins.
    final defaultOwnsBackdrop = tier == GlassTier.background;
    final ownsBackdrop = useOwnBackdrop ?? defaultOwnsBackdrop;

    // Merge tint color with base surface if provided.
    final effectiveSurface =
        tintColor != null ? Color.alphaBlend(tintColor!, surface) : surface;

    final decoration = BoxDecoration(
      color: gradient == null ? effectiveSurface : null,
      gradient: gradient,
      borderRadius: radius,
      border: showBorder ? Border.all(color: border, width: borderWidth) : null,
      boxShadow: showShadow
          ? <BoxShadow>[
              BoxShadow(
                color: theme.glassShadow,
                blurRadius: AppSizes.cardShadowBlur,
                offset: const Offset(0, AppSizes.cardShadowOffsetY),
              ),
              // Single hairline top inset — light catches the rim.
              BoxShadow(
                color: AppColors.white.withValues(alpha: 0.7),
                offset: const Offset(0, AppSizes.glassTopHighlightInset),
                blurStyle: BlurStyle.inner,
              ),
            ]
          : null,
    );

    Widget content = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    // Wrap in BackdropFilter only when this card OWNS its backdrop and
    // the device supports blur. Otherwise: clip for rounded corners only
    // and rely on the parent surface's backdrop.
    if (ownsBackdrop && canBlur) {
      content = RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(_kSaturate160Matrix),
              child: content,
            ),
          ),
        ),
      );
    } else {
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
