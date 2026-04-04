import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_resolver.dart';
import '../../../../core/utils/transaction_grouper.dart';
import '../../../../domain/adapters/transfer_adapter.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/home_filter_provider.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/transaction_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import 'date_group_header.dart';

/// Lazy SliverList of transactions grouped by date with daily net subtotals.
///
/// Watches [filteredActivityProvider] for the filtered/sorted data and
/// interleaves [DateGroupHeader] rows with [TransactionCard] items in a flat
/// list fed to [SliverList.builder] (D-13, D-15, D-26).
class TransactionSliverList extends ConsumerWidget {
  const TransactionSliverList({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  /// Callback when a transaction's edit action is triggered.
  final void Function(TransactionEntity tx)? onEdit;

  /// Callback when a transaction's delete action is triggered.
  final void Function(TransactionEntity tx)? onDelete;

  /// Callback when a transaction is tapped.
  final void Function(TransactionEntity tx)? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(filteredActivityProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedWalletId = ref.watch(selectedAccountIdProvider);
    final filter = ref.watch(homeFilterProvider);

    // Build wallet lookup maps for All Accounts view + transfer resolution.
    final walletNames = <int, String>{
      for (final w in wallets) w.id: w.name,
    };
    final walletTypes = <int, String>{
      for (final w in wallets) w.id: w.type,
    };

    final showWalletName = selectedWalletId == null;

    return asyncItems.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.xl),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Center(
            child: Text(
              e.toString(),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.error,
              ),
            ),
          ),
        ),
      ),
      data: (transactions) {
        // ── Empty state (D-26) ────────────────────────────────────────
        if (transactions.isEmpty) {
          final hasFilters = filter.typeFilter != TransactionTypeFilter.all ||
              filter.searchQuery.isNotEmpty ||
              selectedWalletId != null;

          return SliverToBoxAdapter(
            child: hasFilters
                ? EmptyState(
                    compact: true,
                    title: context.l10n.home_no_matching_transactions,
                    subtitle: context.l10n.home_clear_filters,
                  )
                : EmptyState(
                    compact: true,
                    title: context.l10n.dashboard_welcome_empty,
                    subtitle: context.l10n.dashboard_welcome_empty_sub,
                  ),
          );
        }

        // ── Build flat list of date headers + transaction items ───────
        final grouped = groupTransactionsByDate(context, transactions);
        final flatItems = <_ListItem>[];

        for (final entry in grouped.entries) {
          // Compute daily net: income - expenses. Transfers are net zero.
          final dailyNet = entry.value.fold<int>(0, (sum, tx) {
            if (tx.type == 'income') return sum + tx.amount;
            if (tx.type == 'expense') return sum - tx.amount;
            return sum;
          });

          flatItems.add(_ListItem.header(entry.key, dailyNet));
          for (final tx in entry.value) {
            flatItems.add(_ListItem.transaction(tx));
          }
        }

        return SliverList.builder(
          itemCount: flatItems.length,
          itemBuilder: (context, index) {
            final item = flatItems[index];

            if (item.isHeader) {
              return DateGroupHeader(
                dateLabel: item.dateLabel!,
                dailyNet: item.dailyNet!,
              );
            }

            final tx = item.tx!;
            final resolved = resolveCategory(
              categoryId: tx.categoryId,
              categories: categories,
              fallbackColor: context.colors.outline,
              languageCode: context.languageCode,
            );

            // Resolve counterpart info for transfer entries (port from
            // transaction_list_section.dart — transfers have categoryId 0
            // which resolves to "?" without this intercept).
            IconData? transferCounterpartIcon;
            String? transferDisplayName;
            if (tx.type == 'transfer') {
              final cpId = counterpartWalletId(tx.tags);
              if (cpId != null) {
                final cpName = walletNames[cpId];
                if (cpName != null) {
                  transferCounterpartIcon =
                      AppIcons.walletType(walletTypes[cpId] ?? 'bank');
                  final isSender = isTransferSender(tx.tags);
                  transferDisplayName = isSender
                      ? '${context.l10n.common_transfer} → $cpName'
                      : '${context.l10n.common_transfer} ← $cpName';
                }
              }
            }

            final isTransfer = tx.id < 0;
            return TransactionCard(
              transaction: tx,
              categoryIcon: resolved.icon,
              categoryColor: resolved.color,
              categoryName: transferDisplayName ?? resolved.name,
              transferCounterpartIcon: transferCounterpartIcon,
              walletName: showWalletName ? walletNames[tx.walletId] : null,
              onTap: onTap != null ? () => onTap!(tx) : null,
              onEdit: !isTransfer && onEdit != null ? () => onEdit!(tx) : null,
              onDelete: onDelete != null ? () => onDelete!(tx) : null,
            );
          },
        );
      },
    );
  }
}

// ── Internal item model for the flat list ────────────────────────────────────

class _ListItem {
  const _ListItem._({this.dateLabel, this.dailyNet, this.tx});

  factory _ListItem.header(String dateLabel, int dailyNet) =>
      _ListItem._(dateLabel: dateLabel, dailyNet: dailyNet);

  factory _ListItem.transaction(TransactionEntity tx) => _ListItem._(tx: tx);

  final String? dateLabel;
  final int? dailyNet;
  final TransactionEntity? tx;

  bool get isHeader => dateLabel != null;
}
