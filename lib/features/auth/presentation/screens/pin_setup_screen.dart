import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

/// PIN Setup — two phases: Enter PIN → Confirm PIN.
/// On success, stores SHA-256 hash via [AuthService] and enables PIN in prefs.
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String _firstPin = '';
  bool _isConfirming = false;
  late final AnimationController _shakeController;

  static const _pinLength = 6;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: AppDurations.pinPadAnim,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(int digit) {
    if (_pin.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() => _pin += digit.toString());
    if (_pin.length == _pinLength) {
      _onPinComplete();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _onPinComplete() async {
    if (!_isConfirming) {
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _isConfirming = true;
      });
      return;
    }

    if (_pin == _firstPin) {
      final auth = AuthService();
      await auth.setPin(_pin);
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.enablePin();
      if (!mounted) return;
      SnackHelper.showSuccess(context, context.l10n.settings_pin_enabled);
      context.pop();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0);
      setState(() {
        _pin = '';
        _firstPin = '';
        _isConfirming = false;
      });
      if (mounted) {
        SnackHelper.showError(context, context.l10n.auth_pin_mismatch);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = context.colors;

    return Scaffold(
      appBar: AppAppBar(title: l10n.auth_pin_setup_title),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Text(
                _isConfirming
                    ? l10n.auth_pin_confirm
                    : l10n.auth_pin_setup_subtitle,
                style: context.textStyles.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSizes.xl),
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
            ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}
