/// Pure Dart domain entity — zero Flutter/Drift imports.
class BudgetEntity {
  const BudgetEntity({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.limitAmount,
    required this.rollover,
    required this.rolloverAmount,
    this.spentAmount = 0,
  });

  final int id;
  final int categoryId;

  /// 1–12
  final int month;

  final int year;

  /// Budget cap in piastres — NEVER a double.
  final int limitAmount;

  final bool rollover;

  /// Carried-over amount from previous month (piastres).
  final int rolloverAmount;

  /// Computed field: populated by BudgetRepository from Transactions stream.
  final int spentAmount;

  /// Effective limit = limitAmount (rollover disabled).
  int get effectiveLimit => limitAmount;

  /// 0.0 – 1.0+  (can exceed 1.0 if over-budget)
  double get progressFraction =>
      effectiveLimit > 0 ? spentAmount / effectiveLimit : 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
