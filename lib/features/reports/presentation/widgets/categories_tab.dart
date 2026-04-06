import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/budget_entity.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import 'insight_card.dart';
import 'tab_filter_row.dart';

/// Categories tab — donut chart + ranked list of spending/income by category.
///
/// Uses [AutomaticKeepAliveClientMixin] to preserve scroll position and filter
/// state when the user switches between report tabs.
class CategoriesTab extends ConsumerStatefulWidget {
  const CategoriesTab({super.key});

  @override
  ConsumerState<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends ConsumerState<CategoriesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ── Local filter state ───────────────────────────────────────────────
  String _timePreset = 'this_month';
  String _typeFilter = 'expense';
  int? _walletId;
  DateTimeRange? _customRange;

  (int, int) get _selectedMonth {
    final now = DateTime.now();
    return switch (_timePreset) {
      'last_month' => (
          DateTime(now.year, now.month - 1).year,
          DateTime(now.year, now.month - 1).month,
        ),
      _ => (now.year, now.month),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final typeParam = _typeFilter == 'all' ? null : _typeFilter;
    final params = (
      year: _selectedMonth.$1,
      month: _selectedMonth.$2,
      walletId: _walletId,
      typeFilter: typeParam,
    );
    final breakdownAsync = ref.watch(categoryBreakdownProvider(params));
    final budgets = ref
            .watch(
              budgetsByMonthProvider((_selectedMonth.$1, _selectedMonth.$2)),
            )
            .valueOrNull ??
        [];
    final budgetByCategoryId = {for (final b in budgets) b.categoryId: b};

    // Previous month breakdown for delta badges.
    final prevMonth = DateTime(_selectedMonth.$1, _selectedMonth.$2 - 1);
    final prevParams = (
      year: prevMonth.year,
      month: prevMonth.month,
      walletId: _walletId,
      typeFilter: typeParam,
    );
    final prevBreakdown =
        ref.watch(categoryBreakdownProvider(prevParams)).valueOrNull ?? [];
    final prevByCategory = {
      for (final c in prevBreakdown) c.categoryId: c.amount,
    };

    final cs = context.colors;
    final isIncome = _typeFilter == 'income';

    return Column(
      children: [
        // ── Filter Row ─────────────────────────────────────────────────
        TabFilterRow(
          timePreset: _timePreset,
          typeFilter: _typeFilter,
          walletId: _walletId,
          customRange: _customRange,
          timePresets: [
            (key: 'this_month', label: (c) => c.l10n.reports_this_month),
            (key: 'last_month', label: (c) => c.l10n.reports_last_month),
          ],
          onFilterChanged: ({
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
          },
        ),

        // ── Body ───────────────────────────────────────────────────────
        Expanded(
          child: breakdownAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => EmptyState(
              title: context.l10n.common_error_title,
              ctaLabel: context.l10n.common_retry,
              onCta: () => ref.invalidate(categoryBreakdownProvider(params)),
            ),
            data: (breakdown) {
              if (breakdown.isEmpty) {
                return EmptyState(
                  title: context.l10n.reports_empty_title,
                  subtitle: context.l10n.reports_empty_sub,
                );
              }

              final totalAmount =
                  breakdown.fold<int>(0, (sum, cat) => sum + cat.amount);

              return ListView(
                padding: const EdgeInsets.only(
                  bottom: AppSizes.bottomScrollPadding,
                ),
                children: [
                  const SizedBox(height: AppSizes.lg),

                  // ── Hero Section ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenHPadding,
                    ),
                    child: Column(
                      children: [
                        Text(
                          isIncome
                              ? context.l10n.reports_income_by_category
                              : context.l10n.reports_spending_by_category,
                          style: context.textStyles.titleSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          MoneyFormatter.format(totalAmount),
                          style: context.textStyles.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: [const FontFeature.tabularFigures()],
                            color: isIncome
                                ? context.appTheme.incomeColor
                                : context.appTheme.expenseColor,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          context.l10n.reports_category_count(breakdown.length),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // ── Donut Chart ──────────────────────────────────────
                  Center(
                    child: Semantics(
                      label:
                          'Category breakdown donut chart with ${breakdown.length} categories',
                      child: RepaintBoundary(
                        child: SizedBox(
                          height: AppSizes.donutChartSize,
                          width: AppSizes.donutChartSize,
                          child: Stack(
                            children: [
                              PieChart(
                                PieChartData(
                                  centerSpaceRadius: AppSizes.donutCenterRadius,
                                  sectionsSpace: 2,
                                  sections: breakdown.map((cat) {
                                    return PieChartSectionData(
                                      value: cat.amount.toDouble(),
                                      color: ColorUtils.fromHex(cat.colorHex),
                                      radius: 16,
                                      showTitle: false,
                                    );
                                  }).toList(),
                                  borderData: FlBorderData(show: false),
                                ),
                              ),
                              Positioned.fill(
                                child: Center(
                                  child: Text(
                                    MoneyFormatter.formatCompact(totalAmount),
                                    style:
                                        context.textStyles.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: [
                                        const FontFeature.tabularFigures(),
                                      ],
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // ── Category Ranked List ─────────────────────────────
                  ...List.generate(breakdown.length, (i) {
                    final cat = breakdown[i];
                    final prevAmount = prevByCategory[cat.categoryId];
                    return _CategoryRow(
                      spending: cat,
                      budget: budgetByCategoryId[cat.categoryId],
                      totalAmount: totalAmount,
                      previousAmount: prevAmount,
                    );
                  }),

                  const SizedBox(height: AppSizes.md),

                  // ── Insight Card ─────────────────────────────────────
                  if (breakdown.isNotEmpty)
                    InsightCard(
                      text: context.l10n
                          .reports_category_top(breakdown.first.categoryName),
                    ),

                  const SizedBox(height: AppSizes.md),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.spending,
    this.budget,
    required this.totalAmount,
    this.previousAmount,
  });

  final CategorySpending spending;
  final BudgetEntity? budget;
  final int totalAmount;
  final int? previousAmount;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final catColor = ColorUtils.fromHex(spending.colorHex);
    final hasBudget = budget != null;
    final percentText = '${(spending.fraction * 100).toStringAsFixed(0)}%';

    // Delta vs previous month.
    int? deltaPct;
    if (previousAmount != null && previousAmount! > 0) {
      deltaPct = (((spending.amount - previousAmount!) * 100) / previousAmount!)
          .round();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: colored icon container ──────────────────────────────
          Container(
            width: AppSizes.iconContainerSm,
            height: AppSizes.iconContainerSm,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: AppSizes.opacityLight2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _categoryIcon(spending.iconName),
              size: AppSizes.iconSm,
              color: catColor,
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // ── Middle: name, amount, progress, budget ────────────────────
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
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      MoneyFormatter.format(spending.amount),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: cs.outline,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),

                // Progress bar with optional budget marker
                Semantics(
                  label:
                      '${spending.categoryName}: ${(spending.fraction * 100).toStringAsFixed(0)} percent of total',
                  child: _BudgetProgressBar(
                    fraction: spending.fraction,
                    color: catColor,
                    backgroundColor: cs.surfaceContainerHighest,
                    budgetFraction: hasBudget && totalAmount > 0
                        ? (budget!.limitAmount / totalAmount).clamp(0.0, 1.0)
                        : null,
                  ),
                ),

                // Budget label
                if (hasBudget) ...[
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    context.l10n.reports_budget_label(
                      MoneyFormatter.format(budget!.limitAmount),
                    ),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),

          // ── Right: percentage + delta badge ────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                percentText,
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: catColor,
                ),
              ),
              if (deltaPct != null && deltaPct != 0)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.xxs),
                  child: Semantics(
                    label:
                        '${deltaPct > 0 ? "increased" : "decreased"} ${deltaPct.abs()} percent versus last month',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xs,
                        vertical: AppSizes.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: (deltaPct > 0
                                ? context.appTheme.expenseColor
                                : context.appTheme.incomeColor)
                            .withValues(alpha: AppSizes.opacityLight2),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusFull),
                      ),
                      child: Text(
                        '${deltaPct > 0 ? '\u2191' : '\u2193'}${deltaPct.abs()}%',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: deltaPct > 0
                              ? context.appTheme.expenseColor
                              : context.appTheme.incomeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Budget progress bar with marker ──────────────────────────────────────────

/// Progress bar that optionally shows a thin vertical marker at the budget
/// threshold position.
class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({
    required this.fraction,
    required this.color,
    required this.backgroundColor,
    this.budgetFraction,
  });

  final double fraction;
  final Color color;
  final Color backgroundColor;
  final double? budgetFraction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.categoryProgressHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          return Stack(
            children: [
              // Background + filled portion
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
                child: LinearProgressIndicator(
                  value: fraction,
                  color: color,
                  backgroundColor: backgroundColor,
                  minHeight: AppSizes.categoryProgressHeight,
                ),
              ),
              // Budget marker line
              if (budgetFraction != null)
                PositionedDirectional(
                  start: totalWidth * budgetFraction!,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: AppSizes.xxs,
                    color: context.colors.onSurface
                        .withValues(alpha: AppSizes.opacityMedium),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── Icon resolver ─────────────────────────────────────────────────────────────

/// Maps a category's [iconName] to the corresponding [AppIcons] constant.
IconData _categoryIcon(String iconName) {
  return switch (iconName) {
    'food' => AppIcons.food,
    'transport' => AppIcons.transport,
    'shopping' => AppIcons.shopping,
    'entertainment' => AppIcons.entertainment,
    'health' => AppIcons.health,
    'education' => AppIcons.education,
    'salary' => AppIcons.salary,
    'freelance' => AppIcons.freelance,
    'business' => AppIcons.business,
    'investment' => AppIcons.investment,
    'groceries' => AppIcons.groceries,
    'utilities' => AppIcons.utilities,
    'housing' => AppIcons.housing,
    'subscriptions' => AppIcons.subscriptions,
    'clothing' => AppIcons.clothing,
    'gifts' => AppIcons.gifts,
    'travel' => AppIcons.travel,
    'coffee' => AppIcons.coffee,
    'fuel' => AppIcons.fuel,
    'insurance' => AppIcons.insurance,
    'charity' => AppIcons.charity,
    'delivery' => AppIcons.delivery,
    'pets' => AppIcons.pets,
    'kidsFamily' => AppIcons.kidsFamily,
    _ => AppIcons.category,
  };
}
