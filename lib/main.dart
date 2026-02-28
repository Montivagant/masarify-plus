import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/crash_log_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/preferences_service.dart';
import 'core/services/recurring_scheduler.dart';
import 'core/services/sms_parser_service.dart';
import 'shared/providers/ai_provider.dart';
import 'shared/providers/database_provider.dart';
import 'shared/providers/notification_listener_provider.dart';
import 'shared/providers/pending_transactions_provider.dart';
import 'shared/providers/repository_providers.dart';
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

  await NotificationService.initialize();

  // Run init tasks before UI mounts, reusing the same container.
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // Seed default categories if the table is empty (first launch).
  await container.read(categoryRepositoryProvider).seedDefaultsIfEmpty();

  // Start notification listener if user has enabled it.
  if (PreferencesService(prefs).isNotificationParserEnabled) {
    final listener = container.read(notificationListenerProvider);
    listener.onNewPending = () {
      container.invalidate(pendingParsedTransactionsProvider);
    };
    await listener.start();
  }

  // Launch app FIRST, then run background tasks.
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MasarifyApp(),
    ),
  );

  // CR-13 fix: run RecurringScheduler AFTER runApp() to avoid blocking splash.
  unawaited(
    RecurringScheduler(
      ruleRepository: container.read(recurringRuleRepositoryProvider),
      transactionRepository: container.read(transactionRepositoryProvider),
      walletRepository: container.read(walletRepositoryProvider),
      categoryRepository: container.read(categoryRepositoryProvider),
    ).run(),
  );

  // Scan SMS inbox in background after UI is mounted.
  if (PreferencesService(prefs).isSmsParserEnabled) {
    _scanSmsInBackground(container);
  }
}

/// H1 fix: run SMS scan asynchronously after app launch.
/// Loads categories directly from DAO instead of from provider
/// (which hasn't emitted yet at startup).
Future<void> _scanSmsInBackground(ProviderContainer container) async {
  final smsDao = container.read(smsParserLogDaoProvider);
  final aiParser = container.read(aiTransactionParserProvider);
  // Load categories from repository directly — StreamProvider hasn't emitted yet
  final categoryRepo = container.read(categoryRepositoryProvider);
  final categories = await categoryRepo.getAll();
  final count = await SmsParserService(
    smsDao,
    aiParser: aiParser,
    categories: categories,
  ).scanInbox();
  if (count > 0) {
    container.invalidate(pendingParsedTransactionsProvider);
  }
}
