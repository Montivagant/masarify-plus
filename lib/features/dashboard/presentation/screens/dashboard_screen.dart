import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/activity_provider.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/home_filter_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/balance_header.dart';
import '../widgets/filter_badge.dart';
import '../widgets/filter_bar.dart';
import '../widgets/filter_bar_delegate.dart';
import '../widgets/insight_cards_zone.dart';
import '../widgets/search_header.dart';
import '../widgets/transaction_sliver_list.dart';

/// Dashboard -- CustomScrollView + Slivers shell (Phase 03 overhaul).
///
/// Replaces the previous SingleChildScrollView + Column layout with a
/// sliver-based architecture for performance with large transaction lists
/// and pinned filter bar support.
///
/// Layout order:
/// 1. Offline banner (conditional)
/// 2. Balance header with account chips (or Search header when searching)
/// 3. Insight cards zone (scroll away, hidden during search)
/// 4. Pinned filter bar
/// 5. Filter badge (when both account + type filters active)
/// 6. Transaction SliverList with date grouping and swipe actions
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final filter = ref.watch(homeFilterProvider);
    final selectedWalletId = ref.watch(selectedAccountIdProvider);

    // Result count for search header.
    final resultCount = filter.isSearchActive && filter.searchQuery.isNotEmpty
        ? ref.watch(filteredActivityProvider).valueOrNull?.length
        : null;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.dashboard_title,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.ai),
            onPressed: () => context.push(AppRoutes.chat),
            tooltip: context.l10n.dashboard_chat_tooltip,
          ),
          IconButton(
            icon: const Icon(AppIcons.settings),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: context.l10n.settings_title,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(recentActivityProvider);
          ref.invalidate(transactionsByMonthProvider(monthKey));
          ref.invalidate(budgetsByMonthProvider(monthKey));
          if (selectedWalletId != null) {
            ref.invalidate(activityByWalletProvider(selectedWalletId));
          }
          await ref.read(recentActivityProvider.future);
        },
        child: SlidableAutoCloseBehavior(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Offline banner ────────────────────────────────────────
              if (!isOnline) SliverToBoxAdapter(child: _OfflineBanner()),

              // ── Balance header or Search header ───────────────────────
              if (!filter.isSearchActive)
                const SliverToBoxAdapter(child: BalanceHeader()),
              if (filter.isSearchActive)
                SliverToBoxAdapter(
                  child: SearchHeader(resultCount: resultCount),
                ),

              // ── Insight cards zone (scroll away, hidden during search)
              if (!filter.isSearchActive)
                const SliverToBoxAdapter(child: InsightCardsZone()),

              // ── Pinned filter bar (D-09) ──────────────────────────────
              const SliverPersistentHeader(
                pinned: true,
                delegate: FilterBarDelegate(child: FilterBar()),
              ),

              // ── Filter badge (D-14 — both account + type active) ─────
              const SliverToBoxAdapter(child: FilterBadge()),

              // ── Transaction list with date grouping (D-13) ───────────
              TransactionSliverList(
                onTap: (tx) => _onTransactionTap(context, tx),
                onEdit: (tx) => _editTransaction(context, ref, tx),
                onDelete: (tx) => _deleteTransaction(context, ref, tx),
              ),

              // ── Bottom padding for nav bar clearance ──────────────────
              const SliverPadding(
                padding: EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Transaction actions ──────────────────────────────────────────────────

  void _onTransactionTap(BuildContext context, TransactionEntity tx) {
    // Only real transactions have detail screens (positive IDs).
    if (tx.id > 0) {
      context.push(AppRoutes.transactionDetailPath(tx.id));
    }
  }

  void _editTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) {
    if (tx.id < 0) {
      // Synthetic transfer entries cannot be edited.
      SnackHelper.showInfo(
        context,
        context.l10n.transfer_cannot_edit,
      );
      return;
    }
    context.push('/transactions/${tx.id}/edit');
  }

  void _deleteTransaction(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) {
    if (tx.id < 0) {
      // Transfer entry — 2-step confirmation (D-17).
      _confirmTransferDelete(context, ref, tx);
    } else {
      // Regular transaction — single-step confirmation.
      _confirmRegularDelete(context, ref, tx);
    }
  }

  void _confirmRegularDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.transaction_delete_confirm_title),
        content: Text(ctx.l10n.transaction_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(ctx.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(
              ctx.l10n.common_delete,
              style: TextStyle(color: ctx.colors.error),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await ref.read(transactionRepositoryProvider).delete(tx.id);
        if (context.mounted) {
          SnackHelper.showSuccess(context, context.l10n.transaction_deleted);
        }
      }
    });
  }

  void _confirmTransferDelete(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity tx,
  ) {
    // Extract original transfer ID from synthetic negative ID.
    // fromEntry.id = -(transfer.id * 2), toEntry.id = -(transfer.id * 2 + 1)
    final syntheticId = tx.id.abs();
    final originalTransferId = syntheticId ~/ 2;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.transfer_delete_confirm_title),
        content: Text(ctx.l10n.transfer_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(ctx.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(
              ctx.l10n.common_delete,
              style: TextStyle(color: ctx.colors.error),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await ref.read(transferRepositoryProvider).delete(originalTransferId);
        if (context.mounted) {
          SnackHelper.showSuccess(context, context.l10n.transaction_deleted);
        }
      }
    });
  }
}

// ── Offline banner ──────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      color: context.colors.errorContainer,
      child: Row(
        children: [
          Icon(
            AppIcons.warning,
            size: AppSizes.iconSm,
            color: context.colors.onErrorContainer,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.l10n.dashboard_offline_banner,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
