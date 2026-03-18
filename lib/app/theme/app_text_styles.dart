import 'package:flutter/material.dart';

/// Typography scale for Masarify using Plus Jakarta Sans.
/// Applied via ThemeData.textTheme — do not use directly in widgets;
/// instead use context.textStyles.displayLarge etc.
abstract final class AppTextStyles {
  /// Size/weight overrides only — NO colors, NO fontFamily.
  /// Merged on top of the base theme to preserve flex_color_scheme colors.
  static const TextTheme sizeOverrides = TextTheme(
    // 32sp Bold — Wallet balance (dashboard hero number)
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    // 26sp Bold — Screen titles
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    // 22sp SemiBold — Section headers
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    // 20sp SemiBold — Sub-section headers
    headlineSmall: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
    // 18sp Medium — List primary text, card titles
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
    ),
    // 14sp Medium — Compact titles, labels
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    // 16sp Regular — Amounts, body copy
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    // 14sp Regular — Secondary info, dates
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    // 12sp Regular — Tertiary body text, fine print
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    // 14sp Medium — Buttons, tabs, chips
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    // 11sp Regular — Timestamps, tertiary labels
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    ),
  );
}
