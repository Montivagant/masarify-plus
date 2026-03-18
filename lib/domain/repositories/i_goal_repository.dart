import '../entities/goal_contribution_entity.dart';
import '../entities/savings_goal_entity.dart';

abstract interface class IGoalRepository {
  Stream<List<SavingsGoalEntity>> watchActive();

  Stream<List<SavingsGoalEntity>> watchCompleted();

  Future<SavingsGoalEntity?> getById(int id);

  /// Returns the new goal's id.
  Future<int> createGoal({
    required String name,
    required String iconName,
    required String colorHex,
    required int targetAmount,
    String currencyCode = 'EGP',
    DateTime? deadline,
    String keywords = '[]',
    int? walletId,
  });

  Future<bool> updateGoal(SavingsGoalEntity goal);

  Future<bool> deleteGoal(int id);

  // ── Contributions ─────────────────────────────────────────────────────────

  Stream<List<GoalContributionEntity>> watchContributions(int goalId);

  /// Adds a contribution AND increments [SavingsGoalEntity.currentAmount] atomically.
  /// Returns the new contribution's id.
  Future<int> addContribution({
    required int goalId,
    required int amount,
    required DateTime date,
    String? note,
  });

  /// Atomically: deduct [amount] from [walletId] + insert contribution + update goal progress.
  /// Returns the new contribution's id.
  Future<int> addContributionWithDeduction({
    required int goalId,
    required int amount,
    required DateTime date,
    required int walletId,
    String? note,
  });

  Future<bool> deleteContribution(int id);
}
