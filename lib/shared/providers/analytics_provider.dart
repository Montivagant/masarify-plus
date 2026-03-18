import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // Watch all recent transactions so past-month edits also trigger refresh
  ref.watch(recentTransactionsProvider);
  final results = <MonthlyTotal>[];

  for (var i = count - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final y = d.year;
    final m = d.month;
    final [income, expense] = await Future.wait([
      repo.sumByTypeAndMonth('income', y, m),
      repo.sumByTypeAndMonth('expense', y, m),
    ]);
    results
        .add(MonthlyTotal(year: y, month: m, income: income, expense: expense));
  }

  return results;
});

// ── Category breakdown for a given month ─────────────────────────────────

/// Expense categories ranked by amount for a (year, month).
/// Watches the transactions stream internally so the family key is stable.
final categoryBreakdownProvider =
    Provider.family<AsyncValue<List<CategorySpending>>, (int year, int month)>(
  (ref, params) {
    final txAsync = ref.watch(transactionsByMonthProvider(params));
    // Watch these unconditionally so changes always retrigger this provider,
    // even when txAsync is briefly in loading state.
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final lang = ref.watch(localeProvider)?.languageCode ?? 'en';
    return txAsync.whenData((transactions) {
      final expenses = transactions.where((tx) => tx.type == 'expense');
      final byCategory = <int, int>{};
      for (final tx in expenses) {
        byCategory[tx.categoryId] =
            (byCategory[tx.categoryId] ?? 0) + tx.amount;
      }

      final sorted = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final total = sorted.fold<int>(0, (s, e) => s + e.value);
      if (total == 0) return <CategorySpending>[];

      final categoryMap = {for (final c in categories) c.id: c};

      return sorted.map((entry) {
        final cat = categoryMap[entry.key];
        return CategorySpending(
          categoryId: entry.key,
          categoryName: cat?.displayName(lang) ?? '?',
          colorHex: cat?.colorHex ?? '#9E9E9E',
          iconName: cat?.iconName ?? 'category',
          amount: entry.value,
          fraction: entry.value / total,
        );
      }).toList();
    });
  },
);

// ── Daily spending for trend line ────────────────────────────────────────

/// Daily expense totals for the last [days] days.
final dailySpendingProvider =
    FutureProvider.family<List<DailySpending>, int>((ref, days) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day - days + 1);
  // midnight tomorrow (exclusive)
  final end = DateTime(now.year, now.month, now.day + 1);

  final repo = ref.watch(transactionRepositoryProvider);
  // Watch all recent transactions so backdated edits also trigger refresh
  ref.watch(recentTransactionsProvider);
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
