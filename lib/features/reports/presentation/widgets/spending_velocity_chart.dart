import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Cumulative area chart showing spending pace with a projected dashed line
/// extending to the end of the month at the current daily average rate.
class SpendingVelocityChart extends StatelessWidget {
  const SpendingVelocityChart({
    super.key,
    required this.dailyData,
    required this.isIncome,
  });

  /// Daily spending entries — expected to be sorted by date ascending.
  final List<DailySpending> dailyData;

  /// When `true`, uses income colour; otherwise expense colour.
  final bool isIncome;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final lineColor = isIncome ? theme.incomeColor : theme.expenseColor;

    // ── Compute cumulative totals (int piastres — Rule #1) ───────────
    // Money must stay integer piastres. Previously this used a double
    // accumulator; at realistic data scales doubles are exact, but the
    // principle matters — every other money code path uses int.
    // Conversion to double happens only at the FlSpot boundary.
    final cumulative = <int>[];
    var runningTotal = 0;
    for (final d in dailyData) {
      runningTotal += d.amount;
      cumulative.add(runningTotal);
    }

    final totalAmount = runningTotal;
    final daysWithData = dailyData.length;
    final dailyAverage = daysWithData > 0 ? totalAmount ~/ daysWithData : 0;

    // ── Actual spots ──────────────────────────────────────────────────
    final actualSpots = List.generate(cumulative.length, (i) {
      return FlSpot(i.toDouble(), cumulative[i].toDouble());
    });

    // ── Projection spots (extend from last actual point to day 30) ────
    const projectedEnd = 30;
    final projectionSpots = <FlSpot>[];
    if (daysWithData > 0 && daysWithData < projectedEnd) {
      final lastCumulative = cumulative.last;

      // Start projection from the last actual data point.
      projectionSpots.add(
        FlSpot((daysWithData - 1).toDouble(), lastCumulative.toDouble()),
      );
      // End projection at day 30 using integer daily average to stay honest.
      final projectedTotal =
          lastCumulative + dailyAverage * (projectedEnd - daysWithData);
      projectionSpots.add(
        FlSpot((projectedEnd - 1).toDouble(), projectedTotal.toDouble()),
      );
    }

    // ── Compute max Y ────────────────────────────────────────────────
    final allValues = <int>[
      ...cumulative,
      if (projectionSpots.isNotEmpty) projectionSpots.last.y.round(),
    ];
    final maxY = allValues.fold<int>(0, (s, v) => v > s ? v : s) * 1.15;
    final effectiveMaxY = maxY > 0 ? maxY : 100000.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section title ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: Text(
            context.l10n.reports_spending_pace,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // ── Chart ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: GlassCard(
            tier: GlassTier.inset,
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSizes.sm,
              AppSizes.md,
              AppSizes.md,
              AppSizes.sm,
            ),
            child: Column(
              children: [
                Semantics(
                  label: context.l10n.semantics_spending_velocity_chart,
                  child: RepaintBoundary(
                    child: SizedBox(
                      height: AppSizes.velocityChartHeight,
                      child: LineChart(
                        LineChartData(
                          maxY: effectiveMaxY,
                          minY: 0,
                          clipData: const FlClipData.all(),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) {
                                return spots.map((spot) {
                                  final baseStyle =
                                      context.textStyles.bodySmall ??
                                          const TextStyle();
                                  return LineTooltipItem(
                                    MoneyFormatter.formatAmount(
                                      spot.y.round(),
                                    ),
                                    baseStyle.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
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
                                  final day = value.toInt() + 1;
                                  if (day != 1 &&
                                      day != 7 &&
                                      day != 14 &&
                                      day != 21 &&
                                      day != 28) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppSizes.xs,
                                    ),
                                    child: Text(
                                      '$day',
                                      style: context.textStyles.labelSmall
                                          ?.copyWith(
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
                            horizontalInterval: effectiveMaxY / 3,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: cs.outlineVariant,
                              strokeWidth: 0.5,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            // Actual cumulative line (solid, with area fill).
                            LineChartBarData(
                              spots: actualSpots,
                              isCurved: true,
                              preventCurveOverShooting: true,
                              color: lineColor,
                              barWidth: 2.5,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: lineColor.withValues(
                                  alpha: AppSizes.opacityXLight,
                                ),
                              ),
                            ),

                            // Projection dashed line (gray, no fill).
                            if (projectionSpots.isNotEmpty)
                              LineChartBarData(
                                spots: projectionSpots,
                                isCurved: true,
                                color: cs.outline,
                                barWidth: 1.5,
                                dashArray: [5, 5],
                                dotData: const FlDotData(show: false),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),

                // ── Pace label ─────────────────────────────────────────
                Text(
                  context.l10n.reports_pace_label(
                    MoneyFormatter.format(dailyAverage),
                  ),
                  style: context.textStyles.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
