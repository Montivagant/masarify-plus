import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_recurring_rule_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_wallet_repository.dart';
import '../utils/money_formatter.dart';
import 'crash_log_service.dart';
import 'notification_service.dart';

/// Called on every app open (from main.dart via ProviderContainer).
///
/// For each rule where [nextDueDate] ≤ today:
/// - [autoLog = true]  → creates a Transaction + advances nextDueDate
/// - [autoLog = false] → fire a local notification reminder (Phase 3)
///
/// All side-effects are idempotent: [lastProcessedDate] guards double-processing.
class RecurringScheduler {
  const RecurringScheduler({
    required IRecurringRuleRepository ruleRepository,
    required ITransactionRepository transactionRepository,
    required IWalletRepository walletRepository,
    required ICategoryRepository categoryRepository,
  })  : _ruleRepo = ruleRepository,
        _txRepo = transactionRepository,
        _walletRepo = walletRepository,
        _categoryRepo = categoryRepository;

  final IRecurringRuleRepository _ruleRepo;
  final ITransactionRepository _txRepo;
  final IWalletRepository _walletRepo;
  final ICategoryRepository _categoryRepo;

  Future<void> run() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueRules = await _ruleRepo.getDue(now);

    for (final rule in dueRules) {
      // M14 fix: wrap each rule in try/catch so one failure doesn't abort all
      try {
        if (!rule.isActive) continue;

        // C7 fix: check endDate — deactivate expired rules
        if (rule.endDate != null && today.isAfter(rule.endDate!)) {
          await _ruleRepo.update(
            RecurringRuleEntity(
              id: rule.id,
              walletId: rule.walletId,
              categoryId: rule.categoryId,
              amount: rule.amount,
              type: rule.type,
              title: rule.title,
              frequency: rule.frequency,
              startDate: rule.startDate,
              endDate: rule.endDate,
              nextDueDate: rule.nextDueDate,
              autoLog: rule.autoLog,
              isActive: false,
              lastProcessedDate: now,
            ),
          );
          continue;
        }

        // Guard: already processed today
        if (rule.lastProcessedDate != null &&
            _isSameDay(rule.lastProcessedDate!, now)) {
          continue;
        }

        // C6 fix: deactivate rule if wallet/category was deleted or archived
        final wallet = await _walletRepo.getById(rule.walletId);
        final category = await _categoryRepo.getById(rule.categoryId);
        if (wallet == null || category == null ||
            wallet.isArchived || (category.isArchived)) {
          await _ruleRepo.update(
            RecurringRuleEntity(
              id: rule.id,
              walletId: rule.walletId,
              categoryId: rule.categoryId,
              amount: rule.amount,
              type: rule.type,
              title: rule.title,
              frequency: rule.frequency,
              startDate: rule.startDate,
              endDate: rule.endDate,
              nextDueDate: rule.nextDueDate,
              autoLog: rule.autoLog,
              isActive: false,
              lastProcessedDate: now,
            ),
          );
          continue;
        }

        // C6 fix: catch-up loop — process ALL missed periods, not just one
        // R5-C3 fix: cap iterations to prevent unbounded loop
        const maxCatchUp = 365;
        var iterations = 0;
        var nextDue = rule.nextDueDate;
        while (!nextDue.isAfter(today) && iterations < maxCatchUp) {
          iterations++;
          // C7 fix: also check endDate within loop
          if (rule.endDate != null && nextDue.isAfter(rule.endDate!)) {
            break;
          }

          if (rule.autoLog) {
            await _autoLogTransaction(rule, nextDue);
          }
          // Non-autoLog: fire only one notification (most recent overdue),
          // not one per missed period. Skip notification inside the loop
          // and fire once after the loop completes.

          nextDue = _computeNextDueDate(nextDue, rule.frequency);
        }

        // CR-13 fix: fire a single notification for overdue non-autoLog rules
        if (!rule.autoLog && iterations > 0) {
          await _fireReminder(rule);
        }

        // Advance nextDueDate and mark processed
        await _ruleRepo.update(
          RecurringRuleEntity(
            id: rule.id,
            walletId: rule.walletId,
            categoryId: rule.categoryId,
            amount: rule.amount,
            type: rule.type,
            title: rule.title,
            frequency: rule.frequency,
            startDate: rule.startDate,
            endDate: rule.endDate,
            nextDueDate: nextDue,
            autoLog: rule.autoLog,
            isActive: rule.isActive,
            lastProcessedDate: now,
          ),
        );
      } catch (e, stack) {
        // M14: skip this rule, continue processing others
        // R5-I5 fix: log errors instead of silently swallowing
        CrashLogService.log(e, stack);
      }
    }
  }

  Future<void> _fireReminder(RecurringRuleEntity rule) async {
    // Use rule.id + 100000 offset to avoid notification id collisions.
    await NotificationService.show(
      id: rule.id + 100000,
      title: rule.title,
      body: MoneyFormatter.format(rule.amount),
    );
  }

  Future<void> _autoLogTransaction(
    RecurringRuleEntity rule,
    DateTime transactionDate,
  ) async {
    await _txRepo.create(
      walletId: rule.walletId,
      categoryId: rule.categoryId,
      amount: rule.amount,
      type: rule.type,
      title: rule.title,
      transactionDate: transactionDate,
      isRecurring: true,
      recurringRuleId: rule.id,
      source: 'recurring',
    );
  }

  /// Advance [from] by one period of [frequency].
  /// H1 fix: clamp day to max days in target month to prevent date drift.
  static DateTime _computeNextDueDate(DateTime from, String frequency) {
    return switch (frequency) {
      'daily' => from.add(const Duration(days: 1)),
      'weekly' => from.add(const Duration(days: 7)),
      'biweekly' => from.add(const Duration(days: 14)),
      'monthly' => _addMonths(from, 1),
      'quarterly' => _addMonths(from, 3),
      'yearly' => _addMonths(from, 12),
      _ => from.add(const Duration(days: 30)),
    };
  }

  /// Add [months] to [from], clamping the day to avoid drift
  /// (e.g. Jan 31 + 1 month → Feb 28, not Mar 3).
  static DateTime _addMonths(DateTime from, int months) {
    final targetMonth = from.month + months;
    final targetYear = from.year + (targetMonth - 1) ~/ 12;
    final normalizedMonth = ((targetMonth - 1) % 12) + 1;
    final maxDay = _daysInMonth(targetYear, normalizedMonth);
    final clampedDay = from.day > maxDay ? maxDay : from.day;
    return DateTime(targetYear, normalizedMonth, clampedDay);
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
