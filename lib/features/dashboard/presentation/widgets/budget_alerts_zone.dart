import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/widgets/cards/budget_progress_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Zone 5: Budget alerts — watches only budgets + categories.
class BudgetAlertsZone extends ConsumerWidget {
  const BudgetAlertsZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final budgets = ref.watch(budgetsByMonthProvider(monthKey));
    final categories = ref.watch(categoriesProvider);

    return budgets.when(
      data: (budgetList) {
        final catMap = {
          for (final c in categories.valueOrNull ?? <CategoryEntity>[])
            c.id: c,
        };
        final atRisk = budgetList
            .where((b) => b.progressFraction >= 0.7)
            .take(3)
            .toList();
        if (atRisk.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.sectionGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.dashboard_budget_alerts,
                    style: context.textStyles.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.budgets),
                    label: Text(context.l10n.dashboard_see_all),
                    icon: Icon(
                      context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                      size: AppSizes.iconXs,
                    ),
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            ...atRisk.map((budget) {
              final cat = catMap[budget.categoryId];
              if (cat == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                  vertical: AppSizes.xs,
                ),
                child: BudgetProgressCard(
                  categoryName: cat.displayName(context.languageCode),
                  categoryIcon:
                      CategoryIconMapper.fromName(cat.iconName),
                  limitPiastres: budget.effectiveLimit,
                  spentPiastres: budget.spentAmount,
                  onTap: () => context.push(AppRoutes.budgets),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: EmptyState(title: context.l10n.dashboard_failed_budgets),
      ),
    );
  }
}
