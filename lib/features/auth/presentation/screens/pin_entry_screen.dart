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
  late final AnimationController _shakeController;
  final _auth = AuthService();

  static const _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDurations.pinPadAnim,
    );
    _checkBiometric();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await _auth.isBiometricAvailable();
    if (!mounted) return;

    final prefs = await ref.read(preferencesFutureProvider.future);
    final biometricEnabled = prefs.isBiometricEnabled;

    setState(() => _biometricAvailable = available && biometricEnabled);

    if (_biometricAvailable) {
      _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    final ok = await _auth.authenticateWithBiometric(
      localizedReason: context.l10n.auth_biometric_prompt,
    );
    if (ok && mounted) {
      _unlock();
    }
  }

  void _onDigit(int digit) {
    if (_pin.length >= _pinLength) return;
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
    if (ok) {
      _unlock();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() => _pin = '');
      if (mounted) {
        SnackHelper.showError(context, context.l10n.auth_pin_wrong);
      }
    }
  }

  void _unlock() {
    // H2 fix: mark app as unlocked so GoRouter redirect guard doesn't loop
    AppLockService.instance.unlock();
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

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
