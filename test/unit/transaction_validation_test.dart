import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/services/ai/chat_action.dart';

void main() {
  group('ChatAction.fromJson() — Transaction Parsing', () {
    // Helper to build a valid create_transaction JSON map.
    Map<String, dynamic> _validTxJson({
      String title = 'Lunch',
      dynamic amount = 150.50,
      String type = 'expense',
      String category = 'Food',
      String? date,
      String? note,
    }) =>
        {
          'action': 'create_transaction',
          'title': title,
          'amount': amount,
          'type': type,
          'category': category,
          if (date != null) 'date': date,
          if (note != null) 'note': note,
        };

    group('valid transactions', () {
      test('parses a valid expense with all fields', () {
        final action = ChatAction.fromJson(_validTxJson(
          title: 'Coffee',
          amount: 25,
          type: 'expense',
          category: 'Food',
          date: '2026-03-20',
          note: 'Morning coffee',
        ));

        expect(action, isA<CreateTransactionAction>());
        final tx = action! as CreateTransactionAction;
        expect(tx.title, 'Coffee');
        expect(tx.amountPiastres, 2500); // 25 EGP × 100
        expect(tx.type, 'expense');
        expect(tx.categoryName, 'Food');
        expect(tx.date, '2026-03-20');
        expect(tx.note, 'Morning coffee');
      });

      test('parses a valid income transaction', () {
        final action = ChatAction.fromJson(_validTxJson(
          title: 'Salary',
          amount: 5000,
          type: 'income',
          category: 'Salary',
        ));

        expect(action, isA<CreateTransactionAction>());
        final tx = action! as CreateTransactionAction;
        expect(tx.type, 'income');
        expect(tx.amountPiastres, 500000); // 5000 EGP × 100
      });

      test('EGP→piastres conversion: 150.50 → 15050', () {
        final action = ChatAction.fromJson(_validTxJson(amount: 150.50));

        expect(action, isA<CreateTransactionAction>());
        final tx = action! as CreateTransactionAction;
        expect(tx.amountPiastres, 15050);
      });

      test('accepts amount as string "250"', () {
        final action = ChatAction.fromJson(_validTxJson(amount: '250'));

        expect(action, isA<CreateTransactionAction>());
        final tx = action! as CreateTransactionAction;
        expect(tx.amountPiastres, 25000);
      });

      test('accepts amount as int 100', () {
        final action = ChatAction.fromJson(_validTxJson(amount: 100));

        expect(action, isA<CreateTransactionAction>());
        final tx = action! as CreateTransactionAction;
        expect(tx.amountPiastres, 10000);
      });
    });

    group('zero and negative amounts', () {
      test('zero amount returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: 0));
        expect(action, isNull);
      });

      test('negative amount returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: -50));
        expect(action, isNull);
      });

      test('string zero amount returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: '0'));
        expect(action, isNull);
      });

      test('negative string amount returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: '-100'));
        expect(action, isNull);
      });
    });

    group('amount exceeding max (100M EGP)', () {
      test('amount at 100M EGP boundary is accepted', () {
        // 100,000,000 EGP = 10,000,000,000 piastres = _kMaxPiastres
        // The code checks piastres > _kMaxPiastres, so exactly at boundary
        // should be accepted.
        final action = ChatAction.fromJson(_validTxJson(amount: 100000000));

        expect(action, isA<CreateTransactionAction>());
        final tx = action! as CreateTransactionAction;
        expect(tx.amountPiastres, 10000000000);
      });

      test('amount exceeding 100M EGP returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: 100000001));
        expect(action, isNull);
      });

      test('very large amount returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: 999999999));
        expect(action, isNull);
      });
    });

    group('invalid transaction type', () {
      test('type "transfer" is rejected', () {
        final action = ChatAction.fromJson(_validTxJson(type: 'transfer'));
        expect(action, isNull);
      });

      test('type "refund" is rejected', () {
        final action = ChatAction.fromJson(_validTxJson(type: 'refund'));
        expect(action, isNull);
      });

      test('empty type is rejected', () {
        final action = ChatAction.fromJson(_validTxJson(type: ''));
        expect(action, isNull);
      });

      test('uppercase "INCOME" is rejected (case sensitive)', () {
        final action = ChatAction.fromJson(_validTxJson(type: 'INCOME'));
        expect(action, isNull);
      });
    });

    group('missing required fields', () {
      test('missing action key returns null', () {
        final action = ChatAction.fromJson({
          'title': 'Test',
          'amount': 100,
          'type': 'expense',
          'category': 'Food',
        });
        expect(action, isNull);
      });

      test('missing title returns null', () {
        final json = _validTxJson();
        json.remove('title');
        final action = ChatAction.fromJson(json);
        expect(action, isNull);
      });

      test('empty title returns null', () {
        final action = ChatAction.fromJson(_validTxJson(title: ''));
        expect(action, isNull);
      });

      test('missing amount returns null', () {
        final json = _validTxJson();
        json.remove('amount');
        final action = ChatAction.fromJson(json);
        expect(action, isNull);
      });

      test('missing type returns null', () {
        final json = _validTxJson();
        json.remove('type');
        final action = ChatAction.fromJson(json);
        expect(action, isNull);
      });

      test('missing category returns null', () {
        final json = _validTxJson();
        json.remove('category');
        final action = ChatAction.fromJson(json);
        expect(action, isNull);
      });
    });

    group('unrecognized action type', () {
      test('unknown action returns null', () {
        final action = ChatAction.fromJson({
          'action': 'unknown_action',
          'title': 'Test',
        });
        expect(action, isNull);
      });
    });

    group('toJson round-trip', () {
      test('transaction toJson converts piastres back to EGP', () {
        final tx = const CreateTransactionAction(
          title: 'Test',
          amountPiastres: 15050,
          type: 'expense',
          categoryName: 'Food',
        );
        final json = tx.toJson();
        expect(json['amount'], 150.50);
        expect(json['action'], 'create_transaction');
      });

      test('fromJson → toJson → fromJson round-trip preserves data', () {
        final original = _validTxJson(
          title: 'Dinner',
          amount: 250.75,
          type: 'expense',
          category: 'Food',
          note: 'With friends',
        );
        final action =
            ChatAction.fromJson(original)! as CreateTransactionAction;
        final json = action.toJson();
        final restored = ChatAction.fromJson(json)! as CreateTransactionAction;

        expect(restored.title, action.title);
        expect(restored.amountPiastres, action.amountPiastres);
        expect(restored.type, action.type);
        expect(restored.categoryName, action.categoryName);
        expect(restored.note, action.note);
      });
    });

    group('non-numeric amount edge cases', () {
      test('non-parseable string amount treated as zero → returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: 'abc'));
        expect(action, isNull);
      });

      test('boolean amount treated as zero → returns null', () {
        final action = ChatAction.fromJson(_validTxJson(amount: true));
        expect(action, isNull);
      });

      test('null amount returns null', () {
        final json = _validTxJson();
        json['amount'] = null;
        final action = ChatAction.fromJson(json);
        expect(action, isNull);
      });
    });
  });
}
