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
