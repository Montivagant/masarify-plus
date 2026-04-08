import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import 'add_transaction_screen.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final theme = context.appTheme;
    final txAsync = ref.watch(transactionByIdProvider(id));

    return txAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar(title: context.l10n.transaction_detail_title),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppAppBar(title: context.l10n.transaction_detail_title),
        body: EmptyState(title: context.l10n.common_error_title),
      ),
      data: (tx) {
        if (tx == null) {
          return Scaffold(
            appBar: AppAppBar(title: context.l10n.transaction_detail_title),
            body: EmptyState(title: context.l10n.transaction_not_found),
          );
        }

        final typeColor = switch (tx.type) {
          'expense' => theme.expenseColor,
          'income' => theme.incomeColor,
          _ => theme.transferColor,
        };
        final typeLabel = switch (tx.type) {
          'expense' => context.l10n.transaction_type_expense,
          'income' => context.l10n.transaction_type_income,
          _ => context.l10n.transaction_type_transfer,
        };
        final signPrefix = switch (tx.type) {
          'income' => '+',
          'expense' => '\u2212',
          _ => '',
        };

        final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
        final cat = categories.where((c) => c.id == tx.categoryId).firstOrNull;
        final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
        final wallet = wallets.where((w) => w.id == tx.walletId).firstOrNull;

        final catColor =
            cat != null ? ColorUtils.fromHex(cat.colorHex) : cs.outline;
        final catIcon = cat != null
            ? CategoryIconMapper.fromName(cat.iconName)
            : switch (tx.type) {
                'expense' => AppIcons.expense,
                'income' => AppIcons.income,
                _ => AppIcons.transfer,
              };

        return Scaffold(
          appBar: AppAppBar(
            title: context.l10n.transaction_detail_title,
            actions: [
              IconButton(
                icon: const Icon(AppIcons.edit),
                tooltip: context.l10n.common_edit,
                onPressed: () => AddTransactionScreen.showEdit(context, tx.id),
              ),
              IconButton(
                icon: const Icon(AppIcons.delete),
                tooltip: context.l10n.common_delete,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero: Receipt-style amount card ───────────────────
                GlassCard(
                  margin: const EdgeInsets.all(AppSizes.screenHPadding),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.xl,
                  ),
                  showShadow: true,
                  tintColor:
                      typeColor.withValues(alpha: AppSizes.opacitySubtle),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        // Icon badge
                        GlassCard(
                          tier: GlassTier.inset,
                          padding: EdgeInsets.zero,
                          tintColor: catColor.withValues(
                            alpha: AppSizes.opacityLight2,
                          ),
                          borderRadius: BorderRadius.circular(
                            AppSizes.borderRadiusFull,
                          ),
                          child: SizedBox(
                            width: AppSizes.iconContainerXl,
                            height: AppSizes.iconContainerXl,
                            child: Icon(
                              catIcon,
                              color: catColor,
                              size: AppSizes.iconLg,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Amount with sign
                        Text(
                          '$signPrefix${MoneyFormatter.format(tx.amount)}',
                          style: context.textStyles.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        // Title
                        Text(
                          tx.title,
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface.withValues(
                              alpha: AppSizes.opacityStrong,
                            ),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        // Date + type row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TypeBadge(
                              label: typeLabel,
                              color: typeColor,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            _TypeBadge(
                              label: DateFormat.yMMMd(context.languageCode)
                                  .format(tx.transactionDate),
                              color: cs.outline,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Details card ──────────────────────────────────────
                GlassCard(
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                  ),
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: catIcon,
                        iconColor: catColor,
                        label: context.l10n.transaction_category,
                        value:
                            cat?.displayName(context.languageCode) ?? '\u2014',
                      ),
                      const SizedBox(height: AppSizes.md),
                      _DetailRow(
                        icon: wallet != null
                            ? AppIcons.walletType(wallet.type)
                            : AppIcons.wallet,
                        iconColor: wallet != null
                            ? ColorUtils.fromHex(wallet.colorHex)
                            : cs.primary,
                        label: context.l10n.transaction_wallet,
                        value: wallet?.name ?? '\u2014',
                      ),
                      const SizedBox(height: AppSizes.md),
                      _DetailRow(
                        icon: AppIcons.calendar,
                        iconColor: cs.outline,
                        label: context.l10n.transaction_date,
                        value: DateFormat.yMd(context.languageCode)
                            .add_jm()
                            .format(tx.transactionDate),
                      ),
                      if (tx.note != null && tx.note!.isNotEmpty) ...[
                        const SizedBox(height: AppSizes.md),
                        _DetailRow(
                          icon: AppIcons.edit,
                          iconColor: cs.outline,
                          label: context.l10n.transaction_note,
                          value: tx.note!,
                        ),
                      ],
                      if (tx.locationName != null) ...[
                        const SizedBox(height: AppSizes.md),
                        _DetailRow(
                          icon: AppIcons.location,
                          iconColor: cs.outline,
                          label: context.l10n.transaction_location,
                          value: tx.locationName!,
                        ),
                        if (tx.latitude != null && tx.longitude != null) ...[
                          const SizedBox(height: AppSizes.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusMd,
                            ),
                            child: SizedBox(
                              height: AppSizes.chartHeightMd,
                              child: FlutterMap(
                                options: MapOptions(
                                  initialCenter:
                                      LatLng(tx.latitude!, tx.longitude!),
                                  initialZoom: 15,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.masarify.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          tx.latitude!,
                                          tx.longitude!,
                                        ),
                                        child: Icon(
                                          AppIcons.location,
                                          color: cs.primary,
                                          size: AppSizes.iconLg,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                      if (tx.source != 'manual') ...[
                        const SizedBox(height: AppSizes.md),
                        _DetailRow(
                          icon: _sourceIcon(tx.source),
                          iconColor: cs.outline,
                          label: context.l10n.transaction_source_label,
                          value: _sourceLabel(context, tx.source),
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Tags ───────────────────────────────────────────────
                if (tx.tagList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenHPadding,
                      vertical: AppSizes.sm,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.tag,
                          size: AppSizes.iconSm,
                          color: cs.outline,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Wrap(
                            spacing: AppSizes.xs,
                            children: tx.tagList
                                .map(
                                  (t) => Chip(
                                    label: Text(t),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Raw source text ────────────────────────────────────
                if (tx.rawSourceText != null && tx.rawSourceText!.isNotEmpty)
                  GlassCard(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenHPadding,
                      vertical: AppSizes.sm,
                    ),
                    tintColor: cs.outlineVariant.withValues(
                      alpha: AppSizes.opacitySubtle,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        tx.rawSourceText!,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: cs.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.transaction_delete_title),
        content: Text(l10n.transaction_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              ctx.pop();
              try {
                await ref.read(transactionRepositoryProvider).delete(id);
                HapticFeedback.mediumImpact();
                if (context.mounted) context.pop();
              } catch (e) {
                if (context.mounted) {
                  SnackHelper.showError(context, l10n.common_error_generic);
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.appTheme.expenseColor,
            ),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
  }

  static IconData _sourceIcon(String source) => switch (source) {
        'voice' => AppIcons.mic,
        'sms' => AppIcons.phone,
        'notification' => AppIcons.notification,
        'import' => AppIcons.import_,
        'ai_chat' => AppIcons.ai,
        'recurring' => AppIcons.recurring,
        _ => AppIcons.edit,
      };

  static String _sourceLabel(BuildContext context, String source) =>
      switch (source) {
        'voice' => context.l10n.transaction_source_voice,
        'sms' => context.l10n.transaction_source_sms,
        'notification' => context.l10n.transaction_source_notification,
        'import' => context.l10n.transaction_source_import,
        'ai_chat' => context.l10n.transaction_source_ai_chat,
        'recurring' => context.l10n.transaction_source_recurring,
        _ => context.l10n.transaction_source_manual,
      };
}

// ── Type badge (small pill) ─────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.opacityLight2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        border: Border.all(
          color: color.withValues(alpha: AppSizes.opacityLight4),
        ),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Detail row (used inside the grouped GlassCard) ──────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.md,
      ),
      child: Row(
        children: [
          GlassCard(
            tier: GlassTier.inset,
            padding: EdgeInsets.zero,
            tintColor: iconColor.withValues(alpha: AppSizes.opacitySubtle),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            child: SizedBox(
              width: AppSizes.iconContainerMd,
              height: AppSizes.iconContainerMd,
              child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.outline,
                  ),
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  value,
                  style: context.textStyles.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
