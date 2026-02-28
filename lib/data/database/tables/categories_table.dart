import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get nameAr => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  TextColumn get type => text()(); // 'income' | 'expense' | 'both'
  TextColumn get groupType => text().nullable()(); // 'needs' | 'wants' | 'savings'
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived =>
      boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
}
