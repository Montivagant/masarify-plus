import 'package:drift/drift.dart';

import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/repositories/i_recurring_rule_repository.dart';
import '../database/app_database.dart';
import '../database/daos/recurring_rule_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../database/daos/wallet_dao.dart';

class RecurringRuleRepositoryImpl implements IRecurringRuleRepository {
  const RecurringRuleRepositoryImpl(this._dao, this._db, this._walletDao, this._transactionDao);

  final RecurringRuleDao _dao;
  final AppDatabase _db;
  final WalletDao _walletDao;
  final TransactionDao _transactionDao;

  @override
  Stream<List<RecurringRuleEntity>> watchAll() =>
      _dao.watchAll().map((list) => list.map(_toEntity).toList());

  @override
  Future<List<RecurringRuleEntity>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<RecurringRuleEntity>> getDue(DateTime asOf) async {
    final rows = await _dao.getDue(asOf);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<RecurringRuleEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<int> create({
    required int walletId,
    required int categoryId,
    required int amount,
    required String type,
    required String title,
    required String frequency,
    required DateTime startDate,
    required DateTime nextDueDate,
    DateTime? endDate,
  }) =>
      _dao.insertRule(
        RecurringRulesCompanion.insert(
          walletId: walletId,
          categoryId: categoryId,
          amount: amount,
          type: type,
          title: title,
          frequency: frequency,
          startDate: startDate,
          nextDueDate: nextDueDate,
          endDate: Value(endDate),
        ),
      );

  @override
  Future<bool> update(RecurringRuleEntity rule) => _dao.saveRule(
        RecurringRulesCompanion(
          id: Value(rule.id),
          walletId: Value(rule.walletId),
          categoryId: Value(rule.categoryId),
          amount: Value(rule.amount),
          type: Value(rule.type),
          title: Value(rule.title),
          frequency: Value(rule.frequency),
          startDate: Value(rule.startDate),
          endDate: Value(rule.endDate),
          nextDueDate: Value(rule.nextDueDate),
          isPaid: Value(rule.isPaid),
          paidAt: Value(rule.paidAt),
          linkedTransactionId: Value(rule.linkedTransactionId),
          isActive: Value(rule.isActive),
          lastProcessedDate: Value(rule.lastProcessedDate),
        ),
      );

  @override
  Future<bool> delete(int id) => _dao.deleteById(id);

  @override
  Stream<List<RecurringRuleEntity>> watchUnpaid() =>
      _dao.watchUnpaid().map((list) => list.map(_toEntity).toList());

  @override
  Future<bool> markPaid(int id, DateTime paidAt, {int? transactionId}) =>
      _dao.markPaid(id, paidAt, transactionId: transactionId);

  @override
  Future<int> payBill({
    required int ruleId,
    required int walletId,
    required int categoryId,
    required int amount,
    required String type,
    required String title,
  }) async {
    // Atomic: create transaction + adjust wallet + mark rule paid
    return _db.transaction(() async {
      // Validate wallet is not archived
      final wallet = await _walletDao.getById(walletId);
      if (wallet == null) {
        throw ArgumentError('Wallet does not exist');
      }
      if (wallet.isArchived) {
        throw ArgumentError('Cannot pay bill with archived account');
      }

      final now = DateTime.now();
      final txType = type == 'income' ? 'income' : 'expense';

      final txId = await _transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          walletId: walletId,
          categoryId: categoryId,
          amount: amount,
          type: txType,
          title: title,
          transactionDate: now,
          source: const Value('recurring'),
        ),
      );

      // Adjust wallet balance
      final delta = txType == 'income' ? amount : -amount;
      await _walletDao.adjustBalance(walletId, delta);

      // Mark rule as paid with linked transaction
      await _dao.markPaid(ruleId, now, transactionId: txId);

      return txId;
    });
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static RecurringRuleEntity _toEntity(RecurringRule r) => RecurringRuleEntity(
        id: r.id,
        walletId: r.walletId,
        categoryId: r.categoryId,
        amount: r.amount,
        type: r.type,
        title: r.title,
        frequency: r.frequency,
        startDate: r.startDate,
        endDate: r.endDate,
        nextDueDate: r.nextDueDate,
        isPaid: r.isPaid,
        paidAt: r.paidAt,
        linkedTransactionId: r.linkedTransactionId,
        isActive: r.isActive,
        lastProcessedDate: r.lastProcessedDate,
      );
}
