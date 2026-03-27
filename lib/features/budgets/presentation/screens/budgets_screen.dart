import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/extensions/month_name_extension.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/cards/budget_progress_card.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _prevMonth() {
    // M4 fix: cap backward navigation to 10 years ago
    final minYear = DateTime.now().year - 10;
    if (_year <= minYear && _month == 1) return;
    setState(() {
      if (_month == 1) {
        _month = 12;
        _year--;
      } else {
        _month--;
      }
    });
  }

  void _nextMonth() {
    // I17 fix: cap forward navigation to current year + 1
    final maxYear = DateTime.now().year + 1;
    if (_year > maxYear || (_year == maxYear && _month == 12)) return;
    setState(() {
      if (_month == 12) {
        _month = 1;
        _year++;
      } else {
        _month++;
      }
    });
  }

  Future<void> _confirmDeleteBudget(BuildContext context, int budgetId) async {
    final confirmed = await ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.budget_delete_title,
      message: context.l10n.budget_delete_confirm,
    );
    // MD-12 fix: check mounted after async gap
    if (confirmed && context.mounted) {
      await ref.read(budgetRepositoryProvider).delete(budgetId);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final budgetsAsync = ref.watch(budgetsByMonthProvider((_year, _month)));
    final hasPro = ref.watch(hasProAccessProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.budgets_title,
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              !hasPro && (budgetsAsync.valueOrNull?.length ?? 0) >= 2
                  ? AppIcons.lock
                  : AppIcons.add,
            ),
            tooltip: context.l10n.budget_set,
            onPressed: () {
              if (!hasPro && (budgetsAsync.valueOrNull?.length ?? 0) >= 2) {
                context.push(AppRoutes.paywall);
              } else {
                context.push(
                  AppRoutes.budgetSet,
                  extra: {'year': _year, 'month': _month},
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _MonthNavigator(
            label: '${context.l10n.monthName(_month)} $_year',
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          Expanded(
            child: budgetsAsync.when(
              data: (budgets) {
                if (budgets.isEmpty) {
                  return EmptyState(
                    title: context.l10n.budgets_empty_title,
                    subtitle: context.l10n.budgets_empty_sub_long,
                    ctaLabel: context.l10n.budget_set,
                    onCta: () => context.push(
                      AppRoutes.budgetSet,
                      extra: {'year': _year, 'month': _month},
                    ),
                  );
                }
                final totalLimit =
                    budgets.fold(0, (s, b) => s + b.effectiveLimit);
                final totalSpent = budgets.fold(0, (s, b) => s + b.spentAmount);

                // E4: Staggered entry animation for budget cards.
                final reduceMotion = context.reduceMotion;

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                  ).copyWith(bottom: AppSizes.bottomScrollPadding),
                  children: [
                    _SummaryCard(
                      totalLimit: totalLimit,
                      totalSpent: totalSpent,
                    ),
                    for (var i = 0; i < budgets.length; i++)
                      () {
                        final budget = budgets[i];
                        final cat = categories
                            .where((c) => c.id == budget.categoryId)
                            .firstOrNull;
                        if (cat == null) return const SizedBox.shrink();
                        // H7 fix: swipe-to-delete for budgets
                        final card = Slidable(
                          key: ValueKey(budget.id),
                          endActionPane: ActionPane(
                            motion: const BehindMotion(),
                            extentRatio: 0.25,
                            children: [
                              SlidableAction(
                                onPressed: (_) =>
                                    _confirmDeleteBudget(context, budget.id),
                                backgroundColor: context.colors.error,
                                foregroundColor: context.colors.onError,
                                icon: AppIcons.delete,
                                label: context.l10n.common_delete,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusSm,
                                ),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.xs,
                            ),
                            child: BudgetProgressCard(
                              categoryName:
                                  cat.displayName(context.languageCode),
                              categoryIcon:
                                  CategoryIconMapper.fromName(cat.iconName),
                              limitPiastres: budget.effectiveLimit,
                              spentPiastres: budget.spentAmount,
                              onTap: () => context.push(
                                '/budgets/${budget.id}/edit',
                                extra: {'year': _year, 'month': _month},
                              ),
                            ),
                          ),
                        );
                        if (reduceMotion) return card;
                        return card
                            .animate()
                            .fadeIn(duration: AppDurations.listItemEntry)
                            .slideY(
                              begin: 0.03,
                              end: 0,
                              duration: AppDurations.listItemEntry,
                              curve: Curves.easeOutCubic,
                            )
                            .then(delay: AppDurations.staggerDelay * i);
                      }(),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSizes.screenHPadding),
                child: ShimmerList(itemCount: 4),
              ),
              error: (_, __) =>
                  EmptyState(title: context.l10n.common_error_title),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthNavigator extends StatelessWidget {
  const _MonthNavigator({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });
  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              context.isRtl ? AppIcons.chevronRight : AppIcons.chevronLeft,
            ),
            onPressed: onPrev,
            tooltip: context.l10n.month_previous,
          ),
          Text(
            label,
            style: context.textStyles.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: Icon(
              context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
            ),
            onPressed: onNext,
            tooltip: context.l10n.month_next,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalLimit, required this.totalSpent});
  final int totalLimit;
  final int totalSpent;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final remaining = totalLimit - totalSpent;
    final isOver = remaining < 0;
    return GlassCard(
      showShadow: true,
      margin: const EdgeInsets.symmetric(vertical: AppSizes.screenHPadding),
      tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              label: context.l10n.budget_total_label,
              value: MoneyFormatter.formatCompact(totalLimit),
              color: cs.onPrimaryContainer,
            ),
          ),
          Expanded(
            child: _Stat(
              label: context.l10n.budget_spent_label,
              value: MoneyFormatter.formatCompact(totalSpent),
              // M3 fix: highlight spent amount when over budget
              color: isOver ? cs.error : cs.onPrimaryContainer,
            ),
          ),
          Expanded(
            child: _Stat(
              // M3 fix: show "Over by" when over budget
              label: isOver
                  ? context.l10n.budget_over_by
                  : context.l10n.budget_remaining,
              value: MoneyFormatter.formatCompact(remaining.abs()),
              color: isOver ? cs.error : cs.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: context.textStyles.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: color.withValues(alpha: AppSizes.opacityStrong),
          ),
        ),
      ],
    );
  }
}
