import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import 'spending_heatmap.dart';
import 'spending_velocity_chart.dart';
import 'tab_filter_row.dart';

/// Trends tab — full redesign with filter row, hero metric, main area chart
/// with previous-period comparison, velocity chart, summary row, heatmap,
/// and weekly breakdown.
class TrendsTab extends ConsumerStatefulWidget {
  const TrendsTab({super.key});

  @override
  ConsumerState<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends ConsumerState<TrendsTab>
    with AutomaticKeepAliveClientMixin {
  // ── Local filter state ──────────────────────────────────────────────────
  String _timePreset = '30_days'; // '7_days', '30_days', '90_days', 'custom'
  String _typeFilter = 'expense';
  int? _walletId;
  DateTimeRange? _customRange;

  @override
  bool get wantKeepAlive => true;

  /// Resolved day count from the active preset.
  int get _days => switch (_timePreset) {
        '7_days' => 7,
        '30_days' => 30,
        '90_days' => 90,
        'custom' => _customRange != null
            ? _customRange!.end.difference(_customRange!.start).inDays + 1
            : 30,
        _ => 30,
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ── Provider params ──────────────────────────────────────────────────
    final typeParam = _typeFilter == 'all' ? null : _typeFilter;
    final currentParams = (
      days: _days,
      walletId: _walletId,
      typeFilter: typeParam,
    );
    // Fetch 2x days and split to get the previous period for comparison.
    final compParams = (
      days: _days * 2,
      walletId: _walletId,
      typeFilter: typeParam,
    );

    final dailyAsync = ref.watch(dailySpendingProvider(currentParams));
    final compAsync = ref.watch(dailySpendingProvider(compParams));

    return Column(
      children: [
        // ── Filter row ──────────────────────────────────────────────────
        TabFilterRow(
          timePreset: _timePreset,
          typeFilter: _typeFilter,
          walletId: _walletId,
          customRange: _customRange,
          timePresets: [
            (key: '7_days', label: (c) => c.l10n.reports_last_7_days),
            (key: '30_days', label: (c) => c.l10n.reports_last_30_days),
            (key: '90_days', label: (c) => c.l10n.reports_3_months),
          ],
          onFilterChanged: ({
            timePreset,
            typeFilter,
            walletId,
            clearWallet,
            customRange,
          }) {
            setState(() {
              if (timePreset != null) _timePreset = timePreset;
              if (typeFilter != null) _typeFilter = typeFilter;
              if (walletId != null) _walletId = walletId;
              if (clearWallet == true) _walletId = null;
              if (customRange != null) _customRange = customRange;
            });
          },
        ),

        // ── Content ─────────────────────────────────────────────────────
        Expanded(
          child: dailyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => EmptyState(
              title: context.l10n.common_error_title,
              ctaLabel: context.l10n.common_retry,
              onCta: () => ref.invalidate(dailySpendingProvider(currentParams)),
            ),
            data: (dailyData) {
              final hasData = dailyData.any((d) => d.amount > 0);
              if (!hasData) {
                return EmptyState(
                  title: context.l10n.reports_empty_title,
                );
              }

              // Split comparison data into previous and current halves.
              final compData = compAsync.valueOrNull ?? [];
              final halfLen = compData.length ~/ 2;
              final prevData = compData.length >= halfLen * 2
                  ? compData.sublist(0, halfLen)
                  : <DailySpending>[];

              return _TrendsBody(
                data: dailyData,
                prevData: prevData,
                days: _days,
                typeFilter: _typeFilter,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Trends body (scrollable content) ────────────────────────────────────────

class _TrendsBody extends StatelessWidget {
  const _TrendsBody({
    required this.data,
    required this.prevData,
    required this.days,
    required this.typeFilter,
  });

  final List<DailySpending> data;
  final List<DailySpending> prevData;
  final int days;
  final String typeFilter;

  @override
  Widget build(BuildContext context) {
    final isIncome = typeFilter == 'income';

    // ── Aggregate metrics ─────────────────────────────────────────────────
    final total = data.fold<int>(0, (s, d) => s + d.amount);
    final prevTotal = prevData.fold<int>(0, (s, d) => s + d.amount);
    final changePct =
        prevTotal > 0 ? ((total - prevTotal) * 100.0 / prevTotal) : 0.0;

    // Smart colouring: for expenses a decrease is good (green).
    final isBetter = isIncome ? changePct >= 0 : changePct <= 0;

    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.only(
        bottom: AppSizes.bottomScrollPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSizes.md),

          // 1. Hero metric ────────────────────────────────────────────────
          _HeroMetric(
            total: total,
            changePct: changePct,
            isBetter: isBetter,
            isIncome: isIncome,
          ),
          const SizedBox(height: AppSizes.lg),

          // 2. Main area chart ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: Semantics(
              label: context.l10n.semantics_spending_trend_chart(days),
              child: RepaintBoundary(
                child: SizedBox(
                  height: AppSizes.chartHeightMd,
                  child: _MainAreaChart(
                    data: data,
                    prevData: prevData,
                    isIncome: isIncome,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Legend row
          _ChartLegend(isIncome: isIncome),
          const SizedBox(height: AppSizes.lg),

          // 3. Spending velocity chart ────────────────────────────────────
          SpendingVelocityChart(
            dailyData: data,
            isIncome: isIncome,
          ),
          const SizedBox(height: AppSizes.lg),

          // 4. Summary row ────────────────────────────────────────────────
          _SummaryRow(data: data, total: total, days: days),
          const SizedBox(height: AppSizes.lg),

          // 5. Spending heatmap ───────────────────────────────────────────
          SpendingHeatmap(
            dailyData: data,
            isExpense: !isIncome,
          ),
          const SizedBox(height: AppSizes.lg),

          // 6. Weekly breakdown ───────────────────────────────────────────
          _WeeklyBreakdown(data: data, isIncome: isIncome),
        ],
      ),
    );
  }
}

// ── Hero metric ─────────────────────────────────────────────────────────────

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.total,
    required this.changePct,
    required this.isBetter,
    required this.isIncome,
  });

  final int total;
  final double changePct;
  final bool isBetter;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final lineColor = isIncome ? theme.incomeColor : theme.expenseColor;
    final badgeColor = isBetter ? theme.incomeColor : theme.expenseColor;
    final arrow = changePct >= 0 ? '\u2191' : '\u2193';

    return Column(
      children: [
        Text(
          isIncome
              ? context.l10n.reports_total_income_period
              : context.l10n.reports_total_expenses_period,
          style: context.textStyles.labelLarge?.copyWith(
            color: cs.outline,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          MoneyFormatter.format(total),
          style: context.textStyles.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: lineColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (changePct != 0) ...[
          const SizedBox(height: AppSizes.sm),
          Semantics(
            label: isBetter
                ? '${changePct.abs().toStringAsFixed(1)}% improvement versus previous period'
                : '${changePct.abs().toStringAsFixed(1)}% worse versus previous period',
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: AppSizes.opacityLight2),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
              ),
              child: Text(
                context.l10n.reports_vs_previous_pct(
                  arrow,
                  changePct.abs().toStringAsFixed(1),
                ),
                style: context.textStyles.labelSmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Main area chart with previous-period comparison ─────────────────────────

class _MainAreaChart extends StatelessWidget {
  const _MainAreaChart({
    required this.data,
    required this.prevData,
    required this.isIncome,
  });

  final List<DailySpending> data;
  final List<DailySpending> prevData;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final chartColor = isIncome ? theme.incomeColor : theme.expenseColor;

    // Current period spots.
    final spots = List.generate(data.length, (i) {
      return FlSpot(i.toDouble(), data[i].amount.toDouble());
    });

    // Previous period spots (aligned to same x-axis indices).
    final prevSpots = List.generate(prevData.length, (i) {
      return FlSpot(i.toDouble(), prevData[i].amount.toDouble());
    });

    // Compute max Y across both datasets.
    final allAmounts = [
      ...data.map((d) => d.amount),
      ...prevData.map((d) => d.amount),
    ];
    final maxAmount = allAmounts.fold<int>(0, (s, a) => math.max(s, a));
    final maxY = maxAmount > 0 ? maxAmount * 1.2 : 100000.0;
    final lastIndex = data.length - 1;

    return LineChart(
      LineChartData(
        maxY: maxY,
        minY: 0,
        clipData: const FlClipData.all(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final idx = spot.spotIndex;
                final baseStyle =
                    context.textStyles.bodySmall ?? const TextStyle();

                // Only show date for the current-period line (barIndex 0).
                if (spot.barIndex == 0 && idx < data.length) {
                  final d = data[idx];
                  return LineTooltipItem(
                    '${DateFormat.MMMd(context.languageCode).format(d.date)}\n',
                    baseStyle.copyWith(color: cs.onSurfaceVariant),
                    children: [
                      TextSpan(
                        text: MoneyFormatter.formatAmount(d.amount),
                        style: baseStyle.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  );
                }
                return LineTooltipItem(
                  MoneyFormatter.formatAmount(spot.y.round()),
                  baseStyle.copyWith(
                    color: cs.outline,
                    fontWeight: FontWeight.w600,
                  ),
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
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (_) => FlLine(
            color: cs.outlineVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          // Current period — solid line with area fill.
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: chartColor,
            barWidth: 2.5,
            dotData: FlDotData(
              checkToShowDot: (spot, barData) => spot.x.toInt() == lastIndex,
              getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                radius: AppSizes.chartDotRadius + 1,
                color: chartColor,
                strokeWidth: AppSizes.chartDotStrokeWidth,
                strokeColor: cs.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withValues(
                alpha: AppSizes.opacityLight,
              ),
            ),
          ),

          // Previous period — dashed gray line (no fill).
          if (prevSpots.isNotEmpty)
            LineChartBarData(
              spots: prevSpots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: cs.outline,
              barWidth: 1.5,
              dashArray: [5, 5],
              dotData: const FlDotData(show: false),
            ),
        ],
      ),
    );
  }
}

// ── Chart legend ────────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.isIncome});

  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final currentColor = isIncome ? theme.incomeColor : theme.expenseColor;
    final labelStyle = context.textStyles.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Solid dot — current period
        Container(
          width: AppSizes.dotSm,
          height: AppSizes.dotSm,
          decoration: BoxDecoration(
            color: currentColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(context.l10n.reports_current_period, style: labelStyle),
        const SizedBox(width: AppSizes.md),
        // Dashed indicator — previous period
        SizedBox(
          width: AppSizes.md,
          child: CustomPaint(
            size: const Size(AppSizes.md, 2),
            painter: _DashedLinePainter(color: cs.outline),
          ),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(context.l10n.reports_previous_period, style: labelStyle),
      ],
    );
  }
}

/// Paints a short dashed line for the legend indicator.
class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    const dashWidth = 4.0;
    const dashGap = 3.0;
    var x = 0.0;
    final y = size.height / 2;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dashWidth, size.width), y),
        paint,
      );
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}

// ── Summary row (3 metric cards) ────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.data,
    required this.total,
    required this.days,
  });

  final List<DailySpending> data;
  final int total;
  final int days;

  @override
  Widget build(BuildContext context) {
    final dailyAverage = days > 0 ? total ~/ days : 0;

    // Highest day.
    final highest = data.isNotEmpty
        ? data.reduce((a, b) => a.amount >= b.amount ? a : b)
        : null;

    // Lowest day (including zero-spend days).
    final lowest = data.isNotEmpty
        ? data.reduce((a, b) => a.amount <= b.amount ? a : b)
        : null;

    final dateFmt = DateFormat.MMMd(context.languageCode);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
      ),
      child: Row(
        children: [
          // Daily Average
          Expanded(
            child: _SummaryCard(
              label: context.l10n.reports_daily_average,
              value: MoneyFormatter.format(dailyAverage),
              subtitle: null,
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Highest Day
          Expanded(
            child: _SummaryCard(
              label: context.l10n.reports_highest_day,
              value:
                  highest != null ? MoneyFormatter.format(highest.amount) : '-',
              subtitle: highest != null ? dateFmt.format(highest.date) : null,
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // Lowest Day
          Expanded(
            child: _SummaryCard(
              label: context.l10n.reports_lowest_day,
              value:
                  lowest != null ? MoneyFormatter.format(lowest.amount) : '-',
              subtitle: lowest != null ? dateFmt.format(lowest.date) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return GlassCard(
      tier: GlassTier.inset,
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            value,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppSizes.xxs),
            Text(
              subtitle!,
              style: context.textStyles.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Weekly breakdown ────────────────────────────────────────────────────────

class _WeeklyBreakdown extends StatelessWidget {
  const _WeeklyBreakdown({
    required this.data,
    required this.isIncome,
  });

  final List<DailySpending> data;
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final barColor = isIncome ? theme.incomeColor : theme.expenseColor;

    // Group daily data into 7-day chunks.
    final weeks = <int>[];
    for (var i = 0; i < data.length; i += 7) {
      final end = (i + 7).clamp(0, data.length);
      final weekTotal =
          data.sublist(i, end).fold<int>(0, (s, d) => s + d.amount);
      weeks.add(weekTotal);
    }

    if (weeks.isEmpty) return const SizedBox.shrink();

    final maxWeek = weeks.fold<int>(0, (s, w) => math.max(s, w));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: Text(
            context.l10n.reports_weekly_breakdown,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // Bars
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: Column(
            children: List.generate(weeks.length, (i) {
              final fraction = maxWeek > 0 ? weeks[i] / maxWeek : 0.0;
              return Padding(
                padding: EdgeInsets.only(
                  top: i > 0 ? AppSizes.sm : AppSizes.none,
                ),
                child: Row(
                  children: [
                    // Week label
                    SizedBox(
                      width: AppSizes.weeklyLabelWidth,
                      child: Text(
                        context.l10n.reports_week_n(i + 1),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),

                    // Bar
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final reduceMotion = context.reduceMotion;
                          final barWidth = constraints.maxWidth * fraction;
                          return Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: AnimatedContainer(
                              duration: reduceMotion
                                  ? Duration.zero
                                  : AppDurations.chartBarAnim,
                              curve: Curves.easeOutCubic,
                              width: math.max(
                                barWidth,
                                AppSizes.weeklyBarMinWidth,
                              ),
                              height: AppSizes.weeklyBarHeight,
                              decoration: BoxDecoration(
                                color: barColor.withValues(
                                  alpha: AppSizes.opacityHeavy,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusXs,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),

                    // Amount label
                    Text(
                      MoneyFormatter.formatCompact(weeks[i]),
                      style: context.textStyles.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
