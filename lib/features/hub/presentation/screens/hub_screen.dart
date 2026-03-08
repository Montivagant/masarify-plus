import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/cards/glass_section.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Planning tab — focused hub for Accounts, Budgets & Goals, Recurring & Bills,
/// and AI Assistant.
///
/// Previously the "More/Hub" tab which was a dumping ground with 9 items.
/// Categories, Backup, and Parser Review moved to Settings.
class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);

    // Watch providers for summary badges
    final budgets = ref.watch(budgetsByMonthProvider(monthKey));
    final activeGoals = ref.watch(activeGoalsProvider);
    final activeBudgetCount = budgets.valueOrNull?.length ?? 0;
    final activeGoalCount = activeGoals.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.hub_planning_title,
        showBack: false,
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.only(
          start: AppSizes.screenHPadding,
          end: AppSizes.screenHPadding,
          top: AppSizes.md,
        ),
        children: [
          // ── Accounts ───────────────────────────────────────────────
          _section(context, context.l10n.hub_section_accounts, [
            _tile(
              context,
              context.l10n.hub_wallets,
              AppIcons.wallet,
              AppRoutes.wallets,
            ),
          ]),

          // ── Budgets & Goals ────────────────────────────────────────
          _section(context, context.l10n.hub_section_goals_budgets, [
            _tile(
              context,
              context.l10n.budgets_title,
              AppIcons.budget,
              AppRoutes.budgets,
              subtitle: activeBudgetCount > 0
                  ? '$activeBudgetCount ${context.l10n.hub_active}'
                  : null,
            ),
            _tile(
              context,
              context.l10n.goals_title,
              AppIcons.goals,
              AppRoutes.goals,
              subtitle: activeGoalCount > 0
                  ? '$activeGoalCount ${context.l10n.hub_in_progress}'
                  : null,
            ),
          ]),

          // ── Recurring & Bills ──────────────────────────────────────
          _section(context, context.l10n.hub_section_recurring, [
            _tile(
              context,
              context.l10n.recurring_and_bills_title,
              AppIcons.recurring,
              AppRoutes.recurring,
            ),
          ]),

          // ── AI Assistant ──────────────────────────────────────────────
          _section(context, context.l10n.hub_section_ai, [
            _tile(
              context,
              context.l10n.chat_title,
              AppIcons.ai,
              AppRoutes.chat,
            ),
          ]),

          const SizedBox(height: AppSizes.bottomScrollPadding),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> tiles) {
    return GlassSection(
      header: title,
      children: tiles,
    );
  }

  Widget _tile(
    BuildContext context,
    String label,
    IconData icon,
    String route, {
    String? subtitle,
  }) {
    final cs = context.colors;
    return ListTile(
      leading: GlassCard(
        tier: GlassTier.inset,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
        child: SizedBox(
          width: AppSizes.colorSwatchSize,
          height: AppSizes.colorSwatchSize,
          child: Icon(icon, size: AppSizes.iconSm, color: cs.onPrimaryContainer),
        ),
      ),
      title: Text(label),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.primary,
                  ),
            )
          : null,
      trailing: Icon(
        context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
        size: AppSizes.iconSm,
      ),
      onTap: () => context.push(route),
    );
  }
}
