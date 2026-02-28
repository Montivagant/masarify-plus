import 'package:flutter/material.dart';

/// All brand color constants for Masarify.
/// NEVER use Color(0xFF...) directly in widgets — import from here.
abstract final class AppColors {
  // ── Brand palette — Light Mode (Minty Fresh) ────────────────────────
  static const Color primary = Color(0xFF3DA37A); // Mint Green
  static const Color primaryLight = Color(0xFFE0F7EF); // Very Light Mint
  static const Color accent = Color(0xFF558B71); // Sage Green
  static const Color incomeGreen = Color(0xFF2D7A4F); // Forest Green
  static const Color expenseRed = Color(0xFFC4384A); // Coral Red (WS-5: reduced brightness)
  static const Color transferBlue = Color(0xFF2E7DD1); // Ocean Blue
  static const Color warning = Color(0xFFB8860B); // Warm Amber
  static const Color surface = Color(0xFFF5FBF8); // Mint White
  static const Color onSurface = Color(0xFF1A2E27); // Deep Green-Black
  static const Color surfaceCard = Color(0xFFFFFFFF); // Pure White

  // ── Dark Mode (Gothic Noir) ─────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0E0E0E); // True Noir
  static const Color surfaceDark = Color(0xFF1A1A1A); // Dark Charcoal
  static const Color primaryDark = Color(0xFF6B5B95); // Muted Purple (WS-5: lower saturation)
  static const Color onSurfaceDark = Color(0xFFC4C4C4); // Silver Gray
  static const Color surfaceCardDark = Color(0xFF1E1E2A); // Dark indigo-gray (WS-5: cooler)

  // ── Comparison / Previous Period ──────────────────────────────────────
  static const Color lastMonthGray = Color(0xFF94A3B8); // Slate 400
  static const Color lastMonthGrayLight = Color(0xFFCBD5E1); // Slate 300
  static const Color lastMonthGrayDark = Color(0xFF94A3B8); // Slate 400
  static const Color lastMonthGrayLightDark = Color(0xFF64748B); // Slate 500

  // ── Semantic ──────────────────────────────────────────────────────────
  static const Color success = Color(0xFF1B7A4A); // Deep Emerald
  static const Color successDark = Color(0xFF7DAE8B); // Sage Green
  static const Color error = expenseRed;

  // ── Dark mode semantic colors ────────────────────────────────────────
  static const Color incomeGreenDark = Color(0xFFE19B8B); // Rose Gold
  static const Color expenseRedDark = Color(0xFFB85450); // Warm terracotta (WS-5: less aggressive)
  static const Color transferBlueDark = Color(0xFF6B7FA3); // Muted Blue
  static const Color warningDark = Color(0xFFD4A574); // Warm Tan

  // ── Disabled ─────────────────────────────────────────────────────────
  static const Color disabled = Color(0xFFB0C4B8); // Muted Sage
  static const Color disabledDark = Color(0xFF4A4A4A); // Charcoal Gray
  static const Color onDisabled = Color(0xFF64748B); // Slate 500

  // ── Semantic text overlays (on solid semantic backgrounds) ───────────
  static const Color onSuccess = Colors.white;
  static const Color onError = Colors.white;
  static const Color onWarning = Colors.white;
  static const Color onTransfer = Colors.white;

  // ── Gradient stops (WS-7) ─────────────────────────────────────────────
  static const Color gradientStartLight = Color(0xFF3DA37A); // Mint
  static const Color gradientEndLight = Color(0xFF2D8A65); // Deep Mint
  static const Color gradientStartDark = Color(0xFF6B5B95); // Purple
  static const Color gradientEndDark = Color(0xFF4A3D6E); // Deep Purple

  // ── Glass surface (WS-7) ──────────────────────────────────────────────
  static const Color glassSurfaceLight = Color(0x33FFFFFF); // White 20%
  static const Color glassBorderLight = Color(0x1AFFFFFF); // White 10%
  static const Color glassSurfaceDark = Color(0x33FFFFFF); // White 20%
  static const Color glassBorderDark = Color(0x1AFFFFFF); // White 10%
}
