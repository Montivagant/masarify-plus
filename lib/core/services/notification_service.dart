import 'dart:developer' as dev;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Callback invoked when user taps a notification.
/// Set via [NotificationService.onNotificationTap].
typedef NotificationTapCallback = void Function(String? payload);

/// Wrapper around flutter_local_notifications.
/// Handles initialization, permission, scheduling, and deep-link dispatch.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// External callback for notification taps (set from main.dart / router).
  static NotificationTapCallback? onNotificationTap;

  /// Preloaded SharedPreferences instance — set from main.dart before use.
  /// Avoids calling SharedPreferences.getInstance() on every notification.
  static SharedPreferences? _prefs;

  /// Inject the preloaded SharedPreferences instance (call from main.dart).
  static void setSharedPreferences(SharedPreferences prefs) {
    _prefs = prefs;
  }

  /// Notification ID for the daily spending recap.
  /// Recurring rules use `rule.id + 100_000`, so this must stay below 100_000
  /// and above any manually-assigned ID to avoid collisions.
  static const recapNotificationId = 99999;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    // Set device-local timezone so scheduled notifications fire at correct
    // local time instead of UTC (the default for tz.local).
    try {
      final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTzInfo.identifier));
    } catch (_) {
      // Fallback: leave as UTC if timezone detection fails.
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );

    // Create Android notification channels (required for Android 8.0+).
    // Without this, notifications silently fail on API 26+.
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'masarify_default',
          'Masarify',
          description: 'Masarify notifications',
          importance: Importance.high,
        ),
      );
      // Delete stale channel (was created with default importance — locked
      // on Android 8+ and cannot be changed programmatically).
      await androidPlugin.deleteNotificationChannel('masarify_recap');
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'masarify_recap_v2',
          'Daily Recap',
          description: 'Daily spending recap reminder',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'masarify_bills',
          'Bill Reminders',
          description: 'Upcoming bill and subscription reminders',
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  static void _onResponse(NotificationResponse response) {
    onNotificationTap?.call(response.payload);
  }

  /// Request notification permission (Android 13+ and iOS).
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }

    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iOS != null) {
      final granted = await iOS.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return false;
  }

  /// Request exact alarm permission (Android 14+).
  /// Needed for zonedSchedule() — without this, scheduled notifications
  /// may silently fail on Android 14+ even with inexact mode.
  static Future<void> requestExactAlarmPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestExactAlarmsPermission();
    }
  }

  /// M-18 fix: check if app was launched from a notification tap (cold start).
  /// Returns the payload string, or null if not launched from notification.
  static Future<String?> getLaunchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  /// Show an instant notification.
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // H-10: Enforce quiet hours — suppress notifications during user-defined window.
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      final quietEnabled = prefs.getBool('quiet_hours_enabled') ?? false;
      if (quietEnabled) {
        final start = prefs.getInt('quiet_hours_start') ?? 22;
        final end = prefs.getInt('quiet_hours_end') ?? 7;
        final hour = DateTime.now().hour;
        // Handle window that spans midnight (e.g. 22:00 - 07:00).
        final inQuietWindow = start > end
            ? (hour >= start || hour < end)
            : (hour >= start && hour < end);
        if (inQuietWindow) return;
      }
    } catch (_) {
      // If prefs fail, allow notification through (fail-open).
    }

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'masarify_default',
          'Masarify',
          channelDescription: 'Masarify notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Schedule a daily notification at [hour]:[minute] local time.
  /// Uses `DateTimeComponents.time` so it repeats every day.
  static Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // If the time has already passed today, schedule for tomorrow.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'masarify_recap_v2',
            'Daily Recap',
            channelDescription: 'Daily spending recap reminder',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (e) {
      dev.log('scheduleDaily failed: $e', name: 'NotificationService');
    }
  }

  /// Schedule a one-shot notification at [scheduledDate].
  /// Fires once — no repeating. Used for bill reminders.
  static Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    // Guard: do not schedule in the past.
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'masarify_bills',
            'Bill Reminders',
            channelDescription: 'Upcoming bill and subscription reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      dev.log('scheduleOnce failed: $e', name: 'NotificationService');
    }
  }

  /// Cancel a scheduled notification by [id].
  static Future<void> cancelScheduled(int id) async {
    await _plugin.cancel(id);
  }

  /// Check whether notifications are enabled at the OS level.
  ///
  /// Returns `true` on iOS (always enabled once granted) and on Android
  /// when the user has not disabled the app's notifications in Settings.
  static Future<bool> areEnabled() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.areNotificationsEnabled() ?? false;
    }
    // iOS: assume enabled — the permission request covers this.
    return true;
  }
}
