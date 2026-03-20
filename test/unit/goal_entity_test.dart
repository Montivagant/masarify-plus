import 'package:flutter_test/flutter_test.dart';
import 'package:masarify/domain/entities/savings_goal_entity.dart';

void main() {
  group('SavingsGoalEntity', () {
    // Helper to create a SavingsGoalEntity with sensible defaults.
    SavingsGoalEntity makeGoal({
      int targetAmount = 1000000, // 10,000 EGP
      int currentAmount = 0,
    }) {
      return SavingsGoalEntity(
        id: 1,
        name: 'Emergency Fund',
        iconName: 'savings',
        colorHex: '#FF5733',
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        currencyCode: 'EGP',
        isCompleted: false,
        keywords: '[]',
        createdAt: DateTime(2026, 1, 1),
      );
    }

    group('progressFraction', () {
      test('0% — no contributions', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 0,
        );

        expect(goal.progressFraction, 0.0);
      });

      test('50% — half saved', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 500000,
        );

        expect(goal.progressFraction, 0.5);
      });

      test('100% — completed', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 1000000,
        );

        expect(goal.progressFraction, 1.0);
      });

      test('clamped to 1.0 when over-contributed', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 1500000, // saved more than target
        );

        expect(goal.progressFraction, 1.0);
        // Verify it doesn't exceed 1.0
        expect(goal.progressFraction, lessThanOrEqualTo(1.0));
      });

      test('25% — quarter progress', () {
        final goal = makeGoal(
          targetAmount: 100000, // 1000 EGP
          currentAmount: 25000, // 250 EGP
        );

        expect(goal.progressFraction, 0.25);
      });

      test('zero target amount → 0% progress (no division by zero)', () {
        final goal = makeGoal(
          targetAmount: 0,
          currentAmount: 50000,
        );

        expect(goal.progressFraction, 0.0);
      });

      test('both zero → 0% progress', () {
        final goal = makeGoal(
          targetAmount: 0,
          currentAmount: 0,
        );

        expect(goal.progressFraction, 0.0);
      });

      test('fractional progress is accurate for small amounts', () {
        final goal = makeGoal(
          targetAmount: 30000, // 300 EGP
          currentAmount: 10000, // 100 EGP
        );

        expect(goal.progressFraction, closeTo(0.3333, 0.001));
      });
    });

    group('remainingAmount', () {
      test('full remaining when no contributions', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 0,
        );

        expect(goal.remainingAmount, 1000000);
      });

      test('partial remaining', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 400000,
        );

        expect(goal.remainingAmount, 600000);
      });

      test('zero remaining when completed', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 1000000,
        );

        expect(goal.remainingAmount, 0);
      });

      test('clamped to 0 when over-contributed', () {
        final goal = makeGoal(
          targetAmount: 1000000,
          currentAmount: 1500000,
        );

        expect(goal.remainingAmount, 0);
        expect(goal.remainingAmount, greaterThanOrEqualTo(0));
      });

      test('remaining correctly computed for small amounts', () {
        final goal = makeGoal(
          targetAmount: 50000, // 500 EGP
          currentAmount: 12345,
        );

        expect(goal.remainingAmount, 37655);
      });
    });

    group('all amounts are integer piastres', () {
      test('targetAmount is int', () {
        final goal = makeGoal(targetAmount: 10050);
        expect(goal.targetAmount, isA<int>());
        expect(goal.targetAmount, 10050); // 100.50 EGP
      });

      test('currentAmount is int', () {
        final goal = makeGoal(currentAmount: 7525);
        expect(goal.currentAmount, isA<int>());
        expect(goal.currentAmount, 7525); // 75.25 EGP
      });

      test('remainingAmount is int', () {
        final goal = makeGoal(
          targetAmount: 10050,
          currentAmount: 3025,
        );
        expect(goal.remainingAmount, isA<int>());
        expect(goal.remainingAmount, 7025);
      });
    });

    group('equality', () {
      test('same id → equal', () {
        final g1 = makeGoal(targetAmount: 100000, currentAmount: 0);
        final g2 = SavingsGoalEntity(
          id: 1, // same id
          name: 'Different Name',
          iconName: 'different_icon',
          colorHex: '#000000',
          targetAmount: 999999,
          currentAmount: 888888,
          currencyCode: 'USD',
          isCompleted: true,
          keywords: '["test"]',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(g1, equals(g2));
        expect(g1.hashCode, equals(g2.hashCode));
      });

      test('different id → not equal', () {
        final g1 = makeGoal();
        final g2 = SavingsGoalEntity(
          id: 2,
          name: 'Emergency Fund',
          iconName: 'savings',
          colorHex: '#FF5733',
          targetAmount: 1000000,
          currentAmount: 0,
          currencyCode: 'EGP',
          isCompleted: false,
          keywords: '[]',
          createdAt: DateTime(2026, 1, 1),
        );

        expect(g1, isNot(equals(g2)));
      });
    });

    group('edge cases', () {
      test('very large target (10M EGP = 1B piastres)', () {
        final goal = makeGoal(
          targetAmount: 1000000000,
          currentAmount: 500000000,
        );

        expect(goal.progressFraction, 0.5);
        expect(goal.remainingAmount, 500000000);
      });

      test('1 piastre target', () {
        final goal = makeGoal(
          targetAmount: 1,
          currentAmount: 0,
        );

        expect(goal.progressFraction, 0.0);
        expect(goal.remainingAmount, 1);
      });

      test('1 piastre current on 1 piastre target', () {
        final goal = makeGoal(
          targetAmount: 1,
          currentAmount: 1,
        );

        expect(goal.progressFraction, 1.0);
        expect(goal.remainingAmount, 0);
      });
    });
  });
}
