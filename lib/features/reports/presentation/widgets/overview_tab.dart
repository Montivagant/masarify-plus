import 'dart:math' as math;

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
import '../widgets/insight_card.dart';
import '../widgets/tab_filter_row.dart';

/// Overview tab — hero Net Cash Flow, filter row, income/expense side-by-side,
/// grouped bar chart, savings insight banner, and 2x2 summary grid.
class OverviewTab extends ConsumerStatefulWidget {
  const OverviewTab({super.key});

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab>
    with AutomaticKeepAliveClientMixin {
  // ── Local filter state (per-tab, NOT providers) ────────────────────────
  String _timePreset = 'this_month';
  String _typeFilter = 'all'; // 'all', 'expense', 'income'
  int? _walletId;
  DateTimeRange? _customRange;
  final int _barChartMonths = 6;

  @override
  bool get wantKeepAlive => true;

  // ── Provider param helpers ─────────────────────────────────────────────

  MonthlyTotalsParams get _barChartParams => (
        count: _barChartMonths,
        walletId: _walletId,
        typeFilter: _typeFilter == 'all' ? null : _typeFilter,
      );

  /// Always fetch at least 2 months so we can compute delta for the hero.
  MonthlyTotalsParams get _heroParams => (
        count: 2,
        walletId: _walletId,
        typeFilter: _typeFilter == 'all' ? null : _typeFilter,
      );

  DailySpendingParams get _sparklineParams => (
        days: 30,
        walletId: _walletId,
        typeFilter: _typeFilter == 'all' ? null : _typeFilter,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final heroAsync = ref.watch(monthlyTotalsProvider(_heroParams));
    final barChartAsync = ref.watch(monthlyTotalsProvider(_barChartParams));
    final sparklineAsync = ref.watch(dailySpendingProvider(_sparklineParams));

    return heroAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => EmptyState(
        title: context.l10n.common_error_title,
        ctaLabel: context.l10n.common_retry,
        onCta: () {
          ref.invalidate(monthlyTotalsProvider(_heroParams));
          ref.invalidate(monthlyTotalsProvider(_barChartParams));
          ref.invalidate(dailySpendingProvider(_sparklineParams));
        },
      ),
      data: (heroTotals) {
        final hasData = heroTotals.any((t) => t.income > 0 || t.expense > 0);
        if (!hasData) {
          return Column(
            children: [
              const SizedBox(height: AppSizes.md),
              TabFilterRow(
                timePreset: _timePreset,
                typeFilter: _typeFilter,
                walletId: _walletId,
                customRange: _customRange,
                onFilterChanged: _onFilterChanged,
              ),
              const Expanded(
                child: EmptyState(
                  title: '', // filled below
                  compact: true,
                ),
              ),
            ],
          );
        }

        final current = heroTotals.last;
        final previous =
            heroTotals.length >= 2 ? heroTotals[heroTotals.length - 2] : null;

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          children: [
            const SizedBox(height: AppSizes.md),

            // ── 1. Tab Filter Row ────────────────────────────────────
            TabFilterRow(
              timePreset: _timePreset,
              typeFilter: _typeFilter,
              walletId: _walletId,
              customRange: _customRange,
              onFilterChanged: _onFilterChanged,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── 2. Hero Card — Net Cash Flow ─────────────────────────
            _HeroCard(
              current: current,
              previous: previous,
              typeFilter: _typeFilter,
              sparklineAsync: sparklineAsync,
            ),
            const SizedBox(height: AppSizes.lg),

            // ── 3. Income vs Expense side-by-side ────────────────────
            _IncomeExpenseRow(current: current),
            const SizedBox(height: AppSizes.lg),

            // ── 4. Bar Chart header ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${context.l10n.reports_income_vs_expense} · ${context.l10n.reports_last_6_months}',
                      style: context.textStyles.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── 4. Bar Chart ─────────────────────────────────────────
            barChartAsync.when(
              loading: () => const SizedBox(
                height: AppSizes.chartHeightMd,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox(height: AppSizes.chartHeightMd),
              data: (totals) => Semantics(
                label:
                    'Income vs expense bar chart for the last $_barChartMonths months',
                child: Column(
                  children: [
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
                    const _ChartLegend(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── 5. Insight Card — savings rate ───────────────────────
            if (current.income > 0) ...[
              Builder(
                builder: (context) {
                  final savingsRate =
                      ((current.income - current.expense) * 100) ~/
                          current.income;
                  if (savingsRate <= 0) return const SizedBox.shrink();
                  return InsightCard(
                    text: context.l10n.reports_insight_savings(savingsRate),
                  );
                },
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            // ── 6. Summary Grid (2x2) ───────────────────────────────
            _SummaryGrid(
              current: current,
              sparklineAsync: sparklineAsync,
            ),
          ],
        );
      },
    );
  }

  void _onFilterChanged({
    String? timePreset,
    String? typeFilter,
    int? walletId,
    bool? clearWallet,
    DateTimeRange? customRange,
  }) {
    setState(() {
      if (timePreset != null) _timePreset = timePreset;
      if (typeFilter != null) _typeFilter = typeFilter;
      if (walletId != null) _walletId = walletId;
      if (clearWallet == true) _walletId = null;
      if (customRange != null) _customRange = customRange;
    });
  }
}

// ── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.current,
    required this.previous,
    required this.typeFilter,
    required this.sparklineAsync,
  });

  final MonthlyTotal current;
  final MonthlyTotal? previous;
  final String typeFilter;
  final AsyncValue<List<DailySpending>> sparklineAsync;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;

    // Resolve hero value, label, and color based on type filter.
    final int heroValue;
    final String heroLabel;
    final Color heroColor;

    switch (typeFilter) {
      case 'expense':
        heroValue = current.expense;
        heroLabel = context.l10n.reports_total_expenses_period;
        heroColor = theme.expenseColor;
      case 'income':
        heroValue = current.income;
        heroLabel = context.l10n.reports_total_income_period;
        heroColor = theme.incomeColor;
      default: // 'all' — Net Cash Flow
        heroValue = current.net;
        heroLabel = context.l10n.reports_net_cash_flow;
        heroColor = current.net >= 0 ? theme.incomeColor : theme.expenseColor;
    }

    // Delta badge: compare vs previous month.
    final int? deltaPercent = _computeDelta();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: GlassCard(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          children: [
            // Label
            Text(
              heroLabel,
              style: context.textStyles.labelLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSizes.xs),

            // Large formatted number
            Text(
              typeFilter == 'all'
                  ? '${heroValue >= 0 ? '+' : '\u2212'}${MoneyFormatter.format(heroValue.abs())}'
                  : MoneyFormatter.format(heroValue),
              style: context.textStyles.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: heroColor,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),

            // Delta badge
            if (deltaPercent != null) ...[
              const SizedBox(height: AppSizes.sm),
              _DeltaBadge(
                percent: deltaPercent,
                typeFilter: typeFilter,
              ),
            ],

            // Mini sparkline
            const SizedBox(height: AppSizes.md),
            SizedBox(
              height: AppSizes.sparklineHeight,
              child: sparklineAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (data) {
                  if (data.isEmpty || data.every((d) => d.amount == 0)) {
                    return const SizedBox.shrink();
                  }
                  return Semantics(
                    label: context.l10n.semantics_daily_trend_sparkline,
                    child: RepaintBoundary(
                      child: _MiniSparkline(
                        data: data,
                        color: heroColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  int? _computeDelta() {
    if (previous == null) return null;

    final int currentVal;
    final int previousVal;

    switch (typeFilter) {
      case 'expense':
        currentVal = current.expense;
        previousVal = previous!.expense;
      case 'income':
        currentVal = current.income;
        previousVal = previous!.income;
      default: // 'all' — net
        currentVal = current.net;
        previousVal = previous!.net;
    }

    if (previousVal == 0) return null;
    return (((currentVal - previousVal) * 100) / previousVal).round();
  }
}

// ── Delta Badge ──────────────────────────────────────────────────────────────

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({
    required this.percent,
    required this.typeFilter,
  });

  final int percent;
  final String typeFilter;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    // For expenses: decrease is good (green). For income/net: increase is good.
    final bool isPositive;
    if (typeFilter == 'expense') {
      isPositive = percent <= 0; // expenses going down = good
    } else {
      isPositive = percent >= 0; // income/net going up = good
    }

    final color = isPositive ? theme.incomeColor : theme.expenseColor;
    final arrow = percent >= 0 ? '\u2191' : '\u2193'; // up or down arrow
    final absPercent = percent.abs();

    return Semantics(
      label:
          '${percent >= 0 ? "up" : "down"} $absPercent percent versus last month',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: AppSizes.opacityLight2),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        ),
        child: Text(
          context.l10n.reports_vs_last_month_pct(arrow, absPercent),
          style: context.textStyles.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Mini Sparkline ───────────────────────────────────────────────────────────

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({
    required this.data,
    required this.color,
  });

  final List<DailySpending> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].amount.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        clipData: const FlClipData.all(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: AppSizes.opacityLight3),
                  color.withValues(alpha: AppSizes.none),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Income vs Expense Row ────────────────────────────────────────────────────

class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({required this.current});

  final MonthlyTotal current;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Row(
        children: [
          Expanded(
            child: _IncomeExpenseCard(
              icon: AppIcons.income,
              label: context.l10n.dashboard_income,
              amount: current.income,
              color: theme.incomeColor,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: _IncomeExpenseCard(
              icon: AppIcons.expense,
              label: context.l10n.dashboard_expense,
              amount: current.expense,
              color: theme.expenseColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseCard extends StatelessWidget {
  const _IncomeExpenseCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      tier: GlassTier.inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconXs, color: color),
              const SizedBox(width: AppSizes.xs),
              Text(
                label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            MoneyFormatter.format(amount),
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Income vs Expense Bar Chart ──────────────────────────────────────────────

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
        final m = math.max(t.income, t.expense);
        return math.max(m, prev);
      },
    );
    final maxY = maxVal > 0 ? maxVal * 1.2 : 100000.0;
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
                  fontFeatures: [const FontFeature.tabularFigures()],
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
                  topLeft: Radius.circular(AppSizes.borderRadiusXs),
                  topRight: Radius.circular(AppSizes.borderRadiusXs),
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
                  topLeft: Radius.circular(AppSizes.borderRadiusXs),
                  topRight: Radius.circular(AppSizes.borderRadiusXs),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Chart Legend ──────────────────────────────────────────────────────────────

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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ── 2x2 Summary Grid ────────────────────────────────────────────────────────

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.current,
    required this.sparklineAsync,
  });

  final MonthlyTotal current;
  final AsyncValue<List<DailySpending>> sparklineAsync;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final cs = context.colors;

    // Daily average: current month expense / days elapsed.
    final daysElapsed = DateTime.now().day;
    final dailyAvg = current.expense > 0 ? current.expense ~/ daysElapsed : 0;

    // Savings rate.
    final savingsRate = current.income > 0
        ? ((current.income - current.expense) * 100) ~/ current.income
        : 0;

    // Highest day from sparkline data.
    final dailyData = sparklineAsync.valueOrNull ?? [];
    final highestDay = dailyData.isNotEmpty
        ? dailyData.reduce((a, b) => a.amount >= b.amount ? a : b)
        : null;

    // Transaction count: sum of non-zero days as proxy.
    final txCount = dailyData.where((d) => d.amount > 0).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryGridCard(
                  icon: AppIcons.calendar,
                  label: context.l10n.reports_daily_average,
                  value: MoneyFormatter.formatAmount(dailyAvg),
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _SummaryGridCard(
                  icon: AppIcons.expense,
                  label: context.l10n.reports_highest_day,
                  value: highestDay != null && highestDay.amount > 0
                      ? MoneyFormatter.formatAmount(highestDay.amount)
                      : '\u2014',
                  color: theme.expenseColor,
                  subtitle: highestDay != null && highestDay.amount > 0
                      ? DateFormat.MMMd(context.languageCode)
                          .format(highestDay.date)
                      : null,
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
                  label: context.l10n.reports_savings_rate(savingsRate),
                  value: '${savingsRate >= 0 ? '' : ''}$savingsRate%',
                  color:
                      savingsRate >= 0 ? theme.incomeColor : theme.expenseColor,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: _SummaryGridCard(
                  icon: AppIcons.transactions,
                  label: context.l10n.reports_transactions_count,
                  value: txCount > 0 ? '$txCount' : '\u2014',
                  color: cs.primary,
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
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? subtitle;

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
            value,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.xxs),
            Text(
              subtitle!,
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colors.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
