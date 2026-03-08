import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/app_lock_service.dart';
import '../../../../shared/providers/preferences_provider.dart';

/// Splash screen — brand logo with fade-in animation (1.5s), then auto-routes:
///   - First launch        → OnboardingScreen
///   - Returning + PIN     → PinEntryScreen   (Phase 4)
///   - Returning + no PIN  → DashboardScreen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.splashFade,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _navigate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _controller.duration = Duration.zero;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(AppDurations.splashHold);
    if (!mounted) return;

    final prefs = await ref.read(preferencesFutureProvider.future);
    if (!mounted) return;

    if (!prefs.isOnboardingDone) {
      context.go(AppRoutes.onboarding);
    } else if (prefs.isPinEnabled) {
      // H2 fix: set requiresAuth so GoRouter redirect guard blocks deep links
      AppLockService.instance.setRequiresAuth(true);
      context.go(AppRoutes.pinEntry);
    } else {
      // No PIN — mark as unlocked so redirect guard doesn't interfere
      AppLockService.instance.unlock();
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Scaffold(
      backgroundColor: cs.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.wallet,
                size: AppSizes.splashIconSize,
                color: cs.onPrimary,
              ),
              const SizedBox(height: AppSizes.md),
              Text(
                'Masarify',
                style: context.textStyles.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                'مصاريفي',
                style: context.textStyles.bodyLarge?.copyWith(
                      color: cs.onPrimary.withValues(alpha: AppSizes.opacityStrong),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
