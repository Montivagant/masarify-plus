import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/app/theme/app_colors.dart';

void main() {
  group('Gradient stops', () {
    test('light gradient has 7 stops, anchored mint at top, white at bottom',
        () {
      expect(AppColors.gradientLightStops, hasLength(7));
      expect(AppColors.gradientLightStops.first, const Color(0xFFDFF6E5));
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
}
