import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/sms_parser_log_dao.dart';
import 'crash_log_service.dart';
import 'notification_transaction_parser.dart';

/// Wraps the notification_listener_service plugin.
///
/// Filters incoming notifications from known financial senders, parses them,
/// deduplicates via SHA-256 hash, and stores pending candidates in
/// [SmsParserLogs] for user review.
class NotificationListenerWrapper {
  NotificationListenerWrapper(this._dao);

  final SmsParserLogDao _dao;
  StreamSubscription<ServiceNotificationEvent>? _subscription;
  bool _disposed = false;
  bool _isStarting = false;

  /// Called after a new pending transaction is stored.
  /// Set this to invalidate providers for live refresh.
  VoidCallback? onNewPending;

  /// Check if the user has granted notification listener permission.
  static Future<bool> hasPermission() async {
    try {
      return await NotificationListenerService.isPermissionGranted();
    } catch (_) {
      return false;
    }
  }

  /// Request the notification listener permission (opens system settings).
  static Future<void> requestPermission() async {
    try {
      await NotificationListenerService.requestPermission();
    } catch (_) {
      // Silently fail — user can always grant later in settings.
    }
  }

  /// Start listening for financial notifications.
  ///
  /// Includes retry logic because the Android NotificationListenerService
  /// may not be fully bound immediately after permission is granted.
  /// Safe to call after [stop] — resets the disposed flag.
  Future<void> start() {
    _disposed = false; // Allow restart after stop()
    return _start(0);
  }

  Future<void> _start(int retryCount) async {
    // Prevent concurrent start() calls (race between lifecycle handlers).
    if (_isStarting && retryCount == 0) {
      debugPrint('[NotificationListener] _start already in progress, skipping');
      return;
    }
    if (retryCount == 0) _isStarting = true;

    try {
      // Guard against double-subscribe
      _subscription?.cancel();
      _subscription = null;

      debugPrint('[NotificationListener] _start(retry=$retryCount)');

      try {
        final hasAccess = await hasPermission();
        debugPrint('[NotificationListener] hasPermission=$hasAccess');
        if (!hasAccess) {
          CrashLogService.log('NotificationListenerWrapper: permission not granted', StackTrace.current);
          return;
        }
      } catch (e, stack) {
        debugPrint('[NotificationListener] permission check error: $e');
        CrashLogService.log(e, stack);
        return;
      }

      try {
        _subscription = NotificationListenerService.notificationsStream.listen(
          _onNotification,
          onError: (Object e, StackTrace stack) {
            debugPrint('[NotificationListener] stream error: $e');
            CrashLogService.log(e, stack);
          },
        );
        debugPrint('[NotificationListener] stream subscribed successfully');
      } catch (e, stack) {
        debugPrint('[NotificationListener] stream subscribe failed (retry=$retryCount): $e');
        CrashLogService.log(e, stack);
        // Retry up to 5 times — service may not be fully bound after permission grant.
        if (retryCount < 5) {
          final delay = Duration(seconds: 1 + retryCount); // 1s, 2s, 3s, 4s, 5s backoff
          debugPrint('[NotificationListener] retrying in ${delay.inSeconds}s...');
          await Future<void>.delayed(delay);
          if (!_disposed) {
            await _start(retryCount + 1);
          }
        } else {
          debugPrint('[NotificationListener] max retries reached, giving up');
        }
      }
    } finally {
      if (retryCount == 0) _isStarting = false;
    }
  }

  /// Stop listening.
  void stop() {
    _isStarting = false;
    _disposed = true;
    try {
      _subscription?.cancel();
    } catch (_) {
      // Subscription already cancelled or stream closed
    }
    _subscription = null;
  }

  // recheckPermission() removed — the settings screen's own WidgetsBindingObserver
  // handles permission re-check on resume. Edge case of granting via system
  // app info screen requires the user to re-toggle the switch.

  /// Dispose resources.
  void dispose() {
    stop();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<void> _onNotification(ServiceNotificationEvent event) async {
    if (_disposed) return;

    try {
      final packageName = event.packageName ?? '';
      final title = event.title ?? '';
      final body = event.content ?? '';

      if (body.isEmpty) return;

      // IM-34 fix: check both package name AND extracted sender for financial match
      final sender = _extractSender(packageName, title);
      if (!NotificationTransactionParser.isFinancialSender(sender) &&
          !NotificationTransactionParser.isFinancialPackage(packageName)) {
        return;
      }

      debugPrint('[NotificationListener] financial notification from $sender');

      // Parse
      final parsed = NotificationTransactionParser.parse(
        sender: sender,
        body: body,
        receivedAt: DateTime.now(),
      );
      if (parsed == null) return;

      if (_disposed) return; // Re-check after parse

      // Insert-first dedup: ON CONFLICT DO NOTHING prevents duplicates
      // without a check-then-act race with the SMS parser.
      await _dao.insertLog(
        SmsParserLogsCompanion.insert(
          senderAddress: parsed.senderAddress,
          bodyHash: parsed.bodyHash,
          body: parsed.body,
          parsedStatus: 'pending',
          source: 'notification',
          receivedAt: parsed.receivedAt,
        ),
      );

      if (_disposed) return; // Re-check after DB insert

      final inserted = await _dao.getByHash(parsed.bodyHash);
      if (inserted == null || inserted.aiEnrichmentJson != null) return;
      if (inserted.source != 'notification') return;

      // AI enrichment is user-initiated from the review screen.
      // Just notify that a new pending item arrived.
      onNewPending?.call();
    } catch (e, stack) {
      debugPrint('[NotificationListener] _onNotification error: $e');
      CrashLogService.log(e, stack);
    }
  }

  String _extractSender(String packageName, String title) {
    // Try to extract a recognizable name from the notification title or package
    if (title.isNotEmpty) return title;
    // Fallback: use the last segment of the package name
    final parts = packageName.split('.');
    return parts.isNotEmpty ? parts.last.toUpperCase() : packageName;
  }
}
