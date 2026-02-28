import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ── Streams ──────────────────────────────────────────────────────────────

  Stream<List<Transaction>> watchAll({int limit = 50, int offset = 0}) =>
      (select(transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(limit, offset: offset))
          .watch();

  Stream<List<Transaction>> watchByWallet(
    int walletId, {
    int limit = 50,
    int offset = 0,
  }) =>
      (select(transactions)
            ..where((t) => t.walletId.equals(walletId))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(limit, offset: offset))
          .watch();

  Stream<List<Transaction>> watchByMonth(int year, int month) {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(transactions)
          ..where(
            (t) =>
                t.transactionDate.isBiggerOrEqualValue(start) &
                t.transactionDate.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }

  // ── Queries ───────────────────────────────────────────────────────────────

  Future<Transaction?> getById(int id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Transaction>> getByCategory(int categoryId, {int limit = 50}) =>
      (select(transactions)
            ..where((t) => t.categoryId.equals(categoryId))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
            ..limit(limit))
          .get();

  /// M2 fix: standardized to exclusive upper bound (start <= date < end).
  Future<List<Transaction>> getByDateRange(DateTime start, DateTime end) =>
      (select(transactions)
            ..where(
              (t) =>
                  t.transactionDate.isBiggerOrEqualValue(start) &
                  t.transactionDate.isSmallerThanValue(end),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .get();

  /// Total income or expense for a given month (in piastres)
  Future<int> sumByTypeAndMonth(String type, int year, int month) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final result = await customSelect(
      'SELECT COALESCE(SUM(amount), 0) AS total FROM transactions '
      'WHERE type = ? AND transaction_date >= ? AND transaction_date < ?',
      variables: [
        Variable.withString(type),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
      readsFrom: {transactions},
    ).getSingle();
    return result.read<int>('total');
  }

  Future<int> sumByCategoryAndMonth(int categoryId, int year, int month) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1); // Dart normalizes month 13 → Jan next year
    final result = await customSelect(
      'SELECT COALESCE(SUM(t.amount), 0) AS total '
      'FROM transactions t '
      'JOIN wallets w ON t.wallet_id = w.id '
      'WHERE t.category_id = ? AND t.type = ? '
      'AND t.transaction_date >= ? AND t.transaction_date < ? '
      'AND w.is_archived = 0',
      variables: [
        Variable.withInt(categoryId),
        Variable.withString('expense'),
        Variable.withDateTime(start),
        Variable.withDateTime(end),
      ],
      readsFrom: {transactions},
    ).getSingle();
    return result.read<int>('total');
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> saveTransaction(TransactionsCompanion entry) =>
      (update(transactions)..where((t) => t.id.equals(entry.id.value)))
          .write(entry)
          .then((count) => count > 0);

  Future<bool> deleteById(int id) =>
      (delete(transactions)..where((t) => t.id.equals(id)))
          .go()
          .then((count) => count > 0);

  Future<void> truncate() => delete(transactions).go();

  /// H9 fix: count transactions for a given wallet.
  Future<int> countByWallet(int walletId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM transactions WHERE wallet_id = ?',
      variables: [Variable.withInt(walletId)],
      readsFrom: {transactions},
    ).getSingle();
    return result.read<int>('cnt');
  }
}
