import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/preferences_service.dart';
import 'theme_provider.dart';

/// Synchronous provider — uses the preloaded SharedPreferences instance
/// from [sharedPreferencesProvider] (overridden in main.dart).
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(sharedPreferencesProvider));
});

/// Legacy alias for callers that still use the old FutureProvider name.
/// Returns an already-resolved AsyncValue wrapping PreferencesService.
final preferencesFutureProvider =
    FutureProvider<PreferencesService>((ref) async {
  return ref.watch(preferencesServiceProvider);
});

/// H12 fix: reactive first day of week preference (6=Sat, 7=Sun, 1=Mon).
final firstDayOfWeekProvider = FutureProvider<int>((ref) async {
  // CR-3 fix: capture future before await
  final prefsFuture = ref.watch(preferencesFutureProvider.future);
  final prefs = await prefsFuture;
  return prefs.firstDayOfWeek;
});

/// H13 fix: reactive currency preference.
final currencyCodeProvider = FutureProvider<String>((ref) async {
  // CR-3 fix: capture future before await
  final prefsFuture = ref.watch(preferencesFutureProvider.future);
  final prefs = await prefsFuture;
  return prefs.currencyCode;
});

/// M-16 fix: reactive first day of month preference (1-28, budget cycle start).
final firstDayOfMonthProvider = FutureProvider<int>((ref) async {
  final prefsFuture = ref.watch(preferencesFutureProvider.future);
  final prefs = await prefsFuture;
  return prefs.firstDayOfMonth;
});
