import 'dart:developer' as dev;

import '../../domain/repositories/i_recurring_rule_repository.dart';

/// Processes overdue recurring rules that have auto-pay enabled.
///
/// Uses [IRecurringRuleRepository.payBill] for atomic transaction creation,
/// wallet balance adjustment, and rule paid-status update.
class AutoPayService {
  const AutoPayService(this._recurringRepo);

  final IRecurringRuleRepository _recurringRepo;

  /// Check all active auto-pay rules and pay any that are overdue.
  Future<void> processOverdue() async {
    try {
      final rules = await _recurringRepo.getAll();
      final now = DateTime.now();

      for (final rule in rules) {
        if (!rule.isActive ||
            !rule.autoMarkPaid ||
            rule.autoPayWalletId == null) {
          continue;
        }
        if (rule.isPaid) continue;
        if (rule.nextDueDate.isAfter(now)) continue;

        try {
          await _recurringRepo.payBill(
            ruleId: rule.id,
            walletId: rule.autoPayWalletId!,
            categoryId: rule.categoryId,
            amount: rule.amount,
            type: rule.type,
            title: rule.title,
          );
          dev.log('Auto-paid: ${rule.title}', name: 'AutoPay');
        } catch (e) {
          dev.log('Auto-pay failed for ${rule.title}: $e', name: 'AutoPay');
        }
      }
    } catch (e) {
      dev.log('AutoPayService error: $e', name: 'AutoPay');
    }
  }
}
