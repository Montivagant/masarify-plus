/// Sentinel object used to distinguish "not passed" from "explicitly null"
/// in [copyWith] methods. This allows clearing nullable fields.
const _sentinel = Object();

/// Pure Dart domain entity — zero Flutter/Drift imports.
/// NOTE: Wallet-to-wallet transfers use [TransferEntity], NOT this class.
class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.walletId,
    required this.categoryId,
    required this.amount,
    required this.type,
    required this.currencyCode,
    required this.title,
    this.note,
    required this.transactionDate,
    this.receiptImagePath,
    required this.tags,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.source,
    this.rawSourceText,
    required this.isRecurring,
    this.recurringRuleId,
    this.goalId,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int walletId;
  final int categoryId;

  /// Always positive, stored in piastres — NEVER a double.
  final int amount;

  /// 'income' | 'expense'
  final String type;

  final String currencyCode;
  final String title;
  final String? note;
  final DateTime transactionDate;
  final String? receiptImagePath;

  /// Comma-separated tag string (empty string = no tags).
  final String tags;

  final double? latitude;
  final double? longitude;
  final String? locationName;

  /// 'manual' | 'voice' | 'sms' | 'notification' | 'import'
  final String source;

  final String? rawSourceText;
  final bool isRecurring;
  final int? recurringRuleId;
  final int? goalId;
  final DateTime createdAt;
  final DateTime updatedAt;

  List<String> get tagList =>
      tags.isEmpty ? [] : tags.split(',').map((t) => t.trim()).toList();

  /// Pass explicit `null` to clear a nullable field.
  /// Omit parameter (or don't pass it) to keep the current value.
  TransactionEntity copyWith({
    int? id,
    int? walletId,
    int? categoryId,
    int? amount,
    String? type,
    String? currencyCode,
    String? title,
    Object? note = _sentinel,
    DateTime? transactionDate,
    Object? receiptImagePath = _sentinel,
    String? tags,
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    Object? locationName = _sentinel,
    String? source,
    Object? rawSourceText = _sentinel,
    bool? isRecurring,
    Object? recurringRuleId = _sentinel,
    Object? goalId = _sentinel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TransactionEntity(
        id: id ?? this.id,
        walletId: walletId ?? this.walletId,
        categoryId: categoryId ?? this.categoryId,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        currencyCode: currencyCode ?? this.currencyCode,
        title: title ?? this.title,
        note: note == _sentinel ? this.note : note as String?,
        transactionDate: transactionDate ?? this.transactionDate,
        receiptImagePath: receiptImagePath == _sentinel
            ? this.receiptImagePath
            : receiptImagePath as String?,
        tags: tags ?? this.tags,
        latitude:
            latitude == _sentinel ? this.latitude : latitude as double?,
        longitude:
            longitude == _sentinel ? this.longitude : longitude as double?,
        locationName: locationName == _sentinel
            ? this.locationName
            : locationName as String?,
        source: source ?? this.source,
        rawSourceText: rawSourceText == _sentinel
            ? this.rawSourceText
            : rawSourceText as String?,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringRuleId: recurringRuleId == _sentinel
            ? this.recurringRuleId
            : recurringRuleId as int?,
        goalId: goalId == _sentinel ? this.goalId : goalId as int?,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
