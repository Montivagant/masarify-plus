import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';

/// Bottom sheet for editing a single voice-parsed transaction draft.
/// Used by both the swipe-card view and the list view when the user taps
/// to edit a transaction's details.
class DraftEditSheet extends ConsumerWidget {
  const DraftEditSheet({
    super.key,
    required this.amountPiastres,
    required this.type,
    required this.categoryId,
    required this.walletId,
    required this.noteController,
    required this.onAmountChanged,
    required this.onTypeChanged,
    required this.onCategoryChanged,
    required this.onWalletChanged,
    this.isCashType = false,
  });

  final int amountPiastres;
  final String type;
  final int? categoryId;
  final int? walletId;
  final TextEditingController noteController;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<int> onCategoryChanged;
  final ValueChanged<int> onWalletChanged;
  final bool isCashType;

  /// Opens this sheet as a modal bottom sheet with a draggable scroll area.
  static Future<void> show(
    BuildContext context, {
    required int amountPiastres,
    required String type,
    required int? categoryId,
    required int? walletId,
    required TextEditingController noteController,
    required ValueChanged<int> onAmountChanged,
    required ValueChanged<String> onTypeChanged,
    required ValueChanged<int> onCategoryChanged,
    required ValueChanged<int> onWalletChanged,
    bool isCashType = false,
  }) {
    // Use local mutable copies so the sheet UI reflects changes immediately.
    var localType = type;
    var localCategoryId = categoryId;
    var localWalletId = walletId;
    var localAmount = amountPiastres;
    var localIsCash = isCashType;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: AppSizes.sheetInitialSize,
        minChildSize: AppSizes.sheetMinSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, controller) => StatefulBuilder(
          builder: (sbCtx, setSheetState) => SingleChildScrollView(
            controller: controller,
            child: DraftEditSheet(
              amountPiastres: localAmount,
              type: localType,
              categoryId: localCategoryId,
              walletId: localWalletId,
              noteController: noteController,
              onAmountChanged: (v) {
                setSheetState(() => localAmount = v);
                onAmountChanged(v);
              },
              onTypeChanged: (v) {
                setSheetState(() {
                  localType = v;
                  localIsCash = v == 'cash_withdrawal' || v == 'cash_deposit';
                });
                onTypeChanged(v);
              },
              onCategoryChanged: (v) {
                setSheetState(() => localCategoryId = v);
                onCategoryChanged(v);
              },
              onWalletChanged: (v) {
                setSheetState(() => localWalletId = v);
                onWalletChanged(v);
              },
              isCashType: localIsCash,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final lang = context.languageCode;

    // Resolve display names for current selections.
    final selectedCategory = categoryId != null
        ? categories.where((c) => c.id == categoryId).firstOrNull
        : null;
    final nonSystemWallets = wallets.where((w) => !w.isSystemWallet).toList();
    final selectedWallet = walletId != null
        ? wallets.where((w) => w.id == walletId).firstOrNull
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drag handle
          const DragHandle(),

          // 2. Title
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Text(
              context.l10n.common_edit,
              style: context.textStyles.titleLarge,
            ),
          ),

          // 3. Amount input (compact)
          AmountInput(
            initialPiastres: amountPiastres,
            onAmountChanged: onAmountChanged,
            compact: true,
            autofocus: false,
          ),
          const SizedBox(height: AppSizes.sm),

          // 4. Title / note text field
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              hintText: context.l10n.voice_edit_title_hint,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // 5. Type chips (expense / income) — hidden for cash types
          if (!isCashType) ...[
            _TypeChipsRow(
              currentType: type,
              onTypeChanged: onTypeChanged,
            ),
            const SizedBox(height: AppSizes.md),
          ],

          // 6. Category selector
          ListTile(
            leading: Icon(
              selectedCategory != null
                  ? CategoryIconMapper.fromName(selectedCategory.iconName)
                  : AppIcons.category,
              color: selectedCategory != null
                  ? ColorUtils.fromHex(selectedCategory.colorHex)
                  : null,
              size: AppSizes.iconMd,
            ),
            title: Text(
              selectedCategory?.displayName(lang) ??
                  context.l10n.voice_confirm_select_category,
            ),
            trailing: Icon(
              context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
            ),
            onTap: () => _showCategoryPicker(
              context,
              ref,
              type: type,
            ),
          ),

          // 7. Wallet selector
          ListTile(
            leading: const Icon(AppIcons.wallet, size: AppSizes.iconMd),
            title: Text(
              selectedWallet?.name ?? context.l10n.voice_select_wallet,
            ),
            trailing: Icon(
              context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
            ),
            onTap: () => _showWalletPicker(
              context,
              nonSystemWallets,
            ),
          ),

          // Bottom safe-area padding
          SizedBox(height: MediaQuery.paddingOf(context).bottom + AppSizes.md),
        ],
      ),
    );
  }

  // ── Nested pickers ──────────────────────────────────────────────────────

  void _showCategoryPicker(
    BuildContext context,
    WidgetRef ref, {
    required String type,
  }) {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final typeCats =
        categories.where((c) => c.type == type || c.type == 'both').toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: AppSizes.sheetInitialSize,
        minChildSize: AppSizes.sheetMinSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md,
                0,
                AppSizes.md,
                AppSizes.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.l10n.voice_confirm_select_category,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: typeCats.length,
                itemBuilder: (_, i) {
                  final cat = typeCats[i];
                  final color = ColorUtils.fromHex(cat.colorHex);
                  return ListTile(
                    leading: Icon(
                      CategoryIconMapper.fromName(cat.iconName),
                      size: AppSizes.iconMd,
                      color: color,
                    ),
                    title: Text(cat.displayName(context.languageCode)),
                    selected: cat.id == categoryId,
                    onTap: () {
                      onCategoryChanged(cat.id);
                      ctx.pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletPicker(
    BuildContext context,
    List<WalletEntity> nonSystemWallets,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: AppSizes.sheetSmallInitialSize,
        maxChildSize: AppSizes.sheetSmallMaxSize,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md,
                0,
                AppSizes.md,
                AppSizes.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.l10n.voice_select_wallet,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: nonSystemWallets.length,
                itemBuilder: (_, i) {
                  final w = nonSystemWallets[i];
                  return ListTile(
                    leading: const Icon(AppIcons.wallet, size: AppSizes.iconMd),
                    title: Text(w.name),
                    selected: w.id == walletId,
                    onTap: () {
                      onWalletChanged(w.id);
                      ctx.pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of ChoiceChips to toggle between expense and income types.
class _TypeChipsRow extends StatelessWidget {
  const _TypeChipsRow({
    required this.currentType,
    required this.onTypeChanged,
  });

  final String currentType;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;

    return Row(
      children: [
        ChoiceChip(
          avatar: Icon(
            AppIcons.expense,
            size: AppSizes.iconSm,
            color: currentType == 'expense'
                ? theme.expenseColor
                : context.colors.onSurfaceVariant,
          ),
          label: Text(context.l10n.transaction_type_expense),
          selected: currentType == 'expense',
          selectedColor:
              theme.expenseColor.withValues(alpha: AppSizes.opacityLight),
          onSelected: (_) => onTypeChanged('expense'),
        ),
        const SizedBox(width: AppSizes.sm),
        ChoiceChip(
          avatar: Icon(
            AppIcons.income,
            size: AppSizes.iconSm,
            color: currentType == 'income'
                ? theme.incomeColor
                : context.colors.onSurfaceVariant,
          ),
          label: Text(context.l10n.transaction_type_income),
          selected: currentType == 'income',
          selectedColor:
              theme.incomeColor.withValues(alpha: AppSizes.opacityLight),
          onSelected: (_) => onTypeChanged('income'),
        ),
      ],
    );
  }
}
