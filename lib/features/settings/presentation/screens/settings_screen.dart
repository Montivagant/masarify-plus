import 'package:another_telephony/telephony.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/config/ai_config.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/crash_log_service.dart';
import '../../../../core/services/notification_listener_wrapper.dart';
import '../../../../core/services/sms_parser_service.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../../shared/providers/ai_provider.dart';
import '../../../../shared/providers/database_provider.dart';
import '../../../../shared/providers/notification_listener_provider.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  String _currency = 'EGP';
  String? _language;
  int _firstDayOfWeek = 6;
  int _firstDayOfMonth = 1;
  bool _notificationParserEnabled = false;
  bool _smsParserEnabled = false;
  String _aiModel = 'auto';
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  int _autoLockTimeoutMs = 0;
  bool _loaded = false;

  /// WS-1 fix: lifecycle-aware permission flow flags.
  bool _awaitingNotificationPermission = false;
  bool _awaitingSmsPermission = false;

  List<({String code, String label})> _currencies(BuildContext context) => [
        (code: 'EGP', label: context.l10n.settings_currency_egp),
        (code: 'USD', label: context.l10n.settings_currency_usd),
        (code: 'EUR', label: context.l10n.settings_currency_eur),
        (code: 'SAR', label: context.l10n.settings_currency_sar),
        (code: 'AED', label: context.l10n.settings_currency_aed),
        (code: 'KWD', label: context.l10n.settings_currency_kwd),
      ];

  List<({int value, String label})> _weekDays(BuildContext context) => [
        (value: 6, label: context.l10n.settings_day_saturday),
        (value: 7, label: context.l10n.settings_day_sunday),
        (value: 1, label: context.l10n.settings_day_monday),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_awaitingNotificationPermission) {
        _finishNotificationPermission();
      }
      if (_awaitingSmsPermission) {
        _finishSmsPermission();
      }
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await ref.read(preferencesFutureProvider.future);
    if (!mounted) return;
    setState(() {
      _currency = prefs.currencyCode;
      _language = ref.read(localeProvider)?.languageCode;
      _firstDayOfWeek = prefs.firstDayOfWeek;
      _firstDayOfMonth = prefs.firstDayOfMonth;
      _notificationParserEnabled = prefs.isNotificationParserEnabled;
      _smsParserEnabled = prefs.isSmsParserEnabled;
      _aiModel = prefs.aiModel;
      _pinEnabled = prefs.isPinEnabled;
      _biometricEnabled = prefs.isBiometricEnabled;
      _autoLockTimeoutMs = prefs.autoLockTimeoutMs;
      _loaded = true;
    });
  }

  Future<void> _setCurrency(String code) async {
    setState(() => _currency = code);
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.setCurrency(code);
  }

  Future<void> _setLanguage(String? lang) async {
    setState(() => _language = lang);
    if (lang == null) {
      ref.read(localeProvider.notifier).clearLocale();
    } else {
      ref.read(localeProvider.notifier).setLocale(lang);
    }
    if (mounted) {
      SnackHelper.showSuccess(context, context.l10n.settings_language_changed);
    }
  }

  Future<void> _setFirstDayOfWeek(int day) async {
    setState(() => _firstDayOfWeek = day);
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.setFirstDayOfWeek(day);
  }

  Future<void> _setFirstDayOfMonth(int day) async {
    setState(() => _firstDayOfMonth = day);
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.setFirstDayOfMonth(day);
  }

  Future<void> _toggleNotificationParser(bool value) async {
    try {
      if (value) {
        // Show rationale before requesting.
        if (!mounted) return;
        final allowed = await PermissionHelper.showRationale(
          context,
          title: context.l10n.permission_notification_title,
          rationale: context.l10n.permission_notification_body,
        );
        if (!allowed || !mounted) return;

        // WS-1 fix: set flag before opening system settings, finish on resume.
        _awaitingNotificationPermission = true;
        await NotificationListenerWrapper.requestPermission();
        // Don't check immediately — Android recreates activity.
        // _finishNotificationPermission() runs on lifecycle resume.
      } else {
        // Stop listener and save pref.
        ref.read(notificationListenerProvider).stop();
        final prefs = await ref.read(preferencesFutureProvider.future);
        await prefs.setNotificationParserEnabled(false);
        if (!mounted) return;
        setState(() => _notificationParserEnabled = false);
      }
    } catch (e) {
      CrashLogService.log(e, StackTrace.current);
      _awaitingNotificationPermission = false;
      if (!mounted) return;
      setState(() => _notificationParserEnabled = !value);
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }

  /// WS-1: called on lifecycle resume after returning from notification settings.
  Future<void> _finishNotificationPermission() async {
    _awaitingNotificationPermission = false;
    try {
      final granted = await NotificationListenerWrapper.hasPermission();
      if (!mounted) return;

      if (!granted) {
        // User didn't grant — no state change needed.
        return;
      }

      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.setNotificationParserEnabled(true);
      if (!mounted) return;
      setState(() => _notificationParserEnabled = true);

      // WS-38 fix: delay before starting listener — Android service needs
      // time to bind after permission is granted.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      // Start the listener.
      final listener = ref.read(notificationListenerProvider);
      listener.onNewPending = () {
        ref.invalidate(pendingParsedTransactionsProvider);
      };
      try {
        await listener.start();
      } catch (e) {
        CrashLogService.log(e, StackTrace.current);
        if (!mounted) return;
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } catch (e) {
      CrashLogService.log(e, StackTrace.current);
      if (!mounted) return;
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }

  Future<void> _toggleSmsParser(bool value) async {
    try {
      if (value) {
        // Show rationale before requesting.
        if (!mounted) return;
        final allowed = await PermissionHelper.showRationale(
          context,
          title: context.l10n.permission_sms_title,
          rationale: context.l10n.permission_sms_body,
        );
        if (!allowed || !mounted) return;

        // WS-1 fix: set flag, request permission, finish on resume or inline.
        _awaitingSmsPermission = true;
        final granted = await Telephony.instance.requestSmsPermissions ?? false;
        // Guard: lifecycle handler may have already run _finishSmsPermission().
        if (!_awaitingSmsPermission) return;
        _awaitingSmsPermission = false;
        if (!granted || !mounted) return;

        await _finishSmsPermission();
      } else {
        final prefs = await ref.read(preferencesFutureProvider.future);
        await prefs.setSmsParserEnabled(false);
        if (!mounted) return;
        setState(() => _smsParserEnabled = false);
      }
    } catch (e) {
      CrashLogService.log(e, StackTrace.current);
      _awaitingSmsPermission = false;
      if (!mounted) return;
      setState(() => _smsParserEnabled = !value);
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }

  /// WS-1: called after SMS permission is granted (inline or on resume).
  Future<void> _finishSmsPermission() async {
    _awaitingSmsPermission = false;
    try {
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.setSmsParserEnabled(true);
      if (!mounted) return;
      setState(() => _smsParserEnabled = true);

      final dao = ref.read(smsParserLogDaoProvider);
      final aiParser = ref.read(aiTransactionParserProvider);
      final categoryRepo = ref.read(categoryRepositoryProvider);
      final cats = await categoryRepo.getAll();
      final count = await SmsParserService(
        dao,
        aiParser: aiParser,
        categories: cats,
      ).scanInbox();
      if (!mounted) return;
      if (count > 0) {
        ref.invalidate(pendingParsedTransactionsProvider);
      }
    } catch (e) {
      CrashLogService.log(e, StackTrace.current);
      if (!mounted) return;
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }

  Future<void> _setAiModel(String model) async {
    setState(() => _aiModel = model);
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.setAiModel(model);
    ref.invalidate(aiModelPreferenceProvider);
  }

  String _aiModelLabel(String model) {
    final l10n = context.l10n;
    return switch (model) {
      'auto' => l10n.settings_ai_model_auto,
      AiConfig.modelGeminiFlash => l10n.settings_ai_model_gemini_flash,
      AiConfig.modelGemma27b => l10n.settings_ai_model_gemma_27b,
      AiConfig.modelQwen3_4b => l10n.settings_ai_model_qwen3_4b,
      _ => model,
    };
  }

  void _showAiModelPicker() {
    final l10n = context.l10n;
    final options = [
      (id: 'auto', label: l10n.settings_ai_model_auto),
      (id: AiConfig.modelGeminiFlash, label: l10n.settings_ai_model_gemini_flash),
      (id: AiConfig.modelGemma27b, label: l10n.settings_ai_model_gemma_27b),
      (id: AiConfig.modelQwen3_4b, label: l10n.settings_ai_model_qwen3_4b),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                l10n.settings_ai_model,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...options.map(
              (o) => ListTile(
                title: Text(o.label),
                trailing: o.id == _aiModel
                    ? Icon(
                        AppIcons.check,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  _setAiModel(o.id);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePin(bool value) async {
    if (value) {
      // Navigate to PIN setup screen — it saves and enables PIN.
      await context.push(AppRoutes.pinSetup);
      // Re-read prefs to reflect the change.
      final prefs = await ref.read(preferencesFutureProvider.future);
      if (!mounted) return;
      setState(() => _pinEnabled = prefs.isPinEnabled);
    } else {
      // Disable PIN — verify first, then remove.
      final verified = await _verifyCurrentPin();
      if (!verified || !mounted) return;

      final auth = AuthService();
      await auth.removePin();
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.disablePin();
      await prefs.disableBiometric();
      if (!mounted) return;
      setState(() {
        _pinEnabled = false;
        _biometricEnabled = false;
      });
      SnackHelper.showSuccess(context, context.l10n.settings_pin_disabled);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    final auth = AuthService();
    if (value) {
      final available = await auth.isBiometricAvailable();
      if (!available) {
        if (mounted) {
          SnackHelper.showError(
            context,
            context.l10n.settings_biometric_unavailable,
          );
        }
        return;
      }
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.enableBiometric();
      if (!mounted) return;
      setState(() => _biometricEnabled = true);
      SnackHelper.showSuccess(context, context.l10n.settings_biometric_enabled);
    } else {
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.disableBiometric();
      if (!mounted) return;
      setState(() => _biometricEnabled = false);
      SnackHelper.showSuccess(
        context,
        context.l10n.settings_biometric_disabled,
      );
    }
  }

  Future<bool> _verifyCurrentPin() async {
    final l10n = context.l10n;
    var pin = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settings_verify_pin_first),
        content: TextField(
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: '••••••',
            border: OutlineInputBorder(),
            isDense: true,
            counterText: '',
          ),
          onChanged: (v) => pin = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              final auth = AuthService();
              final ok = await auth.verifyPin(pin);
              if (ctx.mounted) Navigator.pop(ctx, ok);
            },
            child: Text(l10n.common_done),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _changePin() async {
    final verified = await _verifyCurrentPin();
    if (!verified || !mounted) return;
    await context.push(AppRoutes.pinSetup);
  }

  String _autoLockLabel(dynamic l10n) {
    return switch (_autoLockTimeoutMs) {
      0 => l10n.settings_auto_lock_immediate as String,
      60000 => l10n.settings_auto_lock_1_min as String,
      300000 => l10n.settings_auto_lock_5_min as String,
      _ => l10n.settings_auto_lock_immediate as String,
    };
  }

  void _showAutoLockPicker() {
    final l10n = context.l10n;
    final options = [
      (ms: 0, label: l10n.settings_auto_lock_immediate),
      (ms: 60000, label: l10n.settings_auto_lock_1_min),
      (ms: 300000, label: l10n.settings_auto_lock_5_min),
    ];
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                l10n.settings_auto_lock,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...options.map(
              (o) => ListTile(
                title: Text(o.label),
                trailing: o.ms == _autoLockTimeoutMs
                    ? Icon(
                        AppIcons.check,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () async {
                  final prefs =
                      await ref.read(preferencesFutureProvider.future);
                  await prefs.setAutoLockTimeoutMs(o.ms);
                  if (mounted) {
                    setState(() => _autoLockTimeoutMs = o.ms);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed || !mounted) return;

    final db = ref.read(databaseProvider);
    // M16 fix: wrap in single transaction for atomicity
    // H8 fix: include exchange_rates (11th table) in clear sequence
    await db.transaction(() async {
      await db.customStatement('DELETE FROM transactions');
      await db.customStatement('DELETE FROM transfers');
      await db.customStatement('DELETE FROM budgets');
      await db.customStatement('DELETE FROM goal_contributions');
      await db.customStatement('DELETE FROM savings_goals');
      await db.customStatement('DELETE FROM recurring_rules');
      await db.customStatement('DELETE FROM bills');
      await db.customStatement('DELETE FROM sms_parser_logs');
      await db.customStatement('DELETE FROM exchange_rates');
      await db.customStatement('DELETE FROM wallets');
      await db.customStatement('DELETE FROM categories');
    });

    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.clearAll();

    // IM-21 fix: re-seed default categories so the app isn't empty after re-onboarding
    await ref.read(categoryRepositoryProvider).seedDefaultsIfEmpty();

    if (!mounted) return;
    context.go(AppRoutes.onboarding);
  }

  Future<bool> _showDeleteConfirmation() async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.settings_clear_data_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settings_clear_data_warning),
              const SizedBox(height: AppSizes.md),
              Text(l10n.settings_clear_data_confirm),
              const SizedBox(height: AppSizes.sm),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.settings_delete_confirm_word,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: controller.text == l10n.settings_delete_confirm_word
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              child: Text(l10n.settings_clear_data_permanent),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final cs = Theme.of(context).colorScheme;

    final l10n = context.l10n;

    if (!_loaded) {
      return Scaffold(
        appBar: AppAppBar(title: l10n.settings_title),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Scaffold(
      appBar: AppAppBar(title: l10n.settings_title),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_appearance),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
              vertical: AppSizes.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settings_theme,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.outline),
                ),
                const SizedBox(height: AppSizes.sm),
                SegmentedButton<ThemeMode>(
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text(l10n.settings_theme_auto),
                      icon: const Icon(AppIcons.settings, size: AppSizes.iconXs),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text(l10n.settings_theme_light),
                      icon: const Icon(AppIcons.themeLight, size: AppSizes.iconXs),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text(l10n.settings_theme_dark),
                      icon: const Icon(AppIcons.theme, size: AppSizes.iconXs),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (set) =>
                      ref.read(themeModeProvider.notifier).setMode(set.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          // ── Language ───────────────────────────────────────────────────
          Builder(builder: (context) {
            final langCode = ref.watch(localeProvider)?.languageCode;
            return _SettingsTile(
              icon: AppIcons.language,
              label: l10n.settings_language,
              subtitle: switch (langCode) {
                'ar' => l10n.language_ar,
                'en' => l10n.language_en,
                _ => l10n.language_system,
              },
              onTap: () => _showLanguagePicker(),
            );
          },),

          // ── General ───────────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_general),
          _SettingsTile(
            icon: AppIcons.currency,
            label: l10n.settings_currency,
            subtitle: _currencies(context)
                .firstWhere((c) => c.code == _currency, orElse: () => _currencies(context).first)
                .label,
            onTap: () => _showCurrencyPicker(),
          ),
          _SettingsTile(
            icon: AppIcons.calendar,
            label: l10n.settings_first_day_of_week,
            subtitle: _weekDays(context)
                .firstWhere((d) => d.value == _firstDayOfWeek, orElse: () => _weekDays(context).first)
                .label,
            onTap: () => _showWeekDayPicker(),
          ),
          _SettingsTile(
            icon: AppIcons.calendar,
            label: l10n.settings_first_day_budget_cycle,
            subtitle: '$_firstDayOfMonth',
            onTap: () => _showMonthDayPicker(),
          ),

          // ── Data management ─────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_data_management),
          _SettingsTile(
            icon: AppIcons.wallet,
            label: l10n.settings_wallets_label,
            subtitle: l10n.settings_wallets_subtitle,
            onTap: () => context.push(AppRoutes.wallets),
          ),
          _SettingsTile(
            icon: AppIcons.category,
            label: l10n.settings_categories_label,
            subtitle: l10n.settings_categories_subtitle,
            onTap: () => context.push(AppRoutes.categories),
          ),

          // ── Smart Input ──────────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_smart_input),
          SwitchListTile(
            secondary: Container(
              width: AppSizes.colorSwatchSize,
              height: AppSizes.colorSwatchSize,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Icon(
                AppIcons.notification,
                size: AppSizes.iconSm,
                color: cs.onPrimaryContainer,
              ),
            ),
            title: Text(l10n.settings_notification_parser),
            subtitle: Text(l10n.settings_notification_parser_subtitle),
            value: _notificationParserEnabled,
            onChanged: _toggleNotificationParser,
          ),
          SwitchListTile(
            secondary: Container(
              width: AppSizes.colorSwatchSize,
              height: AppSizes.colorSwatchSize,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Icon(
                AppIcons.sms,
                size: AppSizes.iconSm,
                color: cs.onPrimaryContainer,
              ),
            ),
            title: Text(l10n.settings_sms_parser),
            subtitle: Text(l10n.settings_sms_parser_subtitle),
            value: _smsParserEnabled,
            onChanged: _toggleSmsParser,
          ),
          _SettingsTile(
            icon: AppIcons.ai,
            label: l10n.settings_ai_model,
            subtitle: _aiModelLabel(_aiModel),
            onTap: _showAiModelPicker,
          ),

          // ── Security ────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_security),
          SwitchListTile(
            secondary: Container(
              width: AppSizes.colorSwatchSize,
              height: AppSizes.colorSwatchSize,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Icon(
                AppIcons.pin,
                size: AppSizes.iconSm,
                color: cs.onPrimaryContainer,
              ),
            ),
            title: Text(l10n.settings_pin_lock_label),
            subtitle: Text(l10n.settings_pin_subtitle),
            value: _pinEnabled,
            onChanged: _togglePin,
          ),
          SwitchListTile(
            secondary: Container(
              width: AppSizes.colorSwatchSize,
              height: AppSizes.colorSwatchSize,
              decoration: BoxDecoration(
                color: _pinEnabled
                    ? cs.primaryContainer
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Icon(
                AppIcons.security,
                size: AppSizes.iconSm,
                color: _pinEnabled ? cs.onPrimaryContainer : cs.outline,
              ),
            ),
            title: Text(
              l10n.settings_biometric,
              style: TextStyle(color: _pinEnabled ? null : cs.outline),
            ),
            subtitle: Text(l10n.settings_biometric_subtitle),
            value: _biometricEnabled,
            onChanged: _pinEnabled ? _toggleBiometric : null,
          ),
          if (_pinEnabled)
            _SettingsTile(
              icon: AppIcons.calendar,
              label: l10n.settings_auto_lock,
              subtitle: _autoLockLabel(l10n),
              onTap: _showAutoLockPicker,
            ),
          if (_pinEnabled)
            _SettingsTile(
              icon: AppIcons.pin,
              label: l10n.settings_pin_change,
              onTap: () => _changePin(),
            ),

          // ── Backup & export ───────────────────────────────────────────
          _SectionHeader(title: l10n.settings_backup_section),
          _SettingsTile(
            icon: AppIcons.backup,
            label: l10n.settings_backup_label,
            subtitle: l10n.settings_backup_subtitle,
            onTap: () => context.push(AppRoutes.settingsBackup),
          ),

          // ── Danger zone ───────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_danger_zone),
          _SettingsTile(
            icon: AppIcons.delete,
            label: l10n.settings_clear_data_label,
            subtitle: l10n.settings_clear_data_subtitle,
            onTap: _clearAllData,
          ),

          // ── About ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.settings_about_section),
          _AppVersionTile(),
          _SettingsTile(
            icon: AppIcons.help,
            label: l10n.settings_help_label,
            subtitle: l10n.settings_help_subtitle,
            trailing: _ComingSoonChip(),
            onTap: null,
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    final l10n = context.l10n;
    final currencies = _currencies(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                l10n.settings_currency,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...currencies.map(
              (c) => ListTile(
                title: Text(c.label),
                trailing: c.code == _currency
                    ? Icon(
                        AppIcons.check,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  _setCurrency(c.code);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                l10n.settings_language,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              title: Text(l10n.language_system),
              trailing: _language == null
                  ? Icon(
                      AppIcons.check,
                      color: Theme.of(ctx).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                _setLanguage(null);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.language_ar),
              trailing: _language == 'ar'
                  ? Icon(
                      AppIcons.check,
                      color: Theme.of(ctx).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                _setLanguage('ar');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: Text(l10n.language_en),
              trailing: _language == 'en'
                  ? Icon(
                      AppIcons.check,
                      color: Theme.of(ctx).colorScheme.primary,
                    )
                  : null,
              onTap: () {
                _setLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  void _showWeekDayPicker() {
    final l10n = context.l10n;
    final weekDays = _weekDays(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                l10n.settings_first_day_of_week,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ...weekDays.map(
              (d) => ListTile(
                title: Text(d.label),
                trailing: d.value == _firstDayOfWeek
                    ? Icon(
                        AppIcons.check,
                        color: Theme.of(ctx).colorScheme.primary,
                      )
                    : null,
                onTap: () {
                  _setFirstDayOfWeek(d.value);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  void _showMonthDayPicker() {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.settings_first_day_of_month,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                l10n.settings_budget_cycle_subtitle,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: AppSizes.md),
              SizedBox(
                height: AppSizes.chartHeightSm,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 40,
                  controller: FixedExtentScrollController(
                    initialItem: _firstDayOfMonth - 1,
                  ),
                  onSelectedItemChanged: (i) => _setFirstDayOfMonth(i + 1),
                  physics: const FixedExtentScrollPhysics(),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 28,
                    builder: (ctx, i) => Center(
                      child: Text(
                        '${i + 1}',
                        style: Theme.of(ctx).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              AppButton(
                label: l10n.common_done,
                icon: AppIcons.check,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.screenHPadding,
        AppSizes.lg,
        AppSizes.screenHPadding,
        AppSizes.xs,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return ListTile(
      leading: Container(
        width: AppSizes.colorSwatchSize,
        height: AppSizes.colorSwatchSize,
        decoration: BoxDecoration(
          color: enabled
              ? cs.primaryContainer
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconSm,
          color: enabled ? cs.onPrimaryContainer : cs.outline,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(color: enabled ? null : cs.outline),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ??
          (enabled
              ? Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? AppIcons.chevronLeft
                      : AppIcons.chevronRight,
                )
              : null),
      onTap: onTap,
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
      ),
      child: Text(
        context.l10n.common_coming_soon,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.outline,
            ),
      ),
    );
  }
}

class _AppVersionTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data != null
            ? '${snapshot.data!.version} (${snapshot.data!.buildNumber})'
            : '—';
        return ListTile(
          leading: Container(
            width: AppSizes.colorSwatchSize,
            height: AppSizes.colorSwatchSize,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: Icon(
              AppIcons.info,
              size: AppSizes.iconSm,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(context.l10n.settings_version),
          subtitle: Text(version),
        );
      },
    );
  }
}
