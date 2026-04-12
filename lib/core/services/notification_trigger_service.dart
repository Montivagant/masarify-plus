import 'dart:ui';

import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/entities/savings_goal_entity.dart';
import '../../l10n/app_localizations.dart';
import '../utils/money_formatter.dart';
import '../utils/recurring_date_calculator.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

/// Bridges business events → local notifications.
///
/// Called from repositories/providers when state changes occur.
/// Respects user preferences via [PreferencesService].
///
/// ID offset ranges (each gives 100k slots — max rule/budget/goal id is ~99_999):
/// - Scheduled bill reminders: `ruleId + 500_000 + (slot * 100_000)` for slot 0..2
///   → slot 0: 500_000–599_999
///   → slot 1: 600_000–699_999
///   → slot 2: 700_000–799_999
/// - Instant overdue reminders (RecurringScheduler): `ruleId + 100_000`
/// - Budget alerts: `budgetId + 200_000`
/// - Goal milestones: `goalId + 300_000`
/// - Daily recap: `99_999`
class NotificationTriggerService {
  const NotificationTriggerService(this._prefs);

  final PreferencesService _prefs;

  /// How many upcoming occurrences to schedule per recurring rule. Three
  /// gives ~3 periods of safety margin if the user doesn't open the app;
  /// startup top-up via [syncBillReminders] refills the window each time
  /// the app launches.
  static const int _maxUpcomingReminders = 3;

  /// Base offset for slot 0. Subsequent slots are +100k each.
  static const int _billReminderBaseOffset = 500000;
  static const int _billReminderSlotStride = 100000;

  /// Resolve l10n strings without a BuildContext by reading the stored locale.
  AppLocalizations get _l10n {
    final lang = _prefs.language;
    return lookupAppLocalizations(Locale(lang));
  }

  // ── Bill / Recurring Rule Reminders ──────────────────────────────────────

  /// Compute the notification id for a given rule + slot.
  static int _billReminderId(int ruleId, int slot) =>
      ruleId + _billReminderBaseOffset + (slot * _billReminderSlotStride);

  /// Schedule up to [_maxUpcomingReminders] upcoming occurrences for a
  /// recurring rule. Idempotent — rescheduling overwrites previous slots by id.
  ///
  /// For `frequency == 'once'`, only slot 0 is scheduled (one-time bills
  /// don't recur). For recurring rules, slots 0..2 are scheduled at
  /// `nextDueDate`, `advance(nextDueDate)`, `advance(advance(nextDueDate))`.
  ///
  /// Rule lifecycle:
  /// - Called on rule create/edit (UI) — seeds the reminder window.
  /// - Called on app startup via [syncBillReminders] — refills window after
  ///   [RecurringScheduler] advances `nextDueDate` so the OS always has
  ///   alarms queued for the next few periods, even while the app is closed.
  Future<void> scheduleBillReminders({
    required int ruleId,
    required String title,
    required int amount,
    required String frequency,
    required DateTime nextDueDate,
    DateTime? endDate,
    bool isActive = true,
    bool isPaid = false,
  }) async {
    if (!_prefs.notifyBillReminder) return;

    // Clear all slots first — handles the case where frequency changed
    // (e.g. monthly → once leaves stale slot 1/2 reminders behind).
    await cancelBillReminders(ruleId);

    // Skip inactive rules and already-paid one-time bills.
    if (!isActive) return;
    if (frequency == 'once' && isPaid) return;

    // One-time bills schedule a single reminder in slot 0.
    if (frequency == 'once') {
      await _scheduleSingleBillReminder(
        slot: 0,
        ruleId: ruleId,
        title: title,
        amount: amount,
        dueDate: nextDueDate,
      );
      return;
    }

    // Recurring rules: schedule next N occurrences, stopping at endDate.
    var due = nextDueDate;
    for (var slot = 0; slot < _maxUpcomingReminders; slot++) {
      if (endDate != null && due.isAfter(endDate)) break;
      await _scheduleSingleBillReminder(
        slot: slot,
        ruleId: ruleId,
        title: title,
        amount: amount,
        dueDate: due,
      );
      due = RecurringDateCalculator.advance(due, frequency);
    }
  }

  /// Schedule one bill reminder at the given slot. The reminder fires at
  /// 9 AM the day before the due date (or 9 AM on the due date if that's
  /// already in the past). If both are in the past, the reminder is skipped
  /// silently — don't spam the user with notifications for old bills.
  Future<void> _scheduleSingleBillReminder({
    required int slot,
    required int ruleId,
    required String title,
    required int amount,
    required DateTime dueDate,
  }) async {
    final l10n = _l10n;
    final now = DateTime.now();

    // 9 AM the day before the due date.
    final dayBefore = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day - 1,
      9,
    );
    final sameDay = DateTime(dueDate.year, dueDate.month, dueDate.day, 9);

    final effectiveDate = dayBefore.isAfter(now)
        ? dayBefore
        : (sameDay.isAfter(now) ? sameDay : null);

    // Past — silently skip. Slot 0 of an overdue rule will be refreshed by
    // the next scheduler run (or fired instantly by RecurringScheduler's
    // own overdue notification path).
    if (effectiveDate == null) return;

    await NotificationService.scheduleOnce(
      id: _billReminderId(ruleId, slot),
      title: l10n.notif_bill_due_title(title),
      body: l10n.notif_bill_due_body(MoneyFormatter.format(amount)),
      scheduledDate: effectiveDate,
      payload: 'recurring:$ruleId',
    );
  }

  /// Cancel all scheduled bill reminders for a rule (slots 0..2).
  Future<void> cancelBillReminders(int ruleId) async {
    for (var slot = 0; slot < _maxUpcomingReminders; slot++) {
      await NotificationService.cancelScheduled(_billReminderId(ruleId, slot));
    }
  }

  /// Top up the OS-level reminder window for every active rule. Called on
  /// app startup AFTER [RecurringScheduler.run] has advanced `nextDueDate`
  /// for any rules that fired while the app was closed.
  ///
  /// This is the "Option A" half of the fix: without it, after the scheduler
  /// advances `nextDueDate` the OS still holds alarms for the OLD dates (or
  /// has no alarms if the rule was just created months ago). Re-scheduling
  /// each active rule ensures reminders match the current `nextDueDate`.
  ///
  /// Idempotent — calling [scheduleBillReminders] with the same ruleId
  /// overwrites existing slots, so repeated calls converge to the same
  /// scheduled state.
  Future<void> syncBillReminders(List<RecurringRuleEntity> rules) async {
    if (!_prefs.notifyBillReminder) return;
    for (final rule in rules) {
      if (!rule.isActive) continue;
      await scheduleBillReminders(
        ruleId: rule.id,
        title: rule.title,
        amount: rule.amount,
        frequency: rule.frequency,
        nextDueDate: rule.nextDueDate,
        endDate: rule.endDate,
        isActive: rule.isActive,
        isPaid: rule.isPaid,
      );
    }
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
