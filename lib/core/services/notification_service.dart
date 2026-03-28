import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Notification ID for the daily spending recap.
  /// Recurring rules use `rule.id + 100_000`, so this must stay below 100_000
  /// and above any manually-assigned ID to avoid collisions.
  static const recapNotificationId = 99999;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

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
      final prefs = await SharedPreferences.getInstance();
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

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'masarify_recap',
          'Daily Recap',
          channelDescription: 'Daily spending recap reminder',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
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
  }

  /// Cancel a scheduled notification by [id].
  static Future<void> cancelScheduled(int id) async {
    await _plugin.cancel(id);
  }
}
