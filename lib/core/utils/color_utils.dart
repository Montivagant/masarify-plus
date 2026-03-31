import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Utility for converting hex color strings to [Color] values.
abstract final class ColorUtils {
  /// Parses a hex color string to a [Color].
  ///
  /// Accepts formats: "#RRGGBB", "#AARRGGBB", "RRGGBB", "AARRGGBB".
  /// Falls back to [fallback] if parsing fails.
  static Color fromHex(String hex, {Color fallback = AppColors.fallbackGray}) {
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {
      // Fall through to return fallback
    }
    return fallback;
  }

  /// Returns a visually appropriate foreground color (black or white)
  /// for text/icons placed on top of [background].
  static Color contrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.35 ? AppColors.black : AppColors.white;
  }
}
