import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Trends tab — line chart with 7d / 30d / 90d toggle.
class TrendsTab extends ConsumerStatefulWidget {
  const TrendsTab({super.key});

  @override
  ConsumerState<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends ConsumerState<TrendsTab> {
  int _selectedDays = 30;

  @override
  Widget build(BuildContext context) {
    final dailyAsync = ref.watch(dailySpendingProvider(_selectedDays));

    return Column(
      children: [
        // ── Period selector ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(AppSizes.screenHPadding),
          child: SegmentedButton<int>(
            segments: [
              ButtonSegment(
                value: 7,
                label: Text(context.l10n.reports_period_7d),
              ),
              ButtonSegment(
                value: 30,
                label: Text(context.l10n.reports_period_30d),
              ),
              ButtonSegment(
                value: 90,
                label: Text(context.l10n.reports_period_90d),
              ),
            ],
            selected: {_selectedDays},
            onSelectionChanged: (val) {
              setState(() => _selectedDays = val.first);
            },
            showSelectedIcon: false,
          ),
        ),

        // ── Chart ──────────────────────────────────────────────
        Expanded(
          child: dailyAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
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

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: _SpendingLineChart(
                  data: dailyData,
                  days: _selectedDays,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Spending line chart ───────────────────────────────────────────────────

class _SpendingLineChart extends StatelessWidget {
  const _SpendingLineChart({
    required this.data,
    required this.days,
  });

  final List<DailySpending> data;
  final int days;

  @override
  Widget build(BuildContext context) {
    final maxAmount = data.fold<int>(0, (s, e) => e.amount > s ? e.amount : s);
    final maxY = maxAmount > 0 ? maxAmount * 1.2 : 100.0;

    final spots = List.generate(data.length, (i) {
      return FlSpot(i.toDouble(), data[i].amount.toDouble());
    });

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
                final baseStyle = context.textStyles.bodySmall ?? const TextStyle();
                return LineTooltipItem(
                  '${d.date.day}/${d.date.month}\n',
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
              interval: days <= 7 ? 1 : (days <= 30 ? 7 : 15),
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xs),
                  child: Text(
                    '${data[idx].date.day}/${data[idx].date.month}',
                    style: context.textStyles.bodySmall?.copyWith(
                          fontSize: AppSizes.chartLabelSize,
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
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: AppSizes.opacityMedium),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: context.appTheme.expenseColor,
            barWidth: 3.0, // WS-9: thicker line
            shadow: Shadow(
              color: context.appTheme.expenseColor.withValues(alpha: AppSizes.opacityLight4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            dotData: FlDotData(
              show: days <= 7,
              getDotPainter: (spot, percent, bar, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: context.appTheme.expenseColor,
                strokeWidth: 2,
                strokeColor: context.colors.surface,
              ),
            ),
            // WS-9: gradient area fill (0.25→0.0 alpha)
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appTheme.expenseColor.withValues(alpha: AppSizes.opacityQuarter),
                  context.appTheme.expenseColor.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
