import 'package:drift/drift.dart';

import '../../domain/entities/goal_contribution_entity.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../domain/repositories/i_goal_repository.dart';
import '../database/app_database.dart';
import '../database/daos/goal_dao.dart';
import '../database/daos/wallet_dao.dart';

class GoalRepositoryImpl implements IGoalRepository {
  const GoalRepositoryImpl(this._dao, this._db, this._walletDao);

  final GoalDao _dao;
  final AppDatabase _db;
  final WalletDao _walletDao;

  // ── Goals ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<SavingsGoalEntity>> watchActive() =>
      _dao.watchAll().map((list) => list.map(_toGoalEntity).toList());

  @override
  Stream<List<SavingsGoalEntity>> watchCompleted() =>
      _dao.watchCompleted().map((list) => list.map(_toGoalEntity).toList());

  @override
  Future<SavingsGoalEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toGoalEntity(row) : null;
  }

  @override
  Future<int> createGoal({
    required String name,
    required String iconName,
    required String colorHex,
    required int targetAmount,
    String currencyCode = 'EGP',
    DateTime? deadline,
    String keywords = '[]',
    int? walletId,
  }) {
    // I4 fix: validate target amount is positive
    if (targetAmount <= 0) {
      throw ArgumentError('Goal target amount must be positive');
    }
    return _dao.insertGoal(
      SavingsGoalsCompanion.insert(
        name: name,
        iconName: iconName,
        colorHex: colorHex,
        targetAmount: targetAmount,
        currencyCode: Value(currencyCode),
        deadline: Value(deadline),
        keywords: Value(keywords),
        walletId: Value(walletId),
      ),
    );
  }

  @override
  Future<bool> updateGoal(SavingsGoalEntity goal) {
    // Auto-set isCompleted based on current vs target
    final completed = goal.currentAmount >= goal.targetAmount;
    return _dao.saveGoal(
      SavingsGoalsCompanion(
        id: Value(goal.id),
        name: Value(goal.name),
        iconName: Value(goal.iconName),
        colorHex: Value(goal.colorHex),
        targetAmount: Value(goal.targetAmount),
        currentAmount: Value(goal.currentAmount),
        currencyCode: Value(goal.currencyCode),
        deadline: Value(goal.deadline),
        isCompleted: Value(completed),
        keywords: Value(goal.keywords),
        walletId: Value(goal.walletId),
      ),
    );
  }

  /// M10 fix: delete contributions before deleting goal to avoid orphans.
  /// B1 fix: restore wallet balances for contributions that had wallet deductions.
  @override
  Future<bool> deleteGoal(int id) async {
    return _db.transaction(() async {
      // Null out goalId references in transactions
      await _db.customStatement(
        'UPDATE transactions SET goal_id = NULL WHERE goal_id = ?',
        [id],
      );
      // Restore wallet balances for contributions that had wallet deductions,
      // then delete the contributions.
      final contributions = await _dao.getContributionsByGoal(id);
      for (final c in contributions) {
        if (c.walletId != null) {
          await _walletDao.adjustBalance(c.walletId!, c.amount);
        }
      }
      await _db.customStatement(
        'DELETE FROM goal_contributions WHERE goal_id = ?',
        [id],
      );
      return _dao.deleteGoal(id);
    });
  }

  // ── Contributions ─────────────────────────────────────────────────────────

  @override
  Stream<List<GoalContributionEntity>> watchContributions(int goalId) => _dao
      .watchContributions(goalId)
      .map((list) => list.map(_toContributionEntity).toList());

  @override
  Future<int> addContribution({
    required int goalId,
    required int amount,
    required DateTime date,
    String? note,
  }) async {
    return _db.transaction(() async {
      // I1 fix: prevent contribution from overshooting target
      final goalBefore = await _dao.getById(goalId);
      if (goalBefore == null) {
        throw ArgumentError('Goal $goalId does not exist');
      }
      final remaining = goalBefore.targetAmount - goalBefore.currentAmount;
      if (remaining <= 0) {
        throw ArgumentError('Goal is already fully funded');
      }
      if (amount > remaining) {
        throw ArgumentError(
          'Contribution exceeds remaining target ($remaining piastres)',
        );
      }
      final id = await _dao.insertContribution(
        GoalContributionsCompanion.insert(
          goalId: goalId,
          amount: amount,
          date: date,
          note: Value(note),
        ),
      );
      await _dao.addProgress(goalId, amount);

      // C5 fix: auto-complete goal when target reached
      final goal = await _dao.getById(goalId);
      if (goal != null &&
          !goal.isCompleted &&
          goal.currentAmount >= goal.targetAmount) {
        await _dao.saveGoal(
          SavingsGoalsCompanion(
            id: Value(goalId),
            isCompleted: const Value(true),
          ),
        );
      }

      return id;
    });
  }

  @override
  Future<int> addContributionWithDeduction({
    required int goalId,
    required int amount,
    required DateTime date,
    required int walletId,
    String? note,
  }) async {
    return _db.transaction(() async {
      // Validate goal exists and has room
      final goalBefore = await _dao.getById(goalId);
      if (goalBefore == null) {
        throw ArgumentError('Goal $goalId does not exist');
      }
      final remaining = goalBefore.targetAmount - goalBefore.currentAmount;
      if (remaining <= 0) {
        throw ArgumentError('Goal is already fully funded');
      }
      if (amount > remaining) {
        throw ArgumentError(
          'Contribution exceeds remaining target ($remaining piastres)',
        );
      }

      // 1. Deduct from wallet
      await _walletDao.adjustBalance(walletId, -amount);

      // 2. Insert contribution with walletId
      final id = await _dao.insertContribution(
        GoalContributionsCompanion.insert(
          goalId: goalId,
          amount: amount,
          date: date,
          note: Value(note),
          walletId: Value(walletId),
        ),
      );

      // 3. Update goal's currentAmount
      await _dao.addProgress(goalId, amount);

      // 4. Auto-complete goal when target reached
      final goal = await _dao.getById(goalId);
      if (goal != null &&
          !goal.isCompleted &&
          goal.currentAmount >= goal.targetAmount) {
        await _dao.saveGoal(
          SavingsGoalsCompanion(
            id: Value(goalId),
            isCompleted: const Value(true),
          ),
        );
      }

      return id;
    });
  }

  @override
  Future<bool> deleteContribution(int id) async {
    return _db.transaction(() async {
      final contribution = await _dao.getContribution(id);
      if (contribution == null) return false;

      // H3 fix: guard against negative currentAmount before subtracting
      final goalBefore = await _dao.getById(contribution.goalId);
      final subtractAmount =
          goalBefore != null && contribution.amount > goalBefore.currentAmount
              ? goalBefore.currentAmount
              : contribution.amount;
      await _dao.subtractProgress(contribution.goalId, subtractAmount);

      // Restore wallet balance if contribution was made with wallet deduction.
      if (contribution.walletId != null) {
        await _walletDao.adjustBalance(
          contribution.walletId!,
          contribution.amount,
        );
      }

      // I2 fix: unmark completed if current drops below target
      final goal = await _dao.getById(contribution.goalId);
      if (goal != null &&
          goal.isCompleted &&
          goal.currentAmount < goal.targetAmount) {
        await _dao.saveGoal(
          SavingsGoalsCompanion(
            id: Value(contribution.goalId),
            isCompleted: const Value(false),
          ),
        );
      }

      return _dao.deleteContribution(id);
    });
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static SavingsGoalEntity _toGoalEntity(SavingsGoal g) => SavingsGoalEntity(
        id: g.id,
        name: g.name,
        iconName: g.iconName,
        colorHex: g.colorHex,
        targetAmount: g.targetAmount,
        currentAmount: g.currentAmount,
        currencyCode: g.currencyCode,
        deadline: g.deadline,
        isCompleted: g.isCompleted,
        keywords: g.keywords,
        walletId: g.walletId,
        createdAt: g.createdAt,
      );

  static GoalContributionEntity _toContributionEntity(GoalContribution c) =>
      GoalContributionEntity(
        id: c.id,
        goalId: c.goalId,
        amount: c.amount,
        date: c.date,
        note: c.note,
        walletId: c.walletId,
      );
}
