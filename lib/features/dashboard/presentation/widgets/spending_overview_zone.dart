import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Zone 4: Spending overview donut chart — watches only monthTxs + categories.
///
/// When [filterWalletId] is non-null, only expenses for that account
/// are shown.
class SpendingOverviewZone extends ConsumerWidget {
  const SpendingOverviewZone({super.key, this.filterWalletId});

  /// When set, only expenses with this walletId are displayed.
  final int? filterWalletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final monthTxs = ref.watch(transactionsByMonthProvider(monthKey));
    final categories = ref.watch(categoriesProvider);

    return monthTxs.when(
      data: (txList) {
        final allExpenses =
            txList.where((tx) => tx.type == 'expense');
        final expenses = filterWalletId != null
            ? allExpenses
                .where((tx) => tx.walletId == filterWalletId)
                .toList()
            : allExpenses.toList();
        if (expenses.isEmpty) return const SizedBox.shrink();

        final catList = categories.valueOrNull ?? [];
        final breakdown = _categoryBreakdown(context, expenses, catList);
        if (breakdown.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.sectionGap),
            _SpendingOverview(breakdown: breakdown),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: EmptyState(title: context.l10n.dashboard_failed_spending),
      ),
    );
  }

  static List<_CategorySlice> _categoryBreakdown(
    BuildContext context,
    List<TransactionEntity> expenses,
    List<CategoryEntity> catList,
  ) {
    final byCategory = <int, int>{};
    for (final tx in expenses) {
      byCategory[tx.categoryId] =
          (byCategory[tx.categoryId] ?? 0) + tx.amount;
    }

    final sorted = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalPiastres = sorted.fold<int>(0, (s, e) => s + e.value);
    if (totalPiastres == 0) return [];

    final categoryMap = {for (final c in catList) c.id: c};
    final slices = <_CategorySlice>[];
    var otherAmount = 0;

    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      if (i < 5) {
        final cat = categoryMap[entry.key];
        slices.add(
          _CategorySlice(
            name: cat != null ? cat.displayName(context.languageCode) : '?',
            piastres: entry.value,
            color: cat != null
                ? ColorUtils.fromHex(cat.colorHex)
                : context.colors.outline,
            fraction: entry.value / totalPiastres,
          ),
        );
      } else {
        otherAmount += entry.value;
      }
    }

    if (otherAmount > 0) {
      slices.add(
        _CategorySlice(
          name: context.l10n.dashboard_other_category,
          piastres: otherAmount,
          color: context.colors.outline,
          fraction: otherAmount / totalPiastres,
        ),
      );
    }
    return slices;
  }
}

// ── Category slice data ──────────────────────────────────────────────────

class _CategorySlice {
  const _CategorySlice({
    required this.name,
    required this.piastres,
    required this.color,
    required this.fraction,
  });
  final String name;
  final int piastres;
  final Color color;
  final double fraction;
}

// ── Spending Overview (donut chart) ──────────────────────────────────────

class _SpendingOverview extends StatefulWidget {
  const _SpendingOverview({required this.breakdown});
  final List<_CategorySlice> breakdown;

  @override
  State<_SpendingOverview> createState() => _SpendingOverviewState();
}

class _SpendingOverviewState extends State<_SpendingOverview> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.breakdown.fold<int>(0, (s, e) => s + e.piastres);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
            vertical: AppSizes.xs,
          ),
          child: Text(
            context.l10n.dashboard_spending_overview,
            style: context.textStyles.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        GlassCard(
          showShadow: true,
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
          child: Column(
            children: [
              SizedBox(
                height: AppSizes.chartHeightMd,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: widget.breakdown.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          final isTouched = i == _touchedIndex;
                          return PieChartSectionData(
                            value: s.piastres.toDouble(),
                            color: s.color,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [s.color, s.color.withValues(alpha: AppSizes.opacityStrong)],
                            ),
                            radius: isTouched
                                ? AppSizes.pieChartRadius + 6
                                : AppSizes.pieChartRadius,
                            showTitle: false,
                          );
                        }).toList(),
                        pieTouchData: PieTouchData(
                          touchCallback: (event, response) {
                            if (event.isInterestedForInteractions) {
                              setState(() {
                                _touchedIndex =
                                    response?.touchedSection?.touchedSectionIndex ?? -1;
                              });
                            } else {
                              setState(() => _touchedIndex = -1);
                            }
                          },
                        ),
                        sectionsSpace: AppSizes.pieChartSectionSpace,
                        centerSpaceRadius: AppSizes.pieChartCenterRadius,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          MoneyFormatter.formatCompact(total),
                          style: context.textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          context.l10n.dashboard_total,
                          style: context.textStyles.bodySmall?.copyWith(
                                color: context.colors.outline,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.md,
                runSpacing: AppSizes.xs,
                children: widget.breakdown.map((s) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppSizes.dotMd,
                        height: AppSizes.dotMd,
                        decoration: BoxDecoration(
                          color: s.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Text(
                        '${s.name} ${(s.fraction * 100).round()}%',
                        style: context.textStyles.bodySmall,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
