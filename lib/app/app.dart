import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_routes.dart';
import '../core/services/app_lock_service.dart';
import '../core/utils/money_formatter.dart';
import '../l10n/app_localizations.dart';
import '../shared/providers/preferences_provider.dart';
import '../shared/providers/theme_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// Root app widget.
class MasarifyApp extends ConsumerStatefulWidget {
  const MasarifyApp({super.key});

  @override
  ConsumerState<MasarifyApp> createState() => _MasarifyAppState();
}

class _MasarifyAppState extends ConsumerState<MasarifyApp>
    with WidgetsBindingObserver {
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLock();
    }
  }

  Future<void> _checkAutoLock() async {
    if (_pausedAt == null) return;
    final prefs = await ref.read(preferencesFutureProvider.future);
    if (!prefs.isPinEnabled) {
      _pausedAt = null;
      return;
    }

    final timeoutMs = prefs.autoLockTimeoutMs;
    final elapsed = DateTime.now().difference(_pausedAt!).inMilliseconds;
    _pausedAt = null;

    if (elapsed >= timeoutMs) {
      // CR-9 fix: lock BEFORE navigating so GoRouter redirect guard is armed
      AppLockService.instance.lock();
      appRouter.go(AppRoutes.pinEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final effectiveLang = locale?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final resolvedLang = (effectiveLang == 'ar') ? 'ar' : 'en';
    MoneyFormatter.setLocale(resolvedLang);

    return MaterialApp.router(
      title: 'Masarify',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),

      // Router
      routerConfig: appRouter,

      // Localization
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      locale: locale,
    );
  }
}
