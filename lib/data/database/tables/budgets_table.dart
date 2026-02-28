import 'package:drift/drift.dart';

import 'categories_table.dart';

class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get month => integer()(); // 1–12
  IntColumn get year => integer()();
  IntColumn get limitAmount => integer()(); // piastres
  BoolColumn get rollover =>
      boolean().withDefault(const Constant(false))();
  IntColumn get rolloverAmount =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, month, year},
      ];
}
