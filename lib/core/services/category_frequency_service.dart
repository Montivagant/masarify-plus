import 'dart:convert';

import '../../domain/entities/category_entity.dart';
import 'preferences_service.dart';

/// Tracks category usage frequency per type (expense/income) via
/// SharedPreferences. No DB table — lightweight JSON maps.
class CategoryFrequencyService {
  const CategoryFrequencyService(this._prefs);

  final PreferencesService _prefs;

  /// Returns `{categoryId: usageCount}` for the given transaction type.
  Map<int, int> getFrequencies(String type) {
    final json = _prefs.getCategoryFrequencyJson(type);
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(int.parse(k), v as int));
    } catch (_) {
      return {};
    }
  }

  /// Increments usage count for [categoryId] and records it as last-used.
  Future<void> recordUsage(String type, int categoryId) async {
    final freqs = getFrequencies(type);
    freqs[categoryId] = (freqs[categoryId] ?? 0) + 1;
    final json = jsonEncode(
      freqs.map((k, v) => MapEntry(k.toString(), v)),
    );
    await _prefs.setCategoryFrequencyJson(type, json);
    await _prefs.setLastCategoryId(type, categoryId);
  }

  /// Returns the last-used category ID for the given type, or null.
  int? getLastUsedCategoryId(String type) => _prefs.getLastCategoryId(type);

  /// Returns keyword hints for time-of-day category suggestions.
  ///
  /// Morning (5-11): breakfast/coffee. Afternoon (11-15): lunch.
  /// Evening (15-22): dinner/groceries. Other hours: empty.
  List<String> getTimeOfDaySuggestedKeywords() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return const ['breakfast', 'coffee', 'فطور', 'قهوة'];
    }
    if (hour >= 11 && hour < 15) {
      return const ['lunch', 'غداء', 'restaurant', 'مطعم'];
    }
    if (hour >= 15 && hour < 22) {
      return const ['dinner', 'groceries', 'عشاء', 'بقالة'];
    }
    return const [];
  }

  /// Sorts [categories] by descending usage frequency for the given [type].
  /// Categories with no recorded usage keep their original relative order.
  List<CategoryEntity> sortByFrequency(
    List<CategoryEntity> categories,
    String type,
  ) {
    final freqs = getFrequencies(type);
    if (freqs.isEmpty) return categories;

    final tracked = <CategoryEntity>[];
    final untracked = <CategoryEntity>[];
    for (final cat in categories) {
      if (freqs.containsKey(cat.id)) {
        tracked.add(cat);
      } else {
        untracked.add(cat);
      }
    }
    tracked.sort((a, b) => (freqs[b.id] ?? 0).compareTo(freqs[a.id] ?? 0));
    return [...tracked, ...untracked];
  }
}
