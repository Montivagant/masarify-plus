import 'package:drift/drift.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../database/app_database.dart';
import '../database/daos/category_dao.dart';
import '../seed/category_seed.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  const CategoryRepositoryImpl(this._dao, this._db);

  final CategoryDao _dao;
  final AppDatabase _db;

  // ── Streams ──────────────────────────────────────────────────────────────

  @override
  Stream<List<CategoryEntity>> watchAll() =>
      _dao.watchAll().map((list) => list.map(_toEntity).toList());

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  Future<List<CategoryEntity>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<CategoryEntity>> getByType(String type) async {
    final rows = await _dao.getByType(type);
    return rows.map(_toEntity).toList();
  }

  @override
  Future<CategoryEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toEntity(row) : null;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  @override
  Future<int> create({
    required String name,
    required String nameAr,
    required String iconName,
    required String colorHex,
    required String type,
    String? groupType,
    bool isDefault = false,
    int displayOrder = 0,
  }) =>
      _dao.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          nameAr: nameAr,
          iconName: iconName,
          colorHex: colorHex,
          type: type,
          groupType: Value(groupType),
          isDefault: Value(isDefault),
          displayOrder: Value(displayOrder),
        ),
      );

  @override
  Future<bool> update(CategoryEntity category) => _dao.saveCategory(
        CategoriesCompanion(
          id: Value(category.id),
          name: Value(category.name),
          nameAr: Value(category.nameAr),
          iconName: Value(category.iconName),
          colorHex: Value(category.colorHex),
          type: Value(category.type),
          groupType: Value(category.groupType),
          isDefault: Value(category.isDefault),
          isArchived: Value(category.isArchived),
          displayOrder: Value(category.displayOrder),
        ),
      );

  @override
  Future<bool> archive(int id) async {
    return _db.transaction(() async {
      // CR-10 fix: cascade — deactivate recurring rules using this category
      await _db.customStatement(
        'UPDATE recurring_rules SET is_active = 0 WHERE category_id = ?',
        [id],
      );
      // M-3 fix: purge stale learning data for archived category
      await _db.customStatement(
        'DELETE FROM category_mappings WHERE category_id = ?',
        [id],
      );
      // Delete budgets referencing this archived category
      await _db.customStatement(
        'DELETE FROM budgets WHERE category_id = ?',
        [id],
      );
      // C4 fix: reassign orphaned transactions to the first default category
      final defaults = await _db.customSelect(
        'SELECT id FROM categories WHERE is_default = 1 AND is_archived = 0 AND id != ? LIMIT 1',
        variables: [Variable.withInt(id)],
      ).get();
      if (defaults.isEmpty) {
        throw StateError(
          'Cannot archive: no default category available for transaction reassignment',
        );
      }
      final fallbackId = defaults.first.read<int>('id');
      await _db.customStatement(
        'UPDATE transactions SET category_id = ? WHERE category_id = ?',
        [fallbackId, id],
      );
      return _dao.archive(id);
    });
  }

  @override
  Future<void> seedDefaultsIfEmpty() async {
    final count = await _dao.countAll();
    if (count == 0) {
      await _dao.seedAll(CategorySeed.all);
    }
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static CategoryEntity _toEntity(Category c) => CategoryEntity(
        id: c.id,
        name: c.name,
        nameAr: c.nameAr,
        iconName: c.iconName,
        colorHex: c.colorHex,
        type: c.type,
        groupType: c.groupType,
        isDefault: c.isDefault,
        isArchived: c.isArchived,
        displayOrder: c.displayOrder,
      );
}
