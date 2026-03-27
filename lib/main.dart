import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/config/app_config.dart';
import 'core/constants/app_routes.dart';
import 'core/services/bill_reminder_service.dart';
import 'core/services/crash_log_service.dart';
import 'core/services/glass_config_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/recurring_scheduler.dart';
import 'core/services/sms_parser_service.dart';
import 'shared/providers/database_provider.dart';
import 'shared/providers/pending_transactions_provider.dart';
import 'shared/providers/repository_providers.dart';
import 'shared/providers/subscription_provider.dart';
import 'shared/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — offline-first requirement.
  // Fonts are bundled via google_fonts asset directory or cached on first use.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize crash log service before anything else.
  await CrashLogService.initialize();

  // Capture Flutter framework errors.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashLogService.log(details.exception, details.stack ?? StackTrace.current);
  };

  // Capture async / platform errors.
  PlatformDispatcher.instance.onError = (error, stack) {
    CrashLogService.log(error, stack);
    return true;
  };

  // Pre-load SharedPreferences before anything else to avoid
  // race conditions in theme/locale providers.
  final prefs = await SharedPreferences.getInstance();

  await GlassConfig.initialize();
  await NotificationService.initialize();

  // Run init tasks before UI mounts, reusing the same container.
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Seed default categories if the table is empty (first launch).
  await container.read(categoryRepositoryProvider).seedDefaultsIfEmpty();

  // Launch app FIRST, then run background tasks.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MasarifyApp(),
    ),
  );

  // Wire notification tap handler — navigates to chat in recap mode.
  // Uses `go` (not `push`) so it works even on cold start when there's
  // no existing route stack. Also resets _recapSentThisSession so a fresh
  // recap notification tap always triggers the priming message.
  NotificationService.onNotificationTap = (payload) {
    if (payload != null && payload == 'recap') {
      appRouter.go('${AppRoutes.chat}?mode=recap');
    }
  };

  // Initialize subscription service (IAP listener + trial).
  final subService = container.read(subscriptionServiceProvider);
  unawaited(subService.initialize());
  unawaited(subService.ensureTrialStarted());

  // CR-13 fix: run RecurringScheduler AFTER runApp() to avoid blocking splash.
  unawaited(
    RecurringScheduler(
      ruleRepository: container.read(recurringRuleRepositoryProvider),
      walletRepository: container.read(walletRepositoryProvider),
      categoryRepository: container.read(categoryRepositoryProvider),
    ).run(),
  );

  // Scan SMS inbox in background after UI is mounted (Android only — local
  // parsing only, no AI enrichment — user triggers enrichment from review screen).
  // Guarded by kSmsEnabled (hidden in AI-first pivot — see app_config.dart).
  if (AppConfig.kSmsEnabled &&
      Platform.isAndroid &&
      PreferencesService(prefs).isSmsParserEnabled) {
    unawaited(_scanSmsInBackground(container));
  }

  // Schedule daily spending recap notification (if user has it enabled).
  // L10n not available pre-UI, so use locale pref to pick strings manually.
  final prefsService = PreferencesService(prefs);
  if (prefsService.notifyDailyReminder) {
    final isAr = prefsService.language == 'ar';
    unawaited(
      NotificationService.scheduleDaily(
        id: NotificationService.recapNotificationId,
        title: isAr
            ? 'إزاي كانت مصاريفك النهارده؟'
            : 'How was your spending today?',
        body: isAr
            ? 'اضغط وقولي — هسجلها ليك'
            : 'Tap to tell me — I\'ll log it for you',
        hour: prefsService.dailyReminderHour,
        minute: prefsService.dailyReminderMinute,
        payload: 'recap',
      ),
    );
  }

  // Schedule bill reminder notifications (fire-and-forget, non-blocking).
  unawaited(_scheduleBillReminders(container, prefs));
}

/// Scan SMS inbox for financial messages (local regex parsing only).
/// AI enrichment is deferred to user action on the review screen.
Future<void> _scanSmsInBackground(ProviderContainer container) async {
  final smsDao = container.read(smsParserLogDaoProvider);
  final count = await SmsParserService(smsDao).scanInbox();
  if (count > 0) {
    container.invalidate(pendingParsedTransactionsProvider);
  }
}

/// Schedule bill reminder notifications for upcoming bills.
/// Non-critical — silently ignores errors on startup.
Future<void> _scheduleBillReminders(
  ProviderContainer container,
  SharedPreferences prefs,
) async {
  try {
    final prefsService = PreferencesService(prefs);
    final recurringRepo = container.read(recurringRuleRepositoryProvider);
    final allRules = await recurringRepo.getAll();

    // Filter to active, unpaid rules with nextDueDate within 7 days.
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 7));
    final upcoming = allRules.where((r) {
      if (!r.isActive || r.isPaid) return false;
      return r.nextDueDate.isAfter(now) && r.nextDueDate.isBefore(cutoff);
    }).toList();

    await BillReminderService.scheduleUpcoming(upcoming, prefsService);
  } catch (_) {
    // Non-critical — silently ignore errors on startup.
  }
}
