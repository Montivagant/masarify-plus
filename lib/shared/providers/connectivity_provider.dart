import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/connectivity_service.dart';

/// Singleton [ConnectivityService] instance.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Emits `true` when online, `false` when offline.
///
/// Used by AI-dependent screens to gate network calls and show
/// offline banners (Tasks 19-20).
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onlineStream;
});
