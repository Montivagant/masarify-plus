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
    this.linkedSenders = const [],
    this.isSystemWallet = false,
    this.isDefaultAccount = false,
    this.sortOrder = 0,
  });

  final int id;
  final String name;

  /// 'physical_cash' | 'bank' | 'mobile_wallet' | 'credit_card' | 'prepaid_card' | 'investment'
  final String type;

  /// Balance in piastres — NEVER a double.
  final int balance;

  final String currencyCode;
  final String iconName;
  final String colorHex;
  final bool isArchived;
  final int displayOrder;
  final DateTime createdAt;

  /// SMS sender addresses / notification package names linked to this wallet.
  /// Used to auto-resolve which wallet a parsed transaction belongs to.
  final List<String> linkedSenders;

  /// True for the mandatory Physical Cash system wallet.
  final bool isSystemWallet;

  /// True for the mandatory default bank account (fallback for transaction assignment).
  final bool isDefaultAccount;

  /// Custom sort order for carousel drag-and-drop reordering.
  final int sortOrder;

  bool get isPhysicalCash => isSystemWallet;

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
    List<String>? linkedSenders,
    bool? isSystemWallet,
    bool? isDefaultAccount,
    int? sortOrder,
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
        linkedSenders: linkedSenders ?? this.linkedSenders,
        isSystemWallet: isSystemWallet ?? this.isSystemWallet,
        isDefaultAccount: isDefaultAccount ?? this.isDefaultAccount,
        sortOrder: sortOrder ?? this.sortOrder,
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
