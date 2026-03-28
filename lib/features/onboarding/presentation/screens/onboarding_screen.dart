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
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../widgets/onboarding_pages.dart';

/// 5-page onboarding flow:
///   Page 0 — Welcome hero (app value prop + language toggle)
///   Pages 1-3 — Value preview slides (animated feature demos)
///   Page 4 — Starting balance (optional, skip → 0)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  bool _loading = false;
  int _currentIndex = 0;

  /// Starting balance in piastres — set on Page 4 (optional, defaults to 0).
  int _startingBalancePiastres = 0;

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

  void _skipToStartingBalance() {
    _pageController.animateToPage(
      _pageCount - 1, // Starting balance = last page
      duration: AppDurations.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  /// Calculates per-page parallax offset.
  double _offsetForPage(int pageIndex) => _currentPage - pageIndex;

  /// Creates default bank account with optional starting balance and
  /// navigates to dashboard.
  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      // Auto-create the mandatory Physical Cash system wallet.
      if (!mounted) return;
      await walletRepo.ensureSystemWalletExists(
        localizedName: context.l10n.wallet_type_physical_cash,
      );

      // Create a default bank account with the optional starting balance.
      if (!mounted) return;
      await walletRepo.create(
        name: context.l10n.onboarding_default_bank_name,
        type: 'bank',
        initialBalance: _startingBalancePiastres.clamp(0, (1 << 31) - 1),
        isDefaultAccount: true,
      );

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
        barrierColor:
            context.colors.scrim.withValues(alpha: AppSizes.opacityMedium2),
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

    // Show skip button on slides 1-3 (value preview), not on welcome or balance.
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
                      onPressed: _skipToStartingBalance,
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
                    // Page 3: AI Financial Advisor
                    ValuePreviewSlide(
                      icon: AppIcons.ai,
                      iconColor: cs.primary,
                      title: context.l10n.onboarding_slide3_title,
                      subtitle: context.l10n.onboarding_slide3_body,
                      demoWidget: const ChatDemo(),
                      pageOffset: _offsetForPage(3),
                      footerWidget: Text(
                        context.l10n.disclaimer_financial,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: cs.outline,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Page 4: Starting balance (optional)
                    _StartingBalancePage(
                      pageOffset: _offsetForPage(4),
                      loading: _loading,
                      onAmountChanged: (piastres) =>
                          _startingBalancePiastres = piastres,
                      onFinish: _finish,
                      onSkip: () {
                        _startingBalancePiastres = 0;
                        _finish();
                      },
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

// ── Page 4: Starting Balance ─────────────────────────────────────────────────

class _StartingBalancePage extends StatelessWidget {
  const _StartingBalancePage({
    required this.pageOffset,
    required this.loading,
    required this.onAmountChanged,
    required this.onFinish,
    required this.onSkip,
  });

  final double pageOffset;
  final bool loading;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const Spacer(),
          // ── Icon ───────────────────────────────────────────────────────
          Transform.translate(
            offset: Offset(pageOffset * AppSizes.onboardingParallaxOffset, 0),
            child: Container(
              width: AppSizes.onboardingIcon,
              height: AppSizes.onboardingIcon,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: AppSizes.opacityLight),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.wallet,
                size: AppSizes.iconXl2,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          // ── Title ──────────────────────────────────────────────────────
          Text(
            context.l10n.onboarding_starting_balance_title,
            style: context.textStyles.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.l10n.onboarding_starting_balance_body,
            style: context.textStyles.bodyMedium?.copyWith(
              color: cs.outline,
              height: AppSizes.lineHeightNormal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
          // ── Amount input ───────────────────────────────────────────────
          AmountInput(
            onAmountChanged: onAmountChanged,
            autofocus: false,
          ),
          const Spacer(flex: 2),
          // ── Buttons ────────────────────────────────────────────────────
          if (loading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xl),
              child: CircularProgressIndicator.adaptive(),
            )
          else ...[
            AppButton(
              label: context.l10n.onboarding_starting_balance_set,
              onPressed: onFinish,
              icon: AppIcons.check,
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: onSkip,
              child: Text(
                context.l10n.common_skip,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.outline,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
