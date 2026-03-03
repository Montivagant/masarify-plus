import '../entities/recurring_rule_entity.dart';

abstract interface class IRecurringRuleRepository {
  Stream<List<RecurringRuleEntity>> watchAll();

  Future<List<RecurringRuleEntity>> getAll();

  /// Returns all rules whose [nextDueDate] ≤ [asOf].
  Future<List<RecurringRuleEntity>> getDue(DateTime asOf);

  Future<RecurringRuleEntity?> getById(int id);

  /// Returns the new rule's id.
  Future<int> create({
    required int walletId,
    required int categoryId,
    required int amount,
    required String type,
    required String title,
    required String frequency,
    required DateTime startDate,
    required DateTime nextDueDate,
    DateTime? endDate,
  });

  Future<bool> update(RecurringRuleEntity rule);

  Future<bool> delete(int id);

  /// Watch all unpaid one-time bills.
  Stream<List<RecurringRuleEntity>> watchUnpaid();

  /// Mark a bill as paid.
  Future<bool> markPaid(int id, DateTime paidAt, {int? transactionId});
}
