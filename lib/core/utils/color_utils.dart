import 'package:flutter/material.dart';

/// Utility for converting hex color strings to [Color] values.
abstract final class ColorUtils {
  /// Parses a hex color string to a [Color].
  ///
  /// Accepts formats: "#RRGGBB", "#AARRGGBB", "RRGGBB", "AARRGGBB".
  /// Falls back to [fallback] if parsing fails.
  static Color fromHex(String hex, {Color fallback = Colors.grey}) {
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
    return luminance > 0.35 ? Colors.black : Colors.white;
  }

  /// Returns a background color derived from [brandColor] with the given
  /// [alpha], ensuring minimum visual contrast against [surface].
  /// If the brand color is too dark for the alpha level, the alpha is
  /// boosted to maintain visibility.
  static Color safeBackgroundFor(
    Color brandColor, {
    double alpha = 0.15,
    Color surface = Colors.white,
  }) {
    final blended = Color.lerp(surface, brandColor, alpha)!;
    // Check if the result is distinguishable from surface
    final surfaceLum = surface.computeLuminance();
    final blendedLum = blended.computeLuminance();
    final contrast = (surfaceLum + 0.05) / (blendedLum + 0.05);
    if (contrast < 1.1 && contrast > 0.9) {
      // Too similar — boost alpha
      return Color.lerp(surface, brandColor, alpha + 0.1)!;
    }
    return blended;
  }
}
