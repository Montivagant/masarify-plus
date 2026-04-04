import 'dart:developer' as dev;

import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';

import '../constants/app_durations.dart';

/// Wraps geolocator + geocoding for optional location tagging.
///
/// Location NEVER blocks saving — callers must handle failures gracefully.
abstract final class LocationService {
  /// Returns the device's current position, or `null` on any failure.
  static Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: AppDurations.locationTimeout,
        ),
      );
    } catch (e) {
      dev.log('Location lookup failed: $e', name: 'LocationService');
      return null;
    }
  }

  /// Reverse-geocodes [latitude]/[longitude] into a human-readable name.
  ///
  /// Returns `null` on any failure (no internet, no result, timeout).
  static Future<String?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await geo
          .placemarkFromCoordinates(
            latitude,
            longitude,
          )
          .timeout(AppDurations.geocodeTimeout);
      if (placemarks.isEmpty) return null;

      final p = placemarks.first;
      // Build a concise location string: subLocality, locality
      final parts = <String>[
        if (p.subLocality != null && p.subLocality!.isNotEmpty) p.subLocality!,
        if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
      ];
      return parts.isEmpty ? p.name : parts.join(', ');
    } catch (e) {
      dev.log('Location lookup failed: $e', name: 'LocationService');
      return null;
    }
  }

  /// Convenience: get current position + reverse geocode in one call.
  ///
  /// Returns a record of (locationName, latitude, longitude), or `null`.
  static Future<({String name, double lat, double lng})?> detect() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final name = await reverseGeocode(position.latitude, position.longitude);
    if (name == null) return null;

    return (name: name, lat: position.latitude, lng: position.longitude);
  }
}
