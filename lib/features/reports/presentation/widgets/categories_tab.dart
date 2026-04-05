import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/budget_entity.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Categories tab — donut chart + ranked list of expense categories.
class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectedMonth = ref.watch(reportsCategoryMonthProvider);
    final breakdownAsync = ref.watch(categoryBreakdownProvider(selectedMonth));
    final budgets =
        ref.watch(budgetsByMonthProvider(selectedMonth)).valueOrNull ?? [];
    final budgetByCategoryId = {for (final b in budgets) b.categoryId: b};

    return breakdownAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => EmptyState(
        title: context.l10n.common_error_title,
        ctaLabel: context.l10n.common_retry,
        onCta: () => ref.invalidate(
          transactionsByMonthProvider(selectedMonth),
        ),
      ),
      data: (breakdown) {
        if (breakdown.isEmpty) {
          return EmptyState(
            title: context.l10n.reports_empty_title,
            subtitle: context.l10n.reports_empty_sub,
          );
        }

        final totalExpense = breakdown.fold<int>(0, (s, e) => s + e.amount);

        return ListView(
          padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          children: [
            // ── Hero Section ──────────────────────────────────────────
            const SizedBox(height: AppSizes.md),
            Center(
              child: Text(
                context.l10n.reports_top_categories,
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.outline,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Center(
              child: Text(
                MoneyFormatter.format(totalExpense),
                style: context.textStyles.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.appTheme.expenseColor,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Month Navigator ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      context.isRtl
                          ? AppIcons.chevronRight
                          : AppIcons.chevronLeft,
                      color: context.colors.outline,
                    ),
                    tooltip: context.l10n.month_previous,
                    onPressed: () {
                      final (y, m) = selectedMonth;
                      final prev = m == 1 ? (y - 1, 12) : (y, m - 1);
                      ref.read(reportsCategoryMonthProvider.notifier).state =
                          prev;
                    },
                  ),
                  Text(
                    DateFormat.yMMMM(context.languageCode).format(
                      DateTime(selectedMonth.$1, selectedMonth.$2),
                    ),
                    style: context.textStyles.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(
                      context.isRtl
                          ? AppIcons.chevronLeft
                          : AppIcons.chevronRight,
                      color: context.colors.outline,
                    ),
                    tooltip: context.l10n.month_next,
                    onPressed: () {
                      final now = DateTime.now();
                      final (y, m) = selectedMonth;
                      if (y >= now.year && m >= now.month) return;
                      final next = m == 12 ? (y + 1, 1) : (y, m + 1);
                      ref.read(reportsCategoryMonthProvider.notifier).state =
                          next;
                    },
                  ),
                ],
              ),
            ),

            // ── Donut Chart ───────────────────────────────────────────
            const SizedBox(height: AppSizes.sm),
            Center(
              child: SizedBox(
                height: AppSizes.chartHeightSm,
                width: AppSizes.chartHeightSm,
                child: RepaintBoundary(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 50,
                          sectionsSpace: 2,
                          sections: breakdown.map((cat) {
                            return PieChartSectionData(
                              value: cat.amount.toDouble(),
                              radius: 16,
                              showTitle: false,
                              color: ColorUtils.fromHex(cat.colorHex),
                            );
                          }).toList(),
                          borderData: FlBorderData(show: false),
                        ),
                      ),
                      Text(
                        context.l10n.reportsCategoryCount(breakdown.length),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Ranked Category List ──────────────────────────────────
            ...List.generate(breakdown.length, (i) {
              final cat = breakdown[i];
              return _CategoryRow(
                spending: cat,
                budget: budgetByCategoryId[cat.categoryId],
              );
            }),
          ],
        );
      },
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.spending,
    this.budget,
  });

  final CategorySpending spending;
  final BudgetEntity? budget;

  @override
  Widget build(BuildContext context) {
    final catColor = ColorUtils.fromHex(spending.colorHex);
    final hasBudget = budget != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color dot
          Container(
            width: AppSizes.iconXxs,
            height: AppSizes.iconXxs,
            margin: const EdgeInsets.only(top: AppSizes.xs),
            decoration: BoxDecoration(
              color: catColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + amount row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spending.categoryName,
                        style: context.textStyles.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      MoneyFormatter.format(spending.amount),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xxs),

                // Percentage
                Text(
                  '${(spending.fraction * 100).toStringAsFixed(1)}%',
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: catColor,
                  ),
                ),
                const SizedBox(height: AppSizes.xxs),

                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusXs),
                  child: LinearProgressIndicator(
                    value: spending.fraction,
                    color: catColor,
                    backgroundColor: context.colors.surfaceContainerHigh,
                    minHeight: 4,
                  ),
                ),

                // Budget label (if exists)
                if (hasBudget) ...[
                  const SizedBox(height: AppSizes.xxs),
                  Text(
                    context.l10n.reportsBudgetLabel(
                      MoneyFormatter.format(budget!.limitAmount),
                    ),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
