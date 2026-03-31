import 'dart:ui';

import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../l10n/app_localizations.dart';
import '../utils/money_formatter.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

/// Bridges business events → local notifications.
///
/// Called from repositories/providers when state changes occur.
/// Respects user preferences via [PreferencesService].
///
/// ID offset ranges (each gives 100k slots):
/// - Scheduled bill reminders: `ruleId + 500_000`
/// - Instant overdue reminders (RecurringScheduler): `ruleId + 100_000`
/// - Budget alerts: `budgetId + 200_000`
/// - Goal milestones: `goalId + 300_000`
/// - Daily recap: `99_999`
class NotificationTriggerService {
  const NotificationTriggerService(this._prefs);

  final PreferencesService _prefs;

  /// Resolve l10n strings without a BuildContext by reading the stored locale.
  AppLocalizations get _l10n {
    final lang = _prefs.language;
    return lookupAppLocalizations(Locale(lang));
  }

  // ── Bill / Recurring Rule Reminders ──────────────────────────────────────

  /// Schedule a one-shot notification 1 day before a bill's due date.
  /// Called when a recurring rule is created or its nextDueDate advances.
  Future<void> scheduleBillReminder({
    required int ruleId,
    required String title,
    required int amount,
    required DateTime dueDate,
  }) async {
    if (!_prefs.notifyBillReminder) return;

    final l10n = _l10n;

    // Schedule for 9 AM the day before the due date.
    final reminderDate = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      9,
    );

    // If reminder is in the past, try same-day at 9 AM.
    final now = DateTime.now();
    final effectiveDate = reminderDate.isBefore(now)
        ? DateTime(dueDate.year, dueDate.month, dueDate.day, 9)
        : reminderDate;

    // Already past — fire an immediate notification instead of silently skipping.
    if (effectiveDate.isBefore(now)) {
      await NotificationService.show(
        id: ruleId + 500000,
        title: l10n.notif_bill_due_title(title),
        body: l10n.notif_bill_due_body(MoneyFormatter.format(amount)),
        payload: 'recurring:$ruleId',
      );
      return;
    }

    await NotificationService.scheduleOnce(
      id: ruleId + 500000,
      title: l10n.notif_bill_due_title(title),
      body: l10n.notif_bill_due_body(MoneyFormatter.format(amount)),
      scheduledDate: effectiveDate,
      payload: 'recurring:$ruleId',
    );
  }

  /// Cancel a previously scheduled bill reminder.
  Future<void> cancelBillReminder(int ruleId) async {
    await NotificationService.cancelScheduled(ruleId + 500000);
  }

  // ── Budget Alerts ───────────────────────────────────────────────────────

  /// Check if a budget has crossed the 80% warning or 100% exceeded threshold
  /// after a new transaction, and fire a notification if so.
  ///
  /// [previousSpent] is the spent amount BEFORE the new transaction.
  /// [budget] contains the current state (with updated spentAmount).
  Future<void> checkBudgetThreshold({
    required BudgetEntity budget,
    required int previousSpent,
    required String categoryName,
  }) async {
    final limit = budget.effectiveLimit;
    if (limit <= 0) return;

    final currentSpent = budget.spentAmount;
    final prevPercent = (previousSpent * 100) ~/ limit;
    final currPercent = (currentSpent * 100) ~/ limit;

    final l10n = _l10n;
    final spentStr = MoneyFormatter.format(currentSpent);
    final limitStr = MoneyFormatter.format(limit);

    // Exceeded (100%+) — just crossed the line
    if (currPercent >= 100 && prevPercent < 100) {
      if (!_prefs.notifyBudgetExceeded) return;
      await NotificationService.show(
        id: budget.id + 200000,
        title: l10n.notif_budget_exceeded_title(categoryName),
        body: l10n.notif_budget_exceeded_body(spentStr, limitStr),
        payload: 'budget:${budget.id}',
      );
      return;
    }

    // Warning (80%+) — just crossed the threshold
    if (currPercent >= 80 && prevPercent < 80) {
      if (!_prefs.notifyBudgetWarning) return;
      await NotificationService.show(
        id: budget.id + 200000,
        title: l10n.notif_budget_warning_title(categoryName, currPercent),
        body: l10n.notif_budget_warning_body(spentStr, limitStr),
        payload: 'budget:${budget.id}',
      );
    }
  }

  // ── Goal Milestones ─────────────────────────────────────────────────────

  /// Check if a goal has crossed a milestone (25%, 50%, 75%, 100%).
  ///
  /// [previousAmount] is the currentAmount BEFORE the contribution.
  Future<void> checkGoalMilestone({
    required SavingsGoalEntity goal,
    required int previousAmount,
  }) async {
    if (!_prefs.notifyGoalMilestone) return;
    if (goal.targetAmount <= 0) return;

    final prevPercent = (previousAmount * 100) ~/ goal.targetAmount;
    final currPercent = (goal.currentAmount * 100) ~/ goal.targetAmount;

    final l10n = _l10n;

    // Check milestones in descending order — fire only the highest crossed.
    for (final milestone in [100, 75, 50, 25]) {
      if (currPercent >= milestone && prevPercent < milestone) {
        final currentStr = MoneyFormatter.format(goal.currentAmount);
        final targetStr = MoneyFormatter.format(goal.targetAmount);
        await NotificationService.show(
          id: goal.id + 300000,
          title: l10n.notif_goal_milestone_title(goal.name, milestone),
          body: l10n.notif_goal_milestone_body(currentStr, targetStr),
          payload: 'goal:${goal.id}',
        );
        break;
      }
    }
  }

  // ── Daily Recap Reschedule ──────────────────────────────────────────────

  /// Reschedule daily recap if enabled. Called on app startup.
  Future<void> rescheduleRecapIfEnabled() async {
    if (!_prefs.notifyDailyReminder) return;

    final l10n = _l10n;
    final hour = _prefs.dailyReminderHour;
    final minute = _prefs.dailyReminderMinute;

    await NotificationService.scheduleDaily(
      id: NotificationService.recapNotificationId,
      title: l10n.recap_notification_title,
      body: l10n.recap_notification_body,
      hour: hour,
      minute: minute,
      payload: 'recap',
    );
  }
}
