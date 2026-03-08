import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/category_mappings_table.dart';

part 'category_mapping_dao.g.dart';

@DriftAccessor(tables: [CategoryMappings])
class CategoryMappingDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryMappingDaoMixin {
  CategoryMappingDao(super.db);

  /// Atomic upsert: increment hit_count if exists, else insert.
  Future<void> upsertMapping(String titlePattern, int categoryId) async {
    await transaction(() async {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final existing = await (select(categoryMappings)
            ..where(
              (m) =>
                  m.titlePattern.equals(titlePattern) &
                  m.categoryId.equals(categoryId),
            ))
          .getSingleOrNull();

      if (existing != null) {
        await (update(categoryMappings)
              ..where((m) => m.id.equals(existing.id)))
            .write(
          CategoryMappingsCompanion(
            hitCount: Value(existing.hitCount + 1),
            lastUsedAt: Value(now),
          ),
        );
      } else {
        await into(categoryMappings).insert(
          CategoryMappingsCompanion.insert(
            titlePattern: titlePattern,
            categoryId: categoryId,
            lastUsedAt: now,
          ),
        );
      }
    });
  }

  Future<int?> bestCategoryFor(String titlePattern) async {
    final results = await (select(categoryMappings)
          ..where((m) => m.titlePattern.equals(titlePattern))
          ..orderBy([(m) => OrderingTerm.desc(m.hitCount)])
          ..limit(1))
        .getSingleOrNull();
    return results?.categoryId;
  }
}
