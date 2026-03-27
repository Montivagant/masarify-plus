import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/category_entity.dart';

/// A category where the user saved money last month.
class BudgetSaving {
  const BudgetSaving({
    required this.categoryName,
    required this.categoryNameAr,
    required this.limitAmount,
    required this.spentAmount,
    required this.savedAmount,
    required this.month,
    required this.year,
  });

  final String categoryName;
  final String categoryNameAr;

  /// Budget cap in piastres.
  final int limitAmount;

  /// Actual spending in piastres.
  final int spentAmount;

  /// Amount saved: limitAmount - spentAmount (piastres).
  final int savedAmount;

  final int month;
  final int year;

  String displayName(String locale) =>
      locale.startsWith('ar') ? categoryNameAr : categoryName;
}

/// Computes which budgets came in under limit last month.
class BudgetSavingsService {
  const BudgetSavingsService();

  /// Returns categories where user came under budget last month.
  /// Sorted by [savedAmount] descending (biggest savings first).
  List<BudgetSaving> computeLastMonthSavings(
    List<BudgetEntity> lastMonthBudgets,
    Map<int, CategoryEntity> categoryMap,
  ) {
    return lastMonthBudgets
        .where(
          (b) =>
              b.limitAmount > 0 &&
              b.spentAmount > 0 &&
              b.spentAmount < b.limitAmount,
        )
        .map((b) {
          final cat = categoryMap[b.categoryId];
          if (cat == null) return null;
          return BudgetSaving(
            categoryName: cat.name,
            categoryNameAr: cat.nameAr,
            limitAmount: b.limitAmount,
            spentAmount: b.spentAmount,
            savedAmount: b.limitAmount - b.spentAmount,
            month: b.month,
            year: b.year,
          );
        })
        .whereType<BudgetSaving>()
        .toList()
      ..sort((a, b) => b.savedAmount.compareTo(a.savedAmount));
  }
}
