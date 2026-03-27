import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../constants/app_durations.dart';

/// Exposes network connectivity state as a stream and one-shot check.
///
/// Used by AI features (voice parsing, SMS enrichment) to avoid HTTP
/// calls when the device is offline, and by the UI to show offline banners.
class ConnectivityService {
  final _connectivity = Connectivity();

  /// Emits `true` when at least one non-[ConnectivityResult.none] result
  /// is present, `false` when all results are [ConnectivityResult.none].
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  /// Returns `true` if the device has a working internet connection.
  ///
  /// First checks connectivity_plus (fast), then verifies with a DNS lookup
  /// to catch WiFi-connected-but-no-internet scenarios.
  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    if (!hasConnection) return false;

    // Verify actual internet access via DNS lookup.
    try {
      final result = await InternetAddress.lookup('openrouter.ai')
          .timeout(AppDurations.dnsLookupTimeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      dev.log('DNS lookup failed — WiFi but no internet', name: 'Connectivity');
      return false;
    } on TimeoutException catch (_) {
      dev.log('DNS lookup timed out', name: 'Connectivity');
      return false;
    }
  }
}
