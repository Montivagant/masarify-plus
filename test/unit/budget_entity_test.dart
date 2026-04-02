import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/domain/entities/budget_entity.dart';

void main() {
  group('BudgetEntity', () {
    // Helper to create a BudgetEntity with sensible defaults.
    BudgetEntity makeBudget({
      int limitAmount = 100000, // 1000 EGP
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

    group('effectiveLimit', () {
      test('effectiveLimit equals limitAmount (rollover removed)', () {
        final budget = makeBudget(
          rolloverAmount: 20000, // ignored — rollover removed
        );

        expect(budget.effectiveLimit, 100000); // just limitAmount
      });

      test('effectiveLimit with zero rollover equals limitAmount', () {
        final budget = makeBudget(
          limitAmount: 50000,
        );

        expect(budget.effectiveLimit, 50000);
      });

      test('effectiveLimit ignores rollover', () {
        final budget = makeBudget(
          rolloverAmount: 500000, // ignored
        );

        expect(budget.effectiveLimit, 100000);
      });
    });

    group('progressFraction', () {
      test('0% — no spending', () {
        final budget = makeBudget(
          
        );

        expect(budget.progressFraction, 0.0);
      });

      test('50% — half spent', () {
        final budget = makeBudget(
          spentAmount: 50000,
        );

        expect(budget.progressFraction, 0.5);
      });

      test('100% — fully spent', () {
        final budget = makeBudget(
          spentAmount: 100000,
        );

        expect(budget.progressFraction, 1.0);
      });

      test('> 100% — over-budget (not clamped)', () {
        final budget = makeBudget(
          spentAmount: 150000, // spent 1500 EGP on 1000 EGP budget
        );

        expect(budget.progressFraction, 1.5);
        expect(budget.progressFraction, greaterThan(1.0));
      });

      test('200% — double over-budget', () {
        final budget = makeBudget(
          spentAmount: 200000,
        );

        expect(budget.progressFraction, 2.0);
      });

      test('zero effectiveLimit → 0.0 (no division by zero)', () {
        final budget = makeBudget(
          limitAmount: 0,
          spentAmount: 50000,
        );

        expect(budget.effectiveLimit, 0);
        expect(budget.progressFraction, 0.0);
      });

      test('progressFraction ignores rollover (rollover removed)', () {
        final budget = makeBudget(
          rolloverAmount: 100000, // ignored
          spentAmount: 100000, // spent 1000 EGP
        );

        // effectiveLimit = 100000 (rollover ignored), spent = 100000 → 100%
        expect(budget.effectiveLimit, 100000);
        expect(budget.progressFraction, 1.0);
      });
    });

    group('all amounts are integer piastres', () {
      test('limitAmount is int', () {
        final budget = makeBudget(limitAmount: 10050);
        expect(budget.limitAmount, isA<int>());
        expect(budget.limitAmount, 10050); // 100.50 EGP
      });

      test('spentAmount is int', () {
        final budget = makeBudget(spentAmount: 7525);
        expect(budget.spentAmount, isA<int>());
        expect(budget.spentAmount, 7525); // 75.25 EGP
      });

      test('rolloverAmount is int', () {
        final budget = makeBudget(rolloverAmount: 3333);
        expect(budget.rolloverAmount, isA<int>());
        expect(budget.rolloverAmount, 3333);
      });

      test('effectiveLimit is int', () {
        final budget = makeBudget(
          limitAmount: 10050,
          rolloverAmount: 3333, // ignored
        );
        expect(budget.effectiveLimit, isA<int>());
        expect(budget.effectiveLimit, 10050);
      });
    });

    group('equality', () {
      test('same id → equal', () {
        const b1 = BudgetEntity(
          id: 1,
          categoryId: 10,
          month: 3,
          year: 2026,
          limitAmount: 100000,
          rollover: false,
          rolloverAmount: 0,
          spentAmount: 50000,
        );
        const b2 = BudgetEntity(
          id: 1,
          categoryId: 20, // different category
          month: 4, // different month
          year: 2026,
          limitAmount: 200000, // different limit
          rollover: true,
          rolloverAmount: 10000,
        );

        expect(b1, equals(b2));
        expect(b1.hashCode, equals(b2.hashCode));
      });

      test('different id → not equal', () {
        final b1 = makeBudget();
        const b2 = BudgetEntity(
          id: 2,
          categoryId: 10,
          month: 3,
          year: 2026,
          limitAmount: 100000,
          rollover: false,
          rolloverAmount: 0,
        );

        expect(b1, isNot(equals(b2)));
      });
    });
  });
}
