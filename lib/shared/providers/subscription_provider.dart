import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_durations.dart';
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
  final timer = Timer(
      Duration(milliseconds: msUntilMidnight) +
          AppDurations.midnightTimerBuffer, () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return (now.year, now.month, now.day);
});

/// Whether the user currently has Pro access (subscription OR trial).
///
/// Uses a dedicated [StreamProvider] for the raw stream so Riverpod manages
/// the subscription lifecycle (no manual `.listen()` leak on rebuild).
final _proStatusStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return service.proStatusStream;
});

/// Synchronous Pro access flag for callers that expect a plain `bool`.
///
/// Re-evaluates at midnight (trial expiry) and whenever the underlying
/// purchase stream emits.
final hasProAccessProvider = Provider<bool>(
  (ref) {
    final service = ref.watch(subscriptionServiceProvider);

    // H-6: Re-evaluate at midnight when trial may expire.
    ref.watch(_dailyTickProvider);

    // Watch the managed stream provider — Riverpod handles the subscription.
    ref.watch(_proStatusStreamProvider);

    return service.hasProAccess;
  },
);

/// Days remaining in the free trial.
final trialDaysRemainingProvider = Provider<int>(
  (ref) => ref.watch(subscriptionServiceProvider).trialDaysRemaining,
);
