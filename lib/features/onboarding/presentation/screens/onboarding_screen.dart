import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../widgets/onboarding_pages.dart';

/// 4-page onboarding flow with glass card design & animations:
///   Page 1 — Welcome hero (app value prop + language toggle)
///   Page 2 — Feature highlights (3 GlassCard feature cards)
///   Page 3 — Account setup (wallet name, type, balance in GlassCard)
///   Page 4 — Ready! (animated checkmark + CTA)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _nameController = TextEditingController();
  int _balancePiastres = 0;
  String _walletType = 'bank';
  bool _loading = false;

  /// Current page offset for parallax — updated on scroll.
  double _currentPage = 0;

  static const _pageCount = 4;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPageScroll() {
    final page = _pageController.page;
    if (page != null) {
      setState(() => _currentPage = page);
    }
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppDurations.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: AppDurations.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  /// Called from Page 4 "Start Tracking" — creates Physical Cash + user wallet.
  Future<void> _finishWithWallet() async {
    setState(() => _loading = true);
    try {
      final walletRepo = ref.read(walletRepositoryProvider);

      // Auto-create the mandatory Physical Cash system wallet.
      await walletRepo.ensureSystemWalletExists();

      if (!mounted) return;
      // Create wallet with user-chosen name and type (defaults: "My Bank", bank)
      final walletName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : context.l10n.onboarding_default_wallet_name;
      await walletRepo.create(
        name: walletName,
        type: _walletType,
        initialBalance: _balancePiastres,
      );

      // Mark onboarding complete
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.markOnboardingDone();

      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

  /// Called from Page 3 "Skip" — creates only Physical Cash, no user wallet.
  Future<void> _finishSkip() async {
    setState(() => _loading = true);
    try {
      final walletRepo = ref.read(walletRepositoryProvider);
      await walletRepo.ensureSystemWalletExists();

      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.markOnboardingDone();

      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

  /// Calculates per-page parallax offset.
  /// 0.0 when the page is centred, ±1.0 when one page away.
  double _offsetForPage(int pageIndex) => _currentPage - pageIndex;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                children: [
                  // ── Page 1: Welcome ────────────────────────────────────
                  WelcomePage(
                    onNext: _nextPage,
                    pageOffset: _offsetForPage(0),
                  ),
                  // ── Page 2: Feature Highlights ─────────────────────────
                  FeaturesPage(
                    onNext: _nextPage,
                    pageOffset: _offsetForPage(1),
                  ),
                  // ── Page 3: Account Setup ──────────────────────────────
                  AccountSetupPage(
                    nameController: _nameController,
                    walletType: _walletType,
                    onWalletTypeChanged: (t) => setState(() => _walletType = t),
                    onAmountChanged: (p) =>
                        setState(() => _balancePiastres = p),
                    onBack: _previousPage,
                    onFinish: _loading ? null : () => _nextPage(),
                    onSkip: _loading ? null : _finishSkip,
                    loading: _loading,
                    pageOffset: _offsetForPage(2),
                  ),
                  // ── Page 4: Ready! ─────────────────────────────────────
                  ReadyPage(
                    onStart: _loading ? null : _finishWithWallet,
                    pageOffset: _offsetForPage(3),
                  ),
                ],
              ),
            ),
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
    );
  }
}
