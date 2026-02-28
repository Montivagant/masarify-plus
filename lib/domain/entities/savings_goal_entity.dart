/// Pure Dart domain entity — zero Flutter/Drift imports.
class SavingsGoalEntity {
  const SavingsGoalEntity({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.targetAmount,
    required this.currentAmount,
    required this.currencyCode,
    this.deadline,
    required this.isCompleted,
    required this.keywords,
    this.walletId,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String iconName;
  final String colorHex;

  /// Target in piastres — NEVER a double.
  final int targetAmount;

  /// Saved so far in piastres — NEVER a double.
  final int currentAmount;

  final String currencyCode;
  final DateTime? deadline;
  final bool isCompleted;

  /// JSON-encoded list of keyword strings.
  final String keywords;

  /// Optional wallet this goal draws from.
  final int? walletId;

  final DateTime createdAt;

  /// 0.0 – 1.0 (clamped)
  double get progressFraction =>
      targetAmount > 0
          ? (currentAmount / targetAmount).clamp(0.0, 1.0)
          : 0.0;

  int get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, targetAmount);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
