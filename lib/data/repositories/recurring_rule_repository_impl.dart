import 'package:drift/drift.dart';

import '../../domain/entities/recurring_rule_entity.dart';
import '../../domain/repositories/i_recurring_rule_repository.dart';
import '../database/app_database.dart';
import '../database/daos/recurring_rule_dao.dart';

class RecurringRuleRepositoryImpl implements IRecurringRuleRepository {
  const RecurringRuleRepositoryImpl(this._dao);

  final RecurringRuleDao _dao;

  @override
  Stream<List<RecurringRuleEntity>> watchAll() =>
      _dao.watchAll().map((list) => list.map(_toEntity).toList());

  @override
  Future<List<RecurringRuleEntity>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<RecurringRuleEntity>> getDue(DateTime asOf) async {
    final rows = await _dao.getDue(asOf);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<RecurringRuleEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toEntity(row) : null;
  }

  @override
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
    bool autoLog = false,
  }) =>
      _dao.insertRule(
        RecurringRulesCompanion.insert(
          walletId: walletId,
          categoryId: categoryId,
          amount: amount,
          type: type,
          title: title,
          frequency: frequency,
          startDate: startDate,
          nextDueDate: nextDueDate,
          endDate: Value(endDate),
          autoLog: Value(autoLog),
        ),
      );

  @override
  Future<bool> update(RecurringRuleEntity rule) => _dao.saveRule(
        RecurringRulesCompanion(
          id: Value(rule.id),
          walletId: Value(rule.walletId),
          categoryId: Value(rule.categoryId),
          amount: Value(rule.amount),
          type: Value(rule.type),
          title: Value(rule.title),
          frequency: Value(rule.frequency),
          startDate: Value(rule.startDate),
          endDate: Value(rule.endDate),
          nextDueDate: Value(rule.nextDueDate),
          autoLog: Value(rule.autoLog),
          isActive: Value(rule.isActive),
          lastProcessedDate: Value(rule.lastProcessedDate),
        ),
      );

  @override
  Future<bool> delete(int id) => _dao.deleteById(id);

  // ── Mapping ───────────────────────────────────────────────────────────────

  static RecurringRuleEntity _toEntity(RecurringRule r) => RecurringRuleEntity(
        id: r.id,
        walletId: r.walletId,
        categoryId: r.categoryId,
        amount: r.amount,
        type: r.type,
        title: r.title,
        frequency: r.frequency,
        startDate: r.startDate,
        endDate: r.endDate,
        nextDueDate: r.nextDueDate,
        autoLog: r.autoLog,
        isActive: r.isActive,
        lastProcessedDate: r.lastProcessedDate,
      );
}
