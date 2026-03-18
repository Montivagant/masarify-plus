import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows / hides an ongoing Android notification while Masarify is monitoring
/// incoming SMS and bank notifications for automatic transaction detection.
class PersistentNotificationService {
  PersistentNotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'masarify_monitor';
  static const _notificationId = 9999;

  /// Callback for notification action taps. Set in main.dart.
  static void Function(String actionId)? onActionTapped;

  Future<void> show() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Transaction Monitoring',
      channelDescription: 'Shows when Masarify is monitoring transactions',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('voice', 'Add by Voice'),
        AndroidNotificationAction('manual', 'Add Manually'),
        AndroidNotificationAction('pause', 'Pause'),
      ],
    );

    await _plugin.show(
      _notificationId,
      'Masarify is monitoring transactions',
      'Tap an action to get started',
      const NotificationDetails(android: androidDetails),
    );
  }

  Future<void> dismiss() async {
    await _plugin.cancel(_notificationId);
  }
}
