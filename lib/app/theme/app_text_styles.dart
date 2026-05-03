import 'package:flutter/material.dart';

/// Typography scale for Masarify using Plus Jakarta Sans.
/// Applied via ThemeData.textTheme — do not use directly in widgets;
/// instead use context.textStyles.displayLarge etc.
///
/// Tabular figures applied to numeric-displaying styles so columns of
/// money line up across rows (theme revamp v7). If Plus Jakarta Sans
/// loaded via google_fonts does not ship the `tnum` OpenType feature,
/// the fontFeature is a silent no-op — verify with `tool/verify_tnum.dart`
/// and self-host the font if needed.
abstract final class AppTextStyles {
  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// Size/weight overrides only — NO colors, NO fontFamily.
  /// Merged on top of the base theme to preserve flex_color_scheme colors.
  static const TextTheme sizeOverrides = TextTheme(
    // 38sp Bold — Wallet balance hero (theme revamp v7).
    displayLarge: TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.9,
      fontFeatures: _tabular,
    ),
    // 26sp Bold — Screen titles
    headlineLarge: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      fontFeatures: _tabular,
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
      fontFeatures: _tabular,
    ),
    // 16sp Medium — Mini balance header (collapsed hero state).
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFeatures: _tabular,
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
      fontFeatures: _tabular,
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
