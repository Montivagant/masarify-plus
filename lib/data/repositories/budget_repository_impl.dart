import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/i_budget_repository.dart';
import '../database/app_database.dart';
import '../database/daos/budget_dao.dart';
import '../database/daos/transaction_dao.dart';

class BudgetRepositoryImpl implements IBudgetRepository {
  const BudgetRepositoryImpl(this._dao, this._txDao);

  final BudgetDao _dao;
  final TransactionDao _txDao;

  // ── Streams ──────────────────────────────────────────────────────────────

  // H7 fix: combine budget stream with transaction stream so that
  // budget "spent" values auto-update when transactions change.
  // Previously used asyncMap with one-shot Future, so spent only refreshed
  // when budget rows changed, not when new transactions were added.
  @override
  Stream<List<BudgetEntity>> watchByMonth(int year, int month) {
    final budgetStream = _dao.watchByMonth(year, month);
    final txStream = _txDao.watchByMonth(year, month);

    return Rx.combineLatest2(
      budgetStream,
      txStream,
      (List<Budget> budgets, List<Transaction> txns) {
        // Compute spend per category in Dart — eliminates N+1 DB queries
        final spendByCat = <int, int>{};
        for (final tx in txns) {
          if (tx.type == 'expense') {
            spendByCat[tx.categoryId] =
                (spendByCat[tx.categoryId] ?? 0) + tx.amount;
          }
        }
        return budgets
            .map((b) => _toEntity(b, spendByCat[b.categoryId] ?? 0))
            .toList();
      },
    );
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  Future<List<BudgetEntity>> getByMonth(int year, int month) async {
    final rows = await _dao.getByMonth(year, month);
    final entities = <BudgetEntity>[];
    for (final row in rows) {
      final spent = await _txDao.sumByCategoryAndMonth(
        row.categoryId,
        year,
        month,
      );
      entities.add(_toEntity(row, spent));
    }
    return entities;
  }

  @override
  Future<BudgetEntity?> getByCategoryAndMonth(
    int categoryId,
    int year,
    int month,
  ) async {
    final row = await _dao.getByCategoryAndMonth(categoryId, year, month);
    if (row == null) return null;
    final spent = await _txDao.sumByCategoryAndMonth(categoryId, year, month);
    return _toEntity(row, spent);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  @override
  Future<int> create({
    required int categoryId,
    required int month,
    required int year,
    required int limitAmount,
    bool rollover = false,
    int rolloverAmount = 0,
  }) async {
    // I3 fix: validate budget limit is positive
    if (limitAmount <= 0) {
      throw ArgumentError('Budget limit must be positive');
    }
    // CR-1 fix: compute rollover from previous month if enabled
    var effectiveRollover = rolloverAmount;
    if (rollover && rolloverAmount == 0) {
      final prevMonth = month == 1 ? 12 : month - 1;
      final prevYear = month == 1 ? year - 1 : year;
      final prev =
          await _dao.getByCategoryAndMonth(categoryId, prevYear, prevMonth);
      if (prev != null && prev.rollover) {
        final prevSpent = await _txDao.sumByCategoryAndMonth(
          categoryId,
          prevYear,
          prevMonth,
        );
        final prevLimit = prev.limitAmount + prev.rolloverAmount;
        final unspent = prevLimit - prevSpent;
        effectiveRollover = unspent > 0 ? unspent : 0;
      }
    }
    return _dao.insertBudget(
      BudgetsCompanion.insert(
        categoryId: categoryId,
        month: month,
        year: year,
        limitAmount: limitAmount,
        rollover: Value(rollover),
        rolloverAmount: Value(effectiveRollover),
      ),
    );
  }

  @override
  Future<bool> update(BudgetEntity budget) => _dao.saveBudget(
        BudgetsCompanion(
          id: Value(budget.id),
          categoryId: Value(budget.categoryId),
          month: Value(budget.month),
          year: Value(budget.year),
          limitAmount: Value(budget.limitAmount),
          rollover: Value(budget.rollover),
          rolloverAmount: Value(budget.rolloverAmount),
        ),
      );

  @override
  Future<bool> delete(int id) => _dao.deleteById(id);

  // ── Mapping ───────────────────────────────────────────────────────────────

  static BudgetEntity _toEntity(Budget b, int spentAmount) => BudgetEntity(
        id: b.id,
        categoryId: b.categoryId,
        month: b.month,
        year: b.year,
        limitAmount: b.limitAmount,
        rollover: b.rollover,
        rolloverAmount: b.rolloverAmount,
        spentAmount: spentAmount,
      );
}
