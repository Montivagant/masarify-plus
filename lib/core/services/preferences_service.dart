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
  static const _kHideBalances = 'hide_balances';
  static const _kNotificationParserEnabled = 'notification_parser_enabled';
  static const _kSmsParserEnabled = 'sms_parser_enabled';
  static const _kAiModel = 'ai_model';

  // ── Onboarding ────────────────────────────────────────────────────────────
  bool get isOnboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;

  Future<void> markOnboardingDone() =>
      _prefs.setBool(_kOnboardingDone, true);

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

  // ── Hide balances ──────────────────────────────────────────────────────
  bool get hideBalances => _prefs.getBool(_kHideBalances) ?? false;

  Future<void> setHideBalances(bool value) =>
      _prefs.setBool(_kHideBalances, value);

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

  // ── Notification Parser ───────────────────────────────────────────────────
  bool get isNotificationParserEnabled =>
      _prefs.getBool(_kNotificationParserEnabled) ?? false;

  Future<void> setNotificationParserEnabled(bool value) =>
      _prefs.setBool(_kNotificationParserEnabled, value);

  // ── SMS Parser ──────────────────────────────────────────────────────────────
  bool get isSmsParserEnabled => _prefs.getBool(_kSmsParserEnabled) ?? false;

  Future<void> setSmsParserEnabled(bool value) =>
      _prefs.setBool(_kSmsParserEnabled, value);

  // ── AI Model ──────────────────────────────────────────────────────────────
  String get aiModel => _prefs.getString(_kAiModel) ?? 'auto';

  Future<void> setAiModel(String model) => _prefs.setString(_kAiModel, model);

  // ── Clear all data ────────────────────────────────────────────────────────
  Future<void> clearAll() => _prefs.clear();
}
