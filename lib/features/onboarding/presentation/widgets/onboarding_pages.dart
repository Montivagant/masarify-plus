import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';

// ── Page 1: Welcome ─────────────────────────────────────────────────────────

class WelcomePage extends ConsumerWidget {
  const WelcomePage({
    super.key,
    required this.onNext,
    required this.pageOffset,
  });

  final VoidCallback onNext;

  /// Fractional offset from PageController for parallax.
  /// 0.0 = this page is fully centred, ±1.0 = one page away.
  final double pageOffset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider)?.languageCode;
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.md),
          // ── Language toggle ──────────────────────────────────────────────
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'ar',
                  label: Text(context.l10n.language_ar),
                ),
                ButtonSegment(
                  value: 'en',
                  label: Text(context.l10n.language_en),
                ),
              ],
              selected: {
                currentLocale ?? (context.languageCode == 'ar' ? 'ar' : 'en'),
              },
              onSelectionChanged: (set) =>
                  ref.read(localeProvider.notifier).setLocale(set.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          const Spacer(),
          // ── Hero icon with decorative circle & parallax ─────────────────
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
          )
              .animate(target: noMotion ? 0 : 1)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
                duration: AppDurations.progressAnim,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: AppDurations.progressAnim),
          const SizedBox(height: AppSizes.xl),
          Text(
            context.l10n.onboarding_page1_title,
            style: context.textStyles.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(
                delay: AppDurations.onboardingTextDelay1,
                duration: AppDurations.listItemEntry,
              )
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSizes.md),
          Text(
            context.l10n.onboarding_page1_body,
            style: context.textStyles.bodyLarge?.copyWith(
              color: cs.outline,
              height: AppSizes.lineHeightRelaxed,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(
                delay: AppDurations.onboardingTextDelay2,
                duration: AppDurations.listItemEntry,
              )
              .slideY(begin: 0.1, end: 0),
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

// ── Page 2: Feature Highlights ──────────────────────────────────────────────

class FeaturesPage extends StatelessWidget {
  const FeaturesPage({
    super.key,
    required this.onNext,
    required this.pageOffset,
  });

  final VoidCallback onNext;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    final features = [
      _FeatureItem(
        icon: AppIcons.mic,
        title: context.l10n.onboarding_feature_voice_title,
        body: context.l10n.onboarding_feature_voice_body,
        color: cs.primary,
      ),
      _FeatureItem(
        icon: AppIcons.budget,
        title: context.l10n.onboarding_feature_budget_title,
        body: context.l10n.onboarding_feature_budget_body,
        color: cs.tertiary,
      ),
      _FeatureItem(
        icon: AppIcons.goals,
        title: context.l10n.onboarding_feature_goal_title,
        body: context.l10n.onboarding_feature_goal_body,
        color: cs.secondary,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.xxl),
          Transform.translate(
            offset: Offset(pageOffset * AppSizes.onboardingParallaxOffset, 0),
            child: Text(
              context.l10n.onboarding_features_title,
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < features.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSizes.md),
                  _FeatureCard(item: features[i])
                      .animate(target: noMotion ? 0 : 1)
                      .fadeIn(
                        delay: Duration(
                          milliseconds:
                              AppDurations.staggerDelay.inMilliseconds *
                                  (i + 1) *
                                  2,
                        ),
                        duration: AppDurations.listItemEntry,
                      )
                      .slideX(
                        begin: context.isRtl ? -0.1 : 0.1,
                        end: 0,
                        delay: Duration(
                          milliseconds:
                              AppDurations.staggerDelay.inMilliseconds *
                                  (i + 1) *
                                  2,
                        ),
                        duration: AppDurations.listItemEntry,
                      ),
                ],
              ],
            ),
          ),
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

class _FeatureItem {
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.item});

  final _FeatureItem item;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: AppSizes.iconContainerLg,
            height: AppSizes.iconContainerLg,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: AppSizes.opacityLight),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
            ),
            child: Icon(item.icon, color: item.color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Text(
                  item.body,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.outline,
                    height: AppSizes.lineHeightNormal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page 3: Account Setup ───────────────────────────────────────────────────

class AccountSetupPage extends StatelessWidget {
  const AccountSetupPage({
    super.key,
    required this.nameController,
    required this.walletType,
    required this.onWalletTypeChanged,
    required this.onAmountChanged,
    required this.onBack,
    required this.onFinish,
    required this.onSkip,
    required this.loading,
    required this.pageOffset,
  });

  final TextEditingController nameController;
  final String walletType;
  final ValueChanged<String> onWalletTypeChanged;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onBack;
  final VoidCallback? onFinish;
  final VoidCallback? onSkip;
  final bool loading;
  final double pageOffset;

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
                context.isRtl ? AppIcons.arrowForward : AppIcons.arrowBack,
              ),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Transform.translate(
            offset: Offset(pageOffset * AppSizes.onboardingParallaxOffset, 0),
            child: Text(
              context.l10n.onboarding_page2_title,
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
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
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Wallet name field
                AppTextField(
                  label: context.l10n.onboarding_account_name_label,
                  hint: context.l10n.onboarding_account_name_hint,
                  controller: nameController,
                  prefixIcon: const Icon(AppIcons.wallet),
                ),
                const SizedBox(height: AppSizes.md),
                // Wallet type selector
                Text(
                  context.l10n.onboarding_account_type_label,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: cs.outline,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    _WalletTypeChip(
                      value: 'bank',
                      label: context.l10n.wallet_type_bank_short,
                      icon: AppIcons.bank,
                      selected: walletType == 'bank',
                      onSelected: () => onWalletTypeChanged('bank'),
                    ),
                    _WalletTypeChip(
                      value: 'mobile_wallet',
                      label: context.l10n.wallet_type_mobile_wallet_short,
                      icon: AppIcons.phone,
                      selected: walletType == 'mobile_wallet',
                      onSelected: () => onWalletTypeChanged('mobile_wallet'),
                    ),
                    _WalletTypeChip(
                      value: 'credit_card',
                      label: context.l10n.wallet_type_credit_card_short,
                      icon: AppIcons.creditCard,
                      selected: walletType == 'credit_card',
                      onSelected: () => onWalletTypeChanged('credit_card'),
                    ),
                    _WalletTypeChip(
                      value: 'prepaid_card',
                      label: context.l10n.wallet_type_prepaid_card_short,
                      icon: AppIcons.prepaidCard,
                      selected: walletType == 'prepaid_card',
                      onSelected: () => onWalletTypeChanged('prepaid_card'),
                    ),
                    _WalletTypeChip(
                      value: 'investment',
                      label: context.l10n.wallet_type_investment_short,
                      icon: AppIcons.investmentAccount,
                      selected: walletType == 'investment',
                      onSelected: () => onWalletTypeChanged('investment'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.lg),
                AmountInput(
                  onAmountChanged: onAmountChanged,
                  autofocus: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          // Physical cash note
          Text(
            context.l10n.onboarding_physical_cash_note,
            style: context.textStyles.bodySmall?.copyWith(
              color: cs.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          AppButton(
            label: loading
                ? context.l10n.onboarding_saving
                : context.l10n.onboarding_page2_cta,
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

// ── Page 4: Ready! ──────────────────────────────────────────────────────────

class ReadyPage extends StatelessWidget {
  const ReadyPage({
    super.key,
    required this.onStart,
    required this.pageOffset,
  });

  final VoidCallback? onStart;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // ── Animated check icon ─────────────────────────────────────────
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
                AppIcons.checkCircle,
                size: AppSizes.iconXl2,
                color: cs.primary,
              ),
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.0, 1.0),
                duration: AppDurations.countUp,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: AppDurations.countUp),
          const SizedBox(height: AppSizes.xl),
          Text(
            context.l10n.onboarding_ready_title,
            style: context.textStyles.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(
                delay: AppDurations.onboardingTextDelay1,
                duration: AppDurations.listItemEntry,
              )
              .slideY(begin: 0.15, end: 0),
          const SizedBox(height: AppSizes.md),
          Text(
            context.l10n.onboarding_ready_body,
            style: context.textStyles.bodyLarge?.copyWith(
              color: cs.outline,
              height: AppSizes.lineHeightRelaxed,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(
                delay: AppDurations.onboardingTextDelay2,
                duration: AppDurations.listItemEntry,
              )
              .slideY(begin: 0.15, end: 0),
          const Spacer(flex: 3),
          AppButton(
            label: context.l10n.onboarding_ready_cta,
            onPressed: onStart,
            icon: AppIcons.check,
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(
                delay: AppDurations.onboardingCtaDelay,
                duration: AppDurations.listItemEntry,
              )
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

// ── Wallet type chip for onboarding ─────────────────────────────────────

class _WalletTypeChip extends StatelessWidget {
  const _WalletTypeChip({
    required this.value,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: AppSizes.iconXs),
      label: Text(label),
      onSelected: (_) => onSelected(),
      showCheckmark: false,
    );
  }
}
