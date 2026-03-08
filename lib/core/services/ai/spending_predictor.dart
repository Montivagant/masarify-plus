import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

/// A prediction that a budgeted category will exceed its limit.
class SpendingPrediction {
  const SpendingPrediction({
    required this.categoryId,
    required this.predictedAmount,
    required this.budgetLimit,
    required this.overByAmount,
  });

  final int categoryId;
  final int predictedAmount;
  final int budgetLimit;
  final int overByAmount;
}

/// Predicts end-of-month spending per budgeted category.
class SpendingPredictor {
  List<SpendingPrediction> predict({
    required List<TransactionEntity> currentMonthTxs,
    required List<TransactionEntity> historicalTxs,
    required List<BudgetEntity> budgets,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final dayOfMonth = today.day;
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    if (dayOfMonth < 3) return [];

    final predictions = <SpendingPrediction>[];

    for (final budget in budgets) {
      final catId = budget.categoryId;
      final limit = budget.effectiveLimit;
      if (limit <= 0) continue;

      final currentSpent = currentMonthTxs
          .where((t) => t.categoryId == catId && t.type == 'expense')
          .fold<int>(0, (s, t) => s + t.amount);

      final paceProjection =
          (currentSpent / dayOfMonth * daysInMonth).round();

      final historicalByMonth = <String, int>{};
      for (final t in historicalTxs) {
        if (t.categoryId != catId || t.type != 'expense') continue;
        final key = '${t.transactionDate.year}-${t.transactionDate.month}';
        historicalByMonth[key] = (historicalByMonth[key] ?? 0) + t.amount;
      }

      final historicalAvg = historicalByMonth.isNotEmpty
          ? historicalByMonth.values.reduce((a, b) => a + b) ~/
              historicalByMonth.length
          : 0;

      final predicted = historicalAvg > 0
          ? (0.6 * paceProjection + 0.4 * historicalAvg).round()
          : paceProjection;

      final threshold = (limit * 1.1).round();
      if (predicted > threshold) {
        predictions.add(
          SpendingPrediction(
            categoryId: catId,
            predictedAmount: predicted,
            budgetLimit: limit,
            overByAmount: predicted - limit,
          ),
        );
      }
    }

    predictions.sort((a, b) => b.overByAmount.compareTo(a.overByAmount));
    return predictions;
  }
}
