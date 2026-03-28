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

// ── Page 0: Welcome ─────────────────────────────────────────────────────────

class WelcomePage extends ConsumerWidget {
  const WelcomePage({
    super.key,
    required this.onNext,
    required this.pageOffset,
  });

  final VoidCallback onNext;
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

// ── Value Preview Slide ──────────────────────────────────────────────────────

/// A single value-preview slide showing an animated feature demo.
class ValuePreviewSlide extends StatelessWidget {
  const ValuePreviewSlide({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.demoWidget,
    required this.pageOffset,
    this.footerWidget,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget demoWidget;
  final double pageOffset;
  final Widget? footerWidget;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // ── Animated demo ──────────────────────────────────────────────
          Transform.translate(
            offset: Offset(pageOffset * AppSizes.onboardingParallaxOffset, 0),
            child: SizedBox(
              height: AppSizes.onboardingDemoHeight,
              child: demoWidget,
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          // ── Title ──────────────────────────────────────────────────────
          Text(
            title,
            style: context.textStyles.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(duration: AppDurations.listItemEntry)
              .slideY(begin: 0.1, end: 0),
          const SizedBox(height: AppSizes.md),
          // ── Subtitle ───────────────────────────────────────────────────
          Text(
            subtitle,
            style: context.textStyles.bodyLarge?.copyWith(
              color: cs.outline,
              height: AppSizes.lineHeightRelaxed,
            ),
            textAlign: TextAlign.center,
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(
                delay: AppDurations.onboardingTextDelay1,
                duration: AppDurations.listItemEntry,
              )
              .slideY(begin: 0.1, end: 0),
          if (footerWidget != null) ...[
            const SizedBox(height: AppSizes.md),
            footerWidget!,
          ],
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ── Slide 1 Demo: "Track in 2 taps" ─────────────────────────────────────────

class TrackingDemo extends StatelessWidget {
  const TrackingDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FAB icon
          Container(
            width: AppSizes.iconXl3,
            height: AppSizes.iconXl3,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withValues(alpha: AppSizes.opacityLight4),
                  blurRadius: AppSizes.heroShadowBlur,
                  offset: const Offset(0, AppSizes.heroShadowOffsetY),
                ),
              ],
            ),
            child: Icon(
              AppIcons.add,
              color: cs.onPrimary,
              size: AppSizes.iconLg,
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: AppDurations.progressAnim,
                curve: Curves.easeOutBack,
              )
              .fadeIn(),
          const SizedBox(height: AppSizes.lg),
          // Mock amount card
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.lg,
              vertical: AppSizes.md,
            ),
            child: Text(
              context.l10n.onboarding_demo_amount,
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.appTheme.expenseColor,
              ),
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay1)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
          const SizedBox(height: AppSizes.sm),
          // Mock category chips
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MockChip(
                label: context.l10n.onboarding_demo_food,
                selected: true,
                color: cs.primary,
              ),
              const SizedBox(width: AppSizes.xs),
              _MockChip(
                label: context.l10n.onboarding_demo_transport,
                selected: false,
                color: cs.outline,
              ),
            ],
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay3)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

// ── Slide 2 Demo: "Just say it" ──────────────────────────────────────────────

class VoiceDemo extends StatelessWidget {
  const VoiceDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mic icon with pulse ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: AppSizes.onboardingIcon,
                height: AppSizes.onboardingIcon,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: AppSizes.opacitySubtle),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    target: noMotion ? 0 : 1,
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: AppDurations.onboardingPulse,
                    curve: Curves.easeInOut,
                  ),
              Container(
                width: AppSizes.iconXl3,
                height: AppSizes.iconXl3,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.mic,
                  color: cs.onPrimary,
                  size: AppSizes.iconLg,
                ),
              )
                  .animate(target: noMotion ? 0 : 1)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: AppDurations.progressAnim,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          // Mock speech bubble
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.mic,
                  color: cs.primary,
                  size: AppSizes.iconSm,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  context.l10n.onboarding_demo_voice_text,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay2)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

// ── Slide 3 Demo: "SMS auto-detect" ──────────────────────────────────────────

class SmsDemo extends StatelessWidget {
  const SmsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Phone icon
          Container(
            width: AppSizes.iconXl3,
            height: AppSizes.iconXl3,
            decoration: BoxDecoration(
              color: cs.tertiary.withValues(alpha: AppSizes.opacityLight2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.sms,
              color: cs.tertiary,
              size: AppSizes.iconLg,
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: AppDurations.progressAnim,
                curve: Curves.easeOutBack,
              )
              .fadeIn(),
          const SizedBox(height: AppSizes.lg),
          // Mock SMS notification
          GlassCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.notification,
                  color: cs.tertiary,
                  size: AppSizes.iconSm,
                ),
                const SizedBox(width: AppSizes.sm),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.onboarding_demo_sms_sender,
                        style: context.textStyles.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        context.l10n.onboarding_demo_sms_body,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: cs.outline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay1)
              .slideX(
                begin: context.isRtl ? 0.3 : -0.3,
                end: 0,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: AppSizes.sm),
          // Arrow down
          Icon(AppIcons.expense, color: cs.primary, size: AppSizes.iconMd)
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay4),
          const SizedBox(height: AppSizes.sm),
          // Auto-detected transaction card
          GlassCard(
            tintColor: cs.primary.withValues(alpha: AppSizes.opacitySubtle),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.checkCircle,
                  color: cs.primary,
                  size: AppSizes.iconSm,
                ),
                const SizedBox(width: AppSizes.sm),
                Text(
                  context.l10n.onboarding_demo_sms_result,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay5)
              .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

// ── Slide 3 Demo: "AI Financial Advisor" ─────────────────────────────────────

class ChatDemo extends StatelessWidget {
  const ChatDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // AI brain icon with pulse ring
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: AppSizes.onboardingIcon,
                height: AppSizes.onboardingIcon,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: AppSizes.opacitySubtle),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    target: noMotion ? 0 : 1,
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    duration: AppDurations.onboardingPulse,
                    curve: Curves.easeInOut,
                  ),
              Container(
                width: AppSizes.iconXl3,
                height: AppSizes.iconXl3,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.ai,
                  color: cs.onPrimary,
                  size: AppSizes.iconLg,
                ),
              )
                  .animate(target: noMotion ? 0 : 1)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: AppDurations.progressAnim,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),
            ],
          ),
          const SizedBox(height: AppSizes.lg),
          // Mock user chat bubble
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: GlassCard(
              tintColor:
                  cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Text(
                context.l10n.onboarding_demo_chat_user,
                style: context.textStyles.bodySmall?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay1)
              .slideX(
                begin: context.isRtl ? -0.3 : 0.3,
                end: 0,
                curve: Curves.easeOut,
              ),
          const SizedBox(height: AppSizes.sm),
          // Mock AI response bubble
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.ai,
                    color: cs.primary,
                    size: AppSizes.iconSm,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Flexible(
                    child: Text(
                      context.l10n.onboarding_demo_chat_ai,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(target: noMotion ? 0 : 1)
              .fadeIn(delay: AppDurations.onboardingDemoDelay3)
              .slideX(
                begin: context.isRtl ? 0.3 : -0.3,
                end: 0,
                curve: Curves.easeOut,
              ),
        ],
      ),
    );
  }
}

// ── Page 4: Account Type Picker ──────────────────────────────────────────────

class AccountTypePicker extends StatelessWidget {
  const AccountTypePicker({
    super.key,
    required this.onTypeSelected,
    required this.loading,
    required this.pageOffset,
  });

  final ValueChanged<String> onTypeSelected;
  final bool loading;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final noMotion = context.reduceMotion;

    final options = [
      (
        type: 'bank',
        icon: AppIcons.bank,
        label: context.l10n.onboarding_type_bank,
        subtitle: context.l10n.onboarding_type_bank_desc,
        color: cs.primary,
      ),
      (
        type: 'physical_cash',
        icon: AppIcons.physicalCash,
        label: context.l10n.onboarding_type_cash,
        subtitle: context.l10n.onboarding_type_cash_desc,
        color: cs.tertiary,
      ),
      (
        type: 'mobile_wallet',
        icon: AppIcons.phone,
        label: context.l10n.onboarding_type_mobile,
        subtitle: context.l10n.onboarding_type_mobile_desc,
        color: cs.secondary,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const Spacer(),
          Transform.translate(
            offset: Offset(pageOffset * AppSizes.onboardingParallaxOffset, 0),
            child: Text(
              context.l10n.onboarding_pick_account_title,
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            context.l10n.onboarding_pick_account_body,
            style: context.textStyles.bodyMedium?.copyWith(
              color: cs.outline,
              height: AppSizes.lineHeightNormal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xl),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xl),
              child: CircularProgressIndicator.adaptive(),
            )
          else
            ...options.asMap().entries.map((entry) {
              final i = entry.key;
              final opt = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.md),
                child: _AccountTypeCard(
                  icon: opt.icon,
                  label: opt.label,
                  subtitle: opt.subtitle,
                  color: opt.color,
                  onTap: () => onTypeSelected(opt.type),
                )
                    .animate(target: noMotion ? 0 : 1)
                    .fadeIn(
                      delay: Duration(
                        milliseconds: AppDurations.staggerDelay.inMilliseconds *
                            (i + 1) *
                            2,
                      ),
                      duration: AppDurations.listItemEntry,
                    )
                    .slideY(begin: 0.1, end: 0),
              );
            }),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  const _AccountTypeCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: AppSizes.iconContainerLg,
            height: AppSizes.iconContainerLg,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppSizes.opacityLight),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
            ),
            child: Icon(icon, color: color, size: AppSizes.iconMd),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  subtitle,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.outline,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
            color: context.colors.outline,
            size: AppSizes.iconSm,
          ),
        ],
      ),
    );
  }
}

// ── Mock chip for demo slides ───────────────────────────────────────────────

class _MockChip extends StatelessWidget {
  const _MockChip({
    required this.label,
    required this.selected,
    required this.color,
  });

  final String label;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: selected
            ? color.withValues(alpha: AppSizes.opacityLight2)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        border: selected ? Border.all(color: color) : null,
      ),
      child: Text(
        label,
        style: context.textStyles.labelMedium?.copyWith(
          color: selected ? color : cs.outline,
          fontWeight: selected ? FontWeight.w600 : null,
        ),
      ),
    );
  }
}
