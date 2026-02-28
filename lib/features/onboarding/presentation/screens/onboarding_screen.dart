import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';

/// 2-page onboarding flow per TASKS.md §2.1:
///   Page 1 — Welcome hero (app value prop)
///   Page 2 — Single AmountInput: "What's your starting cash balance?"
///            Wallet name auto = "Cash", type auto = cash.
///
/// Skip behavior: If user skips or enters 0 → auto-create "Cash" wallet,
/// 0 balance, EGP.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _balancePiastres = 0;
  bool _loading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      // Auto-create default Cash wallet
      await ref.read(walletRepositoryProvider).create(
            name: context.l10n.onboarding_default_wallet_name,
            type: 'cash',
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
      // C3 fix: show error feedback so user isn't stuck
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _BalancePage(
                    onAmountChanged: (p) =>
                        setState(() => _balancePiastres = p),
                    onFinish: _loading ? null : _finish,
                    onSkip: _loading ? null : _finish,
                    loading: _loading,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.lg),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 2,
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
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

// ── Page 1: Welcome ─────────────────────────────────────────────────────────

class _WelcomePage extends ConsumerWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider)?.languageCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.lg),
          // ── Language toggle ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.onboarding_language_prompt,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(width: AppSizes.sm),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {currentLocale ?? (Localizations.localeOf(context).languageCode == 'ar' ? 'ar' : 'en')},
                onSelectionChanged: (set) =>
                    ref.read(localeProvider.notifier).setLocale(set.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: AppSizes.onboardingIcon,
            height: AppSizes.onboardingIcon,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: AppSizes.opacityLight),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.wallet,
              size: AppSizes.iconXl2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Text(
            context.l10n.onboarding_page1_title,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            context.l10n.onboarding_page1_body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  height: AppSizes.lineHeightRelaxed,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            alignment: WrapAlignment.center,
            children: [
              _FeatureChip(icon: AppIcons.wallet, label: context.l10n.onboarding_feature_wallets),
              _FeatureChip(icon: AppIcons.budget, label: context.l10n.onboarding_feature_budgets),
              _FeatureChip(icon: AppIcons.goals, label: context.l10n.onboarding_feature_goals),
              _FeatureChip(icon: AppIcons.insights, label: context.l10n.onboarding_feature_reports),
            ],
          ),
          const Spacer(),
          AppButton(
            label: context.l10n.common_next,
            onPressed: onNext,
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: AppSizes.iconXs, color: cs.primary),
      label: Text(label),
      backgroundColor: cs.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }
}

// ── Page 2: Starting Balance ────────────────────────────────────────────────

class _BalancePage extends StatelessWidget {
  const _BalancePage({
    required this.onAmountChanged,
    required this.onFinish,
    required this.onSkip,
    required this.loading,
  });

  final ValueChanged<int> onAmountChanged;
  final VoidCallback? onFinish;
  final VoidCallback? onSkip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.xxl),
          Text(
            context.l10n.onboarding_page2_title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.l10n.onboarding_page2_body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                  height: AppSizes.lineHeightNormal,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
          AmountInput(
            onAmountChanged: onAmountChanged,
            autofocus: false,
          ),
          const Spacer(),
          AppButton(
            label: loading ? context.l10n.onboarding_saving : context.l10n.onboarding_page2_cta,
            onPressed: onFinish,
            icon: AppIcons.check,
          ),
          const SizedBox(height: AppSizes.sm),
          TextButton(
            onPressed: onSkip,
            child: Text(
              context.l10n.onboarding_page2_skip,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
