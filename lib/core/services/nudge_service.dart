import 'package:shared_preferences/shared_preferences.dart';

/// Tracks insight card dismissals to prevent fatigue.
///
/// Rules:
/// - Each dismissed card type is recorded permanently.
/// - Max [maxDismissalsPerDay] dismissals per day — after that, hide all.
class NudgeService {
  NudgeService(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kDismissedCards = 'dismissed_insight_cards';
  static const _kDismissCountDate = 'dismiss_count_date';
  static const _kDismissCount = 'dismiss_count_today';

  // ── Limits ────────────────────────────────────────────────────────────────
  static const maxDismissalsPerDay = 3;
  static const maxCardsVisible = 2;

  // ── Insight Card Dismissals ──────────────────────────────────────────────

  /// Returns true if the card [key] has been dismissed permanently.
  bool isCardDismissed(String key) {
    final dismissed = _prefs.getStringList(_kDismissedCards) ?? [];
    return dismissed.contains(key);
  }

  /// Dismisses a card permanently and increments the daily counter.
  Future<void> dismissCard(String key) async {
    final dismissed = _prefs.getStringList(_kDismissedCards) ?? [];
    if (!dismissed.contains(key)) {
      dismissed.add(key);
      await _prefs.setStringList(_kDismissedCards, dismissed);
    }
    await _incrementDailyDismissals();
  }

  /// Returns true if more cards can be shown today.
  bool get canShowMoreCards => _dailyDismissals < maxDismissalsPerDay;

  int get _dailyDismissals {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _prefs.getString(_kDismissCountDate);
    if (storedDate != today) return 0; // New day, counter resets.
    return _prefs.getInt(_kDismissCount) ?? 0;
  }

  Future<void> _incrementDailyDismissals() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = _prefs.getString(_kDismissCountDate);
    final current =
        (storedDate == today) ? (_prefs.getInt(_kDismissCount) ?? 0) : 0;
    await _prefs.setString(_kDismissCountDate, today);
    await _prefs.setInt(_kDismissCount, current + 1);
  }
}
