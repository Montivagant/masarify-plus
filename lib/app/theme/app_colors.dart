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
  static const Color surface = Color(0xFFF5FBF8); // Mint White
  static const Color onSurface = Color(0xFF1A2E27); // Deep Green-Black
  static const Color secondaryContainerLight = Color(0xFFD4EDE3); // Light sage
  static const Color tertiaryContainerLight = Color(0xFFD1FAE5); // Emerald 100

  // ── Dark Mode (Gothic Noir) ─────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0E0E0E); // True Noir
  static const Color surfaceDark = Color(0xFF1A1A1A); // Dark Charcoal
  static const Color primaryDark =
      Color(0xFF6B5B95); // Muted Purple (WS-5: lower saturation)
  static const Color onSurfaceDark = Color(0xFFC4C4C4); // Silver Gray
  static const Color primaryContainerDark = Color(0xFF2D2344); // Dark Violet
  static const Color secondaryDark = Color(0xFFC4898A); // Mauve Pink
  static const Color secondaryContainerDark = Color(0xFF3D2A2A); // Dark mauve
  static const Color tertiaryDark = Color(0xFFE19B8B); // Rose Gold
  static const Color tertiaryContainerDark = Color(0xFF3D2B25); // Dark rose
  static const Color errorDark = Color(0xFFB85450); // Warm terracotta

  // ── Comparison / Previous Period ──────────────────────────────────────
  static const Color lastMonthGray = Color(0xFF94A3B8); // Slate 400
  static const Color lastMonthGrayLight = Color(0xFFCBD5E1); // Slate 300
  static const Color lastMonthGrayDark = Color(0xFF94A3B8); // Slate 400
  static const Color lastMonthGrayLightDark = Color(0xFF64748B); // Slate 500

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color error = expenseRed;

  // ── Dark mode semantic colors ────────────────────────────────────────
  static const Color incomeGreenDark = Color(0xFFE19B8B); // Rose Gold
  static const Color expenseRedDark =
      Color(0xFFB85450); // Warm terracotta (WS-5: less aggressive)
  static const Color transferBlueDark = Color(0xFF6B7FA3); // Muted Blue
  static const Color warningDark = Color(0xFFD4A574); // Warm Tan

  // ── Semantic text overlays (on solid semantic backgrounds) ───────────
  static const Color onTransfer = AppColors.white;

  // ── Gradient stops (WS-7) ─────────────────────────────────────────────
  static const Color gradientStartLight = Color(0xFF3DA37A); // Mint
  static const Color gradientEndLight = Color(0xFF2D8A65); // Deep Mint
  static const Color gradientStartDark = Color(0xFF6B5B95); // Purple
  static const Color gradientEndDark = Color(0xFF4A3D6E); // Deep Purple

  // ── 3-Tier Glass Hierarchy ──────────────────────────────────────────
  // Tier 2: Card — semi-transparent with theme tint
  static const Color glassCardSurfaceLight =
      Color(0xDEF5FBF8); // #F5FBF8 at 87%
  static const Color glassCardSurfaceDark = Color(0xDE1E1E2A); // #1E1E2A at 87%
  static const Color glassCardBorderLight = Color(0x14FFFFFF); // White at 8%
  static const Color glassCardBorderDark = Color(0x1AFFFFFF); // White at 10%

  // Tier 1: Sheet — heavier transparency for overlays
  static const Color glassSheetSurfaceLight =
      Color(0xB3F5FBF8); // #F5FBF8 at 70%
  static const Color glassSheetSurfaceDark =
      Color(0xB30E0E0E); // #0E0E0E at 70%
  static const Color glassSheetBorderLight = Color(0x0DFFFFFF); // White at 5%
  static const Color glassSheetBorderDark = Color(0x14FFFFFF); // White at 8%

  // Tier 3: Inset — nested elements, icon badges
  static const Color glassInsetSurfaceLight = Color(0x26FFFFFF); // White at 15%
  static const Color glassInsetSurfaceDark = Color(0x26FFFFFF); // White at 15%
  static const Color glassInsetBorderLight = Color(0x0FFFFFFF); // White at 6%
  static const Color glassInsetBorderDark = Color(0x14FFFFFF); // White at 8%

  // Brand-tinted shadows
  static const Color glassShadowLight = Color(0x1A3DA37A); // Mint at 10%
  static const Color glassShadowDark = Color(0x1A7B68AE); // Purple at 10%

  // ── Barrier & overlay ───────────────────────────────────────────────────
  static const Color barrierScrim = Color(0x26000000); // Black at 15%
  static const Color dragHandle = Color(0x4DFFFFFF); // White at 30%

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
