import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_entity.dart';

/// Daily transaction summary for calendar event dots.
class DaySummary {
  const DaySummary({this.income = 0, this.expense = 0});

  /// Total income piastres for the day.
  final int income;

  /// Total expense piastres for the day.
  final int expense;

  bool get hasIncome => income > 0;
  bool get hasExpense => expense > 0;
  bool get hasBoth => hasIncome && hasExpense;
}

/// Groups a month's transactions by day → DaySummary.
/// Key is the day (DateTime with time zeroed).
final calendarDaySummaryProvider = Provider.family<
    Map<DateTime, DaySummary>,
    (int year, int month, List<TransactionEntity> transactions)>(
  (ref, params) {
    final transactions = params.$3;
    final result = <DateTime, DaySummary>{};

    for (final tx in transactions) {
      final day = DateTime(
        tx.transactionDate.year,
        tx.transactionDate.month,
        tx.transactionDate.day,
      );
      final existing = result[day] ?? const DaySummary();
      if (tx.type == 'income') {
        result[day] = DaySummary(
          income: existing.income + tx.amount,
          expense: existing.expense,
        );
      } else {
        result[day] = DaySummary(
          income: existing.income,
          expense: existing.expense + tx.amount,
        );
      }
    }

    return result;
  },
);
