import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/budgets_table.dart';

part 'budget_dao.g.dart';

@DriftAccessor(tables: [Budgets])
class BudgetDao extends DatabaseAccessor<AppDatabase> with _$BudgetDaoMixin {
  BudgetDao(super.db);

  Future<Budget?> getById(int id) =>
      (select(budgets)..where((b) => b.id.equals(id))).getSingleOrNull();

  Stream<List<Budget>> watchByMonth(int year, int month) => (select(budgets)
        ..where((b) => b.year.equals(year) & b.month.equals(month)))
      .watch();

  Future<List<Budget>> getByMonth(int year, int month) => (select(budgets)
        ..where((b) => b.year.equals(year) & b.month.equals(month)))
      .get();

  Future<Budget?> getByCategoryAndMonth(
    int categoryId,
    int year,
    int month, {
    String period = 'monthly',
  }) =>
      (select(budgets)
            ..where(
              (b) =>
                  b.categoryId.equals(categoryId) &
                  b.year.equals(year) &
                  b.month.equals(month) &
                  b.period.equals(period),
            ))
          .getSingleOrNull();

  Future<int> insertBudget(BudgetsCompanion entry) =>
      into(budgets).insert(entry);

  Future<bool> saveBudget(BudgetsCompanion entry) =>
      (update(budgets)..where((b) => b.id.equals(entry.id.value)))
          .write(entry)
          .then((count) => count > 0);

  Future<bool> deleteById(int id) =>
      (delete(budgets)..where((b) => b.id.equals(id)))
          .go()
          .then((count) => count > 0);
}
