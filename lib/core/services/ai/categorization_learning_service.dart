import '../../../data/database/daos/category_mapping_dao.dart';
import '../../../domain/entities/category_entity.dart';

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

  /// Suggest a category from free-form text by:
  /// 1. Checking learned title→category mappings in the DB.
  /// 2. Falling back to keyword matching against category name/nameAr.
  /// Returns null if no match found.
  Future<CategoryEntity?> suggestFromText(
    String text,
    List<CategoryEntity> categories,
  ) async {
    if (text.trim().isEmpty || categories.isEmpty) return null;

    // 1. Check learned patterns first.
    final normalized = normalize(text);
    if (normalized.isNotEmpty) {
      final learnedId = await _dao.bestCategoryFor(normalized);
      if (learnedId != null) {
        final match = categories.where((c) => c.id == learnedId).firstOrNull;
        if (match != null) return match;
      }
    }

    // 2. Keyword match against category name/nameAr (case-insensitive contains).
    final query = text.trim().toLowerCase();
    for (final cat in categories) {
      if (cat.name.toLowerCase().contains(query) ||
          cat.nameAr.contains(query) ||
          query.contains(cat.name.toLowerCase()) ||
          query.contains(cat.nameAr)) {
        return cat;
      }
    }

    return null;
  }
}
