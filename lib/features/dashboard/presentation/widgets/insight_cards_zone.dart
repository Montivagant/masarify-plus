import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/nudge_service.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Nudge service provider.
final nudgeServiceProvider = Provider<NudgeService>(
  (ref) => NudgeService(ref.watch(sharedPreferencesProvider)),
);

/// Incremented on each card dismiss to trigger InsightCardsZone rebuild.
final _insightDismissVersionProvider = StateProvider<int>((_) => 0);

/// Dashboard zone showing max 2 AI insight cards.
///
/// Card priority (highest first):
/// 1. Budget at risk (spending > 80% of limit)
/// 2. Over-budget prediction (pace predicts overspend)
/// 3. Recurring pattern detected
/// 4. Budget suggestion (unbudgeted high-spend category)
class InsightCardsZone extends ConsumerWidget {
  const InsightCardsZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch dismiss version so this widget rebuilds after each dismiss.
    ref.watch(_insightDismissVersionProvider);
    final nudge = ref.read(nudgeServiceProvider);
    if (!nudge.canShowMoreCards) return const SizedBox.shrink();

    final cards = <_InsightData>[];

    // ── Priority 1: Budget at risk (>80% spent) ───────────────────────
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final budgets =
        ref.watch(budgetsByMonthProvider(monthKey)).valueOrNull ?? [];
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catMap = {for (final c in cats) c.id: c};

    for (final b in budgets) {
      if (b.effectiveLimit <= 0) continue;
      final fraction = b.spentAmount / b.effectiveLimit;
      if (fraction < 0.8) continue;
      final key = 'budget_risk_${b.categoryId}_${now.month}';
      if (nudge.isCardDismissed(key)) continue;
      final catName =
          catMap[b.categoryId]?.displayName(context.languageCode) ?? '';
      final pct = (fraction * 100).round();
      cards.add(
        _InsightData(
          key: key,
          icon: AppIcons.warning,
          color: context.appTheme.expenseColor,
          title: context.l10n.insight_budget_risk_title(catName),
          subtitle: context.l10n.insight_budget_risk_body(pct),
          route: AppRoutes.budgets,
        ),
      );
    }

    // ── Priority 2: Over-budget prediction ────────────────────────────
    final predictions = ref.watch(spendingPredictionsProvider);
    for (final p in predictions) {
      final key = 'prediction_${p.categoryId}_${now.month}';
      if (nudge.isCardDismissed(key)) continue;
      final catName =
          catMap[p.categoryId]?.displayName(context.languageCode) ?? '';
      cards.add(
        _InsightData(
          key: key,
          icon: AppIcons.trendingUp,
          color: context.appTheme.expenseColor,
          title: context.l10n.insight_prediction_title(catName),
          subtitle: context.l10n
              .insight_prediction_body(MoneyFormatter.format(p.overByAmount)),
          route: AppRoutes.budgets,
        ),
      );
    }

    // ── Priority 3: Recurring pattern detected ────────────────────────
    final patterns = ref.watch(detectedPatternsProvider);
    for (final p in patterns.take(1)) {
      final key = 'recurring_${p.categoryId}_${p.amount}';
      if (nudge.isCardDismissed(key)) continue;
      cards.add(
        _InsightData(
          key: key,
          icon: AppIcons.recurring,
          color: context.appTheme.transferColor,
          title: context.l10n.insight_recurring_title(p.title),
          subtitle: context.l10n.insight_recurring_body(
            MoneyFormatter.format(p.amount),
            p.frequency,
          ),
          route: AppRoutes.recurring,
        ),
      );
    }

    // ── Priority 4: Budget suggestion ─────────────────────────────────
    final suggestions = ref.watch(budgetSuggestionsProvider);
    for (final s in suggestions.take(1)) {
      final key = 'suggest_budget_${s.categoryId}';
      if (nudge.isCardDismissed(key)) continue;
      final catName =
          catMap[s.categoryId]?.displayName(context.languageCode) ?? '';
      cards.add(
        _InsightData(
          key: key,
          icon: AppIcons.budget,
          color: context.colors.primary,
          title: context.l10n.insight_suggest_title(catName),
          subtitle: context.l10n.insight_suggest_body(
            MoneyFormatter.format(s.monthlyAvg),
          ),
          route: AppRoutes.budgets,
        ),
      );
    }

    // Take max 2 cards.
    final visible = cards.take(NudgeService.maxCardsVisible).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
      ),
      child: Column(
        children: visible
            .map(
              (data) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: _InsightCard(
                  data: data,
                  onDismiss: () => _dismiss(ref, data.key),
                  onTap: () => context.push(data.route),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _dismiss(WidgetRef ref, String key) {
    ref.read(nudgeServiceProvider).dismissCard(key);
    // Increment version to trigger rebuild of this widget.
    ref.read(_insightDismissVersionProvider.notifier).state++;
  }
}

// ── Data model ──────────────────────────────────────────────────────────────

class _InsightData {
  const _InsightData({
    required this.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final String key;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;
}

// ── Card widget ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.data,
    required this.onDismiss,
    required this.onTap,
  });

  final _InsightData data;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return GlassCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent icon
          Container(
            width: AppSizes.iconContainerMd,
            height: AppSizes.iconContainerMd,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: AppSizes.opacityLight),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: AppSizes.iconSm,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  data.subtitle,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: cs.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Dismiss button
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              AppIcons.close,
              size: AppSizes.iconXs,
              color: cs.outline,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: context.l10n.common_dismiss,
          ),
        ],
      ),
    );
  }
}
