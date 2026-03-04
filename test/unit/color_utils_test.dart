import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/app/theme/app_colors.dart';
import 'package:masarify/core/utils/color_utils.dart';

void main() {
  group('ColorUtils', () {
    group('fromHex()', () {
      test('parses 6-digit hex with hash', () {
        final color = ColorUtils.fromHex('#FF0000');
        expect(color, const Color(0xFFFF0000));
      });

      test('parses 6-digit hex without hash', () {
        final color = ColorUtils.fromHex('00FF00');
        expect(color, const Color(0xFF00FF00));
      });

      test('parses 8-digit hex with alpha', () {
        final color = ColorUtils.fromHex('#80FF0000');
        expect(color, const Color(0x80FF0000));
      });

      test('returns fallback for invalid hex', () {
        final color = ColorUtils.fromHex('xyz');
        expect(color, const Color(0xFF9E9E9E));
      });

      test('returns custom fallback for invalid hex', () {
        final color = ColorUtils.fromHex('invalid', fallback: Colors.blue);
        expect(color, Colors.blue);
      });

      test('returns fallback for empty string', () {
        final color = ColorUtils.fromHex('');
        expect(color, const Color(0xFF9E9E9E));
      });
    });

    group('contrastColor()', () {
      test('returns black for light backgrounds', () {
        expect(ColorUtils.contrastColor(Colors.white), AppColors.black);
      });

      test('returns white for dark backgrounds', () {
        expect(ColorUtils.contrastColor(Colors.black), AppColors.white);
      });

      test('returns appropriate contrast for mid-range colors', () {
        final result = ColorUtils.contrastColor(const Color(0xFF808080));
        expect(result == AppColors.black || result == AppColors.white, true);
      });
    });
  });
}
