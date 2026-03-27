import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Paywall screen showing Pro features and purchase options.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  List<ProductDetails> _products = [];
  bool _loading = true;
  bool _purchasing = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final service = ref.read(subscriptionServiceProvider);
    final products = await service.getProducts();
    if (!mounted) return;
    setState(() {
      _products = products;
      _loading = false;
    });
  }

  Future<void> _purchase(ProductDetails product) async {
    if (_purchasing) return;
    setState(() => _purchasing = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.purchase(product);
    } catch (_) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(subscriptionServiceProvider);
      await service.restorePurchases();
      if (!mounted) return;
      final hasPro = ref.read(hasProAccessProvider);
      if (hasPro) {
        SnackHelper.showSuccess(context, context.l10n.paywall_restored);
        context.pop();
      } else {
        SnackHelper.showInfo(context, context.l10n.paywall_no_purchases);
      }
    } catch (_) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final trialDays = ref.watch(trialDaysRemainingProvider);

    final features = [
      (
        icon: AppIcons.ai,
        label: context.l10n.paywall_feature_chat,
      ),
      (
        icon: AppIcons.trendingUp,
        label: context.l10n.paywall_feature_insights,
      ),
      (
        icon: AppIcons.budget,
        label: context.l10n.paywall_feature_budgets,
      ),
      (
        icon: AppIcons.goals,
        label: context.l10n.paywall_feature_goals,
      ),
      (
        icon: AppIcons.analytics,
        label: context.l10n.paywall_feature_analytics,
      ),
      (
        icon: AppIcons.backup,
        label: context.l10n.paywall_feature_backup,
      ),
      (
        icon: AppIcons.export_,
        label: context.l10n.paywall_feature_export,
      ),
    ];

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.paywall_title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
        child: Column(
          children: [
            const SizedBox(height: AppSizes.md),

            // ── Pro badge ───────────────────────────────────────────
            Icon(
              AppIcons.checkCircle,
              size: AppSizes.iconXl3,
              color: cs.primary,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              context.l10n.paywall_headline,
              style: context.textStyles.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              context.l10n.paywall_subheadline,
              style: context.textStyles.bodyMedium?.copyWith(
                color: cs.outline,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Trial banner ────────────────────────────────────────
            if (trialDays > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                  vertical: AppSizes.md,
                ),
                child: GlassCard(
                  tintColor:
                      cs.primary.withValues(alpha: AppSizes.opacitySubtle),
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
                          style: context.textStyles.bodySmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppSizes.md),

            // ── Feature list ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.paywall_includes,
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                    ...features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Row(
                          children: [
                            Icon(
                              f.icon,
                              size: AppSizes.iconSm,
                              color: cs.primary,
                            ),
                            const SizedBox(width: AppSizes.md),
                            Expanded(
                              child: Text(
                                f.label,
                                style: context.textStyles.bodyMedium,
                              ),
                            ),
                            Icon(
                              AppIcons.check,
                              size: AppSizes.iconXs,
                              color: cs.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // ── Purchase buttons ─────────────────────────────────────
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(AppSizes.lg),
                child: CircularProgressIndicator.adaptive(),
              )
            else if (_products.isEmpty)
              // Store not available — show generic message.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: Text(
                  context.l10n.paywall_store_unavailable,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: cs.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: Column(
                  children: _products.map((product) {
                    final isYearly = product.id == SubscriptionIds.yearlyPro;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: AppButton(
                        label: isYearly
                            ? context.l10n.paywall_yearly(product.price)
                            : context.l10n.paywall_monthly(product.price),
                        onPressed:
                            _purchasing ? null : () => _purchase(product),
                        isLoading: _purchasing,
                        icon: AppIcons.checkCircle,
                      ),
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: AppSizes.md),

            // ── Restore purchases ────────────────────────────────────
            TextButton(
              onPressed: _loading ? null : _restore,
              child: Text(
                context.l10n.paywall_restore,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.outline,
                ),
              ),
            ),

            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }
}
