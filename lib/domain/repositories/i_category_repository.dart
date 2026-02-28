import '../entities/category_entity.dart';

abstract interface class ICategoryRepository {
  Stream<List<CategoryEntity>> watchAll();

  Future<List<CategoryEntity>> getAll();

  /// Returns only non-archived categories matching [type] ('income'|'expense'|'both').
  Future<List<CategoryEntity>> getByType(String type);

  Future<CategoryEntity?> getById(int id);

  /// Returns the new category's id.
  Future<int> create({
    required String name,
    required String nameAr,
    required String iconName,
    required String colorHex,
    required String type,
    String? groupType,
    bool isDefault = false,
    int displayOrder = 0,
  });

  Future<bool> update(CategoryEntity category);

  Future<bool> archive(int id);

  /// Seed categories if the table is empty. Idempotent.
  Future<void> seedDefaultsIfEmpty();
}
