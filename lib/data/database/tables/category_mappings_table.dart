import 'package:drift/drift.dart';

import 'categories_table.dart';

class CategoryMappings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titlePattern => text()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get hitCount => integer().withDefault(const Constant(1))();
  IntColumn get lastUsedAt => integer()(); // Unix timestamp (seconds)

  @override
  List<Set<Column>> get uniqueKeys => [
        {titlePattern, categoryId},
      ];
}
