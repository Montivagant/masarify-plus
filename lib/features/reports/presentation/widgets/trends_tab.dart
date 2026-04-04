import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Whether the chart should use income color instead of expense.
bool _isIncomeFilter(WidgetRef ref) =>
    ref.watch(reportsTypeFilterProvider) == 'income';

/// Trends tab — line chart with 7d / 30d / 90d pill chip toggle,
/// hero total, and summary cards.
class TrendsTab extends ConsumerStatefulWidget {
  const TrendsTab({super.key});

  @override
  ConsumerState<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends ConsumerState<TrendsTab>
    with AutomaticKeepAliveClientMixin {
  int _selectedDays = 30;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dailyAsync = ref.watch(dailySpendingProvider(_selectedDays));
    final isIncome = _isIncomeFilter(ref);

    return Column(
      children: [
        // ── Period selector (pill chips) ──────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSizes.screenHPadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PeriodChip(
                label: context.l10n.reports_period_7d,
                value: 7,
                selected: _selectedDays == 7,
                onSelected: () => setState(() => _selectedDays = 7),
              ),
              const SizedBox(width: AppSizes.sm),
              _PeriodChip(
                label: context.l10n.reports_period_30d,
                value: 30,
                selected: _selectedDays == 30,
                onSelected: () => setState(() => _selectedDays = 30),
              ),
              const SizedBox(width: AppSizes.sm),
              _PeriodChip(
                label: context.l10n.reports_period_90d,
                value: 90,
                selected: _selectedDays == 90,
                onSelected: () => setState(() => _selectedDays = 90),
              ),
            ],
          ),
        ),

        // ── Content ──────────────────────────────────────────────────
        Expanded(
          child: dailyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Text(context.l10n.common_error_generic),
            ),
            data: (dailyData) {
              final hasData = dailyData.any((d) => d.amount > 0);
              if (!hasData) {
                return EmptyState(
                  title: context.l10n.reports_no_data,
                );
              }

              return _TrendsContent(
                data: dailyData,
                days: _selectedDays,
                isIncome: isIncome,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Period chip ────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int value;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      selectedColor: context.colors.primary,
      labelStyle: context.textStyles.labelMedium?.copyWith(
        color: selected ? context.colors.onPrimary : context.colors.onSurface,
      ),
      backgroundColor: context.colors.surfaceContainerHighest,
    );
  }
}

// ── Trends content (hero + chart + summary cards) ─────────────────────────

class _TrendsContent extends StatelessWidget {
  const _TrendsContent({
    required this.data,
    required this.days,
    required this.isIncome,
  });

  final List<DailySpending> data;
  final int days;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final lineColor =
        isIncome ? context.appTheme.incomeColor : context.appTheme.expenseColor;

    // Compute aggregate values.
    final total = data.fold<int>(0, (sum, d) => sum + d.amount);
    final maxDay = data.reduce((a, b) => a.amount >= b.amount ? a : b);

    // Compute previous-period comparison.
    // The previous period is the [days] days immediately before the current
    // range.  Since the provider only returns the current window, we
    // approximate by splitting the data in half: second half is "current",
    // first half is "previous".
    final halfLen = data.length ~/ 2;
    final prevTotal =
        data.sublist(0, halfLen).fold<int>(0, (s, d) => s + d.amount);
    final currTotal =
        data.sublist(halfLen).fold<int>(0, (s, d) => s + d.amount);

    // Percentage change: positive = increase, negative = decrease.
    final double changePct;
    if (prevTotal > 0) {
      changePct = ((currTotal - prevTotal) / prevTotal) * 100;
    } else {
      changePct = currTotal > 0 ? 100 : 0;
    }

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(
        start: AppSizes.screenHPadding,
        end: AppSizes.screenHPadding,
        bottom: AppSizes.bottomScrollPadding,
      ),
      child: Column(
        children: [
          // ── Hero section ────────────────────────────────────────
          _HeroSection(
            total: total,
            changePct: changePct,
            lineColor: lineColor,
            isIncome: isIncome,
          ),
          const SizedBox(height: AppSizes.md),

          // ── Line chart ─────────────────────────────────────────
          RepaintBoundary(
            child: SizedBox(
              height: AppSizes.chartHeightMd,
              child: _SpendingLineChart(
                data: data,
                days: days,
                isIncome: isIncome,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Summary cards ──────────────────────────────────────
          _SummaryCards(
            total: total,
            days: days,
            maxDay: maxDay,
          ),
        ],
      ),
    );
  }
}

// ── Hero section ──────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.total,
    required this.changePct,
    required this.lineColor,
    required this.isIncome,
  });

  final int total;
  final double changePct;
  final Color lineColor;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    // For expenses: increase (positive %) is worse (red), decrease is better (green).
    // For income: increase is better (green), decrease is worse (red).
    final isPositiveChange = changePct >= 0;
    final isBetter = isIncome ? isPositiveChange : !isPositiveChange;
    final badgeColor =
        isBetter ? context.appTheme.incomeColor : context.appTheme.expenseColor;
    final arrow = isPositiveChange ? '\u2191' : '\u2193';

    return Column(
      children: [
        Text(
          context.l10n.reports_total_spending,
          style: context.textStyles.labelLarge?.copyWith(
            color: context.colors.outline,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          MoneyFormatter.format(total),
          style: context.textStyles.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: lineColor,
          ),
        ),
        if (changePct != 0) ...[
          const SizedBox(height: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: AppSizes.opacityLight2),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
            ),
            child: Text(
              '$arrow ${changePct.abs().toStringAsFixed(0)}% ${context.l10n.reports_vs_previous}',
              style: context.textStyles.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Spending line chart ───────────────────────────────────────────────────

class _SpendingLineChart extends StatelessWidget {
  const _SpendingLineChart({
    required this.data,
    required this.days,
    this.isIncome = false,
  });

  final List<DailySpending> data;
  final int days;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final chartColor =
        isIncome ? context.appTheme.incomeColor : context.appTheme.expenseColor;
    final maxAmount = data.fold<int>(0, (s, e) => e.amount > s ? e.amount : s);
    final maxY = maxAmount > 0 ? maxAmount * 1.2 : 100000.0; // 10 EGP floor

    final spots = List.generate(data.length, (i) {
      return FlSpot(i.toDouble(), data[i].amount.toDouble());
    });

    final lastIndex = data.length - 1;

    // Compute 2 evenly-spaced horizontal grid line values.
    final gridInterval = maxY / 3;

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              final tooltipColor = context.colors.onSurfaceVariant;
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final d = data[idx];
                final baseStyle =
                    context.textStyles.bodySmall ?? const TextStyle();
                return LineTooltipItem(
                  '${DateFormat.MMMd(context.languageCode).format(d.date)}\n',
                  baseStyle.copyWith(color: tooltipColor),
                  children: [
                    TextSpan(
                      text: MoneyFormatter.formatAmount(d.amount),
                      style: baseStyle.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                );
              }).toList();
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
              interval: 7,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xs),
                  child: Text(
                    DateFormat('MMM d', context.languageCode)
                        .format(data[idx].date),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
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
          checkToShowHorizontalLine: (value) {
            // Show only the 2 middle lines (1/3 and 2/3).
            if (gridInterval <= 0) return false;
            final normalized = value / gridInterval;
            return (normalized - 1).abs() < 0.01 ||
                (normalized - 2).abs() < 0.01;
          },
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.colors.outlineVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: chartColor,
            dotData: FlDotData(
              checkToShowDot: (spot, barData) => spot.x.toInt() == lastIndex,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: AppSizes.chartDotRadius + 1,
                color: chartColor,
                strokeWidth: AppSizes.chartDotStrokeWidth,
                strokeColor: context.colors.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withValues(alpha: AppSizes.opacityXLight2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary cards ─────────────────────────────────────────────────────────

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({
    required this.total,
    required this.days,
    required this.maxDay,
  });

  final int total;
  final int days;
  final DailySpending maxDay;

  @override
  Widget build(BuildContext context) {
    final dailyAverage = days > 0 ? total ~/ days : 0;

    return Row(
      children: [
        // ── Daily Average card ────────────────────────────────────
        Expanded(
          child: GlassCard(
            tier: GlassTier.inset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.reports_daily_average,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  MoneyFormatter.format(dailyAverage),
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),

        // ── Highest Day card ─────────────────────────────────────
        Expanded(
          child: GlassCard(
            tier: GlassTier.inset,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.reports_highest_day,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  MoneyFormatter.format(maxDay.amount),
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  DateFormat.MMMd(context.languageCode).format(maxDay.date),
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
