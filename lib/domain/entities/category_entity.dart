const _sentinel = Object();

/// Pure Dart domain entity — zero Flutter/Drift imports.
class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.iconName,
    required this.colorHex,
    required this.type,
    this.groupType,
    required this.isDefault,
    required this.isArchived,
    required this.displayOrder,
  });

  final int id;
  final String name;
  final String nameAr;
  final String iconName;
  final String colorHex;

  /// 'income' | 'expense' | 'both'
  final String type;

  /// 'needs' | 'wants' | 'savings' — nullable
  final String? groupType;

  final bool isDefault;
  final bool isArchived;
  final int displayOrder;

  /// Returns the appropriate display name for the current locale.
  /// For default categories, returns nameAr (Arabic) or name (English).
  /// For user-created categories, name == nameAr, so either works.
  String displayName(String locale) {
    if (locale.startsWith('ar')) return nameAr;
    return name;
  }

  CategoryEntity copyWith({
    int? id,
    String? name,
    String? nameAr,
    String? iconName,
    String? colorHex,
    String? type,
    Object? groupType = _sentinel,
    bool? isDefault,
    bool? isArchived,
    int? displayOrder,
  }) =>
      CategoryEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        iconName: iconName ?? this.iconName,
        colorHex: colorHex ?? this.colorHex,
        type: type ?? this.type,
        groupType:
            groupType == _sentinel ? this.groupType : groupType as String?,
        isDefault: isDefault ?? this.isDefault,
        isArchived: isArchived ?? this.isArchived,
        displayOrder: displayOrder ?? this.displayOrder,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
