import '../../domain/entities/recurring_rule_entity.dart';
import '../utils/money_formatter.dart';
import 'notification_service.dart';
import 'preferences_service.dart';

/// Schedules one-shot notifications for upcoming bills/subscriptions.
///
/// Reads a list of upcoming bills and schedules a reminder notification
/// 3 days before each bill's [RecurringRuleEntity.nextDueDate].
/// Uses notification ID convention: `rule.id + 100_000`.
class BillReminderService {
  const BillReminderService._();

  /// Schedule reminders for all upcoming bills.
  ///
  /// Call on app startup and whenever the bill list changes.
  /// Skips scheduling if the user has disabled bill reminders
  /// via [PreferencesService.notifyBillReminder].
  static Future<void> scheduleUpcoming(
    List<RecurringRuleEntity> upcomingBills,
    PreferencesService prefs,
  ) async {
    if (!prefs.notifyBillReminder) return;

    for (final rule in upcomingBills) {
      final dueDate = rule.nextDueDate;
      // Schedule 3 days before due date, at 9:00 AM.
      final reminderDate = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day - 3,
        9, // 9 AM
      );

      // Skip if reminder date is in the past.
      if (reminderDate.isBefore(DateTime.now())) continue;

      final amount = MoneyFormatter.format(rule.amount);
      await NotificationService.scheduleOnce(
        id: rule.id + 100000, // Convention: rule.id + 100_000
        title: rule.title,
        body: '$amount due in 3 days',
        scheduledDate: reminderDate,
        payload: 'bill_reminder:${rule.id}',
      );
    }
  }

  /// Cancel all bill reminder notifications for the given rules.
  static Future<void> cancelAll(List<RecurringRuleEntity> rules) async {
    for (final rule in rules) {
      await NotificationService.cancelScheduled(rule.id + 100000);
    }
  }
}
