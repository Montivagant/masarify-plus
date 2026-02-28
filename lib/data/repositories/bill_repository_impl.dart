import 'package:drift/drift.dart';

import '../../domain/entities/bill_entity.dart';
import '../../domain/repositories/i_bill_repository.dart';
import '../database/app_database.dart';
import '../database/daos/bill_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../database/daos/wallet_dao.dart';

class BillRepositoryImpl implements IBillRepository {
  const BillRepositoryImpl(this._dao, this._txDao, this._walletDao, this._db);

  final BillDao _dao;
  final TransactionDao _txDao;
  final WalletDao _walletDao;
  final AppDatabase _db;

  @override
  Stream<List<BillEntity>> watchAll() =>
      _dao.watchAll().map((list) => list.map(_toEntity).toList());

  @override
  Stream<List<BillEntity>> watchUnpaid() =>
      _dao.watchUnpaid().map((list) => list.map(_toEntity).toList());

  @override
  Future<List<BillEntity>> getDue(DateTime asOf) async {
    final rows = await _dao.getDue(asOf);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<BillEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<int> create({
    required String name,
    required int amount,
    required int walletId,
    required int categoryId,
    required DateTime dueDate,
  }) {
    // R5-I2 fix: validate amount at repo level
    if (amount <= 0) throw ArgumentError('Bill amount must be positive');
    return _dao.insertBill(
        BillsCompanion.insert(
          name: name,
          amount: amount,
          walletId: walletId,
          categoryId: categoryId,
          dueDate: dueDate,
        ),
      );
  }

  @override
  Future<bool> update(BillEntity bill) => _dao.saveBill(
        BillsCompanion(
          id: Value(bill.id),
          name: Value(bill.name),
          amount: Value(bill.amount),
          walletId: Value(bill.walletId),
          categoryId: Value(bill.categoryId),
          dueDate: Value(bill.dueDate),
          isPaid: Value(bill.isPaid),
          paidAt: Value(bill.paidAt),
          linkedTransactionId: Value(bill.linkedTransactionId),
        ),
      );

  @override
  @Deprecated('Use markPaidAtomic() instead — this bypasses balance adjustment')
  Future<bool> markPaid(int id, DateTime paidAt) =>
      throw UnsupportedError('Use markPaidAtomic() to ensure wallet balance is adjusted');

  /// H2 fix: atomically create expense transaction + mark bill paid + link them.
  @override
  Future<int> markPaidAtomic({
    required int billId,
    required int walletId,
    required int categoryId,
    required int amount,
    required String title,
  }) async {
    if (amount <= 0) throw ArgumentError('Bill amount must be positive');
    return _db.transaction(() async {
      // Validate bill exists and is not already paid
      final bill = await _dao.getById(billId);
      if (bill == null) throw StateError('Bill $billId not found');
      if (bill.isPaid) throw StateError('Bill $billId is already paid');

      // Validate wallet exists and is not archived
      final wallet = await _walletDao.getById(walletId);
      if (wallet == null) {
        throw ArgumentError('Wallet $walletId does not exist');
      }
      if (wallet.isArchived) {
        throw ArgumentError('Cannot pay bill from archived wallet');
      }

      final now = DateTime.now();

      // 1. Create expense transaction
      final txId = await _txDao.insertTransaction(
        TransactionsCompanion.insert(
          walletId: walletId,
          categoryId: categoryId,
          amount: amount,
          type: 'expense',
          title: title,
          transactionDate: now,
        ),
      );

      // 2. Adjust wallet balance
      await _walletDao.adjustBalance(walletId, -amount);

      // 3. Mark bill as paid + link transaction
      final saved = await _dao.saveBill(
        BillsCompanion(
          id: Value(billId),
          isPaid: const Value(true),
          paidAt: Value(now),
          linkedTransactionId: Value(txId),
        ),
      );
      if (!saved) throw StateError('Failed to update bill $billId');

      return txId;
    });
  }

  @override
  Future<bool> delete(int id) async {
    return _db.transaction(() async {
      final bill = await _dao.getById(id);
      if (bill == null) return false;
      // If the bill was paid and linked to a transaction, reverse the effect
      if (bill.isPaid && bill.linkedTransactionId != null) {
        final tx = await _txDao.getById(bill.linkedTransactionId!);
        if (tx != null) {
          // Reverse wallet balance (expense was negative, so add back)
          await _walletDao.adjustBalance(tx.walletId, tx.amount);
          await _txDao.deleteById(tx.id);
        }
      }
      return _dao.deleteById(id);
    });
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static BillEntity _toEntity(Bill b) => BillEntity(
        id: b.id,
        name: b.name,
        amount: b.amount,
        walletId: b.walletId,
        categoryId: b.categoryId,
        dueDate: b.dueDate,
        isPaid: b.isPaid,
        paidAt: b.paidAt,
        linkedTransactionId: b.linkedTransactionId,
      );
}
