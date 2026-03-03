import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/cards/glass_section.dart';
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
    final pendingParsed = ref.watch(pendingParsedTransactionsProvider);
    final activeBudgetCount = budgets.valueOrNull?.length ?? 0;
    final activeGoalCount = activeGoals.valueOrNull?.length ?? 0;
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
          ]),

          // ── Planning (Budgets + Goals + Recurring & Bills) ──────────────
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
            _tile(context, context.l10n.recurring_and_bills_title, AppIcons.recurring, AppRoutes.recurring),
          ]),

          // ── Reports ────────────────────────────────────────────────────────
          _section(context, context.l10n.hub_section_reports, [
            _tile(context, context.l10n.hub_calendar, AppIcons.calendar, AppRoutes.calendar),
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
