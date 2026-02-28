import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme_provider.dart';

/// Persisted toggle: when `true`, all balance amounts show `••••` instead.
class HideBalancesNotifier extends StateNotifier<bool> {
  HideBalancesNotifier(SharedPreferences prefs)
      : _prefs = prefs,
        super(prefs.getBool(_key) ?? false);

  final SharedPreferences _prefs;
  static const _key = 'hide_balances';

  Future<void> toggle() async {
    state = !state;
    await _prefs.setBool(_key, state);
  }
}

final hideBalancesProvider =
    StateNotifierProvider<HideBalancesNotifier, bool>((ref) {
  return HideBalancesNotifier(ref.watch(sharedPreferencesProvider));
});
