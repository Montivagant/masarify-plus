import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/preferences_service.dart';

/// Async provider — resolves once SharedPreferences is loaded.
/// Use `ref.read(preferencesFutureProvider.future)` in initState logic.
final preferencesFutureProvider =
    FutureProvider<PreferencesService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return PreferencesService(prefs);
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
