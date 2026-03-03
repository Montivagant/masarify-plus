import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/recurring_rules_table.dart';

part 'recurring_rule_dao.g.dart';

@DriftAccessor(tables: [RecurringRules])
class RecurringRuleDao extends DatabaseAccessor<AppDatabase>
    with _$RecurringRuleDaoMixin {
  RecurringRuleDao(super.db);

  Stream<List<RecurringRule>> watchAll() =>
      (select(recurringRules)
            ..where((r) => r.isActive.equals(true))
            ..orderBy([(r) => OrderingTerm.desc(r.nextDueDate)]))
          .watch();

  Future<List<RecurringRule>> getAll() =>
      (select(recurringRules)
            ..where((r) => r.isActive.equals(true)))
          .get();

  // H10 fix: filter by isActive to prevent disabled rules from generating transactions
  Future<List<RecurringRule>> getDue(DateTime asOf) =>
      (select(recurringRules)
            ..where(
              (r) =>
                  r.isActive.equals(true) &
                  r.nextDueDate.isSmallerOrEqualValue(asOf),
            ))
          .get();

  Future<RecurringRule?> getById(int id) =>
      (select(recurringRules)..where((r) => r.id.equals(id))).getSingleOrNull();

  Future<int> insertRule(RecurringRulesCompanion entry) =>
      into(recurringRules).insert(entry);

  Future<bool> saveRule(RecurringRulesCompanion entry) =>
      (update(recurringRules)..where((r) => r.id.equals(entry.id.value)))
          .write(entry)
          .then((count) => count > 0);

  Future<bool> deleteById(int id) =>
      (delete(recurringRules)..where((r) => r.id.equals(id)))
          .go()
          .then((count) => count > 0);

  /// Watch all unpaid one-time bills, ordered by due date ascending.
  Stream<List<RecurringRule>> watchUnpaid() =>
      (select(recurringRules)
            ..where((r) => r.isPaid.not() & r.frequency.equals('once'))
            ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
          .watch();

  /// Mark a bill as paid with the given timestamp and optional transaction ID.
  Future<bool> markPaid(int id, DateTime paidAt, {int? transactionId}) =>
      (update(recurringRules)..where((r) => r.id.equals(id)))
          .write(
            RecurringRulesCompanion(
              isPaid: const Value(true),
              paidAt: Value(paidAt),
              linkedTransactionId: Value(transactionId),
            ),
          )
          .then((count) => count > 0);
}
