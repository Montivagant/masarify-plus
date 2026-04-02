import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Overview tab — income vs expense bar chart with summary cards and insights.
class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  int _months = 6;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final totalsAsync = ref.watch(monthlyTotalsProvider(_months));

    return totalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(context.l10n.common_error_generic),
      ),
      data: (totals) {
        final hasData = totals.any((t) => t.income > 0 || t.expense > 0);
        if (!hasData) {
          return EmptyState(
            title: context.l10n.reports_empty_title,
            subtitle: context.l10n.reports_empty_sub,
          );
        }

        final current = totals.last;
        final previous = totals.length >= 2 ? totals[totals.length - 2] : null;

        // Savings rate for current month
        final savingsRate = current.income > 0
            ? ((current.income - current.expense) * 100) ~/ current.income
            : 0;

        // Daily average: use days elapsed this month
        final daysElapsed = DateTime.now().day;
        final dailyAvg =
            current.expense > 0 ? current.expense ~/ daysElapsed : 0;

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          children: [
            // ── Period selector ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.sm,
              ),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 3,
                    label: Text(context.l10n.period_3_months),
                  ),
                  ButtonSegment(
                    value: 6,
                    label: Text(context.l10n.period_6_months),
                  ),
                  ButtonSegment(
                    value: 12,
                    label: Text(context.l10n.period_1_year),
                  ),
                ],
                selected: {_months},
                onSelectionChanged: (v) => setState(() => _months = v.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),

            // ── Summary cards ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: context.l10n.reports_total_income,
                      amount: current.income,
                      color: context.appTheme.incomeColor,
                      icon: AppIcons.income,
                      change: _percentChange(
                        current.income,
                        previous?.income,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _SummaryCard(
                      label: context.l10n.reports_total_expense,
                      amount: current.expense,
                      color: context.appTheme.expenseColor,
                      icon: AppIcons.expense,
                      change: _percentChange(
                        current.expense,
                        previous?.expense,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Net + Savings Rate row ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      label: context.l10n.reports_net,
                      amount: current.net.abs(),
                      color: current.net >= 0
                          ? context.appTheme.incomeColor
                          : context.appTheme.expenseColor,
                      icon: current.net >= 0
                          ? AppIcons.trendingUp
                          : AppIcons.trendingDown,
                      prefix: current.net >= 0 ? '+' : '\u2212',
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _SummaryCard(
                      label: context.l10n.reports_daily_average,
                      amount: dailyAvg,
                      color: context.colors.primary,
                      icon: AppIcons.calendar,
                    ),
                  ),
                ],
              ),
            ),

            // ── Savings rate insight ────────────────────────────────
            if (current.income > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenHPadding,
                  AppSizes.sm,
                  AppSizes.screenHPadding,
                  0,
                ),
                child: GlassCard(
                  tier: GlassTier.inset,
                  tintColor: savingsRate >= 20
                      ? context.appTheme.incomeColor
                          .withValues(alpha: AppSizes.opacitySubtle)
                      : context.appTheme.expenseColor
                          .withValues(alpha: AppSizes.opacitySubtle),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        savingsRate >= 20
                            ? AppIcons.checkCircle
                            : AppIcons.warning,
                        size: AppSizes.iconSm,
                        color: savingsRate >= 20
                            ? context.appTheme.incomeColor
                            : context.appTheme.expenseColor,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          context.l10n.reports_savings_rate(savingsRate),
                          style: context.textStyles.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Spending highlights ────────────────────────────────
            _SpendingHighlights(
              expense: current.expense,
              dailyAvg: dailyAvg,
            ),

            const SizedBox(height: AppSizes.lg),

            // ── Bar chart header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Text(
                context.l10n.reports_income_vs_expense,
                style: context.textStyles.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Bar chart ──────────────────────────────────────────
            SizedBox(
              height: AppSizes.chartHeightLg,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: RepaintBoundary(
                  child: _IncomeExpenseBarChart(totals: totals),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Calculate percent change between current and previous period.
  int? _percentChange(int current, int? previous) {
    if (previous == null || previous == 0) return null;
    return (((current - previous) * 100) / previous).round();
  }
}

// ── Summary card (glassmorphic) ─────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.change,
    this.prefix,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  /// Month-over-month percent change (null = no previous data).
  final int? change;

  /// Optional prefix for amount (e.g. '+' or '−').
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tintColor: color.withValues(alpha: AppSizes.opacitySubtle),
      padding: const EdgeInsets.all(AppSizes.sm + AppSizes.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconXs, color: color),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  label,
                  style: context.textStyles.bodySmall?.copyWith(color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            '${prefix ?? ''}${MoneyFormatter.formatAmount(amount)}',
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Month-over-month change indicator
          if (change != null) ...[
            const SizedBox(height: AppSizes.xxs),
            Row(
              children: [
                Icon(
                  change! >= 0 ? AppIcons.trendingUp : AppIcons.trendingDown,
                  size: AppSizes.iconXxs2,
                  color: context.colors.outline,
                ),
                const SizedBox(width: AppSizes.xxs),
                Text(
                  '${change! >= 0 ? '+' : ''}$change%',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.outline,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Income vs Expense bar chart ─────────────────────────────────────────────

class _IncomeExpenseBarChart extends StatelessWidget {
  const _IncomeExpenseBarChart({required this.totals});

  final List<MonthlyTotal> totals;

  @override
  Widget build(BuildContext context) {
    final maxVal = totals.fold<int>(
      0,
      (prev, t) {
        final m = t.income > t.expense ? t.income : t.expense;
        return m > prev ? m : prev;
      },
    );
    final maxY = maxVal > 0 ? maxVal * 1.2 : 100000.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final label = rodIdx == 0
                  ? context.l10n.dashboard_income
                  : context.l10n.dashboard_expense;
              return BarTooltipItem(
                '$label\n${MoneyFormatter.format(rod.toY.round())}',
                (context.textStyles.bodySmall ?? const TextStyle()).copyWith(
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                if (value == meta.max || value == meta.min) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Text(
                    MoneyFormatter.formatCompact(value.toInt()),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontSize: AppSizes.chartLabelSize,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= totals.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xs),
                  child: Text(
                    DateFormat('M/yy', context.languageCode)
                        .format(DateTime(totals[idx].year, totals[idx].month)),
                    style: context.textStyles.bodySmall?.copyWith(
                      fontSize: AppSizes.chartLabelSize,
                      color: context.colors.outline,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.colors.outlineVariant.withValues(
              alpha: AppSizes.opacityMedium,
            ),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(totals.length, (i) {
          final t = totals[i];
          return BarChartGroupData(
            x: i,
            barsSpace: 4,
            barRods: [
              BarChartRodData(
                toY: t.income.toDouble(),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    context.appTheme.incomeColor
                        .withValues(alpha: AppSizes.opacityMedium2),
                    context.appTheme.incomeColor,
                  ],
                ),
                width: AppSizes.barChartWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.borderRadiusSm),
                ),
              ),
              BarChartRodData(
                toY: t.expense.toDouble(),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    context.appTheme.expenseColor
                        .withValues(alpha: AppSizes.opacityMedium2),
                    context.appTheme.expenseColor,
                  ],
                ),
                width: AppSizes.barChartWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.borderRadiusSm),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Spending highlights ─────────────────────────────────────────────────────

class _SpendingHighlights extends ConsumerWidget {
  const _SpendingHighlights({
    required this.expense,
    required this.dailyAvg,
  });

  final int expense;
  final int dailyAvg;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expense == 0) return const SizedBox.shrink();

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft = daysInMonth - now.day;
    final projectedTotal = expense + (dailyAvg * daysLeft);

    // Top category for current month
    final breakdown =
        ref.watch(categoryBreakdownProvider((now.year, now.month))).valueOrNull;
    final topCategory =
        breakdown != null && breakdown.isNotEmpty ? breakdown.first : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.screenHPadding,
        AppSizes.sm,
        AppSizes.screenHPadding,
        0,
      ),
      child: Column(
        children: [
          // Projected month-end spending
          if (daysLeft > 0)
            GlassCard(
              tier: GlassTier.inset,
              tintColor: context.colors.primary
                  .withValues(alpha: AppSizes.opacitySubtle),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.trendingUp,
                    size: AppSizes.iconSm,
                    color: context.colors.primary,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      context.l10n.reports_projected_total(
                        MoneyFormatter.formatCompact(projectedTotal),
                      ),
                      style: context.textStyles.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Top spending category
          if (topCategory != null) ...[
            const SizedBox(height: AppSizes.xs),
            GlassCard(
              tier: GlassTier.inset,
              tintColor: context.appTheme.expenseColor
                  .withValues(alpha: AppSizes.opacitySubtle),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  Icon(
                    AppIcons.expense,
                    size: AppSizes.iconSm,
                    color: context.appTheme.expenseColor,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      context.l10n.reports_top_spending(
                        topCategory.categoryName,
                        MoneyFormatter.formatCompact(topCategory.amount),
                      ),
                      style: context.textStyles.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
