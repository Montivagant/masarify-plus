import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_durations.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/services/category_frequency_service.dart';
import '../../core/services/preferences_service.dart';
import 'category_provider.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';

/// Synchronous provider — available immediately (SharedPreferences is
/// preloaded in main and injected via [sharedPreferencesProvider]).
final categoryFrequencyServiceProvider = Provider<CategoryFrequencyService>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return CategoryFrequencyService(PreferencesService(prefs));
  },
);

/// A frequent transaction pattern detected from history.
class FrequentTransaction {
  const FrequentTransaction({
    required this.categoryId,
    required this.amount,
    required this.title,
    required this.type,
    required this.count,
    required this.categoryIconName,
    required this.categoryColorHex,
  });

  final int categoryId;
  final int amount;
  final String title;
  final String type;
  final int count;
  final String categoryIconName;
  final String categoryColorHex;
}

/// Top 3 most frequent transaction patterns from the last 90 days
/// (minimum 3 occurrences each).
final frequentTransactionsProvider = Provider<List<FrequentTransaction>>((ref) {
  final txsAsync = ref.watch(recentTransactionsProvider);
  final catsAsync = ref.watch(categoriesProvider);

  final txs = txsAsync.valueOrNull;
  final cats = catsAsync.valueOrNull;
  if (txs == null || cats == null) return [];

  final catMap = {for (final c in cats) c.id: c};
  final cutoff = DateTime.now().subtract(AppDurations.quickAddLookback);

  // Group by (categoryId, amount, title).
  final counts = <String, _FreqGroup>{};
  for (final tx in txs) {
    if (tx.transactionDate.isBefore(cutoff)) continue;
    if (tx.type != 'expense' && tx.type != 'income') continue;

    final key = '${tx.categoryId}|${tx.amount}|${tx.title}';
    final existing = counts[key];
    if (existing != null) {
      existing.count++;
    } else {
      counts[key] = _FreqGroup(
        categoryId: tx.categoryId,
        amount: tx.amount,
        title: tx.title,
        type: tx.type,
        count: 1,
      );
    }
  }

  // Filter by min occurrences, sort desc, take top N.
  final qualified = counts.values
      .where((g) => g.count >= AppSizes.quickAddMinOccurrences)
      .toList()
    ..sort((a, b) => b.count.compareTo(a.count));

  return qualified.take(AppSizes.quickAddMaxItems).map((g) {
    final cat = catMap[g.categoryId];
    return FrequentTransaction(
      categoryId: g.categoryId,
      amount: g.amount,
      title: g.title,
      type: g.type,
      count: g.count,
      categoryIconName: cat?.iconName ?? 'question',
      categoryColorHex: cat?.colorHex ?? '#888888',
    );
  }).toList();
});

class _FreqGroup {
  _FreqGroup({
    required this.categoryId,
    required this.amount,
    required this.title,
    required this.type,
    required this.count,
  });

  final int categoryId;
  final int amount;
  final String title;
  final String type;
  int count;
}
