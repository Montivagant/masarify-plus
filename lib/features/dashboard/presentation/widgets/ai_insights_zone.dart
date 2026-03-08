import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/budget_suggestion_service.dart';
import '../../../../core/services/ai/recurring_pattern_detector.dart';
import '../../../../core/services/ai/spending_predictor.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// AI insight cards — horizontal scrollable row of smart, contextual tips.
///
/// Heuristic + pattern-based insights from local DB data. No network required.
/// Phase 2A: auto-categorization, recurring detection, spending predictions,
/// budget suggestions.
///
/// When [filterWalletId] is non-null, insights are scoped to that account.
class AiInsightsZone extends ConsumerWidget {
  const AiInsightsZone({super.key, this.filterWalletId});

  final int? filterWalletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final lastMonthKey =
        now.month == 1 ? (now.year - 1, 12) : (now.year, now.month - 1);

    // Resolve all providers in build (Riverpod best practice).
    final budgets = ref.watch(budgetsByMonthProvider(monthKey)).valueOrNull;
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? <CategoryEntity>[];
    final thisMonthTxs =
        ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];
    final lastMonthTxs =
        ref.watch(transactionsByMonthProvider(lastMonthKey)).valueOrNull ?? [];
    final detectedPatterns = ref.watch(detectedPatternsProvider);
    final spendingPredictions = ref.watch(spendingPredictionsProvider);
    final budgetSuggestions = ref.watch(budgetSuggestionsProvider);

    final insights = _computeInsights(
      context: context,
      now: now,
      budgets: budgets,
      categories: categories,
      thisMonthTxs: thisMonthTxs,
      lastMonthTxs: lastMonthTxs,
      detectedPatterns: detectedPatterns,
      spendingPredictions: spendingPredictions,
      budgetSuggestions: budgetSuggestions,
    );
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: Text(
            context.l10n.dashboard_insights,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        SizedBox(
          height: AppSizes.insightCardListHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            itemCount: insights.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
            itemBuilder: (context, index) => insights[index],
          ),
        ),
      ],
    );
  }

  List<Widget> _computeInsights({
    required BuildContext context,
    required DateTime now,
    required List<dynamic>? budgets,
    required List<CategoryEntity> categories,
    required List<TransactionEntity> thisMonthTxs,
    required List<TransactionEntity> lastMonthTxs,
    required List<DetectedPattern> detectedPatterns,
    required List<SpendingPrediction> spendingPredictions,
    required List<BudgetSuggestion> budgetSuggestions,
  }) {
    final insights = <Widget>[];
    final catMap = {for (final c in categories) c.id: c};
    final wid = filterWalletId;

    // Filter transactions by wallet if needed.
    final filteredThis = wid != null
        ? thisMonthTxs.where((t) => t.walletId == wid).toList()
        : thisMonthTxs;
    final filteredLast = wid != null
        ? lastMonthTxs.where((t) => t.walletId == wid).toList()
        : lastMonthTxs;

    // ── Insight 1: Budget at risk ────────────────────────────────────
    if (budgets != null) {
      final atRisk = budgets.where((b) => b.progressFraction >= 0.8).toList();
      if (atRisk.isNotEmpty) {
        final b = atRisk.first;
        final cat = catMap[b.categoryId];
        if (cat != null) {
          final pct = (b.progressFraction * 100).round();
          insights.add(
            _InsightCard(
              icon: AppIcons.warning,
              iconColor: context.appTheme.expenseColor,
              text: '${cat.displayName(context.languageCode)}: $pct%',
              onTap: () => context.push(AppRoutes.budgets),
            ),
          );
        }
      }
    }

    // ── Insight 2: Over-budget prediction (new) ──────────────────────
    if (spendingPredictions.isNotEmpty) {
      final pred = spendingPredictions.first;
      final cat = catMap[pred.categoryId];
      if (cat != null) {
        insights.add(
          _InsightCard(
            icon: AppIcons.trendingUp,
            iconColor: context.appTheme.expenseColor,
            text: context.l10n.insight_over_budget_prediction(
              cat.displayName(context.languageCode),
              MoneyFormatter.formatCompact(pred.overByAmount),
            ),
            onTap: () => context.push(AppRoutes.budgets),
          ),
        );
      }
    }

    // ── Insight 3: Recurring detected ──────────────────────────────
    if (detectedPatterns.isNotEmpty) {
      final pattern = detectedPatterns.first;
      insights.add(
        _InsightCard(
          icon: AppIcons.recurring,
          iconColor: context.colors.primary,
          text: pattern.frequency == 'weekly'
              ? context.l10n.insight_weekly_detected(pattern.title)
              : context.l10n.insight_recurring_detected(pattern.title),
          onTap: () => context.push(AppRoutes.recurringAdd),
        ),
      );
    }

    // ── Insight 4: Budget suggestion ─────────────────────────────────
    if (budgetSuggestions.isNotEmpty) {
      final suggestion = budgetSuggestions.first;
      final cat = catMap[suggestion.categoryId];
      if (cat != null) {
        insights.add(
          _InsightCard(
            icon: AppIcons.budget,
            iconColor: context.colors.primary,
            text: context.l10n.insight_budget_suggestion(
              MoneyFormatter.formatCompact(suggestion.suggestedAmount),
              cat.displayName(context.languageCode),
            ),
            onTap: () => context.push(AppRoutes.budgetSet),
          ),
        );
      }
    }

    // ── Insight 5: Spending trend vs last month ──────────────────────
    final thisExpense = filteredThis
        .where((t) => t.type == 'expense')
        .fold<int>(0, (s, t) => s + t.amount);
    final lastExpense = filteredLast
        .where((t) => t.type == 'expense')
        .fold<int>(0, (s, t) => s + t.amount);

    if (lastExpense > 0 && thisExpense > 0) {
      // Adjust for day-of-month to compare apples-to-apples.
      final dayOfMonth = now.day;
      final daysInLastMonth = DateTime(now.year, now.month, 0).day;
      final projectedRatio = dayOfMonth / daysInLastMonth;
      final adjustedLastExpense = (lastExpense * projectedRatio).round();

      if (adjustedLastExpense > 0) {
        final diff = ((thisExpense - adjustedLastExpense) /
                adjustedLastExpense *
                100)
            .round();
        if (diff.abs() >= 10) {
          final isUp = diff > 0;
          insights.add(
            _InsightCard(
              icon: isUp ? AppIcons.trendingUp : AppIcons.trendingDown,
              iconColor: isUp
                  ? context.appTheme.expenseColor
                  : context.appTheme.incomeColor,
              text: isUp
                  ? context.l10n.dashboard_insight_spending_up(diff)
                  : context.l10n.dashboard_insight_spending_down(diff.abs()),
              onTap: () => context.go(AppRoutes.analytics),
            ),
          );
        }
      }
    }

    // ── Insight 6: Top category this month ──────────────────────────
    if (thisExpense > 0) {
      final byCat = <int, int>{};
      for (final t in filteredThis.where((t) => t.type == 'expense')) {
        byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
      }
      if (byCat.isNotEmpty) {
        final topEntry =
            byCat.entries.reduce((a, b) => a.value > b.value ? a : b);
        final topCat = catMap[topEntry.key];
        if (topCat != null) {
          insights.add(
            _InsightCard(
              icon: AppIcons.category,
              iconColor: context.colors.primary,
              text:
                  '${topCat.displayName(context.languageCode)}: ${MoneyFormatter.formatCompact(topEntry.value)}',
              onTap: () => context.go(AppRoutes.analytics),
            ),
          );
        }
      }
    }

    return insights;
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.iconColor,
    required this.text,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      tintColor: iconColor.withValues(alpha: AppSizes.opacitySubtle),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSm, color: iconColor),
          const SizedBox(width: AppSizes.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.insightCardMaxWidth,
            ),
            child: Text(
              text,
              style: context.textStyles.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
