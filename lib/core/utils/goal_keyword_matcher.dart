/// Matches transaction titles/notes against savings goal keywords.
///
/// Used in Phase 2 Task 2.4 to automatically link transactions to goals
/// based on the goal's keywords JSON array.
///
/// Example:
/// ```dart
/// final matcher = GoalKeywordMatcher(keywords: ['سفر', 'رحلة', 'طيران']);
/// matcher.matches('تذكرة طيران القاهرة') // → true
/// ```
class GoalKeywordMatcher {
  const GoalKeywordMatcher({required this.keywords});

  /// Keywords from SavingsGoal.keywords (JSON array, lowercase-normalised).
  final List<String> keywords;

  /// Lowercase + strip Arabic tashkeel (diacritics U+064B–U+065F).
  static String _normalize(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[\u064B-\u065F]'), '');

  /// Returns true if [text] contains any of the goal's keywords
  /// (case-insensitive, diacritics-insensitive).
  bool matches(String text) {
    if (keywords.isEmpty) return false;
    final normalized = _normalize(text);
    return keywords.any((kw) => normalized.contains(_normalize(kw)));
  }

  /// Finds the first matching keyword in [text], or null if none match.
  String? firstMatch(String text) {
    if (keywords.isEmpty) return null;
    final normalized = _normalize(text);
    try {
      return keywords.firstWhere(
        (kw) => normalized.contains(_normalize(kw)),
      );
    } catch (_) {
      return null;
    }
  }
}
