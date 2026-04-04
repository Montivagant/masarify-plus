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

/// Overview tab — hero total, pill period selector, income vs expense bar chart,
/// 2x2 summary grid, and savings insight banner.
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

        // Expense comparison percentage
        final int? expenseChangePercent;
        if (previous != null && previous.expense > 0) {
          expenseChangePercent =
              (((current.expense - previous.expense) * 100) / previous.expense)
                  .round();
        } else {
          expenseChangePercent = null;
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          children: [
            const SizedBox(height: AppSizes.md),

            // ── Hero section ──────────────────────────────────────────
            _HeroSection(
              expense: current.expense,
              changePercent: expenseChangePercent,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Period selector (pill chips) ──────────────────────────
            _PeriodSelector(
              months: _months,
              onChanged: (v) => setState(() => _months = v),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Bar chart header ──────────────────────────────────────
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

            // ── Bar chart ─────────────────────────────────────────────
            SizedBox(
              height: AppSizes.chartHeightMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: RepaintBoundary(
                  child: _IncomeExpenseBarChart(totals: totals),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Chart legend ──────────────────────────────────────────
            const _ChartLegend(),
            const SizedBox(height: AppSizes.lg),

            // ── 2x2 Summary cards ─────────────────────────────────────
            _SummaryGrid(
              current: current,
              dailyAvg: dailyAvg,
            ),

            // ── Insight banner ────────────────────────────────────────
            if (savingsRate > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenHPadding,
                  AppSizes.md,
                  AppSizes.screenHPadding,
                  0,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusMdSm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.reports,
                        size: AppSizes.iconXs,
                        color: context.colors.primary,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          context.l10n.reports_savings_rate(savingsRate),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.expense,
    required this.changePercent,
  });

  final int expense;
  final int? changePercent;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final expenseColor = context.appTheme.expenseColor;

    return Column(
      children: [
        // "Total Expenses" label
        Text(
          context.l10n.reports_total_expense,
          style: context.textStyles.labelLarge?.copyWith(
            color: cs.outline,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        // Large hero number
        Text(
          MoneyFormatter.format(expense),
          style: context.textStyles.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: expenseColor,
          ),
        ),
        // Comparison badge
        if (changePercent != null) ...[
          const SizedBox(height: AppSizes.sm),
          _ComparisonBadge(changePercent: changePercent!),
        ],
      ],
    );
  }
}

// ── Comparison badge pill ─────────────────────────────────────────────────────

class _ComparisonBadge extends StatelessWidget {
  const _ComparisonBadge({required this.changePercent});

  final int changePercent;

  @override
  Widget build(BuildContext context) {
    // Green if expenses decreased (good), red if increased (bad)
    final decreased = changePercent <= 0;
    final color = decreased
        ? context.appTheme.incomeColor
        : context.appTheme.expenseColor;
    final arrow = decreased ? '\u2193' : '\u2191'; // ↓ or ↑
    final absPercent = changePercent.abs();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.opacityLight2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
      ),
      child: Text(
        '$arrow $absPercent% ${context.l10n.reports_vs_last_month}',
        style: context.textStyles.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Period selector (pill chips) ──────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.months,
    required this.onChanged,
  });

  final int months;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PillChip(
          label: context.l10n.period_3_months,
          selected: months == 3,
          onTap: () => onChanged(3),
        ),
        const SizedBox(width: AppSizes.sm),
        _PillChip(
          label: context.l10n.period_6_months,
          selected: months == 6,
          onTap: () => onChanged(6),
        ),
        const SizedBox(width: AppSizes.sm),
        _PillChip(
          label: context.l10n.period_1_year,
          selected: months == 12,
          onTap: () => onChanged(12),
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
      labelStyle: context.textStyles.labelMedium?.copyWith(
        color: selected ? cs.onPrimary : cs.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
      ),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
    );
  }
}

// ── Income vs Expense bar chart ───────────────────────────────────────────────

class _IncomeExpenseBarChart extends StatelessWidget {
  const _IncomeExpenseBarChart({required this.totals});

  final List<MonthlyTotal> totals;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;

    final maxVal = totals.fold<int>(
      0,
      (prev, t) {
        final m = t.income > t.expense ? t.income : t.expense;
        return m > prev ? m : prev;
      },
    );
    final maxY = maxVal > 0 ? maxVal * 1.2 : 100000.0;

    // Horizontal grid interval — show ~3 lines
    final gridInterval = maxY / 4;

    final lastIndex = totals.length - 1;

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
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
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
                    DateFormat.MMM(context.languageCode)
                        .format(DateTime(totals[idx].year, totals[idx].month)),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: gridInterval > 0 ? gridInterval : null,
          getDrawingHorizontalLine: (value) => FlLine(
            color: cs.outlineVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(totals.length, (i) {
          final t = totals[i];
          final isCurrentMonth = i == lastIndex;
          final barWidth = isCurrentMonth
              ? AppSizes.barChartWidth + 2
              : AppSizes.barChartWidth;

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
                    theme.incomeColor
                        .withValues(alpha: AppSizes.opacityMedium2),
                    theme.incomeColor,
                  ],
                ),
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              BarChartRodData(
                toY: t.expense.toDouble(),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    theme.expenseColor
                        .withValues(alpha: AppSizes.opacityMedium2),
                    theme.expenseColor,
                  ],
                ),
                width: barWidth,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Chart legend ──────────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  const _ChartLegend();

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final ts = context.textStyles.labelSmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: theme.incomeColor),
        const SizedBox(width: AppSizes.xs),
        Text(context.l10n.dashboard_income, style: ts),
        const SizedBox(width: AppSizes.md),
        _LegendDot(color: theme.expenseColor),
        const SizedBox(width: AppSizes.xs),
        Text(context.l10n.dashboard_expense, style: ts),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.dotSm,
      height: AppSizes.dotSm,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ── 2x2 Summary grid ─────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.current,
    required this.dailyAvg,
  });

  final MonthlyTotal current;
  final int dailyAvg;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final cs = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryGridCard(
                  icon: AppIcons.income,
                  label: context.l10n.dashboard_income,
                  value: MoneyFormatter.formatAmount(current.income),
                  color: theme.incomeColor,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _SummaryGridCard(
                  icon: AppIcons.expense,
                  label: context.l10n.dashboard_expense,
                  value: MoneyFormatter.formatAmount(current.expense),
                  color: theme.expenseColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Row(
            children: [
              Expanded(
                child: _SummaryGridCard(
                  icon: AppIcons.wallet,
                  label: context.l10n.reports_net,
                  value: MoneyFormatter.formatAmount(current.net.abs()),
                  color: cs.primary,
                  prefix: current.net >= 0 ? '+' : '\u2212',
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _SummaryGridCard(
                  icon: AppIcons.calendar,
                  label: context.l10n.reports_daily_average,
                  value: MoneyFormatter.formatAmount(dailyAvg),
                  color: cs.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryGridCard extends StatelessWidget {
  const _SummaryGridCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.prefix,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tier: GlassTier.inset,
      padding: const EdgeInsets.all(AppSizes.borderRadiusMdSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconXs, color: context.colors.outline),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            '${prefix ?? ''}$value',
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
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
