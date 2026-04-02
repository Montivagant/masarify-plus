import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/services/notification_transaction_parser.dart';

void main() {
  group('NotificationTransactionParser', () {
    final now = DateTime(2026, 3, 20, 12);

    group('parse() — expense SMS', () {
      test('"تم خصم 500 ج.م" → type=expense, amount=50000 piastres', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم 500 ج.م من حسابك',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.type, 'expense');
        expect(result.amountPiastres, 50000);
      });

      test('"debited 200 EGP" → type=expense, amount=20000 piastres', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'Your account was debited 200 EGP',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.type, 'expense');
        expect(result.amountPiastres, 20000);
      });
    });

    group('parse() — income SMS', () {
      test('"تم إيداع 1000 EGP" → type=income, amount=100000 piastres', () {
        final result = NotificationTransactionParser.parse(
          sender: 'NBE',
          body: 'تم إيداع 1000 EGP في حسابك',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.type, 'income');
        expect(result.amountPiastres, 100000);
      });

      test('"credited 500 EGP" → type=income', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'Your account has been credited 500 EGP',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.type, 'income');
        expect(result.amountPiastres, 50000);
      });
    });

    group('parse() — amount with commas', () {
      test('"1,500.50 EGP" → 150050 piastres', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم 1,500.50 EGP من حسابك',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.amountPiastres, 150050);
      });

      test('"10,000 EGP" → 1000000 piastres', () {
        final result = NotificationTransactionParser.parse(
          sender: 'NBE',
          body: 'تم خصم 10,000 EGP من رصيدك المتاح',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.amountPiastres, 1000000);
      });
    });

    group('parse() — foreign currency', () {
      test('"USD 100" → currency=USD', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم USD 100 purchase at Amazon',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.currency, 'USD');
        expect(result.amountPiastres, 10000);
      });

      test('"EUR 50" → currency=EUR', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'charged EUR 50 for online purchase',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.currency, 'EUR');
      });

      test('no foreign currency → defaults to EGP', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم 500 ج.م من حسابك',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.currency, 'EGP');
      });
    });

    group('isAtmWithdrawal()', () {
      test('"سحب نقدي" → true', () {
        expect(
          NotificationTransactionParser.isAtmWithdrawal(
            'تم سحب نقدي 1000 ج.م من ماكينة ATM',
          ),
          isTrue,
        );
      });

      test('"ATM withdrawal" → true', () {
        expect(
          NotificationTransactionParser.isAtmWithdrawal(
            'ATM withdrawal of 500 EGP',
          ),
          isTrue,
        );
      });

      test('"cash withdrawal" → true', () {
        expect(
          NotificationTransactionParser.isAtmWithdrawal(
            'cash withdrawal 200 EGP',
          ),
          isTrue,
        );
      });

      test('regular expense → false', () {
        expect(
          NotificationTransactionParser.isAtmWithdrawal(
            'تم خصم 100 ج.م purchase',
          ),
          isFalse,
        );
      });
    });

    group('parse() — balance keyword avoidance', () {
      test('prefers transaction amount over balance amount', () {
        // "تم خصم 500 ج.م. رصيدك 2500 ج.م" — should pick 500, not 2500
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم 500 ج.م. رصيدك 2500 ج.م',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.amountPiastres, 50000); // 500 EGP, not 2500
      });

      test('avoids balance amount in English', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'debited 300 EGP. Your available balance is 1200 EGP.',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.amountPiastres, 30000); // 300, not 1200
      });
    });

    group('isFinancialSender()', () {
      test('"CIB" → true', () {
        expect(NotificationTransactionParser.isFinancialSender('CIB'), isTrue);
      });

      test('"NBE" → true', () {
        expect(NotificationTransactionParser.isFinancialSender('NBE'), isTrue);
      });

      test('"VODAFONE CASH" → true', () {
        expect(
          NotificationTransactionParser.isFinancialSender('VODAFONE CASH'),
          isTrue,
        );
      });

      test('"RANDOM" → false', () {
        expect(
          NotificationTransactionParser.isFinancialSender('RANDOM'),
          isFalse,
        );
      });

      test('"MyApp Notifications" → false', () {
        expect(
          NotificationTransactionParser.isFinancialSender(
              'MyApp Notifications',),
          isFalse,
        );
      });

      test('case insensitive: "cib" → true', () {
        expect(
          NotificationTransactionParser.isFinancialSender('cib'),
          isTrue,
        );
      });
    });

    group('bodyHash()', () {
      test('SHA-256 hash is deterministic', () {
        const body = 'تم خصم 500 ج.م من حسابك';
        final hash1 = NotificationTransactionParser.bodyHash(body);
        final hash2 = NotificationTransactionParser.bodyHash(body);
        expect(hash1, equals(hash2));
      });

      test('hash matches manual SHA-256 computation', () {
        const body = 'Test body';
        final expected = sha256.convert(utf8.encode(body.trim())).toString();
        expect(NotificationTransactionParser.bodyHash(body), equals(expected));
      });

      test('hash is 64-character hex string', () {
        final hash =
            NotificationTransactionParser.bodyHash('Some notification');
        expect(hash.length, 64);
        expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hash), isTrue);
      });

      test('different bodies produce different hashes', () {
        final hash1 = NotificationTransactionParser.bodyHash('تم خصم 500 ج.م');
        final hash2 = NotificationTransactionParser.bodyHash('تم خصم 600 ج.م');
        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('parse() — edge cases', () {
      test('body with no amount → returns null', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم تحديث بيانات حسابك بنجاح',
          receivedAt: now,
        );
        expect(result, isNull);
      });

      test('body with no debit/credit keyword → returns null', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: '500 EGP in your account',
          receivedAt: now,
        );
        expect(result, isNull);
      });

      test('parsed result includes source field', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم 100 EGP',
          receivedAt: now,
          source: 'sms',
        );

        expect(result, isNotNull);
        expect(result!.source, 'sms');
      });

      test('parsed result defaults source to notification', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم 100 EGP',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.source, 'notification');
      });

      test('parsed result includes sender address', () {
        final result = NotificationTransactionParser.parse(
          sender: 'CIB-ALERTS',
          body: 'تم خصم 100 EGP',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.senderAddress, 'CIB-ALERTS');
      });
    });

    group('parse() — positional type detection', () {
      test('debit keyword first → expense even when credit keyword exists', () {
        // "تم خصم 500 عمولة. تحويل وارد 1000" — debit first
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تم خصم 500 EGP عمولة. تحويل وارد 1000 EGP',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.type, 'expense');
      });

      test('credit keyword first → income even when debit keyword exists', () {
        // "تحويل وارد 1000 ج.م تم خصم عمولة 10 ج.م"
        final result = NotificationTransactionParser.parse(
          sender: 'CIB',
          body: 'تحويل وارد 1000 ج.م تم خصم عمولة 10 ج.م',
          receivedAt: now,
        );

        expect(result, isNotNull);
        expect(result!.type, 'income');
      });
    });
  });
}
