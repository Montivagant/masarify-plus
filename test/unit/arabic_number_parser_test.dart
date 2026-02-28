import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/utils/arabic_number_parser.dart';

void main() {
  group('ArabicNumberParser', () {
    group('normalizeDigits()', () {
      test('converts Eastern Arabic numerals to Western', () {
        expect(ArabicNumberParser.normalizeDigits('١٢٣'), '123');
      });

      test('converts Arabic comma to Western comma', () {
        expect(ArabicNumberParser.normalizeDigits('١،٢٣٤'), '1,234');
      });

      test('leaves Western digits unchanged', () {
        expect(ArabicNumberParser.normalizeDigits('123'), '123');
      });

      test('handles mixed digits', () {
        expect(ArabicNumberParser.normalizeDigits('١23'), '123');
      });

      test('handles empty string', () {
        expect(ArabicNumberParser.normalizeDigits(''), '');
      });
    });

    group('parse() - numeric input', () {
      test('parses Latin digits', () {
        expect(ArabicNumberParser.parse('150'), 15000);
      });

      test('parses Latin decimal', () {
        expect(ArabicNumberParser.parse('150.50'), 15050);
      });

      test('parses Eastern Arabic digits', () {
        expect(ArabicNumberParser.parse('١٥٠'), 15000);
      });

      test('extracts number from mixed text', () {
        expect(ArabicNumberParser.parse('100 جنيه'), 10000);
      });

      test('returns null for no number', () {
        expect(ArabicNumberParser.parse('hello'), null);
      });
    });

    group('parse() - spoken Arabic words', () {
      test('parses مية (100)', () {
        expect(ArabicNumberParser.parse('مية'), 10000);
      });

      test('parses خمسين (50)', () {
        expect(ArabicNumberParser.parse('خمسين'), 5000);
      });

      test('parses مية وخمسين (150)', () {
        expect(ArabicNumberParser.parse('مية وخمسين'), 15000);
      });

      test('parses الف (1000)', () {
        expect(ArabicNumberParser.parse('الف'), 100000);
      });

      test('parses ميتين (200)', () {
        expect(ArabicNumberParser.parse('ميتين'), 20000);
      });

      test('parses compound: عشرين (20)', () {
        expect(ArabicNumberParser.parse('عشرين'), 2000);
      });

      test('parses teens: حداشر (11)', () {
        expect(ArabicNumberParser.parse('حداشر'), 1100);
      });
    });

    group('edge cases', () {
      test('returns null for empty string', () {
        expect(ArabicNumberParser.parse(''), null);
      });

      test('returns null for whitespace only', () {
        expect(ArabicNumberParser.parse('   '), null);
      });

      test('handles leading/trailing whitespace', () {
        expect(ArabicNumberParser.parse('  150  '), 15000);
      });
    });
  });
}
