import 'dart:math' as math;

import '../../../domain/entities/transaction_entity.dart';

/// A detected recurring spending pattern.
class DetectedPattern {
  const DetectedPattern({
    required this.categoryId,
    required this.amount,
    required this.title,
    required this.frequency,
    required this.confidence,
    required this.nextExpectedDate,
  });

  final int categoryId;
  final int amount;
  final String title;
  final String frequency; // 'weekly' or 'monthly'
  final double confidence; // 0.0 – 1.0
  final DateTime nextExpectedDate;
}

/// Detects repeated transactions that look like recurring expenses.
class RecurringPatternDetector {
  List<DetectedPattern> detect(List<TransactionEntity> transactions) {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final candidates = transactions.where((t) {
      return t.type == 'expense' &&
          !t.isRecurring &&
          t.transactionDate.isAfter(cutoff);
    }).toList();

    // Group by (categoryId, amount).
    final groups = <String, List<TransactionEntity>>{};
    for (final tx in candidates) {
      final key = '${tx.categoryId}|${tx.amount}';
      (groups[key] ??= []).add(tx);
    }

    final patterns = <DetectedPattern>[];

    for (final entry in groups.entries) {
      final txs = entry.value;
      if (txs.length < 3) continue;

      txs.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

      final intervals = <int>[];
      for (var i = 1; i < txs.length; i++) {
        intervals.add(
          txs[i].transactionDate.difference(txs[i - 1].transactionDate).inDays,
        );
      }

      final avgInterval =
          intervals.reduce((a, b) => a + b) / intervals.length;
      final variance = intervals
              .map((i) => (i - avgInterval).abs())
              .reduce((a, b) => a + b) /
          intervals.length;

      String? frequency;
      if (avgInterval >= 25 && avgInterval <= 34) {
        frequency = 'monthly';
      } else if (avgInterval >= 6 && avgInterval <= 8) {
        frequency = 'weekly';
      }

      if (frequency == null) continue;

      double confidence;
      if (txs.length >= 5) {
        confidence = 0.95;
      } else if (txs.length >= 4) {
        confidence = 0.85;
      } else {
        confidence = 0.7;
      }
      if (variance > 2) confidence -= 0.1;
      confidence = math.max(0.0, confidence);

      if (confidence < 0.7) continue;

      final titleCounts = <String, int>{};
      for (final tx in txs) {
        titleCounts[tx.title] = (titleCounts[tx.title] ?? 0) + 1;
      }
      final bestTitle = titleCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final lastDate = txs.last.transactionDate;
      final nextDate = frequency == 'monthly'
          ? DateTime(lastDate.year, lastDate.month + 1, lastDate.day)
          : lastDate.add(const Duration(days: 7));

      patterns.add(
        DetectedPattern(
          categoryId: txs.first.categoryId,
          amount: txs.first.amount,
          title: bestTitle,
          frequency: frequency,
          confidence: confidence,
          nextExpectedDate: nextDate,
        ),
      );
    }

    patterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    return patterns;
  }
}
