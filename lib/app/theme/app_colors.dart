import 'package:flutter/material.dart';

/// All brand color constants for Masarify.
/// NEVER use Color(0xFF...) directly in widgets — import from here.
abstract final class AppColors {
  // ── Brand palette — Light Mode (Minty Fresh) ────────────────────────
  static const Color primary = Color(0xFF3DA37A); // Mint Green
  static const Color primaryLight = Color(0xFFE0F7EF); // Very Light Mint
  static const Color accent = Color(0xFF558B71); // Sage Green
  static const Color incomeGreen = Color(0xFF2D7A4F); // Forest Green
  static const Color expenseRed =
      Color(0xFFC4384A); // Coral Red (WS-5: reduced brightness)
  static const Color transferBlue = Color(0xFF2E7DD1); // Ocean Blue
  static const Color warning = Color(0xFFB8860B); // Warm Amber
  /// Reduce-transparency fallback solid (matches brightest gradient stop).
  /// Used when [GlassConfig.shouldBlur] returns false.
  static const Color surface = Color(0xFFEFF8F1);
  static const Color secondaryContainerLight = Color(0xFFD4EDE3); // Light sage
  static const Color tertiaryContainerLight = Color(0xFFD1FAE5); // Emerald 100

  // ── Dark Mode (Mint Forest — theme revamp v7) ───────────────────────
  // Names describe Material 3 slot meaning (primary / secondary / tertiary
  // role), NOT hue. Values rebranded from the previous "Gothic Noir"
  // purple identity to the unified mint family.
  static const Color backgroundDark =
      Color(0xFF06140F); // deep mint forest (gradient top)
  /// Reduce-transparency fallback solid for dark mode.
  static const Color surfaceDark = Color(0xFF0E2820);
  static const Color primaryDark =
      Color(0xFF5BC197); // mint glow (matches light primary)
  static const Color primaryContainerDark =
      Color(0xFF143A2B); // deep mint container
  static const Color secondaryDark = Color(0xFF7DD9B8); // pastel mint
  static const Color secondaryContainerDark =
      Color(0xFF1A3A2D); // dark mint container
  static const Color tertiaryDark = Color(0xFF89E0C5); // brighter mint
  static const Color tertiaryContainerDark = Color(0xFF0F2A20); // deep tertiary
  static const Color errorDark = Color(0xFFB85450); // warm terracotta (kept)

  // ── Dark mode semantic colors ────────────────────────────────────────
  static const Color incomeGreenDark = Color(0xFFE19B8B); // Rose Gold
  static const Color expenseRedDark =
      Color(0xFFB85450); // Warm terracotta (WS-5: less aggressive)
  static const Color transferBlueDark = Color(0xFF6B7FA3); // Muted Blue
  static const Color warningDark = Color(0xFFD4A574); // Warm Tan

  // ── Semantic text overlays (on solid semantic backgrounds) ───────────
  static const Color onTransfer = AppColors.white;

  // ── 3-Tier Glass Hierarchy (theme revamp v7 — refined) ──────────────
  // Note: legacy WS-7 `gradientStartLight/End` and `gradientStartDark/End`
  // constants were removed (theme revamp v7). The page gradient is now
  // owned by `gradientLightStops` / `gradientDarkStops` below.
  // Tier 2: Card — milky white frost; gradient bleeds through.
  // v7.1: lowered from 24% → 18% so the gradient reads through the hero.
  static const Color glassCardSurfaceLight = Color(0x2EFFFFFF); // white at 18%
  static const Color glassCardSurfaceDark = Color(0x14FFFFFF); // white at 8%
  static const Color glassCardBorderLight = Color(0x5CFFFFFF); // white at 36%
  static const Color glassCardBorderDark = Color(0x33FFFFFF); // white at 20%

  // Tier 1: Sheet — keeps higher alpha for legibility on busy backdrops.
  static const Color glassSheetSurfaceLight = Color(0xA6FFFFFF); // white at 65%
  static const Color glassSheetSurfaceDark =
      Color(0xCC0E2820); // deep mint at 80%
  static const Color glassSheetBorderLight = Color(0x5CFFFFFF); // white at 36%
  static const Color glassSheetBorderDark = Color(0x33FFFFFF); // white at 20%

  // Tier 3: Inset — nested elements, icon badges (unchanged).
  static const Color glassInsetSurfaceLight = Color(0x26FFFFFF); // White at 15%
  static const Color glassInsetSurfaceDark = Color(0x26FFFFFF); // White at 15%
  static const Color glassInsetBorderLight = Color(0x0FFFFFFF); // White at 6%
  static const Color glassInsetBorderDark = Color(0x14FFFFFF); // White at 8%

  // Slate-neutral shadows (was mint / purple — neutralized for cleaner read).
  static const Color glassShadowLight = Color(0x0F0F1E32); // slate at ~6%
  static const Color glassShadowDark = Color(0x33000000); // black at 20%

  // ── Gradient stops (theme revamp v7) ────────────────────────────────
  /// Top-to-bottom gradient stops for the global page background (light).
  /// Light navy at top → pure white at bottom. Cool only, no warm tones.
  ///
  /// v7.4: gradient palette swapped from mint to light navy per user
  /// request. Brand primary (mint #3DA37A) kept as the accent against
  /// this navy backdrop — FAB, active filter chip, etc. still read as
  /// mint. Top is a soft navy that fades through pale blue into pure
  /// white by ~70%; bottom 30% is essentially white.
  static const List<Color> gradientLightStops = [
    Color(0xFFCDDCEF), // 0%   soft navy mist
    Color(0xFFD5E2F1), // 18%  pale navy
    Color(0xFFDFE7F4), // 38%  pastel sky
    Color(0xFFEDF1F8), // 58%  near-white navy
    Color(0xFFF6F9FC), // 76%  almost white
    Color(0xFFFBFCFE), // 90%  practically white
    Color(0xFFFFFFFF), // 100% pure white
  ];

  /// Stop positions for [gradientLightStops] and [gradientDarkStops].
  static const List<double> gradientStops = [
    0.0,
    0.18,
    0.38,
    0.58,
    0.76,
    0.90,
    1.0,
  ];

  /// Top-to-bottom gradient stops for the dark page background.
  /// Deep navy at top → near-black floor (NOT pure black — preserves
  /// foreground contrast for nav labels and screen-bottom content).
  ///
  /// v7.4: dark variant swapped from mint forest to deep navy.
  static const List<Color> gradientDarkStops = [
    Color(0xFF0A1828), // 0%   deep navy
    Color(0xFF0E2236), // 18%
    Color(0xFF112844), // 38%
    Color(0xFF0C1B2D), // 58%
    Color(0xFF080F1A), // 76%
    Color(0xFF05080F), // 90%
    Color(0xFF080F1A), // 100% near-black floor
  ];

  // ── Radial blooms (theme revamp v7.3 — cool only, no warm tones) ────
  // v7.3 dropped the warm honey bloom that gave the bottom of the
  // screen an orange/yellow cast. Now: soft sky upper-left, soft mint
  // upper-right, pure white halo lower-center. All cool, all subtle.
  // v7.4: bloom colours swapped to navy palette.
  static const Color bloomAquaLight = Color(0x99CCE3FC); // pale sky, ~60%
  static const Color bloomMintLight = Color(0x99BCD3EC); // pale navy, ~60%
  static const Color bloomWhiteLight =
      Color(0xB3FFFFFF); // pure white halo, 70%
  static const Color bloomMintDark = Color(0x4D5B8FC1); // ~30% navy glow
  static const Color bloomTealDark = Color(0x335B97C1); // ~20% sky glow

  // ── Barrier & overlay ───────────────────────────────────────────────────
  static const Color barrierScrim = Color(0x26000000); // Black at 15%

  // ── Utility ────────────────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  /// Neutral gray fallback for missing/invalid color hex values.
  static const Color fallbackGray = Color(0xFF9E9E9E);

  /// Default color hex for goals, wallets, etc. (first picker option).
  static const String defaultColorHex = '#1A6B5E';

  // ── Color picker options ────────────────────────────────────────────────
  /// Shared palette for category, wallet, and goal color pickers.
  static const List<String> pickerOptions = [
    '#1A6B5E',
    '#F5A623',
    '#16A34A',
    '#DC2626',
    '#1E88E5',
    '#7C3AED',
    '#DB2777',
    '#0891B2',
  ];
}
