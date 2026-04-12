import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/providers/recurring_rule_provider.dart';
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

    // Distinct per-card color — drawn from the shared picker palette so
    // every hub item feels like its own object instead of a monotone grid.
    final items = <_HubCardData>[
      _HubCardData(
        icon: AppIcons.wallet,
        label: context.l10n.hub_wallets,
        route: AppRoutes.wallets,
        color: ColorUtils.fromHex('#0891B2'), // Cyan
      ),
      _HubCardData(
        icon: AppIcons.category,
        label: context.l10n.settings_categories_label,
        route: AppRoutes.categories,
        color: ColorUtils.fromHex('#7C3AED'), // Violet
      ),
      _HubCardData(
        icon: AppIcons.budget,
        label: context.l10n.budgets_title,
        route: AppRoutes.budgets,
        color: ColorUtils.fromHex('#F5A623'), // Amber
        badge: activeBudgetCount > 0
            ? '$activeBudgetCount ${context.l10n.hub_active}'
            : null,
      ),
      _HubCardData(
        icon: AppIcons.goals,
        label: context.l10n.goals_title,
        route: AppRoutes.goals,
        color: ColorUtils.fromHex('#16A34A'), // Green
        badge: activeGoalCount > 0
            ? '$activeGoalCount ${context.l10n.hub_in_progress}'
            : null,
      ),
      _HubCardData(
        icon: AppIcons.ai,
        label: context.l10n.chat_title,
        route: AppRoutes.chat,
        color: ColorUtils.fromHex('#DB2777'), // Pink
      ),
      if (AppConfig.kSmsEnabled)
        _HubCardData(
          icon: AppIcons.inbox,
          label: context.l10n.auto_detected_transactions,
          route: AppRoutes.parserReview,
          color: ColorUtils.fromHex('#1E88E5'), // Blue
          badge: pendingCount > 0
              ? context.l10n.sms_new_found(pendingCount)
              : null,
        ),
      _HubCardData(
        icon: AppIcons.settings,
        label: context.l10n.settings_title,
        route: AppRoutes.settings,
        color: ColorUtils.fromHex('#1A6B5E'), // Dark teal
      ),
    ];

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.hub_planning_title,
        showBack: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
          vertical: AppSizes.md,
        ),
        children: [
          // 1. Editorial header
          const _EditorialHeader(),
          const SizedBox(height: AppSizes.lg),
          // 2. Grid via Wrap + LayoutBuilder.
          // Card aspect ratio tuned to 1.08 (just slightly taller than wide).
          // Earlier we used 1.2 which left ~50px of empty vertical space
          // above/below the centered icon cluster — the grid felt "plain
          // and spacey". 1.08 keeps the cards cozy while preserving the
          // vertical rhythm that distinguishes them from a square mosaic.
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppSizes.md) / 2;
              final cardHeight = cardWidth * 1.08;
              return Wrap(
                spacing: AppSizes.md,
                runSpacing: AppSizes.md,
                children: items
                    .map(
                      (item) => SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _HubGridCard(
                          icon: item.icon,
                          label: item.label,
                          color: item.color,
                          badge: item.badge,
                          onTap: () => context.push(item.route),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSizes.lg),
          // 3. Optimization section label
          const _OptimizationLabel(),
          const SizedBox(height: AppSizes.sm),
          // 4. Saving Insights card
          const _InsightsCard(),
          const SizedBox(height: AppSizes.bottomScrollPadding),
        ],
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
    required this.color,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String route;
  final Color color;
  final String? badge;
}

/// A single card in the hub grid.
///
/// Intentionally bypasses [GlassCard] — the glass tier's 87% translucent
/// surface (`#F5FBF8 @ 0xDE`) blends into the mint scaffold background
/// and makes the cards look washed out. The hub grid needs opinionated
/// solid cards with distinct edges and a confident drop shadow, closer
/// to the Stitch reference.
class _HubGridCard extends StatelessWidget {
  const _HubGridCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: Ink(
          decoration: BoxDecoration(
            // Fully opaque surface — no glass translucency.
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            // Hairline outline so the card edge is always legible even
            // when the shadow renders softly.
            border: Border.all(
              color: cs.outlineVariant.withValues(
                alpha: AppSizes.opacityLight3,
              ),
            ),
            // Two-layer drop shadow — one tight close shadow for definition,
            // one wider soft shadow for lift. Matches the Stitch reference
            // where cards clearly float above the mint background.
            boxShadow: [
              BoxShadow(
                color: theme.glassShadow.withValues(
                  alpha: AppSizes.opacityLight3,
                ),
                blurRadius: AppSizes.cardShadowBlur,
                offset: const Offset(0, AppSizes.cardShadowOffsetY),
              ),
              BoxShadow(
                color: theme.glassShadow.withValues(
                  alpha: AppSizes.opacitySubtle,
                ),
                blurRadius: AppSizes.cardShadowBlur * 2,
                offset: const Offset(0, AppSizes.cardShadowOffsetY * 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Stack(
            children: [
              // ── Badge (top-end, plain primary-colored text — no pill) ──
              if (badge != null)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: Text(
                    badge!,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              // ── Icon + Label (centered) ──
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Colorful icon circle — each card owns a distinct hue
                    // (amber, violet, cyan, etc.) passed in via [color].
                    // Circle fills with a soft tint, icon renders in the
                    // full saturated color for a confident accent pop.
                    Container(
                      width: AppSizes.iconContainerXxl,
                      height: AppSizes.iconContainerXxl,
                      decoration: BoxDecoration(
                        color: color.withValues(
                          alpha: AppSizes.opacityLight2,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: color.withValues(
                            alpha: AppSizes.opacityLight3,
                          ),
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: AppSizes.iconLg,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    // titleMedium (was titleSmall) — gives the label
                    // noticeably more visual weight to match the
                    // now-dominant icon circle.
                    Text(
                      label,
                      style: context.textStyles.titleMedium?.copyWith(
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
        ),
      ),
    );
  }
}

/// Editorial headline + subtitle above the grid.
class _EditorialHeader extends StatelessWidget {
  const _EditorialHeader();

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.hub_headline,
          style: context.textStyles.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          context.l10n.hub_subtitle,
          style: context.textStyles.bodyMedium?.copyWith(
            color: cs.outline,
          ),
        ),
      ],
    );
  }
}

/// "OPTIMIZATION" small-caps section label. Uses primary (green) color to
/// match Stitch reference — the label is a subtle brand accent, not a
/// muted footnote.
class _OptimizationLabel extends StatelessWidget {
  const _OptimizationLabel();

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSizes.xs),
      child: Text(
        context.l10n.hub_optimization_label.toUpperCase(),
        style: context.textStyles.labelSmall?.copyWith(
          color: cs.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

/// Saving insights card — summarises the user's active subscription spend
/// and links to the Recurring screen. Hidden entirely when the user has no
/// active recurring rules so no fake content is ever shown.
///
/// "Active" here means `isActive && !isBill` (bills are one-time, not
/// recurring subscriptions). Monthly equivalent is computed from frequency.
class _InsightsCard extends ConsumerWidget {
  const _InsightsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final rules = ref.watch(recurringRulesProvider).valueOrNull ?? [];

    // Only count active expense-type recurring rules (subscriptions). Bills
    // (frequency == 'once') and income rules are excluded — they're not
    // "subscriptions" the user can consolidate to save money.
    final active = rules
        .where(
          (r) => r.isActive && !r.isBill && r.type == 'expense',
        )
        .toList();

    if (active.isEmpty) return const SizedBox.shrink();

    final monthlyTotal = active.fold<int>(
      0,
      (sum, r) => sum + _monthlyEquivalent(r),
    );
    final amountStr = MoneyFormatter.format(monthlyTotal);

    return GlassCard(
      showShadow: true,
      tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacitySubtle),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row with decorative icon in a tinted rounded square —
          // matches Stitch reference where the icon sits in a subtle green
          // chip rather than floating bare against the background.
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.hub_saving_insights_title,
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: AppSizes.iconContainerMd,
                height: AppSizes.iconContainerMd,
                decoration: BoxDecoration(
                  color: cs.primaryContainer
                      .withValues(alpha: AppSizes.opacityLight3),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                ),
                child: Icon(
                  AppIcons.trendingUp,
                  size: AppSizes.iconSm,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Body text — real data from recurringRulesProvider.
          Text(
            context.l10n.hub_saving_insights_body(active.length, amountStr),
            style: context.textStyles.bodySmall?.copyWith(
              color: cs.outline,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          // Single action: navigate to the Recurring screen where the user
          // can actually review their subscriptions. The old "Dismiss" button
          // was removed — it had no backend and dismissing a live data
          // summary doesn't make sense.
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton(
              onPressed: () => context.push(AppRoutes.recurring),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
              ),
              child: Text(context.l10n.hub_view_details),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert a recurring rule's amount to its monthly equivalent in piastres.
  /// Uses 4.33 weeks/month and 30/365 day ratios so totals stay honest across
  /// mixed frequencies. `once` bills and `custom` rules are excluded upstream.
  static int _monthlyEquivalent(RecurringRuleEntity rule) {
    return switch (rule.frequency) {
      'daily' => rule.amount * 30,
      'weekly' => (rule.amount * 4.33).round(),
      'biweekly' => (rule.amount * 2.165).round(),
      'monthly' => rule.amount,
      'quarterly' => (rule.amount / 3).round(),
      'yearly' => (rule.amount / 12).round(),
      _ => rule.amount,
    };
  }
}
