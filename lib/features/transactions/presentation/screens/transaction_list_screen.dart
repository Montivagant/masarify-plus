import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/app_search_bar.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/lists/transaction_list_section.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Full paginated transaction list with search and type filter.
///
/// Grouped by date using date labels (اليوم / أمس / dd/mm/yyyy).
/// Filtering is client-side from the Drift reactive stream.
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() =>
      _TransactionListScreenState();
}

class _TransactionListScreenState
    extends ConsumerState<TransactionListScreen> {
  String _searchQuery = '';
  String _filterType = 'all'; // 'all' | 'expense' | 'income'

  // ── Filter bottom sheet ────────────────────────────────────────────────

  void _showFilter() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md,
                AppSizes.md,
                AppSizes.md,
                AppSizes.sm,
              ),
              child: Text(
                context.l10n.transaction_filter_type_title,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            _FilterTile(
              label: context.l10n.transaction_filter_all,
              icon: AppIcons.transactions,
              selected: _filterType == 'all',
              onTap: () {
                setState(() => _filterType = 'all');
                Navigator.pop(ctx);
              },
            ),
            _FilterTile(
              label: context.l10n.transaction_filter_expenses,
              icon: AppIcons.expense,
              selected: _filterType == 'expense',
              onTap: () {
                setState(() => _filterType = 'expense');
                Navigator.pop(ctx);
              },
            ),
            _FilterTile(
              label: context.l10n.transaction_filter_income,
              icon: AppIcons.income,
              selected: _filterType == 'income',
              onTap: () {
                setState(() => _filterType = 'income');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  // ── Delete with undo ──────────────────────────────────────────────────

  Future<void> _deleteTransaction(TransactionEntity tx) async {
    // L6 fix: confirm before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.transaction_delete_title),
        content: Text(context.l10n.transaction_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.l10n.common_delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final repo = ref.read(transactionRepositoryProvider);
    final deleted = await repo.delete(tx.id);
    if (!deleted || !mounted) return;

    SnackHelper.showSuccess(
      context,
      context.l10n.transaction_deleted_message(tx.title),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: context.l10n.transaction_undo,
        textColor: Theme.of(context).colorScheme.onPrimary,
        onPressed: () async {
          // H12 fix: restore with original ID so budget/goal references
          // aren't orphaned (previously created a new ID via repo.create)
          await repo.restore(tx);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final allTxs = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoriesProvider);

    ({IconData icon, Color color, String name}) resolveCategory(int catId) {
      final catList = categories.valueOrNull ?? [];
      final cat = catList.where((c) => c.id == catId).firstOrNull;
      if (cat == null) {
        return (icon: AppIcons.category, color: Theme.of(context).colorScheme.outline, name: '?');
      }
      return (
        icon: CategoryIconMapper.fromName(cat.iconName),
        color: ColorUtils.fromHex(cat.colorHex),
        name: cat.displayName(context.languageCode),
      );
    }

    final filterActive = _filterType != 'all';

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.transactions_title,
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              AppIcons.filter,
              color: filterActive
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: context.l10n.transactions_filter,
            onPressed: _showFilter,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSizes.screenHPadding,
              AppSizes.sm,
              AppSizes.screenHPadding,
              AppSizes.xs,
            ),
            child: AppSearchBar(
              hint: context.l10n.transactions_search_hint,
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),

          // Active filter chip
          if (filterActive)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.xs,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Chip(
                  label: Text(
                    _filterType == 'expense'
                        ? context.l10n.transaction_filter_expenses_chip
                        : context.l10n.transaction_filter_income_chip,
                  ),
                  deleteIcon: const Icon(AppIcons.close, size: AppSizes.iconXxs2),
                  onDeleted: () => setState(() => _filterType = 'all'),
                ),
              ),
            ),

          // Transaction list
          Expanded(
            child: allTxs.when(
              data: (txList) {
                // Client-side filter
                final filtered = txList.where((tx) {
                  final matchesType =
                      _filterType == 'all' || tx.type == _filterType;
                  final query = _searchQuery.trim().toLowerCase();
                  final matchesSearch = query.isEmpty ||
                      tx.title.toLowerCase().contains(query) ||
                      (tx.note?.toLowerCase().contains(query) ?? false);
                  return matchesType && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    title: _searchQuery.isNotEmpty
                        ? context.l10n.transaction_no_results
                        : context.l10n.transactions_empty_title,
                    subtitle: _searchQuery.isNotEmpty
                        ? context.l10n.transaction_try_different
                        : context.l10n.transactions_empty_sub,
                  );
                }

                final grouped = _groupTransactions(context, filtered);

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: AppSizes.xs,
                    bottom: AppSizes.bottomScrollPadding,
                  ),
                  itemCount: grouped.length,
                  itemBuilder: (_, i) {
                    final entry = grouped.entries.elementAt(i);
                    return TransactionListSection(
                      dateLabel: entry.key,
                      transactions: entry.value,
                      categoryResolver: resolveCategory,
                      onTransactionTap: (tx) =>
                          context.push('/transactions/${tx.id}'),
                      onTransactionDelete: _deleteTransaction,
                      onTransactionEdit: (tx) =>
                          context.push('/transactions/${tx.id}/edit'),
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSizes.screenHPadding),
                child: ShimmerList(),
              ),
              error: (_, __) => EmptyState(
                title: context.l10n.common_error_title,
                subtitle: context.l10n.dashboard_failed_transactions,
              ),
            ),
          ),
        ],
      ),
      // FAB removed — center FAB in AppScaffoldShell handles this globally
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Map<String, List<TransactionEntity>> _groupTransactions(
    BuildContext context,
    List<TransactionEntity> transactions,
  ) {
    final map = <String, List<TransactionEntity>>{};
    for (final tx in transactions) {
      final label = _dateLabel(context, tx.transactionDate);
      (map[label] ??= []).add(tx);
    }
    return map;
  }

  String _dateLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDay).inDays;
    if (diff == 0) return context.l10n.date_today;
    if (diff == 1) return context.l10n.date_yesterday;
    return '${txDay.day}/${txDay.month}/${txDay.year}';
  }
}

// ── Filter tile ───────────────────────────────────────────────────────────

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(label),
      trailing: selected ? const Icon(AppIcons.check) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}
