import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Planning tab — flat 2-column grid hub for quick access to all features.
class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);

    // Watch providers for badges
    final budgets = ref.watch(budgetsByMonthProvider(monthKey));
    final activeGoals = ref.watch(activeGoalsProvider);
    final activeBudgetCount = budgets.valueOrNull?.length ?? 0;
    final activeGoalCount = activeGoals.valueOrNull?.length ?? 0;

    final pendingCount = AppConfig.kSmsEnabled
        ? (ref.watch(pendingCountProvider).valueOrNull ?? 0)
        : 0;

    final items = <_HubCardData>[
      _HubCardData(
        icon: AppIcons.wallet,
        label: context.l10n.hub_wallets,
        route: AppRoutes.wallets,
      ),
      _HubCardData(
        icon: AppIcons.category,
        label: context.l10n.settings_categories_label,
        route: AppRoutes.categories,
      ),
      _HubCardData(
        icon: AppIcons.budget,
        label: context.l10n.budgets_title,
        route: AppRoutes.budgets,
        badge: activeBudgetCount > 0
            ? '$activeBudgetCount ${context.l10n.hub_active}'
            : null,
      ),
      _HubCardData(
        icon: AppIcons.goals,
        label: context.l10n.goals_title,
        route: AppRoutes.goals,
        badge: activeGoalCount > 0
            ? '$activeGoalCount ${context.l10n.hub_in_progress}'
            : null,
      ),
      _HubCardData(
        icon: AppIcons.ai,
        label: context.l10n.chat_title,
        route: AppRoutes.chat,
      ),
      if (AppConfig.kSmsEnabled)
        _HubCardData(
          icon: AppIcons.inbox,
          label: context.l10n.auto_detected_transactions,
          route: AppRoutes.parserReview,
          badge: pendingCount > 0
              ? context.l10n.sms_new_found(pendingCount)
              : null,
        ),
      _HubCardData(
        icon: AppIcons.settings,
        label: context.l10n.settings_title,
        route: AppRoutes.settings,
      ),
    ];

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.hub_planning_title,
        showBack: false,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
          vertical: AppSizes.md,
        ),
        mainAxisSpacing: AppSizes.sm,
        crossAxisSpacing: AppSizes.sm,
        children: items
            .map(
              (item) => _HubGridCard(
                icon: item.icon,
                label: item.label,
                badge: item.badge,
                onTap: () => context.push(item.route),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Data holder for hub grid items.
class _HubCardData {
  const _HubCardData({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String route;
  final String? badge;
}

/// A single card in the hub grid.
class _HubGridCard extends StatelessWidget {
  const _HubGridCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return GlassCard(
      onTap: onTap,
      child: Stack(
        children: [
          // ── Badge (top-end) ──
          if (badge != null)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xxs,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: AppSizes.opacityLight2),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusFull),
                ),
                child: Text(
                  badge!,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // ── Icon + Label (centered) ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassCard(
                  tier: GlassTier.inset,
                  padding: EdgeInsets.zero,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  tintColor: cs.primaryContainer
                      .withValues(alpha: AppSizes.opacityLight4),
                  child: SizedBox(
                    width: AppSizes.iconContainerXl,
                    height: AppSizes.iconContainerXl,
                    child: Icon(
                      icon,
                      size: AppSizes.iconLg,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  label,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
