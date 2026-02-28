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
    required this.autoLog,
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

  /// 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'yearly'
  final String frequency;

  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextDueDate;

  /// If true, auto-creates transaction when due.
  /// If false, sends a local notification reminder.
  final bool autoLog;

  final bool isActive;
  final DateTime? lastProcessedDate;

  bool get isDue => nextDueDate.isBefore(DateTime.now()) || nextDueDate == DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
