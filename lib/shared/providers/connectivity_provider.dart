import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/connectivity_service.dart';

/// Singleton [ConnectivityService] instance.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Emits `true` when online, `false` when offline.
///
/// Seeds the initial connectivity state before listening for changes,
/// so the provider is never in `AsyncLoading` with an unknown state.
/// Used by AI-dependent screens to gate network calls and show
/// offline banners.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);

  final initial = await service.isOnline;
  dev.log('Initial connectivity: $initial', name: 'ConnectivityProvider');
  yield initial;

  await for (final isOnline in service.onlineStream) {
    dev.log('Connectivity changed: $isOnline', name: 'ConnectivityProvider');
    yield isOnline;
  }
});
