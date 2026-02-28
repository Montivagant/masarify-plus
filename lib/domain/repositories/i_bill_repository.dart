import '../entities/bill_entity.dart';

abstract interface class IBillRepository {
  Stream<List<BillEntity>> watchAll();

  Stream<List<BillEntity>> watchUnpaid();

  /// Returns unpaid bills with [dueDate] ≤ [asOf].
  Future<List<BillEntity>> getDue(DateTime asOf);

  Future<BillEntity?> getById(int id);

  /// Returns the new bill's id.
  Future<int> create({
    required String name,
    required int amount,
    required int walletId,
    required int categoryId,
    required DateTime dueDate,
  });

  Future<bool> update(BillEntity bill);

  Future<bool> markPaid(int id, DateTime paidAt);

  /// Atomically: create expense transaction + mark bill paid + link them.
  Future<int> markPaidAtomic({
    required int billId,
    required int walletId,
    required int categoryId,
    required int amount,
    required String title,
  });

  Future<bool> delete(int id);
}
