import '../extensions/datetime_extensions.dart';

/// Shared date-advancement logic for recurring rules.
///
/// Both [RecurringScheduler] (auto-create transactions) and
/// [NotificationTriggerService] (schedule upcoming bill reminders) advance
/// `nextDueDate` by the rule's frequency. Keeping the math in one place
/// prevents drift between the two subsystems.
class RecurringDateCalculator {
  const RecurringDateCalculator._();

  /// Advance [from] by one period of [frequency].
  ///
  /// Uses [DateTimeX.addMonths] for month-based periods to clamp day and
  /// prevent date drift (e.g. Jan 31 + 1 month → Feb 28, not Mar 3).
  static DateTime advance(DateTime from, String frequency) {
    return switch (frequency) {
      'daily' => from.add(const Duration(days: 1)),
      'weekly' => from.add(const Duration(days: 7)),
      'biweekly' => from.add(const Duration(days: 14)),
      'monthly' => from.addMonths(1),
      'quarterly' => from.addMonths(3),
      'yearly' => from.addMonths(12),
      _ => from.add(const Duration(days: 30)),
    };
  }
}
