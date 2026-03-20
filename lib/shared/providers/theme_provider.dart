import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for the SharedPreferences instance.
/// Must be overridden in main() before runApp().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a preloaded instance',
  );
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_readTheme(prefs));

  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  static ThemeMode _readTheme(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ =>
        ThemeMode.light, // Default to light until dark mode is fully polished
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(
      _key,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
    );
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});

// ── Locale ──────────────────────────────────────────────────────────────────

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(_readLocale(prefs));

  final SharedPreferences _prefs;
  static const _key = 'language';

  static Locale? _readLocale(SharedPreferences prefs) {
    final saved = prefs.getString(_key);
    if (saved == null) return null; // system default
    return Locale(saved);
  }

  Future<void> setLocale(String langCode) async {
    state = Locale(langCode);
    await _prefs.setString(_key, langCode);
  }

  Future<void> clearLocale() async {
    state = null;
    await _prefs.remove(_key);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});
