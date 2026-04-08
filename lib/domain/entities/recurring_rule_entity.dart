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
    this.autoMarkPaid = false,
    this.autoPayWalletId,
  });

  final int id;
  final int walletId;
  final int categoryId;

  /// Amount in piastres — NEVER a double.
  final int amount;

  /// 'income' | 'expense'
  final String type;

  final String title;

  /// 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom'
  /// Legacy: 'biweekly' | 'quarterly' still supported in scheduler.
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

  /// Whether this rule should be automatically marked as paid when due.
  final bool autoMarkPaid;

  /// The wallet to deduct from when auto-paying. Required when [autoMarkPaid] is true.
  final int? autoPayWalletId;

  /// True when the rule is due. For once-frequency (bills), also checks !isPaid.
  /// M-4 fix: normalize to date-only comparison, matching isOverdue behavior.
  bool get isDue {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final dueDate =
        DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    final due = !dueDate.isAfter(todayDate);
    if (frequency == 'once') return due && !isPaid;
    return due;
  }

  /// True when a one-time bill is past its due date and still unpaid.
  /// Compares date components only (not time) to avoid off-by-one at day
  /// boundaries — a bill due today is NOT overdue until tomorrow.
  bool get isOverdue {
    if (isPaid || frequency != 'once') return false;
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(
      nextDueDate.year,
      nextDueDate.month,
      nextDueDate.day,
    );
    return todayDate.isAfter(dueDate);
  }

  /// Convenience getter: true for one-time bills.
  bool get isBill => frequency == 'once';

  /// Creates a copy with the given fields replaced.
  RecurringRuleEntity copyWith({
    int? id,
    int? walletId,
    int? categoryId,
    int? amount,
    String? type,
    String? title,
    String? frequency,
    DateTime? startDate,
    DateTime? Function()? endDate,
    DateTime? nextDueDate,
    bool? isPaid,
    DateTime? Function()? paidAt,
    int? Function()? linkedTransactionId,
    bool? isActive,
    DateTime? Function()? lastProcessedDate,
    bool? autoMarkPaid,
    int? Function()? autoPayWalletId,
  }) {
    return RecurringRuleEntity(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      title: title ?? this.title,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt != null ? paidAt() : this.paidAt,
      linkedTransactionId: linkedTransactionId != null
          ? linkedTransactionId()
          : this.linkedTransactionId,
      isActive: isActive ?? this.isActive,
      lastProcessedDate: lastProcessedDate != null
          ? lastProcessedDate()
          : this.lastProcessedDate,
      autoMarkPaid: autoMarkPaid ?? this.autoMarkPaid,
      autoPayWalletId:
          autoPayWalletId != null ? autoPayWalletId() : this.autoPayWalletId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
