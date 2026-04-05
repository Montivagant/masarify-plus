import 'dart:developer' as dev;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Device capability detection for glass blur effects.
///
/// Disables expensive [BackdropFilter] blur on low-end devices (< 3 GB RAM)
/// or when the user has enabled Reduce Motion accessibility.
abstract final class GlassConfig {
  static bool _initialized = false;
  static bool _blurEnabled = true;

  /// Whether the device can handle [BackdropFilter] blur without jank.
  /// Always `false` on devices with < 3 GB RAM.
  static bool get blurEnabled => _blurEnabled;

  /// Initialize once at startup. Safe to call multiple times.
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await DeviceInfoPlugin().androidInfo;
        // Disable blur on older devices (API < 28 ~ Android 9) which
        // are typically low-RAM and struggle with BackdropFilter.
        if (info.version.sdkInt < 28) {
          _blurEnabled = false;
        }
      }
    } catch (e) {
      dev.log('GPU capability check failed: $e', name: 'GlassConfig');
      // Keep blur enabled (safe default).
    }
  }

  /// Whether blur should be rendered, accounting for both device capability
  /// and the user's Reduce Motion preference.
  static bool shouldBlur(BuildContext context) {
    if (!_blurEnabled) return false;
    return !MediaQuery.disableAnimationsOf(context);
  }
}
