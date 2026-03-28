import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../widgets/onboarding_pages.dart';

/// 5-page onboarding flow:
///   Page 0 — Welcome hero (app value prop + language toggle)
///   Pages 1-3 — Value preview slides (animated feature demos)
///   Page 4 — Account type picker (single tap → dashboard)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  bool _loading = false;
  int _currentIndex = 0;

  static const _pageCount = 5;

  /// Current page offset for parallax — updated on scroll.
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _pageController.page;
    if (page != null) {
      setState(() {
        _currentPage = page;
        _currentIndex = page.round();
      });
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppDurations.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  void _skipToAccountPicker() {
    _pageController.animateToPage(
      _pageCount - 1, // Last page = account picker
      duration: AppDurations.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  /// Calculates per-page parallax offset.
  double _offsetForPage(int pageIndex) => _currentPage - pageIndex;

  /// Called from account type picker — creates wallets and navigates.
  Future<void> _finishWithType(String walletType) async {
    setState(() => _loading = true);
    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      // Auto-create the mandatory Physical Cash system wallet.
      if (!mounted) return;
      await walletRepo.ensureSystemWalletExists(
        localizedName: context.l10n.wallet_type_physical_cash,
      );

      // Create the user's chosen account type with a default name.
      if (walletType != 'physical_cash') {
        if (!mounted) return;
        final defaultName = switch (walletType) {
          'bank' => context.l10n.onboarding_default_bank_name,
          'mobile_wallet' => context.l10n.onboarding_default_mobile_name,
          _ => context.l10n.onboarding_default_wallet_name,
        };
        await walletRepo.create(
          name: defaultName,
          type: walletType,
          initialBalance: 0,
          isDefaultAccount: true,
        );
      }

      // Mark onboarding complete.
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.markOnboardingDone();

      // Start the 7-day Pro trial (single call site — idempotent).
      final subService = ref.read(subscriptionServiceProvider);
      await subService.ensureTrialStarted();

      if (!mounted) return;

      // Brief success overlay.
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: context.colors.scrim.withValues(alpha: 0.6),
        builder: (_) => const _SuccessOverlay(),
      );
      if (!mounted) return;
      SnackHelper.showSuccess(context, context.l10n.trial_started_message);
      context.go(AppRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    // Show skip button on slides 1-3 (value preview), not on welcome or picker.
    final showSkip = _currentIndex >= 1 && _currentIndex <= 3;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex > 0) {
          _pageController.previousPage(
            duration: AppDurations.pageTransition,
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── Skip button ──────────────────────────────────────────────
              if (showSkip)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      top: AppSizes.sm,
                      end: AppSizes.screenHPadding,
                      start: AppSizes.screenHPadding,
                    ),
                    child: TextButton(
                      onPressed: _skipToAccountPicker,
                      child: Text(
                        context.l10n.common_skip,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: AppSizes.xl),

              // ── Pages ────────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    // Page 0: Welcome
                    WelcomePage(
                      onNext: _nextPage,
                      pageOffset: _offsetForPage(0),
                    ),
                    // Page 1: Track in 2 taps
                    ValuePreviewSlide(
                      icon: AppIcons.add,
                      iconColor: cs.primary,
                      title: context.l10n.onboarding_slide1_title,
                      subtitle: context.l10n.onboarding_slide1_body,
                      demoWidget: const TrackingDemo(),
                      pageOffset: _offsetForPage(1),
                    ),
                    // Page 2: Voice input
                    ValuePreviewSlide(
                      icon: AppIcons.mic,
                      iconColor: cs.primary,
                      title: context.l10n.onboarding_slide2_title,
                      subtitle: context.l10n.onboarding_slide2_body,
                      demoWidget: const VoiceDemo(),
                      pageOffset: _offsetForPage(2),
                    ),
                    // Page 3: SMS auto-detect
                    ValuePreviewSlide(
                      icon: AppIcons.sms,
                      iconColor: cs.tertiary,
                      title: context.l10n.onboarding_slide3_title,
                      subtitle: context.l10n.onboarding_slide3_body,
                      demoWidget: const SmsDemo(),
                      pageOffset: _offsetForPage(3),
                    ),
                    // Page 4: Account type picker
                    AccountTypePicker(
                      onTypeSelected: _loading ? (_) {} : _finishWithType,
                      loading: _loading,
                      pageOffset: _offsetForPage(4),
                    ),
                  ],
                ),
              ),

              // ── Page indicator ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.lg),
                child: SmoothPageIndicator(
                  controller: _pageController,
                  count: _pageCount,
                  effect: WormEffect(
                    dotHeight: AppSizes.indicatorDotSize,
                    dotWidth: AppSizes.indicatorDotSize,
                    activeDotColor: cs.primary,
                    dotColor: cs.outlineVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Success Overlay ──────────────────────────────────────────────────────────

class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay();

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay> {
  @override
  void initState() {
    super.initState();
    Future.delayed(AppDurations.splashHold, () {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.xl),
        margin: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: context.colors.shadow
                  .withValues(alpha: AppSizes.opacityLight4),
              blurRadius: AppSizes.lg,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.checkCircle,
              size: AppSizes.iconXl3,
              color: context.colors.primary,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              context.l10n.onboarding_ready_title,
              style: context.textStyles.headlineMedium?.copyWith(
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              context.l10n.onboarding_ready_body,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
