import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/auto_pay_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/activity_provider.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/home_filter_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../../../shared/widgets/sheets/show_transaction_sheet.dart';
import '../widgets/balance_header.dart';
import '../widgets/due_soon_section.dart';
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
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static bool _notificationPermissionRequested = false;
  static bool _autoPayProcessed = false;

  final _scrollController = ScrollController();
  bool _heroCollapsed = false;

  /// Scroll offset above which the hero collapses.
  static const double _collapseThreshold = 300;

  /// Scroll offset below which the hero restores (hysteresis).
  static const double _restoreThreshold = 150;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    if (!_notificationPermissionRequested) {
      _notificationPermissionRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final granted = await NotificationService.requestPermission();
          if (granted) {
            await NotificationService.requestExactAlarmPermission();
          }
        } catch (e) {
          dev.log('Notification permission failed: $e', name: 'Dashboard');
        }
      });
    }
    // Process overdue auto-pay bills once per app session.
    if (!_autoPayProcessed) {
      _autoPayProcessed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final recurringRepo = ref.read(recurringRuleRepositoryProvider);
          final service = AutoPayService(recurringRepo);
          await service.processOverdue();
        } catch (e) {
          dev.log('Auto-pay processing failed: $e', name: 'Dashboard');
        }
      });
    }
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final shouldCollapse = _heroCollapsed
        ? offset > _restoreThreshold
        : offset > _collapseThreshold;
    if (shouldCollapse != _heroCollapsed) {
      setState(() => _heroCollapsed = shouldCollapse);
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        centerTitle: false,
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
      body: Column(
        children: [
          // ── Fixed zone: offline banner + header (never scrolls) ──────
          if (!isOnline) const _OfflineBanner(),
          if (filter.isSearchActive)
            SearchHeader(resultCount: resultCount)
          else
            AnimatedCrossFade(
              firstChild: const BalanceHeader(),
              secondChild: const _MiniBalanceHeader(),
              crossFadeState: _heroCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppDurations.animQuick,
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              sizeCurve: Curves.easeOutCubic,
            ),

          // ── Scrollable zone: insight cards + filter bar + transactions
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(totalBalanceProvider);
                ref.invalidate(recentActivityProvider);
                ref.invalidate(transactionsByMonthProvider(monthKey));
                ref.invalidate(budgetsByMonthProvider(monthKey));
                if (selectedWalletId != null) {
                  ref.invalidate(activityByWalletProvider(selectedWalletId));
                }
                // M-5 fix: invalidate all background AI insight providers
                ref.invalidate(spendingPredictionsProvider);
                ref.invalidate(detectedPatternsProvider);
                ref.invalidate(budgetSuggestionsProvider);
                ref.invalidate(budgetSavingsProvider);
                ref.invalidate(upcomingBillsProvider);
                await ref.read(recentActivityProvider.future);
              },
              child: SlidableAutoCloseBehavior(
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Insight cards zone (scroll away, hidden during search)
                    if (!filter.isSearchActive)
                      const SliverToBoxAdapter(child: InsightCardsZone()),

                    // ── Due-soon bills (scroll away, hidden during search)
                    if (!filter.isSearchActive)
                      const SliverToBoxAdapter(child: DueSoonSection()),

                    // ── Pinned filter bar (D-09) ──────────────────────────
                    const SliverPersistentHeader(
                      pinned: true,
                      delegate: FilterBarDelegate(child: FilterBar()),
                    ),

                    // ── Filter badge (D-14 — both account + type active) ──
                    const SliverToBoxAdapter(child: FilterBadge()),

                    // ── Transaction list with date grouping (D-13) ────────
                    TransactionSliverList(
                      onTap: (tx) => _onTransactionTap(context, tx),
                      onEdit: (tx) => _editTransaction(context, ref, tx),
                      onDelete: (tx) => _deleteTransaction(context, ref, tx),
                    ),

                    // ── Bottom padding for nav bar clearance ──────────────
                    const SliverPadding(
                      padding:
                          EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction actions ──────────────────────────────────────────────────

  void _onTransactionTap(BuildContext context, TransactionEntity tx) {
    if (tx.id > 0) {
      context.push(AppRoutes.transactionDetailPath(tx.id));
    } else {
      // Synthetic transfer entry — extract original transfer ID and show detail.
      final transferId = tx.id.abs() ~/ 2;
      context.push(AppRoutes.transferDetailPath(transferId));
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
    showEditTransactionSheet(context, tx.id);
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
              style: ctx.textStyles.bodyMedium?.copyWith(
                color: ctx.colors.error,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        // Store entity before deletion for undo support.
        final repo = ref.read(transactionRepositoryProvider);
        final entity = await repo.getById(tx.id);
        await repo.delete(tx.id);
        if (context.mounted && entity != null) {
          SnackHelper.showSuccess(
            context,
            context.l10n.transaction_deleted,
            action: SnackBarAction(
              label: context.l10n.common_undo,
              onPressed: () {
                repo.create(
                  walletId: entity.walletId,
                  categoryId: entity.categoryId,
                  amount: entity.amount,
                  type: entity.type,
                  title: entity.title,
                  transactionDate: entity.transactionDate,
                  currencyCode: entity.currencyCode,
                  note: entity.note,
                  tags: entity.tags,
                  source: entity.source,
                  rawSourceText: entity.rawSourceText,
                  isRecurring: entity.isRecurring,
                  recurringRuleId: entity.recurringRuleId,
                  goalId: entity.goalId,
                  locationName: entity.locationName,
                  latitude: entity.latitude,
                  longitude: entity.longitude,
                );
              },
            ),
            duration: AppDurations.snackbarLong,
          );
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
              style: ctx.textStyles.bodyMedium?.copyWith(
                color: ctx.colors.error,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        // Store entity before deletion for undo support.
        final repo = ref.read(transferRepositoryProvider);
        final entity = await repo.getById(originalTransferId);
        await repo.delete(originalTransferId);
        if (context.mounted && entity != null) {
          SnackHelper.showSuccess(
            context,
            context.l10n.transaction_deleted,
            action: SnackBarAction(
              label: context.l10n.common_undo,
              onPressed: () {
                repo.create(
                  fromWalletId: entity.fromWalletId,
                  toWalletId: entity.toWalletId,
                  amount: entity.amount,
                  fee: entity.fee,
                  note: entity.note,
                  transferDate: entity.transferDate,
                );
              },
            ),
            duration: AppDurations.snackbarLong,
          );
        }
      }
    });
  }
}

// ── Mini balance header (collapsed state) ────────────────────────────────────

class _MiniBalanceHeader extends ConsumerWidget {
  const _MiniBalanceHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedAccountIdProvider);
    final totalBalance = ref.watch(totalBalanceProvider).valueOrNull ?? 0;
    final hidden = ref.watch(hideBalancesProvider);
    final cs = context.colors;
    final theme = context.appTheme;

    final displayBalance = selectedId == null
        ? totalBalance
        : wallets.where((w) => w.id == selectedId).firstOrNull?.balance ?? 0;

    return Container(
      height: AppSizes.minTapTarget + AppSizes.md,
      decoration: BoxDecoration(
        color: theme.glassCardSurface,
        border: Border(bottom: BorderSide(color: theme.glassCardBorder)),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSizes.screenHPadding,
      ),
      child: Center(
        child: Text(
          hidden ? '------' : MoneyFormatter.formatTrailing(displayBalance),
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Offline banner ──────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

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
