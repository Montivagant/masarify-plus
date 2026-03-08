import '../../../data/database/daos/category_mapping_dao.dart';

/// Learns user's {title → category} mappings from manual saves.
/// Suggests categories for future SMS/notification transactions.
class CategorizationLearningService {
  CategorizationLearningService(this._dao);

  final CategoryMappingDao _dao;

  /// Normalize title for matching: lowercase, trim, strip digits.
  static String normalize(String title) {
    return title.toLowerCase().trim().replaceAll(RegExp(r'\d+'), '').trim();
  }

  /// Record a mapping from a manual transaction save.
  Future<void> recordMapping(String title, int categoryId) async {
    final pattern = normalize(title);
    if (pattern.isEmpty) return;
    await _dao.upsertMapping(pattern, categoryId);
  }

  /// Suggest a category for a title. Returns null if no mapping found.
  Future<int?> suggestCategory(String title) async {
    final pattern = normalize(title);
    if (pattern.isEmpty) return null;
    return _dao.bestCategoryFor(pattern);
  }
}
