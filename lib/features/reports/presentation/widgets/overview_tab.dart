import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Overview tab — income vs expense bar chart with configurable period.
class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  int _months = 6;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
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

        // Current month summary
        final current = totals.last;

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
                segments: const [
                  ButtonSegment(value: 3, label: Text('3M')),
                  ButtonSegment(value: 6, label: Text('6M')),
                  ButtonSegment(value: 12, label: Text('1Y')),
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
              padding: const EdgeInsets.all(AppSizes.screenHPadding),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryTile(
                      label: context.l10n.reports_total_income,
                      amount: current.income,
                      color: context.appTheme.incomeColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _SummaryTile(
                      label: context.l10n.reports_total_expense,
                      amount: current.expense,
                      color: context.appTheme.expenseColor,
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: _SummaryTile(
                      label: context.l10n.reports_net,
                      amount: current.net.abs(),
                      color: current.net >= 0
                          ? context.appTheme.incomeColor
                          : context.appTheme.expenseColor,
                    ),
                  ),
                ],
              ),
            ),

            // ── Bar chart header ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Text(
                context.l10n.reports_income_vs_expense,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
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
                child: _IncomeExpenseBarChart(totals: totals),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ── Daily average ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: _DailyAverageRow(
                label: context.l10n.reports_daily_average,
                amount: current.expense > 0
                    ? current.expense ~/
                        DateTime.now().day // days elapsed this month
                    : 0,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Summary tile ──────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.opacitySubtle),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            MoneyFormatter.formatAmount(amount),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Income vs Expense bar chart ───────────────────────────────────────────

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
    final maxY = maxVal > 0 ? maxVal * 1.2 : 100.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final label = rodIdx == 0 ? context.l10n.dashboard_income : context.l10n.dashboard_expense;
              return BarTooltipItem(
                '$label\n${MoneyFormatter.format(rod.toY.toInt())}',
                Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                    '${totals[idx].month}/${totals[idx].year % 100}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: AppSizes.chartLabelSize,
                          color: Theme.of(context).colorScheme.outline,
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
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
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
                // WS-9: gradient fill bottom→top
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    context.appTheme.incomeColor.withValues(alpha: 0.6),
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
                    context.appTheme.expenseColor.withValues(alpha: 0.6),
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

// ── Daily average row ─────────────────────────────────────────────────────

class _DailyAverageRow extends StatelessWidget {
  const _DailyAverageRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            MoneyFormatter.format(amount),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
