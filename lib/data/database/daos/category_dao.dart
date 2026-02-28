import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
  CategoryDao(super.db);

  // H9 fix: filter archived categories so downstream consumers
  // (AI parser, budget dropdowns) don't show archived categories.
  Stream<List<Category>> watchAll() =>
      (select(categories)
            ..where((c) => c.isArchived.not())
            ..orderBy([(c) => OrderingTerm.asc(c.displayOrder)]))
          .watch();

  Future<List<Category>> getAll() =>
      (select(categories)
            ..where((c) => c.isArchived.not())
            ..orderBy([(c) => OrderingTerm.asc(c.displayOrder)]))
          .get();

  /// All categories including archived (for backup/restore and admin views).
  Future<List<Category>> getAllIncludingArchived() =>
      (select(categories)
            ..orderBy([(c) => OrderingTerm.asc(c.displayOrder)]))
          .get();

  Future<List<Category>> getByType(String type) =>
      (select(categories)
            ..where((c) => c.type.equals(type) | c.type.equals('both'))
            ..where((c) => c.isArchived.not())
            ..orderBy([(c) => OrderingTerm.asc(c.displayOrder)]))
          .get();

  Future<Category?> getById(int id) =>
      (select(categories)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> saveCategory(CategoriesCompanion entry) =>
      (update(categories)..where((c) => c.id.equals(entry.id.value)))
          .write(entry)
          .then((count) => count > 0);

  Future<bool> archive(int id) =>
      (update(categories)..where((c) => c.id.equals(id)))
          .write(const CategoriesCompanion(isArchived: Value(true)))
          .then((count) => count > 0);

  Future<int> countAll() async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM categories WHERE is_archived = 0',
      readsFrom: {categories},
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Bulk insert for seeding — M5 fix: use DoNothing to preserve
  /// user-edited category names/icons instead of overwriting them.
  Future<void> seedAll(List<CategoriesCompanion> entries) async {
    await batch((b) {
      for (final entry in entries) {
        b.insert(categories, entry, onConflict: DoNothing());
      }
    });
  }
}
