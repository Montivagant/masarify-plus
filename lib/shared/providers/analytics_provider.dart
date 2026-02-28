import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_entity.dart';
import 'category_provider.dart';
import 'repository_providers.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';

// ── Monthly income/expense pair ──────────────────────────────────────────

class MonthlyTotal {
  const MonthlyTotal({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  final int year;
  final int month;
  final int income;
  final int expense;

  int get net => income - expense;
}

// ── Category spending aggregate ──────────────────────────────────────────

class CategorySpending {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.iconName,
    required this.amount,
    required this.fraction,
  });

  final int categoryId;
  final String categoryName;
  final String colorHex;
  final String iconName;
  final int amount;
  final double fraction;
}

// ── Daily spending for trend charts ──────────────────────────────────────

class DailySpending {
  const DailySpending({required this.date, required this.amount});

  final DateTime date;
  final int amount;
}

// ── Last N months income vs expense ──────────────────────────────────────

/// Returns [MonthlyTotal] for the last [count] months (most recent last).
final monthlyTotalsProvider =
    FutureProvider.family<List<MonthlyTotal>, int>((ref, count) async {
  final now = DateTime.now();
  final repo = ref.watch(transactionRepositoryProvider);
  // IM-13 fix: watch reactive stream so totals auto-refresh on tx changes
  ref.watch(transactionsByMonthProvider((now.year, now.month)));
  final results = <MonthlyTotal>[];

  for (var i = count - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final y = d.year;
    final m = d.month;
    final income = await repo.sumByTypeAndMonth('income', y, m);
    final expense = await repo.sumByTypeAndMonth('expense', y, m);
    results.add(MonthlyTotal(year: y, month: m, income: income, expense: expense));
  }

  return results;
});

// ── Category breakdown for a given month ─────────────────────────────────

/// Expense categories ranked by amount for a (year, month).
final categoryBreakdownProvider = Provider.family<
    List<CategorySpending>,
    (int year, int month, List<TransactionEntity> transactions)>(
  (ref, params) {
    final transactions = params.$3;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final lang = ref.watch(localeProvider)?.languageCode ?? 'ar';

    final expenses = transactions.where((tx) => tx.type == 'expense');
    final byCategory = <int, int>{};
    for (final tx in expenses) {
      byCategory[tx.categoryId] =
          (byCategory[tx.categoryId] ?? 0) + tx.amount;
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = sorted.fold<int>(0, (s, e) => s + e.value);
    if (total == 0) return [];

    return sorted.map((entry) {
      final cat = categories.where((c) => c.id == entry.key).firstOrNull;
      return CategorySpending(
        categoryId: entry.key,
        categoryName: cat?.displayName(lang) ?? '?',
        colorHex: cat?.colorHex ?? '#9E9E9E',
        iconName: cat?.iconName ?? 'category',
        amount: entry.value,
        fraction: entry.value / total,
      );
    }).toList();
  },
);

// ── Daily spending for trend line ────────────────────────────────────────

/// Daily expense totals for the last [days] days.
final dailySpendingProvider =
    FutureProvider.family<List<DailySpending>, int>((ref, days) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day - days + 1);
  final end = DateTime(now.year, now.month, now.day + 1); // midnight tomorrow (exclusive)

  final repo = ref.watch(transactionRepositoryProvider);
  final txns = await repo.getByDateRange(start, end);

  final dailyMap = <DateTime, int>{};
  for (var i = 0; i < days; i++) {
    final d = DateTime(start.year, start.month, start.day + i);
    dailyMap[d] = 0;
  }

  for (final tx in txns) {
    if (tx.type == 'expense') {
      final key = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
      dailyMap[key] = (dailyMap[key] ?? 0) + tx.amount;
    }
  }

  return dailyMap.entries
      .map((e) => DailySpending(date: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});

// ── Comparison: this month vs last month ─────────────────────────────────

class MonthComparison {
  const MonthComparison({
    required this.thisMonth,
    required this.lastMonth,
  });

  final MonthlyTotal thisMonth;
  final MonthlyTotal lastMonth;
}

final monthComparisonProvider = FutureProvider<MonthComparison>((ref) async {
  final now = DateTime.now();
  final lastMonthDate = DateTime(now.year, now.month - 1);
  // CR-3 fix: capture all watched values before any await
  final repo = ref.watch(transactionRepositoryProvider);
  // IM-14 fix: watch reactive stream to auto-refresh on tx changes
  ref.watch(transactionsByMonthProvider((now.year, now.month)));

  final [thisIncome, thisExpense, lastIncome, lastExpense] = await Future.wait([
    repo.sumByTypeAndMonth('income', now.year, now.month),
    repo.sumByTypeAndMonth('expense', now.year, now.month),
    repo.sumByTypeAndMonth('income', lastMonthDate.year, lastMonthDate.month),
    repo.sumByTypeAndMonth('expense', lastMonthDate.year, lastMonthDate.month),
  ]);

  return MonthComparison(
    thisMonth: MonthlyTotal(
      year: now.year,
      month: now.month,
      income: thisIncome,
      expense: thisExpense,
    ),
    lastMonth: MonthlyTotal(
      year: lastMonthDate.year,
      month: lastMonthDate.month,
      income: lastIncome,
      expense: lastExpense,
    ),
  );
});
