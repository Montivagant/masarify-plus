import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

/// PIN Entry — unlock the app with 6-digit PIN or biometric.
class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _biometricAvailable = false;

  // setState is used for _lockedOut and _failedAttempts despite being security
  // state because the authoritative values are persisted in secure storage via
  // AuthService (setFailedAttempts / setLockoutUntil). These fields mirror that
  // persisted state for UI reactivity, and _restoreLockoutState() rehydrates
  // them on widget rebuild.
  bool _lockedOut = false;
  int _failedAttempts = 0;
  late final AnimationController _shakeController;
  final _auth = AuthService();

  static const _pinLength = 6;
  static const _maxAttempts = 5;
  static const _lockoutDurations = [
    AppDurations.lockoutDuration,
    AppDurations.lockoutDurationMid,
    AppDurations.lockoutDurationMax,
  ];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDurations.pinPadAnim,
    );
    _restoreLockoutState();
    _checkBiometric();
  }

  Future<void> _restoreLockoutState() async {
    final attempts = await _auth.getFailedAttempts();
    final lockoutUntil = await _auth.getLockoutUntil();
    if (!mounted) return;
    setState(() => _failedAttempts = attempts);
    if (lockoutUntil != null && lockoutUntil.isAfter(DateTime.now())) {
      final remaining = lockoutUntil.difference(DateTime.now());
      setState(() => _lockedOut = true);
      Future.delayed(remaining, () {
        if (mounted) setState(() => _lockedOut = false);
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    try {
      final available = await _auth.isBiometricAvailable();
      if (!mounted) return;

      final prefs = await ref.read(preferencesFutureProvider.future);
      if (!mounted) return;
      final biometricEnabled = prefs.isBiometricEnabled;

      setState(() => _biometricAvailable = available && biometricEnabled);

      if (_biometricAvailable) {
        _tryBiometric();
      }
    } catch (_) {
      // Biometric check failed — PIN entry remains available
      if (mounted) setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _tryBiometric() async {
    try {
      final ok = await _auth.authenticateWithBiometric(
        localizedReason: context.l10n.auth_biometric_prompt,
      );
      if (!mounted) return;
      if (ok) {
        _unlock();
      }
    } catch (e) {
      dev.log('Biometric check failed: $e', name: 'PinEntryScreen');
    }
  }

  void _onDigit(int digit) {
    if (_pin.length >= _pinLength || _lockedOut) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit.toString());
    if (_pin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verifyPin() async {
    final ok = await _auth.verifyPin(_pin);
    if (!mounted) return;
    if (ok) {
      _failedAttempts = 0;
      await _auth.clearLockout();
      if (!mounted) return;
      _unlock();
    } else {
      _failedAttempts++;
      await _auth.setFailedAttempts(_failedAttempts);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      if (!context.reduceMotion) _shakeController.forward(from: 0);
      setState(() => _pin = '');
      if (_failedAttempts >= _maxAttempts) {
        _startLockout();
      } else {
        SnackHelper.showError(context, context.l10n.auth_pin_wrong);
      }
    }
  }

  Future<void> _startLockout() async {
    // Exponential backoff: 30s, 5min, 30min (capped)
    final lockoutIndex = ((_failedAttempts - _maxAttempts) ~/ _maxAttempts)
        .clamp(0, _lockoutDurations.length - 1);
    final duration = _lockoutDurations[lockoutIndex];
    final lockoutUntil = DateTime.now().add(duration);
    await _auth.setLockoutUntil(lockoutUntil);
    if (!mounted) return;
    setState(() => _lockedOut = true);
    final durationStr = duration.inSeconds >= 60
        ? '${duration.inMinutes}m'
        : '${duration.inSeconds}s';
    SnackHelper.showError(
      context,
      context.l10n.settings_pin_lockout(durationStr),
    );
    Future.delayed(duration, () {
      if (mounted) setState(() => _lockedOut = false);
    });
  }

  void _unlock() {
    // H2 fix: mark app as unlocked so GoRouter redirect guard doesn't loop
    AppLockService.instance.unlock();
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = context.colors;

    return Scaffold(
      appBar: AppAppBar(
        title: l10n.auth_pin_entry_title,
        showBack: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Icon(
              AppIcons.security,
              size: AppSizes.iconXl,
              color: cs.primary,
            ),
            const SizedBox(height: AppSizes.lg),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (_, child) {
                final dx = _shakeController.isAnimating
                    ? 10 *
                        (0.5 - _shakeController.value).abs() *
                        (_shakeController.value < 0.5 ? 1 : -1)
                    : 0.0;
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: PinDots(filledCount: _pin.length),
            ),
            const Spacer(flex: 3),
            PinKeypad(
              onDigit: _onDigit,
              onBackspace: _onBackspace,
              bottomLeft: _biometricAvailable
                  ? IconButton(
                      onPressed: _tryBiometric,
                      icon: const Icon(AppIcons.fingerprint),
                      iconSize: AppSizes.iconLg,
                      tooltip: l10n.auth_use_pin,
                      style: IconButton.styleFrom(
                        minimumSize: const Size(
                          AppSizes.minTapTarget,
                          AppSizes.minTapTarget,
                        ),
                      ),
                    )
                  : null,
            ),
            if (_biometricAvailable)
              TextButton(
                onPressed: _tryBiometric,
                child: Text(l10n.auth_use_pin),
              ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}
