import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// GitHub-style 5x7 calendar heatmap showing daily spending intensity.
///
/// Displays the last 35 days of data in a grid of 7 columns (one per weekday)
/// and 5 rows (one per week). Cell colour interpolates from the surface colour
/// (zero spending) to the expense/income semantic colour (maximum spending).
class SpendingHeatmap extends StatelessWidget {
  const SpendingHeatmap({
    super.key,
    required this.dailyData,
    required this.isExpense,
  });

  /// Daily spending entries — expected to be sorted by date ascending.
  final List<DailySpending> dailyData;

  /// When `true`, uses expense colour for the hot end of the scale;
  /// otherwise uses income colour.
  final bool isExpense;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final hotColor = isExpense ? theme.expenseColor : theme.incomeColor;

    // Take the last 35 entries (5 full weeks).
    final entries = dailyData.length > 35
        ? dailyData.sublist(dailyData.length - 35)
        : dailyData;

    // Compute normalisation ceiling.
    final maxAmount = entries.fold<int>(0, (s, d) => math.max(s, d.amount));

    return Semantics(
      label: context.l10n.semantics_spending_heatmap(dailyData.length),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section title ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.calendar,
                  size: AppSizes.iconSm,
                  color: cs.onSurfaceVariant,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  context.l10n.reports_daily_activity,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Heatmap grid ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: GlassCard(
              tier: GlassTier.inset,
              padding: const EdgeInsets.all(AppSizes.sm),
              child: Column(
                children: [
                  // Day-of-week labels
                  _DayLabelsRow(cs: cs),
                  const SizedBox(height: AppSizes.xs),

                  // 5-row x 7-column grid
                  _HeatmapGrid(
                    entries: entries,
                    maxAmount: maxAmount,
                    coldColor: cs.surfaceContainerHighest,
                    hotColor: hotColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day labels row ──────────────────────────────────────────────────────────

class _DayLabelsRow extends StatelessWidget {
  const _DayLabelsRow({required this.cs});

  final ColorScheme cs;

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _labels.map((label) {
        return SizedBox(
          width: AppSizes.heatmapCellSize,
          child: Center(
            child: Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 5x7 heatmap grid ───────────────────────────────────────────────────────

class _HeatmapGrid extends StatelessWidget {
  const _HeatmapGrid({
    required this.entries,
    required this.maxAmount,
    required this.coldColor,
    required this.hotColor,
  });

  final List<DailySpending> entries;
  final int maxAmount;
  final Color coldColor;
  final Color hotColor;

  @override
  Widget build(BuildContext context) {
    // Pad entries so the grid always has exactly 35 cells.
    // Leading cells (before data) are shown as "zero".
    final padded = List<int>.filled(35, 0);
    final offset = 35 - entries.length;
    for (var i = 0; i < entries.length; i++) {
      padded[offset + i] = entries[i].amount;
    }

    // Build 5 rows of 7 cells.
    return Column(
      children: List.generate(5, (row) {
        return Padding(
          padding: EdgeInsets.only(
            top: row > 0 ? AppSizes.heatmapCellGap : AppSizes.none,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final idx = row * 7 + col;
              final amount = padded[idx];
              final normalized =
                  maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;

              final cellColor = Color.lerp(
                coldColor,
                hotColor,
                normalized,
              )!;

              return Tooltip(
                message: amount > 0 ? MoneyFormatter.formatCompact(amount) : '',
                child: Container(
                  width: AppSizes.heatmapCellSize,
                  height: AppSizes.heatmapCellSize,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(
                      AppSizes.heatmapCellRadius,
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
