/// Pure Dart domain entity — zero Flutter/Drift imports.
/// Transfers are NEVER counted as income or expense in analytics.
class TransferEntity {
  const TransferEntity({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.fee,
    this.note,
    required this.transferDate,
    required this.createdAt,
  });

  final int id;
  final int fromWalletId;
  final int toWalletId;

  /// Amount in piastres — NEVER a double.
  final int amount;

  /// Transfer fee in piastres (0 if none).
  final int fee;

  final String? note;
  final DateTime transferDate;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
