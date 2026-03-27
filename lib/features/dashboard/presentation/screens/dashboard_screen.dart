import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_resolver.dart';
import '../../../../core/utils/transaction_grouper.dart';
import '../../../../domain/adapters/transfer_adapter.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/activity_provider.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/app_search_bar.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/lists/transaction_list_section.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/account_carousel.dart';
import '../widgets/insight_cards_zone.dart';
import '../widgets/month_summary_zone.dart';
import '../widgets/pending_review_card.dart';
import '../widgets/quick_add_zone.dart';
import '../widgets/quick_start_tip_card.dart';

/// Dashboard — scrollable shell with dashboard zones + full transaction list.
///
/// Uses [CustomScrollView] with slivers so the dashboard zones scroll
/// seamlessly into the full transaction list. A sticky search/filter
/// header fades in once the user scrolls past the dashboard zones.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scrollController = ScrollController();
  final _scrollOffset = ValueNotifier<double>(0.0);

  // Ephemeral search/filter state — setState is allowed per project rules.
  String _searchQuery = '';
  String _filterType = 'all'; // 'all' | 'expense' | 'income' | 'transfer'

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
  }

  // ── Delete with undo ──────────────────────────────────────────────────

  Future<void> _deleteTransaction(TransactionEntity tx) async {
    final confirmed = await ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.transaction_delete_title,
      message: context.l10n.transaction_delete_confirm,
    );
    if (!confirmed || !mounted) return;

    final repo = ref.read(transactionRepositoryProvider);
    final bool deleted;
    try {
      deleted = await repo.delete(tx.id);
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
      return;
    }
    if (!deleted || !mounted) return;

    HapticFeedback.mediumImpact();
    SnackHelper.showSuccess(
      context,
      context.l10n.transaction_deleted_message(tx.title),
      duration: AppDurations.snackbarLong,
      action: SnackBarAction(
        label: context.l10n.transaction_undo,
        textColor: context.colors.onPrimary,
        onPressed: () async {
          await repo.restore(tx);
        },
      ),
    );
  }

  Future<void> _deleteTransfer(TransactionEntity tx) async {
    final transferId = transferIdFromTxId(tx.id);
    final confirmed = await ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.transfer_delete_title,
      message: context.l10n.transfer_delete_confirm,
    );
    if (!confirmed || !mounted) return;

    try {
      await ref.read(transferRepositoryProvider).delete(transferId);
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
      return;
    }
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    SnackHelper.showSuccess(context, context.l10n.transfer_deleted_message);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final selectedWalletId = ref.watch(selectedAccountIdProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final hidden = ref.watch(hideBalancesProvider);

    // Transaction data for the inline list.
    final allTxs = ref.watch(recentActivityProvider);
    final categories = ref.watch(categoriesProvider);

    // Wallet maps for transaction cards.
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final walletNameMap = {for (final w in wallets) w.id: w.name};
    final walletMap = {for (final w in wallets) w.id: w};

    ResolvedCategory resolveCat(int catId) {
      if (catId == 0) {
        return (
          icon: AppIcons.transfer,
          color: context.appTheme.transferColor,
          name: context.l10n.transaction_type_transfer,
        );
      }
      return resolveCategory(
        categoryId: catId,
        categories: categories.valueOrNull ?? [],
        fallbackColor: context.colors.outline,
        languageCode: context.languageCode,
      );
    }

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.dashboard_title,
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              hidden ? AppIcons.eyeOff : AppIcons.eye,
              size: AppSizes.iconSm,
            ),
            tooltip:
                hidden ? context.l10n.balance_show : context.l10n.balance_hide,
            onPressed: () => ref.read(hideBalancesProvider.notifier).toggle(),
          ),
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
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(recentActivityProvider);
          ref.invalidate(transactionsByMonthProvider(monthKey));
          ref.invalidate(budgetsByMonthProvider(monthKey));
          await ref.read(rawRecentTransactionsProvider.future);
        },
        child: CustomScrollView(
          controller: _scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Offline banner ──────────────────────────────────
            if (!isOnline)
              SliverToBoxAdapter(
                child: Container(
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
                ),
              ),

            // ── Quick Start tip card ────────────────────────────
            const SliverToBoxAdapter(child: QuickStartTipCard()),

            // ── Zone 1: Account Carousel (self-spaced) ──────────
            const SliverToBoxAdapter(child: AccountCarousel()),

            // ── Pending review card (self-spaced, SMS only) ────────
            if (AppConfig.kSmsEnabled)
              const SliverToBoxAdapter(child: PendingReviewCard()),

            // ── Zone 2: Month Summary (self-spaced) ─────────────
            SliverToBoxAdapter(
              child: MonthSummaryZone(
                filterWalletId: selectedWalletId,
                hidden: hidden,
              ),
            ),

            // ── Zone 3: AI Insight Cards (self-spaced) ──────────
            const SliverToBoxAdapter(child: InsightCardsZone()),

            // ── Zone 4: Quick Add (self-spaced) ─────────────────
            const SliverToBoxAdapter(child: QuickAddZone()),

            // ── Transactions section header with divider ────────
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppSizes.screenHPadding,
                    endIndent: AppSizes.screenHPadding,
                    color: context.colors.outlineVariant
                        .withValues(alpha: AppSizes.opacityLight4),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenHPadding,
                      vertical: AppSizes.xs,
                    ),
                    child: Text(
                      context.l10n.dashboard_transactions_title,
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sticky search + filter bar ──────────────────────
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickySearchFilterDelegate(
                onSearchChanged: (q) => setState(() => _searchQuery = q),
                filterType: _filterType,
                onFilterChanged: (t) => setState(() => _filterType = t),
                scrollOffset: _scrollOffset,
              ),
            ),

            // ── Full transaction list ───────────────────────────
            ..._buildTransactionSlivers(
              allTxs: allTxs,
              selectedWalletId: selectedWalletId,
              resolveCat: resolveCat,
              walletNameResolver:
                  selectedWalletId == null ? (id) => walletNameMap[id] : null,
              walletMap: walletMap,
            ),

            // ── Bottom padding ──────────────────────────────────
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.bottomScrollPadding),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the transaction slivers: loading, empty, or grouped list.
  List<Widget> _buildTransactionSlivers({
    required AsyncValue<List<TransactionEntity>> allTxs,
    required int? selectedWalletId,
    required ResolvedCategory Function(int) resolveCat,
    String? Function(int walletId)? walletNameResolver,
    required Map<int, WalletEntity> walletMap,
  }) {
    return allTxs.when(
      data: (txList) {
        // Client-side filters: wallet, type, search.
        final filtered = txList.where((tx) {
          if (selectedWalletId != null && tx.walletId != selectedWalletId) {
            return false;
          }
          final matchesType = _filterType == 'all' || tx.type == _filterType;
          final query = _searchQuery.trim().toLowerCase();
          final matchesSearch = query.isEmpty ||
              tx.title.toLowerCase().contains(query) ||
              (tx.note?.toLowerCase().contains(query) ?? false);
          return matchesType && matchesSearch;
        }).toList();

        if (filtered.isEmpty) {
          return [
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: _searchQuery.isNotEmpty
                    ? context.l10n.transaction_no_results
                    : context.l10n.dashboard_no_transactions,
                subtitle: _searchQuery.isNotEmpty
                    ? context.l10n.transaction_try_different
                    : context.l10n.dashboard_start_tracking,
                compact: true,
              ),
            ),
          ];
        }

        final grouped = groupTransactionsByDate(context, filtered);
        final entries = grouped.entries.toList();

        return entries.map<Widget>((entry) {
          final section = TransactionListSection(
            dateLabel: entry.key,
            transactions: entry.value,
            categoryResolver: resolveCat,
            walletNameResolver: walletNameResolver,
            walletInfoResolver: (walletId) {
              final w = walletMap[walletId];
              if (w == null) return null;
              return (icon: AppIcons.walletType(w.type), name: w.name);
            },
            onTransactionTap: (tx) {
              if (tx.id < 0) return; // transfers have no detail screen
              context.push(AppRoutes.transactionDetailPath(tx.id));
            },
            onTransactionDelete: (tx) {
              if (tx.id < 0) {
                _deleteTransfer(tx);
              } else {
                _deleteTransaction(tx);
              }
            },
            onTransactionEdit: (tx) {
              if (tx.id < 0) {
                context.push(AppRoutes.transfer);
              } else {
                context.push('/transactions/${tx.id}/edit');
              }
            },
          );

          Widget child;
          if (context.reduceMotion) {
            child = section;
          } else {
            child = section
                .animate()
                .fadeIn(duration: AppDurations.listItemEntry)
                .slideY(
                  begin: 0.03,
                  end: 0,
                  duration: AppDurations.listItemEntry,
                  curve: Curves.easeOutCubic,
                );
          }
          return SliverToBoxAdapter(child: child);
        }).toList();
      },
      loading: () => [
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(AppSizes.screenHPadding),
            child: ShimmerList(),
          ),
        ),
      ],
      error: (_, __) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            title: context.l10n.common_error_title,
            subtitle: context.l10n.dashboard_failed_transactions,
          ),
        ),
      ],
    );
  }
}

// ── Approximate pixel offset where dashboard zones end ────────────────────
// Used for the sticky header fade-in threshold.
const double _dashboardEndThreshold = 550.0;

// ── Sticky search + filter header delegate ────────────────────────────────

class _StickySearchFilterDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchFilterDelegate({
    required this.onSearchChanged,
    required this.filterType,
    required this.onFilterChanged,
    required this.scrollOffset,
  });

  final ValueChanged<String> onSearchChanged;
  final String filterType;
  final ValueChanged<String> onFilterChanged;
  final ValueNotifier<double> scrollOffset;

  @override
  double get maxExtent => 108;

  @override
  double get minExtent => 108;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset,
      builder: (context, offset, child) {
        final opacity =
            ((offset - _dashboardEndThreshold) / 80.0).clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: opacity < 0.1,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: Material(
        color: context.colors.surface,
        elevation: AppSizes.elevationLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.xs),
              // Search bar
              AppSearchBar(
                hint: context.l10n.transactions_search_hint,
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: AppSizes.xs),
              // Filter chips
              Wrap(
                spacing: AppSizes.sm,
                children: [
                  _FilterChip(
                    label: context.l10n.transaction_filter_all,
                    selected: filterType == 'all',
                    onTap: () => onFilterChanged('all'),
                  ),
                  _FilterChip(
                    label: context.l10n.transaction_filter_expenses,
                    selected: filterType == 'expense',
                    onTap: () => onFilterChanged('expense'),
                  ),
                  _FilterChip(
                    label: context.l10n.transaction_filter_income,
                    selected: filterType == 'income',
                    onTap: () => onFilterChanged('income'),
                  ),
                  _FilterChip(
                    label: context.l10n.transaction_type_transfer,
                    selected: filterType == 'transfer',
                    onTap: () => onFilterChanged('transfer'),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xs),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchFilterDelegate oldDelegate) =>
      filterType != oldDelegate.filterType;
}

// ── Filter chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
    );
  }
}
