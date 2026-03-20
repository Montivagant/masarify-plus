import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Shows current subscription status and links to the paywall.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final hasPro = ref.watch(hasProAccessProvider);
    final trialDays = ref.watch(trialDaysRemainingProvider);
    final service = ref.read(subscriptionServiceProvider);
    final isInTrial = service.isInTrial && !service.isPro;

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.subscription_title),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.xl),
            // Status icon
            Icon(
              hasPro ? AppIcons.checkCircle : AppIcons.lock,
              size: AppSizes.iconXl3,
              color: hasPro ? cs.primary : cs.outline,
            ),
            const SizedBox(height: AppSizes.md),
            // Status label
            Text(
              hasPro
                  ? context.l10n.subscription_active
                  : context.l10n.subscription_inactive,
              style: context.textStyles.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            // Trial/subscription detail
            if (isInTrial)
              GlassCard(
                tintColor: cs.primary.withValues(alpha: AppSizes.opacitySubtle),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.info,
                      color: cs.primary,
                      size: AppSizes.iconSm,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        context.l10n.paywall_trial_banner(trialDays),
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (!hasPro)
              Text(
                context.l10n.subscription_upgrade_prompt,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.outline,
                ),
                textAlign: TextAlign.center,
              ),
            const Spacer(),
            if (!service.isPro)
              AppButton(
                label: context.l10n.pro_upgrade,
                onPressed: () => context.push(AppRoutes.paywall),
                icon: AppIcons.checkCircle,
              ),
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}
