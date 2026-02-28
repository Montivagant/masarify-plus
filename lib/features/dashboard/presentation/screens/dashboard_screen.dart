import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/insight_presenter.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/insight_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/balance_card.dart';
import '../../../../shared/widgets/cards/budget_progress_card.dart';
import '../../../../shared/widgets/cards/insight_card.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/lists/transaction_list_section.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Dashboard — 5 reactive zones per AGENTS.md §7.6:
///   Zone 1  Hero Balance Card
///   Zone 2  Quick Actions (+Expense / +Income)
///   Zone 3  Recent 5 transactions grouped by date
///   Zone 4  Spending Overview (donut chart, below fold)
///   Zone 5  Budget alerts (at-risk >= 70%, below fold)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);

    final lastMonthKey = now.month == 1
        ? (now.year - 1, 12)
        : (now.year, now.month - 1);

    final totalBalance = ref.watch(totalBalanceProvider);
    final income = ref.watch(monthlyIncomeProvider(monthKey));
    final expense = ref.watch(monthlyExpenseProvider(monthKey));
    final lastMonthExpense = ref.watch(monthlyExpenseProvider(lastMonthKey));
    final recentTxs = ref.watch(recentTransactionsProvider);
    final monthTxs = ref.watch(transactionsByMonthProvider(monthKey));
    final categories = ref.watch(categoriesProvider);
    final budgets = ref.watch(budgetsByMonthProvider(monthKey));
    final insightsAsync = ref.watch(insightsProvider);

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

    // Build insights section once — always placed at Zone 6 (after budgets).
    final insightsSection = insightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();
        final top = insights.take(2).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.sectionGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.insights_title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.push(AppRoutes.insights),
                    label: Text(context.l10n.insight_see_all),
                    icon: const Icon(
                      AppIcons.chevronRight,
                      size: AppSizes.iconXs,
                    ),
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            ...top.map(
              (insight) => InsightCard(
                insight: insight,
                title: InsightPresenter.title(context, insight),
                body: InsightPresenter.body(context, insight),
                actionLabel: InsightPresenter.actionLabel(context, insight),
                onAction: () => InsightPresenter.onAction(context, insight),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
        ),
        child: ShimmerList(itemCount: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.dashboard_title,
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(hideBalancesProvider)
                  ? AppIcons.eyeOff
                  : AppIcons.eye,
            ),
            onPressed: () =>
                ref.read(hideBalancesProvider.notifier).toggle(),
            tooltip: ref.watch(hideBalancesProvider)
                ? context.l10n.balance_show
                : context.l10n.balance_hide,
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
          ref.invalidate(monthlyIncomeProvider(monthKey));
          ref.invalidate(monthlyExpenseProvider(monthKey));
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(transactionsByMonthProvider(monthKey));
          ref.invalidate(budgetsByMonthProvider(monthKey));
          ref.invalidate(insightsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Zone 1: Hero Balance Card ───────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppSizes.screenHPadding),
                child: totalBalance.when(
                  data: (total) => BalanceCard(
                    totalPiastres: total,
                    monthlyIncomePiastres: income.valueOrNull ?? 0,
                    monthlyExpensePiastres: expense.valueOrNull ?? 0,
                    lastMonthExpensePiastres: lastMonthExpense.valueOrNull,
                    hidden: ref.watch(hideBalancesProvider),
                    onToggleHide: () =>
                        ref.read(hideBalancesProvider.notifier).toggle(),
                  ),
                  loading: () => const _BalanceCardShimmer(),
                  error: (_, __) => EmptyState(
                    title: context.l10n.dashboard_failed_balance,
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.sectionGap),

              // ── Zone 2: Quick Actions ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.push(
                          AppRoutes.transactionAdd,
                          extra: {'type': 'expense'},
                        ),
                        icon: const Icon(AppIcons.expense, size: AppSizes.iconXs),
                        label: Text(
                          context.l10n.dashboard_quick_add_expense,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              context.appTheme.expenseColor.withValues(alpha: AppSizes.opacityLight),
                          foregroundColor: context.appTheme.expenseColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.push(
                          AppRoutes.transactionAdd,
                          extra: {'type': 'income'},
                        ),
                        icon: const Icon(AppIcons.income, size: AppSizes.iconXs),
                        label: Text(
                          context.l10n.dashboard_quick_add_income,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              context.appTheme.incomeColor.withValues(alpha: AppSizes.opacityLight),
                          foregroundColor: context.appTheme.incomeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.push(AppRoutes.transfer),
                        icon: const Icon(AppIcons.transfer, size: AppSizes.iconXs),
                        label: Text(
                          context.l10n.transfer_title,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: AppSizes.opacityMedium),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.sectionGap),

              // ── Zone 3: Recent transactions ────────────────────────
              recentTxs.when(
                data: (txList) {
                  final recent = txList.take(5).toList();
                  if (recent.isEmpty) {
                    return EmptyState(
                      title: context.l10n.dashboard_no_transactions,
                      subtitle: context.l10n.dashboard_start_tracking,
                      compact: true,
                    );
                  }
                  final grouped = _groupTransactions(context, recent);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.screenHPadding,
                          vertical: AppSizes.xs,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.dashboard_recent_transactions,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  context.go(AppRoutes.transactions),
                              label: Text(context.l10n.dashboard_see_all),
                              icon: const Icon(
                                AppIcons.chevronRight,
                                size: AppSizes.iconXs,
                              ),
                              iconAlignment: IconAlignment.end,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...grouped.entries.map(
                        (e) => TransactionListSection(
                          dateLabel: e.key,
                          transactions: e.value,
                          categoryResolver: resolveCategory,
                          onTransactionTap: (tx) =>
                              context.push(AppRoutes.transactionDetailPath(tx.id)),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSizes.screenHPadding),
                  child: ShimmerList(itemCount: 5),
                ),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: EmptyState(title: context.l10n.dashboard_failed_transactions),
                ),
              ),

              // ── Zone 4: Spending Overview (donut chart) ────────────
              monthTxs.when(
                data: (txList) {
                  final expenses =
                      txList.where((tx) => tx.type == 'expense').toList();
                  if (expenses.isEmpty) return const SizedBox.shrink();

                  final catList = categories.valueOrNull ?? [];
                  final breakdown = _categoryBreakdown(context, expenses, catList);
                  if (breakdown.isEmpty) return const SizedBox.shrink();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: AppSizes.sectionGap),
                      _SpendingOverview(breakdown: breakdown),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: EmptyState(title: context.l10n.dashboard_failed_spending),
                ),
              ),

              // ── Zone 5: Budget alerts ──────────────────────────────
              budgets.when(
                data: (budgetList) {
                  final catList = categories.valueOrNull ?? [];
                  final atRisk = budgetList
                      .where((b) => b.progressFraction >= 0.7)
                      .take(3)
                      .toList();
                  if (atRisk.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.sectionGap),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.screenHPadding,
                          vertical: AppSizes.xs,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.dashboard_budget_alerts,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            TextButton.icon(
                              onPressed: () => context.push(AppRoutes.budgets),
                              label: Text(context.l10n.dashboard_see_all),
                              icon: const Icon(
                                AppIcons.chevronRight,
                                size: AppSizes.iconXs,
                              ),
                              iconAlignment: IconAlignment.end,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...atRisk.map((budget) {
                        final cat = catList
                            .where((c) => c.id == budget.categoryId)
                            .firstOrNull;
                        if (cat == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.screenHPadding,
                            vertical: AppSizes.xs,
                          ),
                          child: BudgetProgressCard(
                            categoryName: cat.displayName(context.languageCode),
                            categoryIcon:
                                CategoryIconMapper.fromName(cat.iconName),
                            limitPiastres: budget.effectiveLimit,
                            spentPiastres: budget.spentAmount,
                            onTap: () => context.push(AppRoutes.budgets),
                          ),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: EmptyState(title: context.l10n.dashboard_failed_budgets),
                ),
              ),

              // ── Zone 6: Smart Insights (always after budgets)
              insightsSection,
            ],
          ),
        ),
      ),
      // FAB removed — center FAB in AppScaffoldShell handles this globally
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  static Map<String, List<TransactionEntity>> _groupTransactions(
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

  static String _dateLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(date.year, date.month, date.day);
    final diff = today.difference(txDay).inDays;
    if (diff == 0) return context.l10n.date_today;
    if (diff == 1) return context.l10n.date_yesterday;
    return DateFormat.yMd(context.languageCode).format(txDay);
  }

  /// Group expenses by category, return top 5 + "Other" for the donut chart.
  static List<_CategorySlice> _categoryBreakdown(
    BuildContext context,
    List<TransactionEntity> expenses,
    List<dynamic> catList,
  ) {
    final byCategory = <int, int>{};
    for (final tx in expenses) {
      byCategory[tx.categoryId] =
          (byCategory[tx.categoryId] ?? 0) + tx.amount;
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalPiastres = sorted.fold<int>(0, (s, e) => s + e.value);
    if (totalPiastres == 0) return [];

    final slices = <_CategorySlice>[];
    var otherAmount = 0;

    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      if (i < 5) {
        final cat = catList
            .where((c) => (c as dynamic).id == entry.key)
            .firstOrNull;
        slices.add(
          _CategorySlice(
            name: cat != null ? (cat as dynamic).displayName(context.languageCode) as String : '?',
            piastres: entry.value,
            color: cat != null
                ? ColorUtils.fromHex((cat as dynamic).colorHex as String)
                : Theme.of(context).colorScheme.outline,
            fraction: entry.value / totalPiastres,
          ),
        );
      } else {
        otherAmount += entry.value;
      }
    }

    if (otherAmount > 0) {
      slices.add(
        _CategorySlice(
          name: context.l10n.dashboard_other_category,
          piastres: otherAmount,
          color: Theme.of(context).colorScheme.outline,
          fraction: otherAmount / totalPiastres,
        ),
      );
    }
    return slices;
  }
}

// ── Category slice data ──────────────────────────────────────────────────

class _CategorySlice {
  const _CategorySlice({
    required this.name,
    required this.piastres,
    required this.color,
    required this.fraction,
  });
  final String name;
  final int piastres;
  final Color color;
  final double fraction;
}

// ── Spending Overview (donut chart) ──────────────────────────────────────

class _SpendingOverview extends StatefulWidget {
  const _SpendingOverview({required this.breakdown});
  final List<_CategorySlice> breakdown;

  @override
  State<_SpendingOverview> createState() => _SpendingOverviewState();
}

class _SpendingOverviewState extends State<_SpendingOverview> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.breakdown.fold<int>(0, (s, e) => s + e.piastres);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
            vertical: AppSizes.xs,
          ),
          child: Text(
            context.l10n.dashboard_spending_overview,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: AppSizes.chartHeightMd,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: widget.breakdown.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    final isTouched = i == _touchedIndex;
                    return PieChartSectionData(
                      value: s.piastres.toDouble(),
                      color: s.color,
                      // WS-9: gradient from solid to 70% opacity
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [s.color, s.color.withValues(alpha: AppSizes.opacityStrong)],
                      ),
                      radius: isTouched
                          ? AppSizes.pieChartRadius + 6
                          : AppSizes.pieChartRadius,
                      showTitle: false,
                    );
                  }).toList(),
                  // WS-9: enable touch for section highlighting
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (event.isInterestedForInteractions) {
                        setState(() {
                          _touchedIndex =
                              response?.touchedSection?.touchedSectionIndex ?? -1;
                        });
                      } else {
                        setState(() => _touchedIndex = -1);
                      }
                    },
                  ),
                  sectionsSpace: AppSizes.pieChartSectionSpace,
                  centerSpaceRadius: AppSizes.pieChartCenterRadius,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    MoneyFormatter.formatCompact(total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    context.l10n.dashboard_total,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.xs,
            children: widget.breakdown.map((s) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: AppSizes.dotMd,
                    height: AppSizes.dotMd,
                    decoration: BoxDecoration(
                      color: s.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    '${s.name} ${(s.fraction * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Shimmer placeholder for BalanceCard ──────────────────────────────────

class _BalanceCardShimmer extends StatelessWidget {
  const _BalanceCardShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLow,
      child: Container(
        height: AppSizes.chartHeightSm,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
      ),
    );
  }
}
