import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_routes.dart';
import '../extensions/build_context_extensions.dart';
import '../services/insight_engine.dart';

/// Shared presentation logic for [Insight] display.
///
/// Eliminates duplication between DashboardScreen and InsightsScreen.
abstract final class InsightPresenter {
  static String title(BuildContext context, Insight insight) {
    final l10n = context.l10n;
    return switch (insight.type) {
      InsightType.categoryOverspend => l10n.insight_overspend_title,
      InsightType.budgetForecast => l10n.insight_budget_forecast_title,
      InsightType.topSpendingDay => l10n.insight_top_day_title,
      InsightType.savingsUp => l10n.insight_savings_up_title,
      InsightType.savingsDown => l10n.insight_savings_down_title,
      InsightType.topCategory => l10n.insight_top_category_title,
      InsightType.transactionStreak => l10n.insight_streak_title,
      InsightType.noIncomeRecorded => l10n.insight_no_income_title,
    };
  }

  static String body(BuildContext context, Insight insight) {
    final l10n = context.l10n;
    return switch (insight.type) {
      InsightType.categoryOverspend => l10n.insight_overspend_body(
          insight.params['category'] as String,
          insight.params['percent'] as int,
        ),
      InsightType.budgetForecast => l10n.insight_budget_forecast_body(
          insight.params['category'] as String,
        ),
      InsightType.topSpendingDay => l10n.insight_top_day_body(
          dayName(context, insight.params['dayIndex'] as int),
        ),
      InsightType.savingsUp => l10n.insight_savings_up_body(
          insight.params['percent'] as int,
        ),
      InsightType.savingsDown => l10n.insight_savings_down_body(
          insight.params['percent'] as int,
        ),
      InsightType.topCategory => l10n.insight_top_category_body(
          insight.params['category'] as String,
          insight.params['percent'] as int,
        ),
      InsightType.transactionStreak => l10n.insight_streak_body(
          insight.params['count'] as int,
        ),
      InsightType.noIncomeRecorded => l10n.insight_no_income_body,
    };
  }

  static String actionLabel(BuildContext context, Insight insight) {
    final l10n = context.l10n;
    return switch (insight.type) {
      InsightType.categoryOverspend => l10n.insight_view_transactions,
      InsightType.budgetForecast => l10n.insight_adjust_budget,
      InsightType.topSpendingDay => l10n.insight_see_trends,
      InsightType.savingsUp => l10n.insight_view_analytics,
      InsightType.savingsDown => l10n.insight_view_analytics,
      InsightType.topCategory => l10n.insight_view_transactions,
      InsightType.transactionStreak => l10n.insight_view_analytics,
      InsightType.noIncomeRecorded => l10n.insight_view_transactions,
    };
  }

  static void onAction(BuildContext context, Insight insight) {
    switch (insight.type) {
      case InsightType.categoryOverspend:
      case InsightType.noIncomeRecorded:
        context.go(AppRoutes.transactions);
      case InsightType.budgetForecast:
        context.push(AppRoutes.budgets);
      case InsightType.topSpendingDay:
      case InsightType.transactionStreak:
        context.go(AppRoutes.analytics);
      case InsightType.savingsUp:
      case InsightType.savingsDown:
      case InsightType.topCategory:
        context.go(AppRoutes.analytics);
    }
  }

  static String dayName(BuildContext context, int dayIndex) {
    final l10n = context.l10n;
    return switch (dayIndex) {
      1 => l10n.day_monday,
      2 => l10n.day_tuesday,
      3 => l10n.day_wednesday,
      4 => l10n.day_thursday,
      5 => l10n.day_friday,
      6 => l10n.day_saturday,
      7 => l10n.day_sunday,
      _ => '?',
    };
  }
}
