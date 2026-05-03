import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/app/theme/app_colors.dart';
import 'package:masarify/core/constants/app_sizes.dart';

void main() {
  group('Gradient stops', () {
    test('light gradient has 7 stops, anchored mint at top, white at bottom',
        () {
      expect(AppColors.gradientLightStops, hasLength(7));
      // v7.3: lightened — soft mint top, pure white bottom, no warm tones.
      expect(AppColors.gradientLightStops.first, const Color(0xFFCDEDDC));
      expect(AppColors.gradientLightStops.last, const Color(0xFFFFFFFF));
    });

    test(
        'dark gradient has 7 stops, mint forest at top, near-black floor at bottom',
        () {
      expect(AppColors.gradientDarkStops, hasLength(7));
      expect(AppColors.gradientDarkStops.first, const Color(0xFF06140F));
      expect(AppColors.gradientDarkStops.last, const Color(0xFF080E0C));
      // Floor is above pure black to preserve foreground contrast.
      expect(AppColors.gradientDarkStops.last, isNot(const Color(0xFF000000)));
    });

    test('stops list is monotonic and matches color count', () {
      expect(AppColors.gradientStops, hasLength(7));
      expect(AppColors.gradientStops,
          equals(<double>[0.0, 0.18, 0.38, 0.58, 0.76, 0.90, 1.0]));
    });
  });

  group('Bloom colors', () {
    test('light blooms defined', () {
      expect(AppColors.bloomAquaLight, isNotNull);
      expect(AppColors.bloomMintLight, isNotNull);
      expect(AppColors.bloomWhiteLight, isNotNull);
    });

    test('dark blooms defined', () {
      expect(AppColors.bloomMintDark, isNotNull);
      expect(AppColors.bloomTealDark, isNotNull);
    });
  });

  group('Glass surface tokens (light) — refined recipe', () {
    test('glassCardSurfaceLight is white at ~18% (v7.1)', () {
      // v7.1 lowered from 24% → 18% so the gradient reads through the hero.
      expect(AppColors.glassCardSurfaceLight, const Color(0x2EFFFFFF));
    });
    test('glassCardBorderLight is white at ~36%', () {
      expect(AppColors.glassCardBorderLight, const Color(0x5CFFFFFF));
    });
    test('glassSheetSurfaceLight retains higher alpha for legibility', () {
      expect(AppColors.glassSheetSurfaceLight, const Color(0xA6FFFFFF));
    });
    test('glassShadowLight is slate-tinted', () {
      expect(AppColors.glassShadowLight, const Color(0x0F0F1E32));
    });
  });

  group('Reduce-transparency fallback solids', () {
    test('AppColors.surface matches brightest gradient stop for continuity',
        () {
      expect(AppColors.surface, const Color(0xFFEFF8F1));
    });
    test('AppColors.surfaceDark matches mid dark gradient stop', () {
      expect(AppColors.surfaceDark, const Color(0xFF0E2820));
    });
  });

  group('Glass size tokens', () {
    test('glassBlurCard bumped to 28', () {
      expect(AppSizes.glassBlurCard, 28.0);
    });
    test('cardShadowOffsetY softened to 6 (refined glass float)', () {
      expect(AppSizes.cardShadowOffsetY, 6.0);
    });
    test('cardShadowBlur is 32 for the airy spread', () {
      expect(AppSizes.cardShadowBlur, 32.0);
    });
    test('glassBackdropSaturation = 1.6 for chromatic frost', () {
      expect(AppSizes.glassBackdropSaturation, 1.6);
    });
    test('glassTopHighlightInset = 0.5 hairline specular', () {
      expect(AppSizes.glassTopHighlightInset, 0.5);
    });
  });
}
