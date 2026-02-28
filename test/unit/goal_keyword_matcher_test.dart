import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/core/utils/goal_keyword_matcher.dart';

void main() {
  group('GoalKeywordMatcher', () {
    group('matches()', () {
      test('matches Arabic keyword in text', () {
        const matcher = GoalKeywordMatcher(keywords: ['سفر', 'رحلة']);
        expect(matcher.matches('تذكرة سفر القاهرة'), true);
      });

      test('returns false when no keywords match', () {
        const matcher = GoalKeywordMatcher(keywords: ['سفر', 'رحلة']);
        expect(matcher.matches('فاتورة كهرباء'), false);
      });

      test('strips Arabic diacritics (tashkeel)', () {
        const matcher = GoalKeywordMatcher(keywords: ['كتاب']);
        // كِتَابٌ has diacritics
        expect(matcher.matches('شراء كِتَابٌ جديد'), true);
      });

      test('case-insensitive English matching', () {
        const matcher = GoalKeywordMatcher(keywords: ['travel', 'flight']);
        expect(matcher.matches('FLIGHT to Cairo'), true);
      });

      test('mixed case English', () {
        const matcher = GoalKeywordMatcher(keywords: ['Travel']);
        expect(matcher.matches('travel expenses'), true);
      });

      test('returns false for empty keywords list', () {
        const matcher = GoalKeywordMatcher(keywords: []);
        expect(matcher.matches('anything'), false);
      });

      test('returns false for empty text', () {
        const matcher = GoalKeywordMatcher(keywords: ['test']);
        expect(matcher.matches(''), false);
      });
    });

    group('firstMatch()', () {
      test('returns first matching keyword', () {
        const matcher = GoalKeywordMatcher(keywords: ['سفر', 'رحلة']);
        expect(matcher.firstMatch('رحلة عائلية'), 'رحلة');
      });

      test('returns null when no match', () {
        const matcher = GoalKeywordMatcher(keywords: ['سفر']);
        expect(matcher.firstMatch('فاتورة كهرباء'), null);
      });

      test('returns null for empty keywords', () {
        const matcher = GoalKeywordMatcher(keywords: []);
        expect(matcher.firstMatch('anything'), null);
      });
    });
  });
}
