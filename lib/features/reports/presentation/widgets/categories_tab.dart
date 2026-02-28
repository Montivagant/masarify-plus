import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Categories tab — horizontal bar chart + ranked list of expense categories.
class CategoriesTab extends ConsumerWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final txAsync =
        ref.watch(transactionsByMonthProvider((now.year, now.month)));

    return txAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(
        child: Text(context.l10n.common_error_generic),
      ),
      data: (transactions) {
        final breakdown = ref.read(
          categoryBreakdownProvider((now.year, now.month, transactions)),
        );

        if (breakdown.isEmpty) {
          return EmptyState(
            title: context.l10n.reports_empty_title,
            subtitle: context.l10n.reports_empty_sub,
          );
        }

        final totalExpense =
            breakdown.fold<int>(0, (s, e) => s + e.amount);

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          children: [
            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSizes.screenHPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.reports_top_categories,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    MoneyFormatter.format(totalExpense),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.appTheme.expenseColor,
                        ),
                  ),
                ],
              ),
            ),

            // ── Horizontal bar chart ───────────────────────────────
            SizedBox(
              height: breakdown.length * 48.0 + 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: _CategoryHorizontalBarChart(breakdown: breakdown),
              ),
            ),

            Divider(height: AppSizes.dividerHeight, color: Theme.of(context).colorScheme.outlineVariant),

            // ── Ranked list ────────────────────────────────────────
            ...List.generate(breakdown.length, (i) {
              final cat = breakdown[i];
              return _CategoryRow(
                rank: i + 1,
                spending: cat,
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Horizontal bar chart ──────────────────────────────────────────────────

class _CategoryHorizontalBarChart extends StatelessWidget {
  const _CategoryHorizontalBarChart({required this.breakdown});

  final List<CategorySpending> breakdown;

  @override
  Widget build(BuildContext context) {
    final maxAmount =
        breakdown.fold<int>(0, (s, e) => e.amount > s ? e.amount : s);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxAmount * 1.15,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              final idx = group.x;
              final name = idx >= 0 && idx < breakdown.length
                  ? breakdown[idx].categoryName
                  : '';
              return BarTooltipItem(
                '$name\n${MoneyFormatter.format(rod.toY.toInt())}',
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
          bottomTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= breakdown.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(
                    breakdown[idx].categoryName,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(breakdown.length, (i) {
          final cat = breakdown[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: cat.amount.toDouble(),
                color: ColorUtils.fromHex(cat.colorHex),
                width: AppSizes.md,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(AppSizes.borderRadiusXs),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.rank,
    required this.spending,
  });

  final int rank;
  final CategorySpending spending;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(spending.colorHex);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSizes.lg,
            child: Text(
              context.l10n.reports_category_rank(rank),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            width: AppSizes.colorSwatchSize,
            height: AppSizes.colorSwatchSize,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppSizes.opacityLight),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: Icon(
              CategoryIconMapper.fromName(spending.iconName),
              size: AppSizes.iconSm,
              color: color,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spending.categoryName,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xxs),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusXs),
                  child: LinearProgressIndicator(
                    value: spending.fraction,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withValues(alpha: AppSizes.opacityLight3),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyFormatter.formatAmount(spending.amount),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(
                '${(spending.fraction * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
