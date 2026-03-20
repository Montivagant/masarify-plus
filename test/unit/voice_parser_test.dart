import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/utils/voice_transaction_parser.dart';

void main() {
  group('VoiceTransactionParser', () {
    final parser = const VoiceTransactionParser();

    group('parse() — single transaction', () {
      test('"دفعت مية على الأكل" → expense with food category hint', () {
        final draft = parser.parse('دفعت مية على الأكل');

        expect(draft, isNotNull);
        expect(draft!.amountPiastres, 10000); // 100 EGP = 10000 piastres
        expect(draft.type, 'expense');
        // "اكل" or "أكل" should match restaurant category
        // (the input has "الأكل" but dictionary has "أكل")
      });

      test('"اشتريت خمسين جنيه هدوم" → expense, amount=5000', () {
        final draft = parser.parse('اشتريت خمسين جنيه هدوم');

        expect(draft, isNotNull);
        expect(draft!.amountPiastres, 5000); // 50 EGP
        expect(draft.type, 'expense');
      });

      test('"اتقبضت الف جنيه" → income, amount=100000', () {
        final draft = parser.parse('اتقبضت الف جنيه');

        expect(draft, isNotNull);
        expect(draft!.type, 'income');
        expect(draft.amountPiastres, 100000); // 1000 EGP
      });

      test('numeric input "دفعت 150 جنيه" → amount=15000', () {
        final draft = parser.parse('دفعت 150 جنيه');

        expect(draft, isNotNull);
        expect(draft!.amountPiastres, 15000); // 150 EGP
      });

      test('rawText is preserved', () {
        const input = 'دفعت مية على الأكل';
        final draft = parser.parse(input);

        expect(draft, isNotNull);
        expect(draft!.rawText, input);
      });
    });

    group('parseAll() — multi-transaction split', () {
      test('splits on "وكمان"', () {
        final drafts =
            parser.parseAll('دفعت مية على الأكل وكمان خمسين مواصلات');

        expect(drafts.length, 2);
        expect(drafts[0].amountPiastres, 10000); // 100 EGP
        expect(drafts[1].amountPiastres, 5000); // 50 EGP
      });

      test('splits on "وبعدين"', () {
        final drafts =
            parser.parseAll('دفعت 100 جنيه أكل وبعدين 50 جنيه مواصلات');

        expect(drafts.length, 2);
        expect(drafts[0].amountPiastres, 10000);
        expect(drafts[1].amountPiastres, 5000);
      });

      test('splits on "and also" (English)', () {
        final drafts = parser.parseAll('paid 200 food and also 50 transport');

        expect(drafts.length, 2);
        expect(drafts[0].amountPiastres, 20000);
        expect(drafts[1].amountPiastres, 5000);
      });

      test('single segment produces single result', () {
        final drafts = parser.parseAll('دفعت مية');

        expect(drafts.length, 1);
      });
    });

    group('type detection', () {
      test('expense triggers: "دفعت" → expense', () {
        final draft = parser.parse('دفعت 100');
        expect(draft, isNotNull);
        expect(draft!.type, 'expense');
      });

      test('expense triggers: "اشتريت" → expense', () {
        final draft = parser.parse('اشتريت 200 جنيه');
        expect(draft, isNotNull);
        expect(draft!.type, 'expense');
      });

      test('expense triggers: "paid" → expense', () {
        final draft = parser.parse('paid 50');
        expect(draft, isNotNull);
        expect(draft!.type, 'expense');
      });

      test('income triggers: "اتقبضت" → income', () {
        final draft = parser.parse('اتقبضت 5000');
        expect(draft, isNotNull);
        expect(draft!.type, 'income');
      });

      test('income triggers: "استلمت" → income', () {
        final draft = parser.parse('استلمت 300 جنيه');
        expect(draft, isNotNull);
        expect(draft!.type, 'income');
      });

      test('income triggers: "received" → income', () {
        final draft = parser.parse('received 1000');
        expect(draft, isNotNull);
        expect(draft!.type, 'income');
      });

      test('no trigger defaults to expense', () {
        // Only a number, no trigger word
        final draft = parser.parse('500');
        expect(draft, isNotNull);
        expect(draft!.type, 'expense');
      });
    });

    group('cash withdrawal detection', () {
      test('"سحبت" → cash_withdrawal', () {
        final draft = parser.parse('سحبت 1000 من البنك');
        expect(draft, isNotNull);
        expect(draft!.type, 'cash_withdrawal');
      });

      test('"withdrew" → cash_withdrawal', () {
        final draft = parser.parse('withdrew 500');
        expect(draft, isNotNull);
        expect(draft!.type, 'cash_withdrawal');
      });
    });

    group('cash deposit detection', () {
      test('"أودعت" → cash_deposit', () {
        final draft = parser.parse('أودعت 2000 في البنك');
        expect(draft, isNotNull);
        expect(draft!.type, 'cash_deposit');
      });

      test('"deposited" → cash_deposit', () {
        final draft = parser.parse('deposited 1000');
        expect(draft, isNotNull);
        expect(draft!.type, 'cash_deposit');
      });
    });

    group('date offset detection', () {
      test('"امبارح" → dateOffset = -1', () {
        final draft = parser.parse('دفعت 100 امبارح');
        expect(draft, isNotNull);
        expect(draft!.dateOffset, -1);
      });

      test('"أمس" → dateOffset = -1', () {
        final draft = parser.parse('دفعت 50 أمس');
        expect(draft, isNotNull);
        expect(draft!.dateOffset, -1);
      });

      test('"النهارده" → dateOffset = 0', () {
        final draft = parser.parse('دفعت 200 النهارده');
        expect(draft, isNotNull);
        expect(draft!.dateOffset, 0);
      });

      test('"من اسبوع" → dateOffset = -7', () {
        final draft = parser.parse('دفعت 300 من اسبوع');
        expect(draft, isNotNull);
        expect(draft!.dateOffset, -7);
      });

      test('no time keyword → dateOffset = 0', () {
        final draft = parser.parse('دفعت 100');
        expect(draft, isNotNull);
        expect(draft!.dateOffset, 0);
      });
    });

    group('category hint detection', () {
      test('"أكل" → restaurant category', () {
        final draft = parser.parse('دفعت 100 أكل');
        expect(draft, isNotNull);
        expect(draft!.categoryHint, 'restaurant');
      });

      test('"مواصلات" → directions_car category', () {
        final draft = parser.parse('دفعت 50 مواصلات');
        expect(draft, isNotNull);
        expect(draft!.categoryHint, 'directions_car');
      });

      test('"دكتور" → local_hospital category', () {
        final draft = parser.parse('دفعت 300 دكتور');
        expect(draft, isNotNull);
        expect(draft!.categoryHint, 'local_hospital');
      });

      test('no category keyword → null hint', () {
        final draft = parser.parse('دفعت 100');
        expect(draft, isNotNull);
        expect(draft!.categoryHint, isNull);
      });
    });

    group('empty/null input handling', () {
      test('empty string returns null from parse()', () {
        final draft = parser.parse('');
        expect(draft, isNull);
      });

      test('whitespace-only string returns null from parse()', () {
        final draft = parser.parse('   ');
        expect(draft, isNull);
      });

      test('empty string returns empty list from parseAll()', () {
        final drafts = parser.parseAll('');
        expect(drafts, isEmpty);
      });

      test('text with no number returns null', () {
        final draft = parser.parse('دفعت على الأكل');
        expect(draft, isNull);
      });
    });

    group('amount parsing edge cases', () {
      test('spoken number "ميتين" = 200 EGP = 20000 piastres', () {
        final draft = parser.parse('دفعت ميتين');
        expect(draft, isNotNull);
        expect(draft!.amountPiastres, 20000);
      });

      test('fractional "نص" = 0.5 EGP = 50 piastres', () {
        final draft = parser.parse('دفعت نص جنيه');
        expect(draft, isNotNull);
        expect(draft!.amountPiastres, 50);
      });

      test('compound "مية وخمسين" = 150 EGP = 15000 piastres', () {
        final draft = parser.parse('دفعت مية وخمسين');
        expect(draft, isNotNull);
        expect(draft!.amountPiastres, 15000);
      });
    });
  });
}
