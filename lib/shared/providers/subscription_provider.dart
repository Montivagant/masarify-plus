import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/subscription_service.dart';
import 'theme_provider.dart';

/// Singleton subscription service — initialized on app start.
final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) {
    final service = SubscriptionService(ref.watch(sharedPreferencesProvider));
    ref.onDispose(service.dispose);
    return service;
  },
);

/// Whether the user currently has Pro access (subscription OR trial).
///
/// Listens to [SubscriptionService.proStatusStream] so the UI rebuilds
/// immediately when a purchase completes — no app restart needed.
final hasProAccessProvider = Provider<bool>(
  (ref) {
    final service = ref.watch(subscriptionServiceProvider);

    // Listen for purchase completions and invalidate self to re-read.
    final sub = service.proStatusStream.listen((_) {
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    return service.hasProAccess;
  },
);

/// Days remaining in the free trial.
final trialDaysRemainingProvider = Provider<int>(
  (ref) => ref.watch(subscriptionServiceProvider).trialDaysRemaining,
);
