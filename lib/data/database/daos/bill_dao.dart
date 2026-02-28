import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/bills_table.dart';

part 'bill_dao.g.dart';

@DriftAccessor(tables: [Bills])
class BillDao extends DatabaseAccessor<AppDatabase> with _$BillDaoMixin {
  BillDao(super.db);

  Stream<List<Bill>> watchAll({int limit = 100}) =>
      (select(bills)
            ..orderBy([(b) => OrderingTerm.asc(b.dueDate)])
            ..limit(limit))
          .watch();

  Stream<List<Bill>> watchUnpaid() =>
      (select(bills)
            ..where((b) => b.isPaid.not())
            ..orderBy([(b) => OrderingTerm.asc(b.dueDate)]))
          .watch();

  Future<List<Bill>> getDue(DateTime asOf) =>
      (select(bills)
            ..where(
              (b) => b.isPaid.not() & b.dueDate.isSmallerOrEqualValue(asOf),
            ))
          .get();

  Future<Bill?> getById(int id) =>
      (select(bills)..where((b) => b.id.equals(id))).getSingleOrNull();

  Future<int> insertBill(BillsCompanion entry) => into(bills).insert(entry);

  Future<bool> saveBill(BillsCompanion entry) =>
      (update(bills)..where((b) => b.id.equals(entry.id.value)))
          .write(entry)
          .then((count) => count > 0);

  Future<bool> markPaid(int id, DateTime paidAt) =>
      (update(bills)..where((b) => b.id.equals(id)))
          .write(
            BillsCompanion(
              isPaid: const Value(true),
              paidAt: Value(paidAt),
            ),
          )
          .then((count) => count > 0);

  Future<bool> deleteById(int id) =>
      (delete(bills)..where((b) => b.id.equals(id)))
          .go()
          .then((count) => count > 0);
}
