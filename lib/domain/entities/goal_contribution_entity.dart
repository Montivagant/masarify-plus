/// Pure Dart domain entity — zero Flutter/Drift imports.
class GoalContributionEntity {
  const GoalContributionEntity({
    required this.id,
    required this.goalId,
    required this.amount,
    required this.date,
    this.note,
  });

  final int id;
  final int goalId;

  /// Amount contributed in piastres — NEVER a double.
  final int amount;

  final DateTime date;
  final String? note;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalContributionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
