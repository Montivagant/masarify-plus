import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/category_frequency_service.dart';
import '../../core/services/preferences_service.dart';
import 'theme_provider.dart';

/// Synchronous provider — available immediately (SharedPreferences is
/// preloaded in main and injected via [sharedPreferencesProvider]).
final categoryFrequencyServiceProvider = Provider<CategoryFrequencyService>(
  (ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    return CategoryFrequencyService(PreferencesService(prefs));
  },
);
