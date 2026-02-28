import '../entities/transaction_entity.dart';

abstract interface class ITransactionRepository {
  /// Paginated reactive stream — most recent first.
  Stream<List<TransactionEntity>> watchAll({int limit = 50, int offset = 0});

  Stream<List<TransactionEntity>> watchByWallet(int walletId);

  Stream<List<TransactionEntity>> watchByMonth(int year, int month);

  Future<TransactionEntity?> getById(int id);

  Future<List<TransactionEntity>> getByCategory(int categoryId, {int limit = 50});

  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end);

  /// Returns total income/expense piastres for a month.
  Future<int> sumByTypeAndMonth(String type, int year, int month);

  Future<int> sumByCategoryAndMonth(int categoryId, int year, int month);

  /// Creates the transaction AND adjusts the wallet balance atomically.
  /// Returns the new transaction's id.
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
  });

  /// Updates the transaction AND reconciles wallet balance difference atomically.
  Future<bool> update(TransactionEntity transaction);

  /// Deletes the transaction AND reverses its wallet balance effect atomically.
  Future<bool> delete(int id);

  /// H12 fix: restores a previously deleted transaction with its original ID.
  /// Used by undo-delete to preserve ID references (budgets, goals).
  Future<void> restore(TransactionEntity transaction);
}
