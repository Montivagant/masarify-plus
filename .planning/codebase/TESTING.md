# Masarify Testing Guide

**Last Updated:** 2026-03-27
**Status:** 218 tests passing, 149 new tests added in P4 audit

---

## 1. Test Framework & Setup

**Framework:** `flutter_test` (standard Flutter)

### Run Tests
```bash
flutter test                          # All tests
flutter test test/unit/money_formatter_test.dart  # Single file
flutter test --coverage               # Coverage report
```

### Test File Location
```
test/unit/<name>_test.dart           # Domain logic, entities, utilities
test/widget/                         # Widget/UI tests (minimal; mostly manual)
test/integration/                    # End-to-end flows (optional)
```

Current focus: **Unit tests** in `test/unit/`.

---

## 2. Test Structure

### Basic Template
```dart
// From test/unit/money_formatter_test.dart
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
    });

    group('edge cases', () {
      test('handles max int-like values', () {
        final result = MoneyFormatter.format(1000000000, locale: 'en-US');
        expect(result, contains('10,000,000.00'));
      });
    });
  });
}
```

**Structure:**
- `main()` → `group()` for test suite
- `setUp()` for shared initialization
- Nested `group()` for organization by method/feature
- `test()` for individual assertions
- Clear, present-tense test names

---

## 3. What's Tested (Current Coverage)

### Domain Layer (Entities)
- ✅ `BudgetEntity` — limit, progress, rollover logic
- ✅ `GoalEntity` — target, contribution, status
- ✅ `TransactionEntity` — validation, categorization
- ✅ `WalletEntity` — archiving, balance (implicit via providers)

**File:** `test/unit/budget_entity_test.dart` (102 lines), `goal_entity_test.dart` (168 lines)

Example:
```dart
// From test/unit/budget_entity_test.dart
test('effectiveLimit equals limitAmount (rollover removed)', () {
  final budget = BudgetEntity(
    id: 1,
    categoryId: 10,
    month: 3,
    year: 2026,
    limitAmount: 100000,  // 1000 EGP
    rolloverAmount: 20000,  // ignored
  );
  expect(budget.effectiveLimit, 100000);
});

test('progressFraction at 50% spending', () {
  final budget = makeBudget(
    limitAmount: 100000,
    spentAmount: 50000,
  );
  expect(budget.progressFraction, 0.5);
});
```

### Utilities & Services
- ✅ `MoneyFormatter` — formatting, locale, currencies
- ✅ `ArabicNumberParser` — Arabic/English digit conversion
- ✅ `SemanticFingerprint` — transaction deduplication
- ✅ `SubscriptionDetector` — bill/subscription classification
- ✅ `GoalKeywordMatcher` — goal keyword detection
- ✅ `TransactionValidator` — title, amount, category validation
- ✅ `ColorUtils` — contrast ratios, color manipulation
- ✅ `NotificationParser` — SMS/notification parsing (post-removal, archive only)

**Files in `test/unit/`:**
- `money_formatter_test.dart` (100 lines)
- `subscription_detector_test.dart` (113 lines)
- `budget_entity_test.dart` (102 lines)
- `goal_entity_test.dart` (168 lines)
- `semantic_fingerprint_test.dart` (227 lines)
- `transaction_validation_test.dart` (205 lines)
- `goal_keyword_matcher_test.dart` (65 lines)
- `arabic_number_parser_test.dart` (65 lines)
- `color_utils_test.dart` (55 lines)
- `voice_parser_test.dart` (237 lines)

### NOT Currently Tested
- ❌ Screens (DashboardScreen, AddTransactionScreen, etc.)
- ❌ Providers (Riverpod state management)
- ❌ Repositories & DAOs (database layer)
- ❌ AI Chat, Voice Input, SMS Parser (complex external deps)
- ❌ Navigation routes
- ❌ Animations

**Reason:** Requires `WidgetTester`, mock Riverpod, Drift database mocks — high setup cost.

---

## 4. Test Naming Conventions

**Pattern:** `<what_is_tested> + <condition> + <expectation>`

```dart
// ✅ GOOD
test('formats zero correctly', () { });
test('formats whole amounts in piastres', () { });
test('handles negative amounts', () { });
test('returns true for subscription category', () { });
test('ignores rollover when disabled', () { });

// ❌ POOR
test('test1', () { });
test('MoneyFormatter works', () { });
test('should not crash', () { });
```

**Rules:**
- Present tense, lowercase start
- Include the edge case or condition
- Max 1 assertion per test (or tightly related assertions)

---

## 5. Assertion & Matcher Patterns

### Expect Syntax
```dart
// String matching
expect(result, contains('100.00'));
expect(result, contains('EGP'));
expect(result, isNot(contains('USD')));

// Numeric
expect(budget.progressFraction, 0.5);
expect(budget.progressFraction, closeTo(0.5, 0.01));

// Boolean
expect(detector.isSubscriptionLike(...), isTrue);
expect(detector.isSubscriptionLike(...), isFalse);

// Collections
expect(list, isEmpty);
expect(list, hasLength(3));
expect(list, contains(item));

// Null checks
expect(value, isNull);
expect(value, isNotNull);

// Exceptions
expect(() => func(), throwsA(isA<CustomException>()));
```

From codebase examples:
```dart
// Money formatter test
expect(MoneyFormatter.format(10000), contains('100.00'));

// Goal entity test
expect(goal.getContributionProgress(), closeTo(0.5, 0.001));

// Subscription detector test
expect(SubscriptionDetector.isSubscriptionLike(...), isTrue);
```

---

## 6. Test Fixtures & Helpers

### Factory Pattern
Create helper functions for test data:

```dart
// From test/unit/budget_entity_test.dart
BudgetEntity makeBudget({
  int limitAmount = 100000,
  int rolloverAmount = 0,
  int spentAmount = 0,
  bool rollover = false,
}) {
  return BudgetEntity(
    id: 1,
    categoryId: 10,
    month: 3,
    year: 2026,
    limitAmount: limitAmount,
    rollover: rollover,
    rolloverAmount: rolloverAmount,
    spentAmount: spentAmount,
  );
}

// Usage in test
test('calculates progress at 50%', () {
  final budget = makeBudget(
    limitAmount: 100000,
    spentAmount: 50000,
  );
  expect(budget.progressFraction, 0.5);
});
```

**Convention:**
- Name: `make<EntityName>()`
- All params optional with sensible defaults
- Minimal required fields only
- Simplifies multi-test assertions

---

## 7. Test Organization by Layer

### Entity Tests (Domain)
```dart
test/unit/budget_entity_test.dart
test/unit/goal_entity_test.dart
```
- Test computed properties (`effectiveLimit`, `progressFraction`)
- Test validation logic
- Test edge cases (zero, max values, negative)
- **No external deps** — pure Dart

### Utility Tests
```dart
test/unit/money_formatter_test.dart
test/unit/subscription_detector_test.dart
test/unit/transaction_validation_test.dart
```
- Static/stateless function testing
- Locale & currency variations
- Boundary conditions

### Service Tests (if integration-light)
```dart
// Currently: voice_parser_test.dart
// Tests: VoiceTransactionParser (parsing, validation)
```
- Initialize service with test config
- Mock external APIs (AI, SMS)
- Validate input/output contracts

---

## 8. Mocking (Minimal in Current Codebase)

**Current approach:** Mostly avoided due to complexity.

### If Needed (Future)
```dart
// Example mock for a repository (NOT used yet)
import 'package:mockito/mockito.dart';

class MockWalletRepository extends Mock implements IWalletRepository {
  @override
  Stream<List<WalletEntity>> watchAll() {
    return Stream.value([
      WalletEntity(id: 1, name: 'Cash', balance: 50000),
      WalletEntity(id: 2, name: 'Card', balance: 100000),
    ]);
  }
}

// In test
final mockRepo = MockWalletRepository();
final provider = walletRepositoryProvider;
// Riverpod testing requires ProviderContainer — complex setup
```

**Why minimal mocking:**
- Entity tests don't need mocks
- Utility tests are pure functions
- Repository/Provider tests require `ProviderContainer` + Riverpod complexity
- Better to test via integration when needed

---

## 9. CI/Test Commands

### Local Development
```bash
# Run all unit tests
flutter test

# Run with coverage
flutter test --coverage
flutter test --coverage --reporter=json > coverage.json

# Run specific test file
flutter test test/unit/money_formatter_test.dart

# Watch mode (re-run on file change)
flutter test --watch

# Verbose output
flutter test -v
```

### Check Before Commit
```bash
flutter test
flutter analyze lib/
```

---

## 10. Best Practices

### ✅ DO
- **One assertion per test** (or tightly related)
- **Clear test names** that describe the condition
- **Helper factories** for test data (avoid repetition)
- **Group by feature/method** with nested `group()`
- **Test edge cases** (zero, negative, max, empty)
- **Use `setUp()`** for shared initialization
- **Document complex assertions** with comments

### ❌ DON'T
- **Skip assertions** (test doesn't actually verify anything)
- **Test implementation details** (internal _methods)
- **Mock when you can test real logic** (mocks hide bugs)
- **Create circular test dependencies** (TestA depends on TestB)
- **Hardcode locale/config** (use setUp)
- **Print debug output** in tests (use `skip()` if WIP)

---

## 11. Test Growth Roadmap

**Phase 4 Audit (2026-03-20):** +149 tests added
- ✅ All entity tests (Budget, Goal, Transaction)
- ✅ All utility tests (Money, Parser, Validator)
- ✅ Voice & SMS parsing edge cases

**Future (P5+):**
- Widget tests for critical flows (add transaction, wallet creation)
- Riverpod provider tests (ProviderContainer setup)
- Integration tests (E2E: add wallet → add transaction → check balance)

---

## Summary

| Aspect | Status |
|--------|--------|
| **Framework** | flutter_test |
| **Total Tests** | 218 passing |
| **Scope** | Unit (domain, utils, services) |
| **Coverage** | 10 test files, ~1,400 lines |
| **Mocking** | Minimal (mostly pure functions) |
| **CI Ready** | `flutter test` in bash |
| **New Tests (P4)** | 149 added (focus: critical paths) |

**Key Files:**
- Tests: `test/unit/*.dart` (10 files)
- Helpers: Inline factories (no shared test libs)
- CI: `flutter test` via Bash

