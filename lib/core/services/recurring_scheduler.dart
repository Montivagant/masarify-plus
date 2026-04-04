import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_recurring_rule_repository.dart';
import '../../domain/repositories/i_wallet_repository.dart';
import '../extensions/datetime_extensions.dart';
import '../utils/money_formatter.dart';
import 'crash_log_service.dart';
import 'notification_service.dart';

/// Called on every app open (from main.dart via ProviderContainer).
///
/// For each **recurring** rule where [nextDueDate] ≤ today:
/// - Advances nextDueDate past today
/// - Fires a local notification reminder
///
/// One-time bills (frequency == 'once') are skipped entirely — they are
/// managed through the UI's "Mark Paid" action and overdue display.
///
/// All side-effects are idempotent: [lastProcessedDate] guards double-processing.
class RecurringScheduler {
  const RecurringScheduler({
    required IRecurringRuleRepository ruleRepository,
    required IWalletRepository walletRepository,
    required ICategoryRepository categoryRepository,
  })  : _ruleRepo = ruleRepository,
        _walletRepo = walletRepository,
        _categoryRepo = categoryRepository;

  final IRecurringRuleRepository _ruleRepo;
  final IWalletRepository _walletRepo;
  final ICategoryRepository _categoryRepo;

  Future<void> run() async {
    final now = DateTime.now();
    final today = now.startOfDay;
    final dueRules = await _ruleRepo.getDue(now);

    for (final rule in dueRules) {
      // M14 fix: wrap each rule in try/catch so one failure doesn't abort all
      try {
        if (!rule.isActive) continue;

        // Skip one-time bills and custom-period rules — they are managed
        // via the UI's "Mark Paid" action.  Paid ones need no processing;
        // unpaid/overdue ones are shown in the recurring screen, not
        // advanced by the scheduler.
        if (rule.frequency == 'once' || rule.frequency == 'custom') continue;

        // C7 fix: check endDate — deactivate expired rules
        if (rule.endDate != null && today.isAfter(rule.endDate!.startOfDay)) {
          await _ruleRepo.update(
            rule.copyWith(
              isActive: false,
              lastProcessedDate: () => now,
            ),
          );
          continue;
        }

        // Guard: already processed today
        if (rule.lastProcessedDate != null &&
            rule.lastProcessedDate!.isSameDay(now)) {
          continue;
        }

        // C6 fix: deactivate rule if wallet/category was deleted or archived
        final wallet = await _walletRepo.getById(rule.walletId);
        final category = await _categoryRepo.getById(rule.categoryId);
        if (wallet == null ||
            category == null ||
            wallet.isArchived ||
            (category.isArchived)) {
          await _ruleRepo.update(
            rule.copyWith(
              isActive: false,
              lastProcessedDate: () => now,
            ),
          );
          continue;
        }

        // C6 fix: catch-up loop — process ALL missed periods, not just one
        // R5-C3 fix: cap iterations to prevent unbounded loop
        // Fix #21: advance nextDueDate after each iteration so a crash
        // mid-loop doesn't re-process already-logged transactions.
        const maxCatchUp = 365;
        var iterations = 0;
        var nextDue = rule.nextDueDate;
        while (!nextDue.isAfter(today) && iterations < maxCatchUp) {
          iterations++;

          nextDue = _computeNextDueDate(nextDue, rule.frequency);

          // C7 fix: check endDate after advancing — break if past end
          if (rule.endDate != null && nextDue.isAfter(rule.endDate!)) {
            break;
          }

          // Persist nextDueDate after each iteration so crash mid-loop
          // doesn't re-run already-processed rules on restart.
          await _ruleRepo.update(
            rule.copyWith(
              nextDueDate: nextDue,
              lastProcessedDate: () => now,
            ),
          );
        }

        // Fire a single notification reminder for overdue rules
        if (iterations > 0) {
          await _fireReminder(rule);
        }
      } catch (e, stack) {
        // M14: skip this rule, continue processing others
        // R5-I5 fix: log errors instead of silently swallowing
        CrashLogService.log(e, stack);
      }
    }
  }

  Future<void> _fireReminder(RecurringRuleEntity rule) async {
    // H-11: Respect user's bill reminder notification preference.
    try {
      final prefs = await SharedPreferences.getInstance();
      final billRemindersEnabled =
          prefs.getBool('notify_bill_reminder') ?? true;
      if (!billRemindersEnabled) return;
    } catch (_) {
      // If prefs fail, allow notification through (fail-open).
    }

    // Use rule.id + 100000 offset to avoid notification id collisions.
    await NotificationService.show(
      id: rule.id + 100000,
      title: rule.title,
      body: MoneyFormatter.format(rule.amount),
      payload: 'recurring:${rule.id}',
    );
  }

  /// Advance [from] by one period of [frequency].
  /// Uses [DateTimeX.addMonths] for month-based periods to clamp day and
  /// prevent date drift (e.g. Jan 31 + 1 month → Feb 28, not Mar 3).
  static DateTime _computeNextDueDate(DateTime from, String frequency) {
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
