import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/services/semantic_fingerprint_service.dart';

void main() {
  group('SemanticFingerprintService', () {
    group('compute()', () {
      test('returns two fingerprints (current + adjacent window)', () {
        final fingerprints = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: DateTime(2026, 3, 20, 10, 0, 0),
        );

        expect(fingerprints, hasLength(2));
        expect(fingerprints[0], isNot(equals(fingerprints[1])));
      });

      test('same sender+amount+type+time window → same fingerprints', () {
        // Two messages within the same 5-minute window
        final time = DateTime(2026, 3, 20, 10, 0, 0);

        final fp1 = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time,
        );
        final fp2 = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time.add(const Duration(minutes: 1)),
        );

        // Same window → same current fingerprint
        expect(fp1[0], equals(fp2[0]));
        // Same adjacent window too
        expect(fp1[1], equals(fp2[1]));
      });

      test('different sender → different fingerprints', () {
        final time = DateTime(2026, 3, 20, 10, 0, 0);

        final fpCIB = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time,
        );
        final fpNBE = SemanticFingerprintService.compute(
          senderOrWalletId: 'NBE',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time,
        );

        expect(fpCIB[0], isNot(equals(fpNBE[0])));
        expect(fpCIB[1], isNot(equals(fpNBE[1])));
      });

      test('different amount → different fingerprints', () {
        final time = DateTime(2026, 3, 20, 10, 0, 0);

        final fp500 = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time,
        );
        final fp1000 = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 100000,
          type: 'expense',
          receivedAt: time,
        );

        expect(fp500[0], isNot(equals(fp1000[0])));
      });

      test('different type → different fingerprints', () {
        final time = DateTime(2026, 3, 20, 10, 0, 0);

        final fpExpense = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time,
        );
        final fpIncome = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'income',
          receivedAt: time,
        );

        expect(fpExpense[0], isNot(equals(fpIncome[0])));
      });

      test('adjacent time windows share one fingerprint (boundary crossing)',
          () {
        // Window size is 5 minutes = 300,000ms
        // Two messages exactly one window apart: the later message's
        // "adjacent" fingerprint matches the earlier message's "current".
        final windowMs = 5 * 60 * 1000;
        // Pick a time that's at the start of a window boundary
        final epochMs = 1000 * windowMs; // exactly on a boundary
        final time1 = DateTime.fromMillisecondsSinceEpoch(epochMs);
        // time2 is in the next window
        final time2 = DateTime.fromMillisecondsSinceEpoch(epochMs + windowMs);

        final fp1 = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time1,
        );
        final fp2 = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time2,
        );

        // fp2's adjacent window = fp1's current window
        expect(fp2[1], equals(fp1[0]));
      });

      test('fingerprints are SHA-256 hex strings (64 chars)', () {
        final fingerprints = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: DateTime(2026, 3, 20, 10, 0, 0),
        );

        for (final fp in fingerprints) {
          expect(fp.length, 64);
          expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(fp), isTrue);
        }
      });

      test('deterministic — same inputs always produce same output', () {
        final time = DateTime(2026, 3, 20, 14, 30, 0);

        final fp1 = SemanticFingerprintService.compute(
          senderOrWalletId: 'NBE',
          amountPiastres: 100000,
          type: 'income',
          receivedAt: time,
        );
        final fp2 = SemanticFingerprintService.compute(
          senderOrWalletId: 'NBE',
          amountPiastres: 100000,
          type: 'income',
          receivedAt: time,
        );

        expect(fp1, equals(fp2));
      });
    });

    group('normalizeSender()', () {
      test('"CIB Transactions" normalizes to "CIB"', () {
        expect(
          SemanticFingerprintService.normalizeSender('CIB Transactions'),
          'CIB',
        );
      });

      test('"CIB" normalizes to "CIB"', () {
        expect(
          SemanticFingerprintService.normalizeSender('CIB'),
          'CIB',
        );
      });

      test('"NBE-Alert" normalizes to "NBE"', () {
        expect(
          SemanticFingerprintService.normalizeSender('NBE-Alert'),
          'NBE',
        );
      });

      test('strips non-alpha characters', () {
        // "V0D@F0NE-C@SH!" → non-alpha stripped → "VDFNECSH" but
        // check if it contains VODAFONECASH... it won't because digits
        // are stripped. Let's use a clear example.
        expect(
          SemanticFingerprintService.normalizeSender('CIB-123'),
          'CIB',
        );
      });

      test('case-insensitive: "cib alerts" → "CIB"', () {
        expect(
          SemanticFingerprintService.normalizeSender('cib alerts'),
          'CIB',
        );
      });

      test('unknown sender returns uppercased alpha-only', () {
        expect(
          SemanticFingerprintService.normalizeSender('SomeRandom123'),
          'SOMERANDOM',
        );
      });

      test('sender with only special chars returns empty string', () {
        expect(
          SemanticFingerprintService.normalizeSender('123-456'),
          '',
        );
      });

      test(
          'cross-source: SMS "CIB" and notification "CIB Transactions" '
          'produce matching fingerprints', () {
        final time = DateTime(2026, 3, 20, 10, 0, 0);

        final fpSms = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time,
        );
        final fpNotif = SemanticFingerprintService.compute(
          senderOrWalletId: 'CIB Transactions',
          amountPiastres: 50000,
          type: 'expense',
          receivedAt: time,
        );

        expect(fpSms[0], equals(fpNotif[0]));
        expect(fpSms[1], equals(fpNotif[1]));
      });
    });
  });
}
