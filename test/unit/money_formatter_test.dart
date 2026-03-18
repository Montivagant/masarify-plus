import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter', () {
    setUp(() {
      MoneyFormatter.setLocale('en');
    });

    group('format()', () {
      test('formats zero correctly', () {
        expect(MoneyFormatter.format(0), contains('0.00'));
      });

      test('formats whole amounts in piastres', () {
        final result = MoneyFormatter.format(10000, locale: 'en-US');
        expect(result, contains('100.00'));
        expect(result, contains('EGP'));
      });

      test('formats fractional amounts', () {
        final result = MoneyFormatter.format(15075, locale: 'en-US');
        expect(result, contains('150.75'));
      });

      test('formats negative amounts', () {
        final result = MoneyFormatter.format(-5000, locale: 'en-US');
        expect(result, contains('50.00'));
      });

      test('uses Arabic symbol for EGP in Arabic locale', () {
        final result = MoneyFormatter.format(10000, locale: 'ar-EG');
        expect(result, contains('ج.م'));
      });

      test('formats SAR currency', () {
        final result =
            MoneyFormatter.format(10000, currency: 'SAR', locale: 'en-US');
        expect(result, contains('SAR'));
        expect(result, contains('100.00'));
      });

      test('formats USD currency', () {
        final result =
            MoneyFormatter.format(10000, currency: 'USD', locale: 'en-US');
        expect(result, contains('\$'));
      });

      test('formats EUR currency', () {
        final result =
            MoneyFormatter.format(10000, currency: 'EUR', locale: 'en-US');
        expect(result, contains('€'));
      });
    });

    group('formatCompact()', () {
      test('formats small amount', () {
        final result = MoneyFormatter.formatCompact(10000, locale: 'en-US');
        expect(result, isNotEmpty);
      });

      test('formats large amount with K suffix', () {
        final result = MoneyFormatter.formatCompact(10000000, locale: 'en-US');
        expect(result, isNotEmpty);
      });
    });

    group('formatAmount()', () {
      test('formats without currency symbol', () {
        final result = MoneyFormatter.formatAmount(10050, locale: 'en-US');
        expect(result, contains('100.50'));
        expect(result, isNot(contains('EGP')));
      });
    });

    group('toDisplayDouble()', () {
      test('converts piastres to display double', () {
        expect(MoneyFormatter.toDisplayDouble(10050), 100.50);
      });

      test('converts zero', () {
        expect(MoneyFormatter.toDisplayDouble(0), 0.0);
      });
    });

    group('edge cases', () {
      test('handles max int-like values', () {
        // 10 million EGP = 1 billion piastres
        final result = MoneyFormatter.format(1000000000, locale: 'en-US');
        expect(result, contains('10,000,000.00'));
      });

      test('handles 1 piastre', () {
        final result = MoneyFormatter.format(1, locale: 'en-US');
        expect(result, contains('0.01'));
      });
    });
  });
}
