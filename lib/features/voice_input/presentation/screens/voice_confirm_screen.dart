import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/voice_dictionary.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/recurring_pattern_detector.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/goal_keyword_matcher.dart';
import '../../../../core/utils/subscription_detector.dart';
import '../../../../core/utils/voice_transaction_parser.dart';
import '../../../../core/utils/wallet_matcher.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';

/// Rule #7: Voice-parsed transactions MUST pass review — never auto-save.
class VoiceConfirmScreen extends ConsumerStatefulWidget {
  const VoiceConfirmScreen({super.key, required this.drafts});

  final List<VoiceTransactionDraft> drafts;

  @override
  ConsumerState<VoiceConfirmScreen> createState() => _VoiceConfirmScreenState();
}

class _VoiceConfirmScreenState extends ConsumerState<VoiceConfirmScreen> {
  late List<_EditableDraft> _editableDrafts;
  bool _saving = false;
  bool _defaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _editableDrafts = widget.drafts.map((d) => _EditableDraft.from(d)).toList();
  }

  @override
  void dispose() {
    for (final d in _editableDrafts) {
      d.titleController.dispose();
      d.noteController.dispose();
    }
    super.dispose();
  }

  /// Apply category auto-match, wallet hint matching, and goal suggestions.
  ///
  /// Reads categories/wallets/goals from providers so it can be re-called
  /// after returning from the wallet-add screen.
  void _applyDefaults() {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final nonSystem = wallets.where((w) => !w.isSystemWallet).toList();
    final cashWallet = ref.read(systemWalletProvider).valueOrNull;
    // Default account from DB flag — fallback for all unmatched drafts.
    final defaultAccount =
        nonSystem.where((w) => w.isDefaultAccount).firstOrNull;
    final defaultAccountId = defaultAccount?.id ?? nonSystem.firstOrNull?.id;
    final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];

    for (final draft in _editableDrafts) {
      if (draft.categoryId == null && draft.categoryHint != null) {
        // WS-4 fix: add type filter to iconName match.
        final match = categories
            .where(
              (c) =>
                  c.iconName == draft.categoryHint &&
                  (c.type == draft.type || c.type == 'both'),
            )
            .firstOrNull;
        if (match != null) {
          draft.categoryId = match.id;
        }
      }
      // WS-4 fix: keyword fallback when AI icon didn't match.
      if (draft.categoryId == null) {
        final text = draft.rawText.toLowerCase();
        for (final entry in VoiceDictionary.categoryKeywords.entries) {
          if (text.contains(entry.key)) {
            final kwMatch = categories
                .where(
                  (c) =>
                      c.iconName == entry.value &&
                      (c.type == draft.type || c.type == 'both'),
                )
                .firstOrNull;
            if (kwMatch != null) {
              draft.categoryId = kwMatch.id;
              break;
            }
          }
        }
      }

      // Transfer drafts: use WalletMatcher for both source and destination.
      if (draft.isTransfer) {
        if (draft.walletHint != null && draft.walletHint!.isNotEmpty) {
          if (cashWallet != null &&
              WalletMatcher.isCashWalletHint(draft.walletHint!)) {
            draft.walletId = cashWallet.id;
          } else {
            final match = WalletMatcher.match(draft.walletHint!, nonSystem);
            if (match != null) {
              draft.walletId = match.id;
            } else {
              draft.walletId = defaultAccountId;
              draft.unmatchedHint = draft.walletHint;
            }
          }
        }
        if (draft.toWalletHint != null && draft.toWalletHint!.isNotEmpty) {
          if (cashWallet != null &&
              WalletMatcher.isCashWalletHint(draft.toWalletHint!)) {
            draft.toWalletId = cashWallet.id;
          } else {
            final match = WalletMatcher.match(draft.toWalletHint!, nonSystem);
            if (match != null) {
              draft.toWalletId = match.id;
            } else {
              draft.unmatchedToHint = draft.toWalletHint;
            }
          }
        }
        // Ensure from != to.
        if (draft.walletId != null && draft.walletId == draft.toWalletId) {
          draft.toWalletId = null;
        }
      } else {
        // Non-transfer: check cash keywords first, then WalletMatcher.
        if (draft.walletHint != null && draft.walletHint!.isNotEmpty) {
          if (cashWallet != null &&
              WalletMatcher.isCashWalletHint(draft.walletHint!)) {
            draft.walletId = cashWallet.id;
          } else {
            final match = WalletMatcher.match(draft.walletHint!, nonSystem);
            if (match != null) {
              draft.walletId = match.id;
            } else {
              draft.walletId = defaultAccountId;
              draft.unmatchedHint = draft.walletHint;
            }
          }
        }
      }
      // Prefer dashboard carousel selection, then DB default account.
      final selectedId = ref.read(selectedAccountIdProvider);
      draft.walletId ??= selectedId ?? defaultAccountId;

      // Goal inline suggestion: check rawText against active goal keywords.
      if (draft.matchedGoalName == null) {
        for (final goal in goals) {
          final List<String> kws;
          try {
            kws = (jsonDecode(goal.keywords) as List).cast<String>();
          } catch (_) {
            continue;
          }
          final matcher = GoalKeywordMatcher(keywords: kws);
          if (matcher.matches(draft.rawText)) {
            draft.matchedGoalName = goal.name;
            draft.goalId = goal.id;
            break;
          }
        }
      }

      // Subscription suggestion for expense-type drafts.
      if (draft.type == 'expense' && draft.categoryId != null) {
        final matchedCat =
            categories.where((c) => c.id == draft.categoryId).firstOrNull;
        draft.showRecurringSuggestion = SubscriptionDetector.isSubscriptionLike(
          categoryName: matchedCat?.name,
          transactionText: draft.rawText,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final hasNonSystemWallet = wallets.any((w) => !w.isSystemWallet);

    // Apply auto-matching once when categories/wallets become available.
    // Set flag immediately to prevent duplicate scheduling from rebuilds.
    if (categories.isNotEmpty && hasNonSystemWallet && !_defaultsApplied) {
      _defaultsApplied = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyDefaults();
          setState(() {});
        }
      });
    }

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.voice_confirm_title,
        actions: _editableDrafts.length > 1
            ? [
                TextButton(
                  onPressed: () {
                    final allIncluded =
                        _editableDrafts.every((d) => d.isIncluded);
                    setState(() {
                      for (final d in _editableDrafts) {
                        d.isIncluded = !allIncluded;
                      }
                    });
                  },
                  child: Text(
                    _editableDrafts.every((d) => d.isIncluded)
                        ? context.l10n.voice_deselect_all
                        : context.l10n.voice_select_all,
                  ),
                ),
              ]
            : null,
      ),
      body: _editableDrafts.isEmpty
          ? Center(
              child: Text(
                context.l10n.voice_no_results,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.outline,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSizes.md,
                bottom: AppSizes.bottomScrollPadding,
              ),
              itemCount: _editableDrafts.length,
              itemBuilder: (context, index) {
                final draft = _editableDrafts[index];
                final cat = categories
                    .where((c) => c.id == draft.categoryId)
                    .firstOrNull;

                final wallet =
                    wallets.where((w) => w.id == draft.walletId).firstOrNull;
                final toWallet = draft.isTransfer
                    ? wallets.where((w) => w.id == draft.toWalletId).firstOrNull
                    : null;

                final card = _DraftCard(
                  draft: draft,
                  categoryName: cat?.displayName(context.languageCode),
                  categoryIcon: cat != null
                      ? CategoryIconMapper.fromName(cat.iconName)
                      : AppIcons.category,
                  categoryColor: cat != null
                      ? ColorUtils.fromHex(cat.colorHex)
                      : context.colors.outline,
                  walletName: wallet?.name,
                  toWalletName: toWallet?.name,
                  isIncluded: draft.isIncluded,
                  matchedGoalName: draft.matchedGoalName,
                  onToggleIncluded: () {
                    setState(() => draft.isIncluded = !draft.isIncluded);
                  },
                  onAmountChanged: (piastres) {
                    draft.amountPiastres = piastres;
                  },
                  onTypeToggle: () {
                    if (draft.type == 'cash_withdrawal' ||
                        draft.type == 'cash_deposit' ||
                        draft.isTransfer) {
                      return;
                    }
                    setState(() {
                      draft.type =
                          draft.type == 'income' ? 'expense' : 'income';
                      // Clear category if it doesn't match the new type
                      if (draft.categoryId != null) {
                        final cat = categories
                            .where((c) => c.id == draft.categoryId)
                            .firstOrNull;
                        if (cat != null &&
                            cat.type != draft.type &&
                            cat.type != 'both') {
                          draft.categoryId = null;
                        }
                      }
                    });
                  },
                  onCategoryTap: () => _showCategoryPicker(context, draft),
                  onWalletTap: () => _showWalletPicker(context, draft),
                  onToWalletTap: draft.isTransfer
                      ? () => _showToWalletPicker(context, draft)
                      : null,
                  onCreateWalletFromHint: draft.unmatchedHint != null
                      ? () => _createWalletFromHint(draft)
                      : null,
                  onAddAsRecurring: draft.showRecurringSuggestion
                      ? () {
                          context.push(
                            AppRoutes.recurringAdd,
                            extra: DetectedPattern(
                              categoryId: draft.categoryId!,
                              amount: draft.amountPiastres,
                              title:
                                  draft.titleController.text.trim().isNotEmpty
                                      ? draft.titleController.text.trim()
                                      : draft.rawText,
                              frequency: 'monthly',
                              confidence: 1.0,
                              nextExpectedDate:
                                  DateTime.now().add(const Duration(days: 30)),
                              type: draft.type,
                            ),
                          );
                        }
                      : null,
                );
                if (context.reduceMotion) return card;
                return card
                    .animate()
                    .fadeIn(duration: AppDurations.listItemEntry)
                    .slideY(
                      begin: 0.03,
                      end: 0,
                      duration: AppDurations.listItemEntry,
                      curve: Curves.easeOutCubic,
                    )
                    .then(delay: AppDurations.staggerDelay * index);
              },
            ),
      bottomNavigationBar: _editableDrafts.isNotEmpty
          ? Builder(
              builder: (context) {
                final includedCount =
                    _editableDrafts.where((d) => d.isIncluded).length;
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.screenHPadding),
                    child: FilledButton(
                      onPressed: _saving || includedCount == 0
                          ? null
                          : () => _confirmAll(context),
                      child: _saving
                          ? SizedBox(
                              width: AppSizes.spinnerSize,
                              height: AppSizes.spinnerSize,
                              child: CircularProgressIndicator(
                                strokeWidth: AppSizes.spinnerStrokeWidth,
                                color: context.colors.onPrimary,
                              ),
                            )
                          : Text(
                              context.l10n.voice_confirm_count(includedCount),
                            ),
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  /// Returns true if [type] is a cash withdrawal or deposit.
  static bool _isCashType(String type) =>
      type == 'cash_withdrawal' || type == 'cash_deposit';

  /// Returns true if [type] is a transfer.
  static bool _isTransferType(String type) => type == 'transfer';

  Future<void> _confirmAll(BuildContext ctx) async {
    // R5-I7 fix: prevent double-tap race condition
    if (_saving) return;

    // Only save included drafts
    final included = _editableDrafts.where((d) => d.isIncluded).toList();
    if (included.isEmpty) return;

    // Separate cash-type, transfer, and regular transaction drafts
    final cashDrafts = included.where((d) => _isCashType(d.type)).toList();
    final transferDrafts =
        included.where((d) => _isTransferType(d.type)).toList();
    final txDrafts = included
        .where((d) => !_isCashType(d.type) && !_isTransferType(d.type))
        .toList();

    // Validate all included drafts
    final total = included.length;
    for (var i = 0; i < total; i++) {
      final draft = included[i];
      final prefix = total > 1 ? '(${i + 1}/$total) ' : '';
      if (draft.amountPiastres <= 0) {
        SnackHelper.showError(ctx, '$prefix${ctx.l10n.error_amount_zero}');
        return;
      }
      // Cash types and transfers don't need a category
      if (draft.categoryId == null &&
          !_isCashType(draft.type) &&
          !_isTransferType(draft.type)) {
        SnackHelper.showError(
          ctx,
          '$prefix${ctx.l10n.error_category_required}',
        );
        return;
      }
      if (draft.walletId == null) {
        SnackHelper.showError(ctx, '$prefix${ctx.l10n.error_wallet_required}');
        return;
      }
      // Transfers require both wallets
      if (_isTransferType(draft.type)) {
        if (draft.toWalletId == null) {
          SnackHelper.showError(
            ctx,
            '$prefix${ctx.l10n.voice_transfer_select_wallets}',
          );
          return;
        }
        if (draft.walletId == draft.toWalletId) {
          SnackHelper.showError(
            ctx,
            '$prefix${ctx.l10n.voice_transfer_select_wallets}',
          );
          return;
        }
      }
    }

    setState(() => _saving = true);
    HapticFeedback.heavyImpact();

    final nav = GoRouter.of(ctx);
    final l10n = ctx.l10n;
    final savedMsg = l10n.transaction_saved;
    final errorMsg = l10n.common_error_generic;

    try {
      // Save cash drafts as transfers
      if (cashDrafts.isNotEmpty) {
        final cashWallet = ref.read(systemWalletProvider).valueOrNull;
        if (cashWallet == null) {
          setState(() => _saving = false);
          if (mounted) SnackHelper.showError(ctx, errorMsg);
          return;
        }

        final transferRepo = ref.read(transferRepositoryProvider);
        for (final draft in cashDrafts) {
          final bankWalletId = draft.walletId!;
          final titleText = draft.titleController.text.trim();
          final noteText = draft.noteController.text.trim();
          final cashNote = titleText.isNotEmpty
              ? titleText
              : noteText.isNotEmpty
                  ? noteText
                  : draft.rawText;
          if (draft.type == 'cash_withdrawal') {
            await transferRepo.create(
              fromWalletId: bankWalletId,
              toWalletId: cashWallet.id,
              amount: draft.amountPiastres,
              note: cashNote,
              transferDate: draft.transactionDate,
            );
          } else {
            // cash_deposit
            await transferRepo.create(
              fromWalletId: cashWallet.id,
              toWalletId: bankWalletId,
              amount: draft.amountPiastres,
              note: cashNote,
              transferDate: draft.transactionDate,
            );
          }
        }
      }

      // Save transfer drafts
      if (transferDrafts.isNotEmpty) {
        final transferRepo = ref.read(transferRepositoryProvider);
        for (final draft in transferDrafts) {
          final titleText = draft.titleController.text.trim();
          final noteText = draft.noteController.text.trim();
          await transferRepo.create(
            fromWalletId: draft.walletId!,
            toWalletId: draft.toWalletId!,
            amount: draft.amountPiastres,
            note: titleText.isNotEmpty
                ? titleText
                : noteText.isNotEmpty
                    ? noteText
                    : draft.rawText,
            transferDate: draft.transactionDate,
          );
        }
      }

      // Save regular transaction drafts as batch
      if (txDrafts.isNotEmpty) {
        final txRepo = ref.read(transactionRepositoryProvider);
        await txRepo.createBatch(
          txDrafts
              .map(
                (draft) => CreateTransactionParams(
                  walletId: draft.walletId!,
                  categoryId: draft.categoryId!,
                  amount: draft.amountPiastres,
                  type: draft.type,
                  title: draft.titleController.text.trim().isNotEmpty
                      ? draft.titleController.text.trim()
                      : draft.rawText,
                  transactionDate: draft.transactionDate,
                  source: 'voice',
                  rawSourceText: draft.rawText,
                  note: draft.noteController.text.trim().isEmpty
                      ? null
                      : draft.noteController.text.trim(),
                  goalId: draft.goalId,
                ),
              )
              .toList(),
        );
      }

      if (!mounted) return;

      // Use the goal match already computed during _applyDefaults.
      final matchedGoalName = txDrafts.map((d) => d.matchedGoalName).firstWhere(
            (n) => n != null,
            orElse: () => null,
          );

      if (matchedGoalName != null) {
        if (mounted) {
          SnackHelper.showInfo(
            context,
            l10n.goal_link_prompt(matchedGoalName),
            duration: AppDurations.snackbarLong,
          );
        }
      } else {
        if (mounted) SnackHelper.showSuccess(context, savedMsg);
      }
      nav.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackHelper.showError(context, errorMsg);
    }
  }

  Future<void> _showCategoryPicker(
    BuildContext context,
    _EditableDraft draft,
  ) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final typeCats = categories
        .where((c) => c.type == draft.type || c.type == 'both')
        .toList();

    await showModalBottomSheet<void>(
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
                  context.l10n.transaction_category_picker,
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
                    selected: cat.id == draft.categoryId,
                    onTap: () {
                      setState(() => draft.categoryId = cat.id);
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

  Future<void> _showWalletPicker(
    BuildContext context,
    _EditableDraft draft,
  ) async {
    // For cash_withdrawal/deposit, picker selects the bank — hide system Cash.
    // For expense/income/transfer, Cash is a valid selection.
    final isCash = _isCashType(draft.type);
    final wallets = (ref.read(walletsProvider).valueOrNull ?? [])
        .where((w) => !isCash || !w.isSystemWallet)
        .toList();

    await showModalBottomSheet<void>(
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
                itemCount: wallets.length,
                itemBuilder: (_, i) {
                  final w = wallets[i];
                  return ListTile(
                    leading: Icon(
                      AppIcons.walletType(w.type),
                      size: AppSizes.iconMd,
                    ),
                    title: Text(w.name),
                    selected: w.id == draft.walletId,
                    onTap: () {
                      setState(() => draft.walletId = w.id);
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

  Future<void> _showToWalletPicker(
    BuildContext context,
    _EditableDraft draft,
  ) async {
    final isCash = _isCashType(draft.type);
    final wallets = (ref.read(walletsProvider).valueOrNull ?? [])
        .where((w) => !isCash || !w.isSystemWallet)
        .toList();

    await showModalBottomSheet<void>(
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
                  context.l10n.voice_transfer_to,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: wallets.length,
                itemBuilder: (_, i) {
                  final w = wallets[i];
                  return ListTile(
                    leading: Icon(
                      AppIcons.walletType(w.type),
                      size: AppSizes.iconMd,
                    ),
                    title: Text(w.name),
                    selected: w.id == draft.toWalletId,
                    onTap: () {
                      setState(() {
                        draft.toWalletId = w.id;
                        draft.unmatchedToHint = null;
                      });
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

  Future<void> _createWalletFromHint(_EditableDraft draft) async {
    final duplicateMsg = context.l10n.wallet_name_duplicate;
    final genericMsg = context.l10n.common_error_generic;
    final hintName = draft.unmatchedHint!;
    try {
      final newId = await ref.read(walletRepositoryProvider).create(
            name: hintName,
            type: 'bank',
            initialBalance: 0,
          );
      if (mounted) {
        setState(() {
          // Update ALL drafts that share the same unmatched wallet hint —
          // not just the one clicked. Otherwise other drafts stay on the
          // default wallet and transactions get assigned to the wrong account.
          for (final d in _editableDrafts) {
            if (d.unmatchedHint == hintName) {
              d.walletId = newId;
              d.unmatchedHint = null;
            }
          }
        });
      }
    } on ArgumentError {
      if (mounted) SnackHelper.showError(context, duplicateMsg);
    } catch (_) {
      if (mounted) SnackHelper.showError(context, genericMsg);
    }
  }
}

// ── Editable draft (mutable copy of VoiceTransactionDraft) ────────────────

class _EditableDraft {
  _EditableDraft({
    required this.rawText,
    required this.amountPiastres,
    this.categoryHint,
    this.walletHint,
    this.toWalletHint,
    String? title,
    this.note,
    required this.type,
    required this.transactionDate,
  })  : titleController = TextEditingController(
          text: title ?? _fallbackTitle(note ?? rawText),
        ),
        noteController = TextEditingController(text: note ?? rawText);

  factory _EditableDraft.from(VoiceTransactionDraft d) => _EditableDraft(
        rawText: d.rawText,
        amountPiastres: d.amountPiastres ?? 0,
        categoryHint: d.categoryHint,
        walletHint: d.walletHint,
        toWalletHint: d.toWalletHint,
        title: d.title,
        note: d.note,
        type: d.type,
        transactionDate: d.transactionDate,
      );

  /// Generates a fallback title from the first 3-4 words of the note text.
  static String _fallbackTitle(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    return words.take(4).join(' ');
  }

  final String rawText;
  int amountPiastres;
  String? categoryHint;
  String? walletHint;
  String? toWalletHint;
  String? note;
  int? categoryId;
  int? walletId;
  int? toWalletId;
  int? goalId;
  String? matchedGoalName;
  String type;
  DateTime transactionDate;
  bool isIncluded = true;
  bool showRecurringSuggestion = false;

  /// Set when wallet hint had no match — transaction defaulted to Default account.
  /// Enables inline "Create '{hint}' instead?" option on the draft card.
  String? unmatchedHint;

  /// Set when to-wallet hint had no match (transfers only).
  String? unmatchedToHint;

  /// Whether this draft represents an inter-account transfer.
  bool get isTransfer => type == 'transfer';

  /// Editable short title (2-4 words, AI-generated or fallback).
  final TextEditingController titleController;

  /// Editable description/note for the full transaction text.
  final TextEditingController noteController;
}

// ── Draft card widget ─────────────────────────────────────────────────────

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    this.walletName,
    this.toWalletName,
    required this.isIncluded,
    this.matchedGoalName,
    required this.onToggleIncluded,
    required this.onAmountChanged,
    required this.onTypeToggle,
    required this.onCategoryTap,
    required this.onWalletTap,
    this.onToWalletTap,
    this.onCreateWalletFromHint,
    this.onAddAsRecurring,
  });

  final _EditableDraft draft;
  final String? categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? walletName;
  final String? toWalletName;
  final bool isIncluded;
  final String? matchedGoalName;
  final VoidCallback onToggleIncluded;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onTypeToggle;
  final VoidCallback onCategoryTap;
  final VoidCallback onWalletTap;
  final VoidCallback? onToWalletTap;
  final VoidCallback? onCreateWalletFromHint;
  final VoidCallback? onAddAsRecurring;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isCash =
        draft.type == 'cash_withdrawal' || draft.type == 'cash_deposit';
    final isTransfer = draft.isTransfer;
    final typeColor = switch (draft.type) {
      'income' => context.appTheme.incomeColor,
      'cash_withdrawal' ||
      'cash_deposit' ||
      'transfer' =>
        context.appTheme.transferColor,
      _ => context.appTheme.expenseColor,
    };

    return Opacity(
      opacity: isIncluded ? 1.0 : AppSizes.opacityLight5,
      child: GlassCard(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
          vertical: AppSizes.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: checkbox + raw text ───────────────────────
            Row(
              children: [
                SizedBox(
                  width: AppSizes.iconContainerSm,
                  height: AppSizes.iconContainerSm,
                  child: Checkbox(
                    value: isIncluded,
                    onChanged: (_) => onToggleIncluded(),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    draft.rawText,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: cs.outline,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Editable title field (short, bold) ────────────────
            IgnorePointer(
              ignoring: !isIncluded,
              child: TextField(
                controller: draft.titleController,
                style: context.textStyles.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.voice_transaction_title_label,
                  hintText: context.l10n.voice_edit_title_hint,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Editable description field (secondary) ────────────
            IgnorePointer(
              ignoring: !isIncluded,
              child: TextField(
                controller: draft.noteController,
                style: context.textStyles.bodySmall?.copyWith(
                  color: cs.outline,
                ),
                decoration: InputDecoration(
                  labelText: context.l10n.voice_transaction_description_label,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Type toggle + Category picker ──────────────────
            IgnorePointer(
              ignoring: !isIncluded,
              child: Row(
                children: [
                  // Type chip — not tappable for cash types or transfers
                  Opacity(
                    opacity:
                        isCash || isTransfer ? AppSizes.opacityMedium : 1.0,
                    child: GestureDetector(
                      onTap: isCash || isTransfer ? null : onTypeToggle,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(
                            alpha: AppSizes.opacityLight2,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadiusSm),
                        ),
                        child: Text(
                          switch (draft.type) {
                            'income' => context.l10n.transaction_type_income,
                            'cash_withdrawal' => context
                                .l10n.transaction_type_cash_withdrawal_short,
                            'cash_deposit' =>
                              context.l10n.transaction_type_cash_deposit_short,
                            'transfer' =>
                              context.l10n.transaction_type_transfer,
                            _ => context.l10n.transaction_type_expense,
                          },
                          style: context.textStyles.bodySmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),

                  // Category chip — hidden for cash types and transfers
                  if (!isCash && !isTransfer)
                    GestureDetector(
                      onTap: onCategoryTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(
                            alpha: AppSizes.opacityLight2,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              categoryIcon,
                              size: AppSizes.iconXxs2,
                              color: categoryColor,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              categoryName ?? context.l10n.transaction_category,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Wallet picker chip(s) ──────────────────────────
            const SizedBox(height: AppSizes.sm),
            IgnorePointer(
              ignoring: !isIncluded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // For transfers: show "From:" label before the wallet chip
                  if (isTransfer)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSizes.xs,
                      ),
                      child: Text(
                        context.l10n.voice_transfer_from,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: onWalletTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer
                            .withValues(alpha: AppSizes.opacityLight2),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.wallet,
                            size: AppSizes.iconXxs2,
                            color: cs.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            walletName ?? context.l10n.voice_select_wallet,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: cs.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // ── Inline "Create instead?" for unmatched hints ──
                  if (draft.unmatchedHint != null)
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(start: AppSizes.sm),
                      child: TextButton(
                        onPressed: onCreateWalletFromHint,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          context.l10n.voice_create_wallet_instead(
                            draft.unmatchedHint!,
                          ),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  // ── Transfer: "To" wallet picker ──────────────────
                  if (isTransfer) ...[
                    const SizedBox(height: AppSizes.sm),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSizes.xs,
                      ),
                      child: Text(
                        context.l10n.voice_transfer_to,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onToWalletTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.xs,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(
                            alpha: AppSizes.opacityLight2,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.wallet,
                              size: AppSizes.iconXxs2,
                              color: typeColor,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Text(
                              toWalletName ?? context.l10n.voice_select_wallet,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: typeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (draft.unmatchedToHint != null)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          start: AppSizes.sm,
                        ),
                        child: Text(
                          context.l10n.chat_action_wallet_not_found(
                            draft.unmatchedToHint!,
                          ),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.appTheme.expenseColor,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // ── Goal suggestion note ────────────────────────────
            if (matchedGoalName != null) ...[
              const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Icon(
                    AppIcons.goals,
                    size: AppSizes.iconXxs2,
                    color: cs.tertiary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Flexible(
                    child: Text(
                      context.l10n.goal_link_prompt(matchedGoalName!),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: cs.tertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // ── Subscription suggestion ──────────────────────────
            if (onAddAsRecurring != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.sm),
                child: TextButton.icon(
                  onPressed: onAddAsRecurring,
                  icon: const Icon(AppIcons.recurring, size: AppSizes.iconXs),
                  label: Text(context.l10n.voice_add_as_recurring),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),

            // ── Tappable amount editor ───────────────────────────
            const SizedBox(height: AppSizes.sm),
            IgnorePointer(
              ignoring: !isIncluded,
              child: AmountInput(
                initialPiastres: draft.amountPiastres,
                onAmountChanged: onAmountChanged,
                autofocus: false,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
