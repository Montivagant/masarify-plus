import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences] for app-wide settings.
///
/// Pin logic lives here so Phase 4 only needs to call [enablePin]/[disablePin].
class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kOnboardingDone = 'onboarding_done';
  static const _kPinEnabled = 'pin_enabled';
  static const _kCurrency = 'currency_code';
  static const _kLanguage = 'language';
  static const _kFirstDayOfWeek = 'first_day_of_week';
  static const _kFirstDayOfMonth = 'first_day_of_month';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kAutoLockTimeout = 'auto_lock_timeout';
  static const _kSmsParserEnabled = 'sms_parser_enabled';
  static const _kLastBackupDate = 'last_backup_date';
  static const _kDriveFileId = 'drive_file_id';

  // Category frequency keys
  static const _kCategoryFreqExpense = 'category_freq_expense';
  static const _kCategoryFreqIncome = 'category_freq_income';
  static const _kLastCatExpense = 'last_cat_expense';
  static const _kLastCatIncome = 'last_cat_income';

  // Notification preference keys
  static const _kNotifyBudgetWarning = 'notify_budget_warning';
  static const _kNotifyBudgetExceeded = 'notify_budget_exceeded';
  static const _kNotifyBillReminder = 'notify_bill_reminder';
  static const _kNotifyRecurring = 'notify_recurring';
  static const _kNotifyGoalMilestone = 'notify_goal_milestone';
  static const _kNotifyDailyReminder = 'notify_daily_reminder';
  static const _kDailyReminderHour = 'daily_reminder_hour';
  static const _kDailyReminderMinute = 'daily_reminder_minute';
  static const _kQuietHoursEnabled = 'quiet_hours_enabled';
  static const _kQuietHoursStart = 'quiet_hours_start';
  static const _kQuietHoursEnd = 'quiet_hours_end';

  static const _kHasSeenAiDisclaimer = 'has_seen_ai_disclaimer';

  // First-time hints
  static const _kFabHintShown = 'fab_hint_shown';
  static const _kSwipeHintShown = 'swipe_hint_shown';

  // ── Onboarding ────────────────────────────────────────────────────────────
  bool get isOnboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> markOnboardingDone() => _prefs.setBool(_kOnboardingDone, true);

  // ── AI Disclaimer ─────────────────────────────────────────────────────
  bool get hasSeenAiDisclaimer =>
      _prefs.getBool(_kHasSeenAiDisclaimer) ?? false;

  Future<void> markAiDisclaimerSeen() =>
      _prefs.setBool(_kHasSeenAiDisclaimer, true);

  // ── First-time hints ─────────────────────────────────────────────────────
  bool get fabHintShown => _prefs.getBool(_kFabHintShown) ?? false;
  Future<void> setFabHintShown() => _prefs.setBool(_kFabHintShown, true);

  bool get swipeHintShown => _prefs.getBool(_kSwipeHintShown) ?? false;
  Future<void> setSwipeHintShown() => _prefs.setBool(_kSwipeHintShown, true);

  // ── PIN (Phase 4) ─────────────────────────────────────────────────────────
  bool get isPinEnabled => _prefs.getBool(_kPinEnabled) ?? false;

  Future<void> enablePin() => _prefs.setBool(_kPinEnabled, true);

  Future<void> disablePin() async => _prefs.remove(_kPinEnabled);

  // ── Biometric (Phase 4) ────────────────────────────────────────────────
  bool get isBiometricEnabled => _prefs.getBool(_kBiometricEnabled) ?? false;

  Future<void> enableBiometric() => _prefs.setBool(_kBiometricEnabled, true);

  Future<void> disableBiometric() => _prefs.remove(_kBiometricEnabled);

  // ── Auto-lock timeout (milliseconds: 0 = immediate, 60000 = 1 min, 300000 = 5 min)
  int get autoLockTimeoutMs => _prefs.getInt(_kAutoLockTimeout) ?? 0;

  Future<void> setAutoLockTimeoutMs(int ms) =>
      _prefs.setInt(_kAutoLockTimeout, ms);

  // ── Currency ──────────────────────────────────────────────────────────────
  String get currencyCode => _prefs.getString(_kCurrency) ?? 'EGP';

  Future<void> setCurrency(String code) => _prefs.setString(_kCurrency, code);

  // ── Language ──────────────────────────────────────────────────────────────
  String get language => _prefs.getString(_kLanguage) ?? 'ar';

  Future<void> setLanguage(String lang) => _prefs.setString(_kLanguage, lang);

  // ── First day of week (6 = Saturday, 7 = Sunday, 1 = Monday) ─────────────
  int get firstDayOfWeek => _prefs.getInt(_kFirstDayOfWeek) ?? 6;

  Future<void> setFirstDayOfWeek(int day) =>
      _prefs.setInt(_kFirstDayOfWeek, day);

  // ── First day of month (1–28, for budget cycle) ───────────────────────────
  int get firstDayOfMonth => _prefs.getInt(_kFirstDayOfMonth) ?? 1;

  Future<void> setFirstDayOfMonth(int day) =>
      _prefs.setInt(_kFirstDayOfMonth, day);

  // ── SMS Parser ──────────────────────────────────────────────────────────────
  bool get isSmsParserEnabled => _prefs.getBool(_kSmsParserEnabled) ?? false;

  // ── Notification preferences ──────────────────────────────────────────────
  bool get notifyBudgetWarning => _prefs.getBool(_kNotifyBudgetWarning) ?? true;
  Future<void> setNotifyBudgetWarning(bool v) =>
      _prefs.setBool(_kNotifyBudgetWarning, v);

  bool get notifyBudgetExceeded =>
      _prefs.getBool(_kNotifyBudgetExceeded) ?? true;
  Future<void> setNotifyBudgetExceeded(bool v) =>
      _prefs.setBool(_kNotifyBudgetExceeded, v);

  bool get notifyBillReminder => _prefs.getBool(_kNotifyBillReminder) ?? true;
  Future<void> setNotifyBillReminder(bool v) =>
      _prefs.setBool(_kNotifyBillReminder, v);

  bool get notifyRecurring => _prefs.getBool(_kNotifyRecurring) ?? true;
  Future<void> setNotifyRecurring(bool v) =>
      _prefs.setBool(_kNotifyRecurring, v);

  bool get notifyGoalMilestone => _prefs.getBool(_kNotifyGoalMilestone) ?? true;
  Future<void> setNotifyGoalMilestone(bool v) =>
      _prefs.setBool(_kNotifyGoalMilestone, v);

  bool get notifyDailyReminder =>
      _prefs.getBool(_kNotifyDailyReminder) ?? false;
  Future<void> setNotifyDailyReminder(bool v) =>
      _prefs.setBool(_kNotifyDailyReminder, v);

  int get dailyReminderHour => _prefs.getInt(_kDailyReminderHour) ?? 20;
  int get dailyReminderMinute => _prefs.getInt(_kDailyReminderMinute) ?? 0;
  Future<void> setDailyReminderTime(int hour, int minute) async {
    await _prefs.setInt(_kDailyReminderHour, hour);
    await _prefs.setInt(_kDailyReminderMinute, minute);
  }

  bool get quietHoursEnabled => _prefs.getBool(_kQuietHoursEnabled) ?? false;
  Future<void> setQuietHoursEnabled(bool v) =>
      _prefs.setBool(_kQuietHoursEnabled, v);

  int get quietHoursStart => _prefs.getInt(_kQuietHoursStart) ?? 22;
  int get quietHoursEnd => _prefs.getInt(_kQuietHoursEnd) ?? 7;
  Future<void> setQuietHours(int start, int end) async {
    await _prefs.setInt(_kQuietHoursStart, start);
    await _prefs.setInt(_kQuietHoursEnd, end);
  }

  // ── Category frequency ────────────────────────────────────────────────────
  String? getCategoryFrequencyJson(String type) => _prefs.getString(
        type == 'income' ? _kCategoryFreqIncome : _kCategoryFreqExpense,
      );

  Future<void> setCategoryFrequencyJson(String type, String json) =>
      _prefs.setString(
        type == 'income' ? _kCategoryFreqIncome : _kCategoryFreqExpense,
        json,
      );

  int? getLastCategoryId(String type) => _prefs.getInt(
        type == 'income' ? _kLastCatIncome : _kLastCatExpense,
      );

  Future<void> setLastCategoryId(String type, int categoryId) => _prefs.setInt(
        type == 'income' ? _kLastCatIncome : _kLastCatExpense,
        categoryId,
      );

  // ── Google Drive Backup ────────────────────────────────────────────────
  String? get lastBackupDate => _prefs.getString(_kLastBackupDate);

  Future<void> setLastBackupDate(String date) =>
      _prefs.setString(_kLastBackupDate, date);

  String? get driveFileId => _prefs.getString(_kDriveFileId);

  Future<void> setDriveFileId(String? id) {
    if (id == null) return _prefs.remove(_kDriveFileId);
    return _prefs.setString(_kDriveFileId, id);
  }

  Future<void> clearDrivePrefs() async {
    await _prefs.remove(_kLastBackupDate);
    await _prefs.remove(_kDriveFileId);
  }

  // ── Clear all data ────────────────────────────────────────────────────────
  Future<void> clearAll() => _prefs.clear();
}
