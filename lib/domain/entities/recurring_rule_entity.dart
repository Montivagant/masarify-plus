/// Pure Dart domain entity — zero Flutter/Drift imports.
class RecurringRuleEntity {
  const RecurringRuleEntity({
    required this.id,
    required this.walletId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.title,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextDueDate,
    required this.isPaid,
    this.paidAt,
    this.linkedTransactionId,
    required this.isActive,
    this.lastProcessedDate,
  });

  final int id;
  final int walletId;
  final int categoryId;

  /// Amount in piastres — NEVER a double.
  final int amount;

  /// 'income' | 'expense'
  final String type;

  final String title;

  /// 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'yearly' | 'once'
  final String frequency;

  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;

  /// Whether this rule (bill) has been paid.
  final bool isPaid;

  /// When the bill was marked as paid.
  final DateTime? paidAt;

  /// The transaction ID created when the bill was paid.
  final int? linkedTransactionId;

  final bool isActive;
  final DateTime? lastProcessedDate;

  /// True when the rule is due. For once-frequency (bills), also checks !isPaid.
  bool get isDue {
    final now = DateTime.now();
    final due = nextDueDate.isBefore(now) ||
        nextDueDate.year == now.year &&
            nextDueDate.month == now.month &&
            nextDueDate.day == now.day;
    if (frequency == 'once') return due && !isPaid;
    return due;
  }

  /// True when a one-time bill is past its due date and still unpaid.
  bool get isOverdue {
    if (isPaid || frequency != 'once') return false;
    final now = DateTime.now();
    final endOfDueDate = DateTime(
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day + 1,
    );
    return now.isAfter(endOfDueDate);
  }

  /// Convenience getter: true for one-time bills.
  bool get isBill => frequency == 'once';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
