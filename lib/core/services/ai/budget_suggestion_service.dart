import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

/// A suggestion to set a budget for a high-spending unbudgeted category.
class BudgetSuggestion {
  const BudgetSuggestion({
    required this.categoryId,
    required this.suggestedAmount,
    required this.monthlyAvg,
  });

  final int categoryId;
  final int suggestedAmount;
  final int monthlyAvg;
}

/// Suggests budgets for high-spending categories without existing budgets.
class BudgetSuggestionService {
  List<BudgetSuggestion> suggest({
    required List<BudgetEntity> budgets,
    required List<TransactionEntity> historicalTxs,
  }) {
    final budgetedCatIds = budgets.map((b) => b.categoryId).toSet();

    final totalByCategory = <int, int>{};
    final monthsByCategory = <int, Set<String>>{};
    for (final t in historicalTxs) {
      if (t.type != 'expense') continue;
      totalByCategory[t.categoryId] =
          (totalByCategory[t.categoryId] ?? 0) + t.amount;
      final monthKey =
          '${t.transactionDate.year}-${t.transactionDate.month}';
      (monthsByCategory[t.categoryId] ??= {}).add(monthKey);
    }

    final suggestions = <BudgetSuggestion>[];

    for (final entry in totalByCategory.entries) {
      final catId = entry.key;
      final total = entry.value;
      final monthCount = monthsByCategory[catId]?.length ?? 1;
      final avg = total ~/ monthCount;

      if (budgetedCatIds.contains(catId)) continue;
      if (avg < 50000) continue; // 500 EGP threshold

      final suggested = ((avg / 10000).ceil()) * 10000;

      suggestions.add(
        BudgetSuggestion(
          categoryId: catId,
          suggestedAmount: suggested,
          monthlyAvg: avg,
        ),
      );
    }

    suggestions.sort((a, b) => b.monthlyAvg.compareTo(a.monthlyAvg));
    return suggestions.take(2).toList();
  }
}
