import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/insight_provider.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Hub / More tab — links to all secondary features.
/// Sections: Money, Planning, Reports, App.
/// Budget & Goals moved here from bottom nav (users check weekly, not daily).
class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);

    // Watch providers for summary badges
    final budgets = ref.watch(budgetsByMonthProvider(monthKey));
    final activeGoals = ref.watch(activeGoalsProvider);
    final insightsAsync = ref.watch(insightsProvider);

    final pendingParsed = ref.watch(pendingParsedTransactionsProvider);
    final activeBudgetCount = budgets.valueOrNull?.length ?? 0;
    final activeGoalCount = activeGoals.valueOrNull?.length ?? 0;
    final insightCount = insightsAsync.valueOrNull?.length ?? 0;
    final pendingCount = pendingParsed.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.hub_title, showBack: false),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
          vertical: AppSizes.md,
        ),
        children: [
          // ── Money ──────────────────────────────────────────────────────────
          _section(context, context.l10n.hub_section_money, [
            _tile(context, context.l10n.hub_wallets, AppIcons.wallet, AppRoutes.wallets),
            _tile(context, context.l10n.hub_net_worth, AppIcons.netWorth, AppRoutes.netWorth),
          ]),

          // ── Planning (Budgets + Goals + Bills + Recurring) ──────────────
          _section(context, context.l10n.hub_section_planning, [
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
            _tile(context, context.l10n.hub_bills, AppIcons.bill, AppRoutes.bills),
            _tile(context, context.l10n.hub_recurring, AppIcons.recurring, AppRoutes.recurring),
          ]),

          // ── Reports ────────────────────────────────────────────────────────
          _section(context, context.l10n.hub_section_reports, [
            _tile(context, context.l10n.hub_calendar, AppIcons.calendar, AppRoutes.calendar),
            _tile(
              context,
              context.l10n.hub_insights,
              AppIcons.insights,
              AppRoutes.insights,
              subtitle: insightCount > 0
                  ? '$insightCount ${context.l10n.hub_new_label}'
                  : null,
            ),
          ]),

          // ── App ─────────────────────────────────────────────────────────
          _section(context, context.l10n.hub_section_app, [
            _tile(context, context.l10n.settings_categories_label, AppIcons.category, AppRoutes.categories),
            _tile(context, context.l10n.hub_backup, AppIcons.backup, AppRoutes.settingsBackup),
            _tile(
              context,
              context.l10n.settings_notification_parser,
              AppIcons.notification,
              AppRoutes.parserReview,
              subtitle: pendingCount > 0
                  ? context.l10n.sms_new_found(pendingCount)
                  : null,
            ),
            _tile(context, context.l10n.hub_settings, AppIcons.settings, AppRoutes.settings),
          ]),

          const SizedBox(height: AppSizes.bottomScrollPadding),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
        Card(child: Column(children: tiles)),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    String label,
    IconData icon,
    String route, {
    String? subtitle,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            )
          : null,
      trailing: const Icon(AppIcons.chevronRight, size: AppSizes.iconSm),
      onTap: () => context.push(route),
    );
  }
}
