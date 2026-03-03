import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    // M1 fix: use provider instead of FutureBuilder so data auto-refreshes
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
          'expense' => context.appTheme.expenseColor,
          'income' => context.appTheme.incomeColor,
          _ => context.appTheme.transferColor,
        };
        final typeLabel = switch (tx.type) {
          'expense' => context.l10n.transaction_type_expense,
          'income' => context.l10n.transaction_type_income,
          _ => context.l10n.transaction_type_transfer,
        };

        final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
        final cat =
            categories.where((c) => c.id == tx.categoryId).firstOrNull;
        final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
        final wallet =
            wallets.where((w) => w.id == tx.walletId).firstOrNull;

        return Scaffold(
          appBar: AppAppBar(
            title: context.l10n.transaction_detail_title,
            actions: [
              IconButton(
                icon: const Icon(AppIcons.edit),
                tooltip: context.l10n.common_edit,
                onPressed: () => context.push('/transactions/${tx.id}/edit'),
              ),
              IconButton(
                icon: const Icon(AppIcons.delete),
                tooltip: context.l10n.common_delete,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero: Amount + type ──────────────────────────────────
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(AppSizes.screenHPadding),
                  padding: const EdgeInsets.all(AppSizes.lg),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: AppSizes.opacitySubtle),
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusMd),
                    border: Border.all(
                      color: typeColor.withValues(alpha: AppSizes.opacityLight3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        switch (tx.type) {
                          'expense' => AppIcons.expense,
                          'income' => AppIcons.income,
                          _ => AppIcons.transfer,
                        },
                        color: typeColor,
                        size: AppSizes.iconLg,
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        MoneyFormatter.format(tx.amount),
                        style:
                            context.textStyles.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: typeColor,
                                ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Chip(
                        label: Text(typeLabel),
                        backgroundColor: typeColor.withValues(alpha: AppSizes.opacityLight2),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Details ─────────────────────────────────────────────
                _DetailRow(
                  icon: cat != null
                      ? CategoryIconMapper.fromName(cat.iconName)
                      : AppIcons.category,
                  iconColor: cat != null
                      ? ColorUtils.fromHex(cat.colorHex)
                      : cs.outline,
                  label: context.l10n.transaction_category,
                  value: cat?.displayName(context.languageCode) ?? '—',
                ),
                _DetailRow(
                  icon: AppIcons.wallet,
                  iconColor: cs.primary,
                  label: context.l10n.transaction_wallet,
                  value: wallet?.name ?? '—',
                ),
                _DetailRow(
                  icon: AppIcons.calendar,
                  iconColor: cs.outline,
                  label: context.l10n.transaction_date,
                  value:
                      '${tx.transactionDate.day}/${tx.transactionDate.month}/${tx.transactionDate.year}',
                ),
                if (tx.note != null && tx.note!.isNotEmpty)
                  _DetailRow(
                    icon: AppIcons.edit,
                    iconColor: cs.outline,
                    label: context.l10n.transaction_note,
                    value: tx.note!,
                  ),
                if (tx.locationName != null)
                  _DetailRow(
                    icon: AppIcons.location,
                    iconColor: cs.outline,
                    label: context.l10n.transaction_location,
                    value: tx.locationName!,
                  ),
                if (tx.tagList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenHPadding,
                      vertical: AppSizes.xs,
                    ),
                    child: Row(
                      children: [
                        Icon(AppIcons.tag, size: AppSizes.iconSm, color: cs.outline),
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
                if (tx.source != 'manual')
                  _DetailRow(
                    icon: _sourceIcon(tx.source),
                    iconColor: cs.outline,
                    label: context.l10n.transaction_source_label,
                    value: _sourceLabel(context, tx.source),
                  ),
                if (tx.rawSourceText != null && tx.rawSourceText!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenHPadding,
                      vertical: AppSizes.sm,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.transaction_delete_title),
        content: Text(context.l10n.transaction_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () async {
              ctx.pop();
              await ref.read(transactionRepositoryProvider).delete(id);
              HapticFeedback.mediumImpact();
              if (context.mounted) context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.appTheme.expenseColor,
            ),
            child: Text(context.l10n.common_delete),
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
        _ => AppIcons.edit,
      };

  static String _sourceLabel(BuildContext context, String source) =>
      switch (source) {
        'voice' => context.l10n.transaction_source_voice,
        'sms' => context.l10n.transaction_source_sms,
        'notification' => context.l10n.transaction_source_notification,
        'import' => context.l10n.transaction_source_import,
        _ => context.l10n.transaction_source_manual,
      };
}

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
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppSizes.iconSm, color: iconColor),
          const SizedBox(width: AppSizes.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.outline,
                    ),
              ),
              Text(
                value,
                style: context.textStyles.bodyLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
