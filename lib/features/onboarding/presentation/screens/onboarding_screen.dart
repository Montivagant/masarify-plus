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
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

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
  final _nameController = TextEditingController();
  int _balancePiastres = 0;
  String _walletType = 'cash';
  bool _loading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppDurations.pageTransition,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      // Create wallet with user-chosen name and type (defaults: "Cash", cash)
      final walletName = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : context.l10n.onboarding_default_wallet_name;
      await ref.read(walletRepositoryProvider).create(
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
      // C3 fix: show error feedback so user isn't stuck
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

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
                  _WelcomePage(onNext: _nextPage),
                  _BalancePage(
                    nameController: _nameController,
                    walletType: _walletType,
                    onWalletTypeChanged: (t) =>
                        setState(() => _walletType = t),
                    onAmountChanged: (p) =>
                        setState(() => _balancePiastres = p),
                    onBack: () => _pageController.previousPage(
                      duration: AppDurations.pageTransition,
                      curve: Curves.easeInOut,
                    ),
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

// ── Page 1: Welcome ─────────────────────────────────────────────────────────

class _WelcomePage extends ConsumerWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider)?.languageCode;

    final cs = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.md),
          // ── Language toggle (top-end corner) ────────────────────────────
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'ar', label: Text(context.l10n.language_ar)),
                ButtonSegment(value: 'en', label: Text(context.l10n.language_en)),
              ],
              selected: {currentLocale ?? (context.languageCode == 'ar' ? 'ar' : 'en')},
              onSelectionChanged: (set) =>
                  ref.read(localeProvider.notifier).setLocale(set.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const Spacer(),
          Container(
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
          const SizedBox(height: AppSizes.xl),
          Text(
            context.l10n.onboarding_page1_title,
            style: context.textStyles.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            context.l10n.onboarding_page1_body,
            style: context.textStyles.bodyLarge?.copyWith(
                  color: context.colors.outline,
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
              _FeatureChip(icon: AppIcons.reports, label: context.l10n.onboarding_feature_reports),
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
    final cs = context.colors;
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
    required this.nameController,
    required this.walletType,
    required this.onWalletTypeChanged,
    required this.onAmountChanged,
    required this.onBack,
    required this.onFinish,
    required this.onSkip,
    required this.loading,
  });

  final TextEditingController nameController;
  final String walletType;
  final ValueChanged<String> onWalletTypeChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onBack;
  final VoidCallback? onFinish;
  final VoidCallback? onSkip;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.md),
          // Back button row
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              onPressed: onBack,
              icon: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? AppIcons.arrowForward
                    : AppIcons.arrowBack,
              ),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.l10n.onboarding_page2_title,
            style: context.textStyles.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.l10n.onboarding_page2_body,
            style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.outline,
                  height: AppSizes.lineHeightNormal,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.lg),
          // Wallet name field
          AppTextField(
            label: context.l10n.onboarding_account_name_label,
            hint: context.l10n.onboarding_account_name_hint,
            controller: nameController,
            prefixIcon: const Icon(AppIcons.wallet),
          ),
          const SizedBox(height: AppSizes.md),
          // Wallet type selector
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              context.l10n.onboarding_account_type_label,
              style: context.textStyles.labelMedium?.copyWith(
                color: cs.outline,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'cash',
                label: Text(context.l10n.wallet_type_cash_short),
                icon: const Icon(AppIcons.wallet, size: AppSizes.iconXs),
              ),
              ButtonSegment(
                value: 'bank',
                label: Text(context.l10n.wallet_type_bank_short),
                icon: const Icon(AppIcons.bank, size: AppSizes.iconXs),
              ),
              ButtonSegment(
                value: 'mobile_wallet',
                label: Text(context.l10n.wallet_type_mobile_wallet_short),
                icon: const Icon(AppIcons.phone, size: AppSizes.iconXs),
              ),
            ],
            selected: {walletType},
            onSelectionChanged: (set) => onWalletTypeChanged(set.first),
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: AppSizes.lg),
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
              style: context.textStyles.bodyMedium?.copyWith(
                color: cs.outline,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
