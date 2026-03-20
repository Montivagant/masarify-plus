import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
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
  if (Platform.isAndroid && PreferencesService(prefs).isSmsParserEnabled) {
    unawaited(_scanSmsInBackground(container));
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
