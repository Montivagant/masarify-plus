import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/voice_dictionary.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/goal_keyword_matcher.dart';
import '../../../../core/utils/voice_transaction_parser.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

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
    // Prefer user's saved default wallet, fallback to first non-system.
    final prefs = ref.read(preferencesFutureProvider).valueOrNull;
    final savedDefaultId = prefs?.defaultWalletId;
    final defaultWalletId =
        (savedDefaultId != null && nonSystem.any((w) => w.id == savedDefaultId))
            ? savedDefaultId
            : nonSystem.firstOrNull?.id ??
                (wallets.isNotEmpty ? wallets.first.id : null);
    final defaultBankWalletId = nonSystem.firstOrNull?.id;
    final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];

    String? unmatchedWalletHint;

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

      // Wallet hint matching: prefer exact match, then unique contains
      if (draft.walletHint != null && draft.walletHint!.isNotEmpty) {
        final hintLower = draft.walletHint!.toLowerCase();
        // 1. Exact case-insensitive match
        final exactMatch =
            wallets.where((w) => w.name.toLowerCase() == hintLower).firstOrNull;
        if (exactMatch != null) {
          draft.walletId = exactMatch.id;
        } else {
          // 2. Contains match — only auto-assign if exactly one match
          final containsMatches = wallets
              .where(
                (w) =>
                    w.name.toLowerCase().contains(hintLower) ||
                    hintLower.contains(w.name.toLowerCase()),
              )
              .toList();
          if (containsMatches.length == 1) {
            draft.walletId = containsMatches.first.id;
          } else if (containsMatches.isEmpty) {
            unmatchedWalletHint ??= draft.walletHint;
            // Find closest wallet by simple character overlap
            final hintChars = draft.walletHint!.toLowerCase();
            WalletEntity? closest;
            int bestScore = 0;
            for (final w in wallets) {
              final score = _similarityScore(hintChars, w.name.toLowerCase());
              // Require at least 50% char overlap to avoid Arabic false positives.
              final threshold =
                  (hintChars.length * 0.5).ceil().clamp(3, hintChars.length);
              if (score > bestScore && score >= threshold) {
                bestScore = score;
                closest = w;
              }
            }
            if (closest != null) {
              draft.suggestedWalletId = closest.id;
              draft.suggestedWalletName = closest.name;
            }
          }
          // Multiple matches: leave walletId null — user picks manually
        }
      }
      final isCash =
          draft.type == 'cash_withdrawal' || draft.type == 'cash_deposit';
      draft.walletId ??= isCash ? defaultBankWalletId : defaultWalletId;

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
    }

    // Show suggestion for unmatched wallet hint
    if (unmatchedWalletHint != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.voice_wallet_not_found(unmatchedWalletHint!),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: AppSizes.snackbarBottomMargin,
              left: AppSizes.md,
              right: AppSizes.md,
            ),
            duration: AppDurations.snackbarLong,
            action: SnackBarAction(
              label: context.l10n.common_create,
              onPressed: () async {
                try {
                  await ref.read(walletRepositoryProvider).create(
                        name: unmatchedWalletHint!,
                        type: 'bank',
                        initialBalance: 0,
                      );
                  if (mounted) {
                    _applyDefaults();
                    setState(() {});
                  }
                } catch (_) {
                  if (mounted) {
                    SnackHelper.showError(
                      context,
                      context.l10n.wallet_name_duplicate,
                    );
                  }
                }
              },
            ),
          ),
        );
      });
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

                final walletNotMatched = draft.walletHint != null &&
                    draft.walletHint!.isNotEmpty &&
                    draft.walletId == null;

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
                        draft.type == 'cash_deposit') {
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
                  walletNotMatched: walletNotMatched,
                  onAcceptSuggestedWallet: draft.suggestedWalletId != null
                      ? () {
                          setState(() {
                            draft.walletId = draft.suggestedWalletId;
                          });
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

  /// Checks [text] against active goals' keywords.
  /// Returns the first matching goal name, or null.

  /// Returns true if [type] is a cash withdrawal or deposit.
  static bool _isCashType(String type) =>
      type == 'cash_withdrawal' || type == 'cash_deposit';

  /// Simple character-overlap similarity score between two strings.
  static int _similarityScore(String a, String b) {
    int score = 0;
    for (int i = 0; i < a.length; i++) {
      if (b.contains(a[i])) score++;
    }
    return score;
  }

  Future<void> _confirmAll(BuildContext ctx) async {
    // R5-I7 fix: prevent double-tap race condition
    if (_saving) return;

    // Only save included drafts
    final included = _editableDrafts.where((d) => d.isIncluded).toList();
    if (included.isEmpty) return;

    // Change 4: validate all included drafts have a wallet assigned
    final missingWallet = included.any((d) => d.walletId == null);
    if (missingWallet) {
      if (mounted) {
        SnackHelper.showError(ctx, ctx.l10n.voice_assign_accounts_first);
      }
      return;
    }

    // Separate cash-type drafts from regular transaction drafts
    final cashDrafts = included.where((d) => _isCashType(d.type)).toList();
    final txDrafts = included.where((d) => !_isCashType(d.type)).toList();

    // Validate all included drafts
    final total = included.length;
    for (var i = 0; i < total; i++) {
      final draft = included[i];
      final prefix = total > 1 ? '(${i + 1}/$total) ' : '';
      if (draft.amountPiastres <= 0) {
        SnackHelper.showError(ctx, '$prefix${ctx.l10n.error_amount_zero}');
        return;
      }
      // Cash types don't need a category
      if (draft.categoryId == null && !_isCashType(draft.type)) {
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
    }

    setState(() => _saving = true);
    HapticFeedback.heavyImpact();

    final messenger = ScaffoldMessenger.of(ctx);
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
          if (draft.type == 'cash_withdrawal') {
            await transferRepo.create(
              fromWalletId: bankWalletId,
              toWalletId: cashWallet.id,
              amount: draft.amountPiastres,
              note: draft.note,
              transferDate: draft.transactionDate,
            );
          } else {
            // cash_deposit
            await transferRepo.create(
              fromWalletId: cashWallet.id,
              toWalletId: bankWalletId,
              amount: draft.amountPiastres,
              note: draft.note,
              transferDate: draft.transactionDate,
            );
          }
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
                  title: draft.noteController.text.trim().isNotEmpty
                      ? draft.noteController.text.trim()
                      : draft.rawText,
                  transactionDate: draft.transactionDate,
                  source: 'voice',
                  rawSourceText: draft.rawText,
                  note: draft.note,
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
        messenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(
              bottom: AppSizes.snackbarBottomMargin,
              left: AppSizes.md,
              right: AppSizes.md,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            ),
            duration: AppDurations.snackbarLong,
            content: Text(l10n.goal_link_prompt(matchedGoalName)),
          ),
        );
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              width: AppSizes.dragHandleWidth,
              height: AppSizes.dragHandleHeight,
              decoration: BoxDecoration(
                color: ctx.colors.outlineVariant,
                borderRadius:
                    BorderRadius.circular(AppSizes.dragHandleHeight / 2),
              ),
            ),
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
    final wallets = (ref.read(walletsProvider).valueOrNull ?? [])
        .where((w) => !w.isSystemWallet)
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              width: AppSizes.dragHandleWidth,
              height: AppSizes.dragHandleHeight,
              decoration: BoxDecoration(
                color: ctx.colors.outlineVariant,
                borderRadius:
                    BorderRadius.circular(AppSizes.dragHandleHeight / 2),
              ),
            ),
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
                    leading: const Icon(AppIcons.wallet, size: AppSizes.iconMd),
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
}

// ── Editable draft (mutable copy of VoiceTransactionDraft) ────────────────

class _EditableDraft {
  _EditableDraft({
    required this.rawText,
    required this.amountPiastres,
    this.categoryHint,
    this.walletHint,
    this.note,
    required this.type,
    required this.transactionDate,
  }) : noteController = TextEditingController(text: note ?? rawText);

  factory _EditableDraft.from(VoiceTransactionDraft d) => _EditableDraft(
        rawText: d.rawText,
        amountPiastres: d.amountPiastres ?? 0,
        categoryHint: d.categoryHint,
        walletHint: d.walletHint,
        note: d.note,
        type: d.type,
        transactionDate: d.transactionDate,
      );

  final String rawText;
  int amountPiastres;
  String? categoryHint;
  String? walletHint;
  String? note;
  int? categoryId;
  int? walletId;
  int? goalId;
  String? matchedGoalName;
  String type;
  DateTime transactionDate;
  bool isIncluded = true;

  /// Fuzzy-matched wallet suggestion when exact/contains match fails.
  int? suggestedWalletId;
  String? suggestedWalletName;

  /// Editable title/note for refining the transaction description.
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
    required this.isIncluded,
    this.matchedGoalName,
    required this.onToggleIncluded,
    required this.onAmountChanged,
    required this.onTypeToggle,
    required this.onCategoryTap,
    required this.onWalletTap,
    required this.walletNotMatched,
    this.onAcceptSuggestedWallet,
  });

  final _EditableDraft draft;
  final String? categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? walletName;
  final bool isIncluded;
  final String? matchedGoalName;
  final VoidCallback onToggleIncluded;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onTypeToggle;
  final VoidCallback onCategoryTap;
  final VoidCallback onWalletTap;
  final bool walletNotMatched;
  final VoidCallback? onAcceptSuggestedWallet;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isCash =
        draft.type == 'cash_withdrawal' || draft.type == 'cash_deposit';
    final typeColor = switch (draft.type) {
      'income' => context.appTheme.incomeColor,
      'cash_withdrawal' || 'cash_deposit' => context.appTheme.transferColor,
      _ => context.appTheme.expenseColor,
    };
    final walletWarningColor = cs.error;

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

            // ── Editable title field ─────────────────────────────
            IgnorePointer(
              ignoring: !isIncluded,
              child: TextField(
                controller: draft.noteController,
                style: context.textStyles.bodySmall,
                decoration: InputDecoration(
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

            // ── Type toggle + Category picker ──────────────────
            IgnorePointer(
              ignoring: !isIncluded,
              child: Row(
                children: [
                  // Type chip — not tappable for cash types
                  GestureDetector(
                    onTap: isCash ? null : onTypeToggle,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color:
                            typeColor.withValues(alpha: AppSizes.opacityLight2),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: Text(
                        switch (draft.type) {
                          'income' => context.l10n.transaction_type_income,
                          'cash_withdrawal' =>
                            context.l10n.transaction_type_cash_withdrawal_short,
                          'cash_deposit' =>
                            context.l10n.transaction_type_cash_deposit_short,
                          _ => context.l10n.transaction_type_expense,
                        },
                        style: context.textStyles.bodySmall?.copyWith(
                          color: typeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),

                  // Category chip — hidden for cash types
                  if (!isCash)
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

            // ── Wallet picker chip ──────────────────────────────
            const SizedBox(height: AppSizes.sm),
            IgnorePointer(
              ignoring: !isIncluded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: onWalletTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: walletNotMatched
                            ? walletWarningColor.withValues(
                                alpha: AppSizes.opacityLight2,
                              )
                            : cs.secondaryContainer
                                .withValues(alpha: AppSizes.opacityLight2),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: walletNotMatched
                            ? Border.all(
                                color: walletWarningColor,
                              )
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            walletNotMatched
                                ? AppIcons.warning
                                : AppIcons.wallet,
                            size: AppSizes.iconXxs2,
                            color: walletNotMatched
                                ? walletWarningColor
                                : cs.onSecondaryContainer,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            walletName ?? context.l10n.voice_select_wallet,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: walletNotMatched
                                  ? walletWarningColor
                                  : cs.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (walletNotMatched) ...[
                    const SizedBox(height: AppSizes.xs),
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(start: AppSizes.md),
                      child: Text(
                        context.l10n.voice_wallet_not_matched,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: walletWarningColor,
                        ),
                      ),
                    ),
                  ],
                  // ── "Did you mean X?" suggestion ──────────────
                  if (draft.suggestedWalletName != null &&
                      draft.walletId != draft.suggestedWalletId)
                    Padding(
                      padding:
                          const EdgeInsetsDirectional.only(start: AppSizes.sm),
                      child: TextButton(
                        onPressed: onAcceptSuggestedWallet,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          context.l10n
                              .voice_did_you_mean(draft.suggestedWalletName!),
                          style: context.textStyles.bodySmall?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
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
