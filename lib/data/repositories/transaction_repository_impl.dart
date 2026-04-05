import 'package:drift/drift.dart';

import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../database/daos/transaction_dao.dart';
import '../database/daos/wallet_dao.dart';

class TransactionRepositoryImpl implements ITransactionRepository {
  const TransactionRepositoryImpl(
    this._dao,
    this._walletDao,
    this._db,
    this._categoryDao,
  );

  final TransactionDao _dao;
  final WalletDao _walletDao;
  final AppDatabase _db;
  final CategoryDao _categoryDao;

  // ── Streams ──────────────────────────────────────────────────────────────

  @override
  Stream<List<TransactionEntity>> watchAll({
    int limit = 50,
    int offset = 0,
  }) =>
      _dao
          .watchAll(limit: limit, offset: offset)
          .map((list) => list.map(_toEntity).toList());

  @override
  Stream<List<TransactionEntity>> watchByWallet(int walletId) =>
      _dao.watchByWallet(walletId).map((list) => list.map(_toEntity).toList());

  @override
  Stream<List<TransactionEntity>> watchByMonth(int year, int month) => _dao
      .watchByMonth(year, month)
      .map((list) => list.map(_toEntity).toList());

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  Future<TransactionEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<List<TransactionEntity>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _dao.getByDateRange(start, end);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<int> sumByTypeAndMonth(
    String type,
    int year,
    int month, {
    int? walletId,
  }) =>
      _dao.sumByTypeAndMonth(type, year, month, walletId: walletId);

  @override
  Future<int> sumByCategoryAndMonth(int categoryId, int year, int month) =>
      _dao.sumByCategoryAndMonth(categoryId, year, month);

  // ── Mutations ─────────────────────────────────────────────────────────────

  @override
  Future<int> create({
    required int walletId,
    required int categoryId,
    required int amount,
    required String type,
    required String title,
    required DateTime transactionDate,
    String currencyCode = 'EGP',
    String? note,
    String tags = '',
    String source = 'manual',
    String? rawSourceText,
    bool isRecurring = false,
    int? recurringRuleId,
    int? goalId,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    // C1 fix: runtime validation (assert is stripped in release builds)
    if (amount <= 0) {
      throw ArgumentError('Transaction amount must be positive');
    }
    if (type != 'income' && type != 'expense') {
      throw ArgumentError('Transaction type must be income or expense');
    }
    return _db.transaction(() async {
      // Validation inside transaction to avoid TOCTOU race
      final cat = await _categoryDao.getById(categoryId);
      if (cat != null && cat.type != 'both' && cat.type != type) {
        throw ArgumentError(
          'Category type "${cat.type}" does not match transaction type "$type"',
        );
      }
      final wallet = await _walletDao.getById(walletId);
      if (wallet == null) {
        throw ArgumentError('Wallet with id $walletId does not exist');
      }
      if (wallet.isArchived) {
        throw ArgumentError('Cannot create transaction on archived account');
      }
      final id = await _dao.insertTransaction(
        TransactionsCompanion.insert(
          walletId: walletId,
          categoryId: categoryId,
          amount: amount,
          type: type,
          title: title,
          transactionDate: transactionDate,
          currencyCode: Value(currencyCode),
          note: Value(note),
          tags: Value(tags),
          source: Value(source),
          rawSourceText: Value(rawSourceText),
          isRecurring: Value(isRecurring),
          recurringRuleId: Value(recurringRuleId),
          goalId: Value(goalId),
          locationName: Value(locationName),
          latitude: Value(latitude),
          longitude: Value(longitude),
        ),
      );
      // Adjust wallet balance atomically
      final delta = type == 'income' ? amount : -amount;
      await _walletDao.adjustBalance(walletId, delta);
      return id;
    });
  }

  @override
  Future<bool> update(TransactionEntity transaction) async {
    // L1 fix: move read inside transaction to avoid TOCTOU race
    return _db.transaction(() async {
      final existing = await _dao.getById(transaction.id);
      if (existing == null) return false;
      // IM-24 fix: validate new wallet exists and is not archived
      if (existing.walletId != transaction.walletId) {
        final newWallet = await _walletDao.getById(transaction.walletId);
        if (newWallet == null) {
          throw ArgumentError('Target wallet does not exist');
        }
        if (newWallet.isArchived) {
          throw ArgumentError('Cannot move transaction to archived wallet');
        }
      }
      // Reverse old balance effect
      final oldDelta =
          existing.type == 'income' ? -existing.amount : existing.amount;
      await _walletDao.adjustBalance(existing.walletId, oldDelta);

      // Apply new balance effect
      final newDelta = transaction.type == 'income'
          ? transaction.amount
          : -transaction.amount;
      await _walletDao.adjustBalance(transaction.walletId, newDelta);

      // I19 fix: verify save succeeded, throw to rollback if row was deleted
      final saved = await _dao.saveTransaction(
        TransactionsCompanion(
          id: Value(transaction.id),
          walletId: Value(transaction.walletId),
          categoryId: Value(transaction.categoryId),
          amount: Value(transaction.amount),
          type: Value(transaction.type),
          currencyCode: Value(transaction.currencyCode),
          title: Value(transaction.title),
          note: Value(transaction.note),
          transactionDate: Value(transaction.transactionDate),
          receiptImagePath: Value(transaction.receiptImagePath),
          tags: Value(transaction.tags),
          latitude: Value(transaction.latitude),
          longitude: Value(transaction.longitude),
          locationName: Value(transaction.locationName),
          source: Value(transaction.source),
          rawSourceText: Value(transaction.rawSourceText),
          isRecurring: Value(transaction.isRecurring),
          recurringRuleId: Value(transaction.recurringRuleId),
          goalId: Value(transaction.goalId),
          updatedAt: Value(DateTime.now()),
        ),
      );
      if (!saved) {
        throw StateError(
          'Transaction ${transaction.id} was deleted during update',
        );
      }
      return true;
    });
  }

  @override
  Future<bool> delete(int id) async {
    // L1 fix: move read inside transaction to avoid TOCTOU race
    return _db.transaction(() async {
      final existing = await _dao.getById(id);
      if (existing == null) return false;
      // H2 fix: null out sms_parser_logs references before deleting
      await _db.customStatement(
        'UPDATE sms_parser_logs SET transaction_id = NULL '
        'WHERE transaction_id = ?',
        [id],
      );
      // Reverse the balance effect
      final reverseDelta =
          existing.type == 'income' ? -existing.amount : existing.amount;
      await _walletDao.adjustBalance(existing.walletId, reverseDelta);
      return _dao.deleteById(id);
    });
  }

  @override
  Future<bool> existsSimilar({
    required int walletId,
    required int amount,
    required String type,
    required DateTime aroundDate,
  }) =>
      _dao.existsSimilar(
        walletId: walletId,
        amount: amount,
        type: type,
        aroundDate: aroundDate,
      );

  @override
  Stream<int> watchCount() => _dao.watchCount();

  // ── Mapping ───────────────────────────────────────────────────────────────

  static TransactionEntity _toEntity(Transaction t) => TransactionEntity(
        id: t.id,
        walletId: t.walletId,
        categoryId: t.categoryId,
        amount: t.amount,
        type: t.type,
        currencyCode: t.currencyCode,
        title: t.title,
        note: t.note,
        transactionDate: t.transactionDate,
        receiptImagePath: t.receiptImagePath,
        tags: t.tags,
        latitude: t.latitude,
        longitude: t.longitude,
        locationName: t.locationName,
        source: t.source,
        rawSourceText: t.rawSourceText,
        isRecurring: t.isRecurring,
        recurringRuleId: t.recurringRuleId,
        goalId: t.goalId,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );
}
