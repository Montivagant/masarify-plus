import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Comparison tab — this month vs last month side-by-side bars.
class ComparisonTab extends ConsumerWidget {
  const ComparisonTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compAsync = ref.watch(monthComparisonProvider);

    return compAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(context.l10n.common_error_generic),
      ),
      data: (comp) {
        final hasData = comp.thisMonth.income > 0 ||
            comp.thisMonth.expense > 0 ||
            comp.lastMonth.income > 0 ||
            comp.lastMonth.expense > 0;

        if (!hasData) {
          return EmptyState(
            title: context.l10n.reports_empty_title,
            subtitle: context.l10n.reports_empty_sub,
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          children: [
            const SizedBox(height: AppSizes.md),

            // ── Bar chart ──────────────────────────────────────────
            SizedBox(
              height: AppSizes.chartHeightXl,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: _ComparisonBarChart(comp: comp),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ── Legend ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(
                    color: context.appTheme.incomeColor,
                    label: context.l10n.reports_this_month,
                  ),
                  const SizedBox(width: AppSizes.lg),
                  _LegendDot(
                    color: context.appTheme.previousPeriodColor,
                    label: context.l10n.reports_last_month,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.xl),

            // ── Detail rows ────────────────────────────────────────
            _ComparisonRow(
              label: context.l10n.reports_total_income,
              thisMonth: comp.thisMonth.income,
              lastMonth: comp.lastMonth.income,
              color: context.appTheme.incomeColor,
            ),
            Divider(height: AppSizes.dividerHeight, color: context.colors.outlineVariant),
            _ComparisonRow(
              label: context.l10n.reports_total_expense,
              thisMonth: comp.thisMonth.expense,
              lastMonth: comp.lastMonth.expense,
              color: context.appTheme.expenseColor,
            ),
            Divider(height: AppSizes.dividerHeight, color: context.colors.outlineVariant),
            _ComparisonRow(
              label: context.l10n.reports_net,
              thisMonth: comp.thisMonth.net.abs(),
              lastMonth: comp.lastMonth.net.abs(),
              color: comp.thisMonth.net >= 0
                  ? context.appTheme.incomeColor
                  : context.appTheme.expenseColor,
            ),
          ],
        );
      },
    );
  }
}

// ── Comparison bar chart ──────────────────────────────────────────────────

class _ComparisonBarChart extends StatelessWidget {
  const _ComparisonBarChart({required this.comp});

  final MonthComparison comp;

  @override
  Widget build(BuildContext context) {
    final values = [
      comp.thisMonth.income,
      comp.lastMonth.income,
      comp.thisMonth.expense,
      comp.lastMonth.expense,
    ];
    final maxVal = values.fold<int>(0, (s, e) => e > s ? e : s);
    final maxY = maxVal > 0 ? maxVal * 1.2 : 100.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final period = rodIdx == 0
                  ? context.l10n.reports_this_month
                  : context.l10n.reports_last_month;
              return BarTooltipItem(
                '$period\n${MoneyFormatter.format(rod.toY.toInt())}',
                context.textStyles.bodySmall!.copyWith(
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
                return Text(
                  MoneyFormatter.formatCompact(value.toInt()),
                  style: context.textStyles.bodySmall?.copyWith(
                        fontSize: AppSizes.chartLabelSize,
                        color: context.colors.onSurfaceVariant,
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
                if (idx == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSizes.xs),
                    child: Text(
                      context.l10n.dashboard_income,
                      style: context.textStyles.bodySmall?.copyWith(
                            fontSize: AppSizes.chartLabelSize,
                            color: context.colors.outline,
                          ),
                    ),
                  );
                }
                if (idx == 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSizes.xs),
                    child: Text(
                      context.l10n.dashboard_expense,
                      style: context.textStyles.bodySmall?.copyWith(
                            fontSize: AppSizes.chartLabelSize,
                            color: context.colors.outline,
                          ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: AppSizes.opacityMedium),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          // Income group
          BarChartGroupData(
            x: 0,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: comp.thisMonth.income.toDouble(),
                color: context.appTheme.incomeColor,
                width: AppSizes.chartBarWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.borderRadiusXs),
                ),
              ),
              BarChartRodData(
                toY: comp.lastMonth.income.toDouble(),
                color: context.appTheme.previousPeriodColor,
                width: AppSizes.chartBarWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.borderRadiusXs),
                ),
              ),
            ],
          ),
          // Expense group
          BarChartGroupData(
            x: 1,
            barsSpace: 6,
            barRods: [
              BarChartRodData(
                toY: comp.thisMonth.expense.toDouble(),
                color: context.appTheme.expenseColor,
                width: AppSizes.chartBarWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.borderRadiusXs),
                ),
              ),
              BarChartRodData(
                toY: comp.lastMonth.expense.toDouble(),
                color: context.appTheme.previousPeriodColorAlt,
                width: AppSizes.chartBarWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.borderRadiusXs),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Legend dot ─────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: AppSizes.dotMd,
          height: AppSizes.dotMd,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(label, style: context.textStyles.bodySmall),
      ],
    );
  }
}

// ── Comparison row ────────────────────────────────────────────────────────

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.thisMonth,
    required this.lastMonth,
    required this.color,
  });

  final String label;
  final int thisMonth;
  final int lastMonth;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final diff = thisMonth - lastMonth;
    final diffPct =
        lastMonth > 0 ? ((diff / lastMonth) * 100).round() : 0;
    final isUp = diff > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textStyles.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              MoneyFormatter.formatAmount(thisMonth),
              style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          SizedBox(
            width: AppSizes.comparisonColumnWidth,
            child: diffPct != 0
                ? Text(
                    '${isUp ? '+' : ''}$diffPct%',
                    style: context.textStyles.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.end,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
