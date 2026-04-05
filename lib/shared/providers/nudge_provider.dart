import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/nudge_service.dart';
import 'theme_provider.dart';

/// Nudge service provider — provides access to the card-dismiss tracking
/// service backed by SharedPreferences.
final nudgeServiceProvider = Provider<NudgeService>(
  (ref) => NudgeService(ref.watch(sharedPreferencesProvider)),
);
