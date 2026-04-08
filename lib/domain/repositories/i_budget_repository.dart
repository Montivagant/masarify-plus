import '../entities/budget_entity.dart';

abstract interface class IBudgetRepository {
  /// Returns a single budget by id, enriched with [spentAmount].
  Future<BudgetEntity?> getById(int id);

  /// Reactive stream of budgets for a month, enriched with [spentAmount].
  Stream<List<BudgetEntity>> watchByMonth(int year, int month);

  Future<List<BudgetEntity>> getByMonth(int year, int month);

  Future<BudgetEntity?> getByCategoryAndMonth(
    int categoryId,
    int year,
    int month,
  );

  /// Returns the new budget's id.
  Future<int> create({
    required int categoryId,
    required int month,
    required int year,
    required int limitAmount,
    bool rollover = false,
    int rolloverAmount = 0,
    String period = 'monthly',
  });

  Future<bool> update(BudgetEntity budget);

  Future<bool> delete(int id);
}
