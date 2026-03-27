import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/entities/budget_entity.dart';
import '../../domain/repositories/i_budget_repository.dart';
import '../database/app_database.dart';
import '../database/daos/budget_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../database/daos/wallet_dao.dart';

class BudgetRepositoryImpl implements IBudgetRepository {
  const BudgetRepositoryImpl(this._dao, this._txDao, this._walletDao);

  final BudgetDao _dao;
  final TransactionDao _txDao;
  final WalletDao _walletDao;

  // ── Streams ──────────────────────────────────────────────────────────────

  // H7 fix: combine budget stream with transaction stream so that
  // budget "spent" values auto-update when transactions change.
  // Previously used asyncMap with one-shot Future, so spent only refreshed
  // when budget rows changed, not when new transactions were added.
  @override
  Stream<List<BudgetEntity>> watchByMonth(int year, int month) {
    final budgetStream = _dao.watchByMonth(year, month);
    final txStream = _txDao.watchByMonth(year, month);

    final walletStream = _walletDao.watchAll();

    return Rx.combineLatest3(
      budgetStream,
      txStream,
      walletStream,
      (List<Budget> budgets, List<Transaction> txns, List<Wallet> wallets) {
        // Filter out transactions from archived wallets for consistency
        // with getByMonth() which uses w.is_archived = 0 in SQL
        final archivedIds = {
          for (final w in wallets)
            if (w.isArchived) w.id,
        };
        final spendByCat = <int, int>{};
        for (final tx in txns) {
          if (tx.type == 'expense' && !archivedIds.contains(tx.walletId)) {
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
    // Rollover disabled — always store false/0 (DB column kept for compat).
    return _dao.insertBudget(
      BudgetsCompanion.insert(
        categoryId: categoryId,
        month: month,
        year: year,
        limitAmount: limitAmount,
        rollover: const Value(false),
        rolloverAmount: const Value(0),
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
