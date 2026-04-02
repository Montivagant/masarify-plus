import '../entities/transaction_entity.dart';

abstract interface class ITransactionRepository {
  /// Paginated reactive stream — most recent first.
  Stream<List<TransactionEntity>> watchAll({int limit = 50, int offset = 0});

  Stream<List<TransactionEntity>> watchByWallet(int walletId);

  Stream<List<TransactionEntity>> watchByMonth(int year, int month);

  Future<TransactionEntity?> getById(int id);

  Future<List<TransactionEntity>> getByCategory(
    int categoryId, {
    int limit = 50,
  });

  Future<List<TransactionEntity>> getByDateRange(DateTime start, DateTime end);

  /// Returns total income/expense piastres for a month.
  /// Optionally filter by [walletId].
  Future<int> sumByTypeAndMonth(String type, int year, int month,
      {int? walletId,});

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

  /// Creates multiple transactions atomically in a single DB transaction.
  /// All succeed or none are written.
  Future<List<int>> createBatch(List<CreateTransactionParams> params);
}

/// Parameters for batch transaction creation.
class CreateTransactionParams {
  const CreateTransactionParams({
    required this.walletId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.title,
    required this.transactionDate,
    this.source = 'manual',
    this.rawSourceText,
    this.note,
    this.goalId,
  });

  final int walletId;
  final int categoryId;
  final int amount;
  final String type;
  final String title;
  final DateTime transactionDate;
  final String source;
  final String? rawSourceText;
  final String? note;
  final int? goalId;
}
