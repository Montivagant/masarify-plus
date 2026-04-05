import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/constants/app_durations.dart';
import 'core/constants/app_routes.dart';
import 'core/services/crash_log_service.dart';
import 'core/services/glass_config_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/recurring_scheduler.dart';
import 'core/services/sms_parser_service.dart';
import 'l10n/app_localizations.dart';
import 'shared/providers/database_provider.dart';
import 'shared/providers/pending_transactions_provider.dart';
import 'shared/providers/repository_providers.dart';
import 'shared/providers/subscription_provider.dart';
import 'shared/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
  NotificationService.setSharedPreferences(prefs);
  await NotificationService.initialize();
  // Request POST_NOTIFICATIONS permission early (Android 13+).
  // Without this, all show() and zonedSchedule() calls silently fail.
  // The system dialog only appears once — subsequent launches are a no-op.
  await NotificationService.requestPermission();
  // Request exact alarm permission (Android 14+) for zonedSchedule().
  await NotificationService.requestExactAlarmPermission();

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

  // M-7 fix: ensure Cash wallet exists even after DB restore/corruption.
  // Resolve platform locale so the wallet name is localized (not hardcoded 'Cash').
  final platformLocale = PlatformDispatcher.instance.locale;
  final l10n = lookupAppLocalizations(
    AppLocalizations.supportedLocales.contains(platformLocale)
        ? platformLocale
        : const Locale('en'),
  );
  unawaited(
    container.read(walletRepositoryProvider).ensureSystemWalletExists(
          localizedName: l10n.wallet_type_physical_cash,
        ),
  );

  // C-4 fix: wire notification tap callback for deep-link navigation
  NotificationService.onNotificationTap = (payload) {
    if (payload != null) _handleNotificationPayload(payload);
  };

  // Initialize subscription service (IAP listener).
  final subService = container.read(subscriptionServiceProvider);
  unawaited(subService.initialize());

  // Reschedule daily recap notification if user enabled it (survives app kill / reboot).
  unawaited(
    container
        .read(notificationTriggerServiceProvider)
        .rescheduleRecapIfEnabled(),
  );

  // CR-13 fix: run RecurringScheduler AFTER runApp() to avoid blocking splash.
  unawaited(
    RecurringScheduler(
      ruleRepository: container.read(recurringRuleRepositoryProvider),
      transactionRepository: container.read(transactionRepositoryProvider),
      walletRepository: container.read(walletRepositoryProvider),
      categoryRepository: container.read(categoryRepositoryProvider),
      sharedPreferences: prefs,
    ).run(),
  );

  // Scan SMS inbox in background after UI is mounted (Android only — local
  // parsing only, no AI enrichment — user triggers enrichment from review screen).
  if (Platform.isAndroid && PreferencesService(prefs).isSmsParserEnabled) {
    unawaited(_scanSmsInBackground(container));
  }

  // M-18 fix: handle cold-start from notification tap.
  final launchPayload = await NotificationService.getLaunchPayload();
  if (launchPayload != null) {
    // Delay slightly to let the router initialize after splash.
    Future<void>.delayed(AppDurations.notificationLaunchDelay, () {
      _handleNotificationPayload(launchPayload);
    });
  }
}

/// Shared notification payload → route mapping.
/// Used by both warm-start tap callback and cold-start launch handler.
void _handleNotificationPayload(String payload) {
  if (payload == 'recap') {
    appRouter.go(AppRoutes.chat);
  } else if (payload.startsWith('recurring:')) {
    appRouter.go(AppRoutes.recurring);
  } else if (payload.startsWith('budget:')) {
    appRouter.go(AppRoutes.analytics);
  } else if (payload.startsWith('goal:')) {
    appRouter.go(AppRoutes.hub);
  }
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
