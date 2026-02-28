/// Pure Dart domain entity — zero Flutter/Drift imports.
class WalletEntity {
  const WalletEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currencyCode,
    required this.iconName,
    required this.colorHex,
    required this.isArchived,
    required this.displayOrder,
    required this.createdAt,
  });

  final int id;
  final String name;

  /// 'cash' | 'bank' | 'mobile_wallet' | 'credit_card' | 'savings'
  final String type;

  /// Balance in piastres — NEVER a double.
  final int balance;

  final String currencyCode;
  final String iconName;
  final String colorHex;
  final bool isArchived;
  final int displayOrder;
  final DateTime createdAt;

  WalletEntity copyWith({
    int? id,
    String? name,
    String? type,
    int? balance,
    String? currencyCode,
    String? iconName,
    String? colorHex,
    bool? isArchived,
    int? displayOrder,
    DateTime? createdAt,
  }) =>
      WalletEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        balance: balance ?? this.balance,
        currencyCode: currencyCode ?? this.currencyCode,
        iconName: iconName ?? this.iconName,
        colorHex: colorHex ?? this.colorHex,
        isArchived: isArchived ?? this.isArchived,
        displayOrder: displayOrder ?? this.displayOrder,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
