import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Exposes network connectivity state as a stream and one-shot check.
///
/// Used by AI features (voice parsing, SMS enrichment) to avoid HTTP
/// calls when the device is offline, and by the UI to show offline banners.
class ConnectivityService {
  final _connectivity = Connectivity();

  /// Emits `true` when at least one non-[ConnectivityResult.none] result
  /// is present, `false` when all results are [ConnectivityResult.none].
  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  /// Returns `true` if the device currently has any network connection.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
