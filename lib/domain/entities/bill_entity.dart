/// Pure Dart domain entity — zero Flutter/Drift imports.
/// Bills = one-off upcoming payments. For repeating use [RecurringRuleEntity].
class BillEntity {
  const BillEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.walletId,
    required this.categoryId,
    required this.dueDate,
    required this.isPaid,
    this.paidAt,
    this.linkedTransactionId,
  });

  final int id;
  final String name;

  /// Amount in piastres — NEVER a double.
  final int amount;

  final int walletId;
  final int categoryId;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidAt;
  final int? linkedTransactionId;

  /// M12 fix: end-of-day semantics — due date day itself is NOT overdue.
  bool get isOverdue {
    if (isPaid) return false;
    final now = DateTime.now();
    final endOfDueDate = DateTime(dueDate.year, dueDate.month, dueDate.day + 1);
    return now.isAfter(endOfDueDate) || now.isAtSameMomentAs(endOfDueDate);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
