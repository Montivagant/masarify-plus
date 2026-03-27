import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/utils/subscription_detector.dart';

void main() {
  group('SubscriptionDetector', () {
    test('returns true for subscription category', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'Subscriptions',
          transactionText: 'Netflix',
        ),
        isTrue,
      );
    });

    test('returns true for insurance category', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'Insurance',
          transactionText: 'Car insurance',
        ),
        isTrue,
      );
    });

    test('returns true for utilities category', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'Utilities',
          transactionText: 'Electricity bill',
        ),
        isTrue,
      );
    });

    test('returns true for installments category', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'Installments',
          transactionText: 'Phone installment',
        ),
        isTrue,
      );
    });

    test('returns true for Netflix keyword', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'Entertainment',
          transactionText: 'Netflix monthly',
        ),
        isTrue,
      );
    });

    test('returns true for Spotify keyword', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: null,
          transactionText: 'Spotify premium',
        ),
        isTrue,
      );
    });

    test('returns true for gym keyword', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'Health',
          transactionText: 'Gold Gym membership',
        ),
        isTrue,
      );
    });

    test('returns true for Arabic subscription keyword', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: null,
          transactionText: 'اشتراك سبوتيفاي',
        ),
        isTrue,
      );
    });

    test('returns true for Arabic rent keyword', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: null,
          transactionText: 'ايجار الشقة',
        ),
        isTrue,
      );
    });

    test('returns true for Arabic installment keyword', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: null,
          transactionText: 'قسط الموبايل',
        ),
        isTrue,
      );
    });

    test('returns false for unrelated transaction', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'Food',
          transactionText: 'Lunch at restaurant',
        ),
        isFalse,
      );
    });

    test('returns false with null category and no keywords', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: null,
          transactionText: 'Grocery shopping',
        ),
        isFalse,
      );
    });

    test('category match is case-insensitive', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: 'INSURANCE',
          transactionText: 'Some payment',
        ),
        isTrue,
      );
    });

    test('keyword match is case-insensitive', () {
      expect(
        SubscriptionDetector.isSubscriptionLike(
          categoryName: null,
          transactionText: 'NETFLIX PREMIUM account',
        ),
        isTrue,
      );
    });
  });
}
