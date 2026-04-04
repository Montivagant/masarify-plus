import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_entity.dart';
import 'activity_provider.dart';
import 'category_provider.dart';
import 'selected_account_provider.dart';

// ── Enums ─────────────────────────────────────────────────────────────────

/// Transaction type filter for home screen.
enum TransactionTypeFilter { all, expenses, income, transfers }

/// Sort order for the home transaction list.
enum SortOrder { dateDesc, dateAsc, amountDesc, amountAsc }

// ── Model ─────────────────────────────────────────────────────────────────

/// Immutable filter state for the home screen transaction list.
class HomeFilter {
  const HomeFilter({
    this.typeFilter = TransactionTypeFilter.all,
    this.categoryId,
    this.searchQuery = '',
    this.sortOrder = SortOrder.dateDesc,
    this.isSearchActive = false,
  });

  final TransactionTypeFilter typeFilter;

  /// When non-null, filters transactions to this category only.
  final int? categoryId;
  final String searchQuery;
  final SortOrder sortOrder;
  final bool isSearchActive;

  HomeFilter copyWith({
    TransactionTypeFilter? typeFilter,
    int? categoryId,
    bool clearCategory = false,
    String? searchQuery,
    SortOrder? sortOrder,
    bool? isSearchActive,
  }) =>
      HomeFilter(
        typeFilter: typeFilter ?? this.typeFilter,
        categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
        searchQuery: searchQuery ?? this.searchQuery,
        sortOrder: sortOrder ?? this.sortOrder,
        isSearchActive: isSearchActive ?? this.isSearchActive,
      );
}

// ── Providers ─────────────────────────────────────────────────────────────

/// Home screen filter/search/sort state.
final homeFilterProvider =
    StateProvider<HomeFilter>((ref) => const HomeFilter());

/// Filtered + sorted activity for the home screen transaction list.
///
/// Reads [selectedAccountIdProvider] to pick per-wallet or all-wallet data,
/// then applies [homeFilterProvider] for type/search/sort.
///
/// Transfer entries created by TransferAdapter have synthetic negative IDs.
final filteredActivityProvider =
    Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final filter = ref.watch(homeFilterProvider);
  final walletId = ref.watch(selectedAccountIdProvider);

  // Choose base stream: unified activity (transactions + transfers merged).
  final baseActivity = walletId != null
      ? ref.watch(activityByWalletProvider(walletId))
      : ref.watch(recentActivityProvider);

  return baseActivity.whenData((items) {
    var result = List<TransactionEntity>.of(items);

    // ── Type filter ───────────────────────────────────────────────────
    if (filter.typeFilter != TransactionTypeFilter.all) {
      result = result.where((tx) {
        switch (filter.typeFilter) {
          case TransactionTypeFilter.expenses:
            return tx.type == 'expense';
          case TransactionTypeFilter.income:
            return tx.type == 'income';
          case TransactionTypeFilter.transfers:
            // TransferAdapter uses negative synthetic IDs for transfers.
            return tx.id < 0;
          case TransactionTypeFilter.all:
            return true;
        }
      }).toList();
    }

    // ── Category filter ───────────────────────────────────────────────
    if (filter.categoryId != null) {
      result =
          result.where((tx) => tx.categoryId == filter.categoryId).toList();
    }

    // ── Search filter ─────────────────────────────────────────────────
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];

      result = result.where((tx) {
        if (tx.title.toLowerCase().contains(q)) return true;
        if (tx.note?.toLowerCase().contains(q) ?? false) return true;

        // Match on resolved category name.
        final cat = categories.where((c) => c.id == tx.categoryId).firstOrNull;
        if (cat != null && cat.name.toLowerCase().contains(q)) return true;
        if (cat != null && cat.nameAr.toLowerCase().contains(q)) return true;

        return false;
      }).toList();
    }

    // ── Sort ──────────────────────────────────────────────────────────
    switch (filter.sortOrder) {
      case SortOrder.dateDesc:
        result.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      case SortOrder.dateAsc:
        result.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      case SortOrder.amountDesc:
        result.sort((a, b) => b.amount.compareTo(a.amount));
      case SortOrder.amountAsc:
        result.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return result;
  });
});
