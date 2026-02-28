import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/goal_contributions_table.dart';
import '../tables/savings_goals_table.dart';

part 'goal_dao.g.dart';

@DriftAccessor(tables: [SavingsGoals, GoalContributions])
class GoalDao extends DatabaseAccessor<AppDatabase> with _$GoalDaoMixin {
  GoalDao(super.db);

  // ── Goals ─────────────────────────────────────────────────────────────────

  Stream<List<SavingsGoal>> watchAll() =>
      (select(savingsGoals)
            ..where((g) => g.isCompleted.not())
            ..orderBy([(g) => OrderingTerm.asc(g.createdAt)]))
          .watch();

  Stream<List<SavingsGoal>> watchCompleted() =>
      (select(savingsGoals)
            ..where((g) => g.isCompleted.equals(true))
            ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
          .watch();

  Future<SavingsGoal?> getById(int id) =>
      (select(savingsGoals)..where((g) => g.id.equals(id))).getSingleOrNull();

  Future<int> insertGoal(SavingsGoalsCompanion entry) =>
      into(savingsGoals).insert(entry);

  Future<bool> saveGoal(SavingsGoalsCompanion entry) =>
      (update(savingsGoals)..where((g) => g.id.equals(entry.id.value)))
          .write(entry)
          .then((count) => count > 0);

  Future<bool> deleteGoal(int id) =>
      (delete(savingsGoals)..where((g) => g.id.equals(id)))
          .go()
          .then((count) => count > 0);

  /// Increment currentAmount for a goal
  Future<void> addProgress(int goalId, int amountPiastres) async {
    await customUpdate(
      'UPDATE savings_goals SET current_amount = current_amount + ? WHERE id = ?',
      variables: [
        Variable.withInt(amountPiastres),
        Variable.withInt(goalId),
      ],
      updates: {savingsGoals},
    );
  }

  /// Decrement currentAmount for a goal (clamped to 0 via MAX).
  /// Returns the number of updated rows (0 if goal not found).
  Future<int> subtractProgress(int goalId, int amountPiastres) async {
    return customUpdate(
      'UPDATE savings_goals SET current_amount = MAX(0, current_amount - ?) WHERE id = ?',
      variables: [
        Variable.withInt(amountPiastres),
        Variable.withInt(goalId),
      ],
      updates: {savingsGoals},
    );
  }

  // ── Goal Contributions ────────────────────────────────────────────────────

  Stream<List<GoalContribution>> watchContributions(int goalId) =>
      (select(goalContributions)
            ..where((c) => c.goalId.equals(goalId))
            ..orderBy([(c) => OrderingTerm.desc(c.date)]))
          .watch();

  Future<int> insertContribution(GoalContributionsCompanion entry) =>
      into(goalContributions).insert(entry);

  Future<GoalContribution?> getContribution(int id) =>
      (select(goalContributions)..where((c) => c.id.equals(id)))
          .getSingleOrNull();

  Future<bool> deleteContribution(int id) =>
      (delete(goalContributions)..where((c) => c.id.equals(id)))
          .go()
          .then((count) => count > 0);
}
