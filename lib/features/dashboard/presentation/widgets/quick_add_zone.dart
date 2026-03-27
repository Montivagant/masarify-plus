import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/smart_defaults_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';

/// Dashboard zone showing compact chips for one-tap frequent transactions.
///
/// Derived from recent transaction history. Shows top patterns that meet
/// [AppSizes.quickAddMinOccurrences]. Tap saves instantly with undo SnackBar.
class QuickAddZone extends ConsumerWidget {
  const QuickAddZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final freqs = ref.watch(frequentTransactionsProvider);
    if (freqs.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: Text(
              context.l10n.dashboard_quick_add,
              style: context.textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.xs,
              children: freqs.map((f) => _QuickAddChip(freq: f)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddChip extends ConsumerWidget {
  const _QuickAddChip({required this.freq});

  final FrequentTransaction freq;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = ColorUtils.fromHex(freq.categoryColorHex);
    return ActionChip(
      avatar: Icon(
        CategoryIconMapper.fromName(freq.categoryIconName),
        size: AppSizes.iconXs,
        color: color,
      ),
      label: Text(
        '${freq.title} ${MoneyFormatter.formatCompact(freq.amount)}',
      ),
      onPressed: () => _quickAdd(context, ref),
    );
  }

  Future<void> _quickAdd(BuildContext context, WidgetRef ref) async {
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    if (wallets.isEmpty) return;

    final selectedId = ref.read(selectedAccountIdProvider);
    final walletId = selectedId ?? wallets.first.id;
    try {
      final txId = await ref.read(transactionRepositoryProvider).create(
            walletId: walletId,
            categoryId: freq.categoryId,
            amount: freq.amount,
            type: freq.type,
            title: freq.title,
            transactionDate: DateTime.now(),
          );

      HapticFeedback.mediumImpact();
      if (!context.mounted) return;

      var undone = false;
      SnackHelper.showSuccessAndReturn(
        context,
        context.l10n.quick_add_saved(freq.title),
        duration: AppDurations.snackbarLong,
        action: SnackBarAction(
          label: context.l10n.common_undo,
          onPressed: () {
            undone = true;
            ref.read(transactionRepositoryProvider).delete(txId);
          },
        ),
      ).closed.then((_) {
        if (!undone) {
          ref
              .read(categoryFrequencyServiceProvider)
              .recordUsage(freq.type, freq.categoryId);
        }
      });
    } catch (_) {
      if (!context.mounted) return;
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }
}
