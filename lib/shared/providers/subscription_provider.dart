import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/subscription_service.dart';
import 'theme_provider.dart';

/// Singleton subscription service — initialized on app start.
final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) {
    final service = SubscriptionService(
      ref.watch(sharedPreferencesProvider),
    );
    ref.onDispose(service.dispose);
    return service;
  },
);

/// Ticks once at midnight to trigger re-evaluation of trial status.
/// Returns current date as (year, month, day) tuple — changes at midnight.
final _dailyTickProvider = Provider<(int, int, int)>((ref) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final msUntilMidnight = tomorrow.difference(now).inMilliseconds;

  // Schedule invalidation at midnight so providers re-evaluate.
  final timer = Timer(Duration(milliseconds: msUntilMidnight + 100), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return (now.year, now.month, now.day);
});

/// Whether the user currently has Pro access (subscription OR trial).
///
/// Listens to [SubscriptionService.proStatusStream] so the UI rebuilds
/// immediately when a purchase completes — no app restart needed.
final hasProAccessProvider = Provider<bool>(
  (ref) {
    final service = ref.watch(subscriptionServiceProvider);

    // H-6: Re-evaluate at midnight when trial may expire.
    ref.watch(_dailyTickProvider);

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
