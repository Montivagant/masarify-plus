import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';
import '../widgets/draft_card.dart';

/// Rule #7: Voice-parsed transactions MUST pass review — never auto-save.
///
/// Revamped glassmorphic full-screen form with:
/// - Prominent type-colored amount with +/- sign
/// - Tappable category/account/date/notes fields
/// - Subscription suggestion banners
/// - Missing-amount handling with disabled Save
/// - Multi-draft PageView with "Save & Next" flow
/// - Clean Arabic RTL with flipped directional arrows for transfers
class VoiceConfirmScreen extends ConsumerStatefulWidget {
  const VoiceConfirmScreen({super.key, required this.drafts});

  final List<VoiceTransactionDraft> drafts;

  @override
  ConsumerState<VoiceConfirmScreen> createState() => _VoiceConfirmScreenState();
}

class _VoiceConfirmScreenState extends ConsumerState<VoiceConfirmScreen> {
  late List<EditableDraft> _editableDrafts;
  late PageController _pageController;
  bool _saving = false;
  bool _defaultsApplied = false;
  int _currentPage = 0;

  /// Tracks which drafts have been individually saved (multi-draft mode).
  late List<bool> _savedFlags;

  /// Tracks dismissed subscription suggestions per draft.
  late List<bool> _subscriptionDismissed;

  @override
  void initState() {
    super.initState();
    _editableDrafts = widget.drafts
        .map(
          (d) => EditableDraft(
            rawText: d.rawText,
            amountPiastres: d.amountPiastres ?? 0,
            categoryHint: d.categoryHint,
            walletHint: d.walletHint,
            note: d.note,
            type: d.type,
            transactionDate: d.transactionDate,
          ),
        )
        .toList();
    _pageController = PageController();
    _savedFlags = List.filled(_editableDrafts.length, false);
    _subscriptionDismissed = List.filled(_editableDrafts.length, false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final d in _editableDrafts) {
      d.noteController.dispose();
    }
    super.dispose();
  }

  bool get _isMultiDraft => _editableDrafts.length > 1;

  // ── Auto-matching (category, wallet, goal) ────────────────────────────

  void _applyDefaults() {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final nonSystem = wallets.where((w) => !w.isSystemWallet).toList();
    final defaultAccount =
        nonSystem.where((w) => w.isDefaultAccount).firstOrNull;
    final defaultAccountId = defaultAccount?.id ?? nonSystem.firstOrNull?.id;
    final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];

    for (final draft in _editableDrafts) {
      // Category matching: iconName → keyword fallback
      if (draft.categoryId == null && draft.categoryHint != null) {
        final match = categories
            .where(
              (c) =>
                  c.iconName == draft.categoryHint &&
                  (c.type == draft.type || c.type == 'both'),
            )
            .firstOrNull;
        if (match != null) draft.categoryId = match.id;
      }
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

      // Wallet hint matching: exact → contains → fuzzy → default
      if (draft.walletHint != null && draft.walletHint!.isNotEmpty) {
        final hintLower = draft.walletHint!.toLowerCase();
        final exactMatch =
            wallets.where((w) => w.name.toLowerCase() == hintLower).firstOrNull;
        if (exactMatch != null) {
          draft.walletId = exactMatch.id;
        } else {
          final containsMatches = wallets
              .where(
                (w) =>
                    w.name.toLowerCase().contains(hintLower) ||
                    hintLower.contains(w.name.toLowerCase()),
              )
              .toList();
          if (containsMatches.length == 1) {
            draft.walletId = containsMatches.first.id;
          } else {
            final hintChars = draft.walletHint!.toLowerCase();
            WalletEntity? closest;
            int bestScore = 0;
            for (final w in wallets) {
              final score = _similarityScore(hintChars, w.name.toLowerCase());
              final threshold =
                  (hintChars.length * 0.5).ceil().clamp(3, hintChars.length);
              if (score > bestScore && score >= threshold) {
                bestScore = score;
                closest = w;
              }
            }
            if (closest != null) {
              draft.walletId = closest.id;
            } else {
              draft.walletId = defaultAccountId;
              draft.unmatchedHint = draft.walletHint;
            }
          }
        }
      }
      draft.walletId ??= defaultAccountId;

      // Goal suggestion
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
  }

  /// Simple character-overlap similarity score between two strings.
  static int _similarityScore(String a, String b) {
    int score = 0;
    for (int i = 0; i < a.length; i++) {
      if (b.contains(a[i])) score++;
    }
    return score;
  }

  /// Returns true if [type] is a cash withdrawal or deposit.
  static bool _isCashType(String type) =>
      type == 'cash_withdrawal' || type == 'cash_deposit';

  /// Inline subscription detection based on keywords.
  bool _isSubscription(int index) {
    if (_subscriptionDismissed[index]) return false;
    final draft = _editableDrafts[index];
    final text = '${draft.rawText} ${draft.noteController.text}'.toLowerCase();
    const keywords = [
      'netflix',
      'spotify',
      'youtube',
      'premium',
      'subscription',
      'اشتراك',
      'shahid',
      'anghami',
      'gym',
      'internet',
      'vodafone',
      'etisalat',
      'orange',
      'we',
    ];
    return keywords.any((k) => text.contains(k));
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final hasNonSystemWallet = wallets.any((w) => !w.isSystemWallet);

    // Apply auto-matching once when categories/wallets become available.
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
        centerTitle: _isMultiDraft,
        actions: _isMultiDraft
            ? [
                Center(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSizes.md,
                    ),
                    child: Text(
                      context.l10n.voice_confirm_draft_count(
                        _currentPage + 1,
                        _editableDrafts.length,
                      ),
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.outline,
                      ),
                    ),
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
          : _isMultiDraft
              ? _buildMultiDraftBody(context, categories, wallets)
              : _buildSingleDraftBody(context, categories, wallets),
      bottomNavigationBar:
          _editableDrafts.isNotEmpty ? _buildBottomBar(context) : null,
    );
  }

  // ── Single draft body ─────────────────────────────────────────────────

  Widget _buildSingleDraftBody(
    BuildContext context,
    List<dynamic> categories,
    List<dynamic> wallets,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsetsDirectional.all(AppSizes.md),
      child: _buildDraftCard(context, 0, categories, wallets),
    );
  }

  // ── Multi-draft PageView body ─────────────────────────────────────────

  Widget _buildMultiDraftBody(
    BuildContext context,
    List<dynamic> categories,
    List<dynamic> wallets,
  ) {
    return Column(
      children: [
        // Page indicator dots
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSizes.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_editableDrafts.length, (i) {
              final isCurrent = i == _currentPage;
              final isSaved = _savedFlags[i];
              return Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSizes.xs,
                ),
                child: AnimatedContainer(
                  duration: AppDurations.animQuick,
                  width: isCurrent ? AppSizes.dotLg : AppSizes.indicatorDotSize,
                  height: AppSizes.indicatorDotSize,
                  decoration: BoxDecoration(
                    color: isSaved
                        ? context.appTheme.incomeColor
                        : isCurrent
                            ? context.colors.primary
                            : context.colors.outlineVariant,
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusFull,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // PageView with draft cards
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _editableDrafts.length,
            itemBuilder: (context, index) {
              return SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(AppSizes.md),
                child: _savedFlags[index]
                    ? _buildSavedOverlay(context, index)
                    : _buildDraftCard(
                        context,
                        index,
                        categories,
                        wallets,
                      ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Saved overlay (multi-draft: already saved card) ───────────────────

  Widget _buildSavedOverlay(BuildContext context, int index) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: AppSizes.xxl),
          Icon(
            AppIcons.checkCircle,
            size: AppSizes.iconXl3,
            color: context.appTheme.incomeColor,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            context.l10n.transaction_saved,
            style: context.textStyles.titleMedium?.copyWith(
              color: context.appTheme.incomeColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Build a single DraftCard at [index] ───────────────────────────────

  Widget _buildDraftCard(
    BuildContext context,
    int index,
    List<dynamic> categories,
    List<dynamic> wallets,
  ) {
    final draft = _editableDrafts[index];
    final cat = categories.where((c) => c.id == draft.categoryId).firstOrNull;
    final wallet = wallets.where((w) => w.id == draft.walletId).firstOrNull;
    final toWallet = draft.toWalletId != null
        ? wallets.where((w) => w.id == draft.toWalletId).firstOrNull
        : null;

    return DraftCard(
      draft: draft,
      categoryName: cat?.displayName(context.languageCode) as String?,
      categoryIcon: cat != null
          ? CategoryIconMapper.fromName(cat.iconName as String)
          : AppIcons.category,
      categoryColor: cat != null
          ? ColorUtils.fromHex(cat.colorHex as String)
          : context.colors.outline,
      walletName: wallet?.name as String?,
      toWalletName: toWallet?.name as String?,
      matchedGoalName: draft.matchedGoalName,
      showSubscriptionSuggestion: _isSubscription(index),
      amountMissing: draft.amountPiastres <= 0,
      onAmountChanged: (piastres) {
        setState(() => draft.amountPiastres = piastres);
      },
      onTypeChanged: (newType) {
        if (_isCashType(draft.type)) return;
        setState(() {
          draft.type = newType;
          // Clear category if it no longer matches the new type
          if (draft.categoryId != null) {
            final matchCat =
                categories.where((c) => c.id == draft.categoryId).firstOrNull;
            if (matchCat != null &&
                matchCat.type != draft.type &&
                matchCat.type != 'both') {
              draft.categoryId = null;
            }
          }
        });
      },
      onCategoryTap: () => _showCategoryPicker(context, draft),
      onWalletTap: () => _showWalletPicker(context, draft),
      onToWalletTap: () => _showWalletPicker(context, draft, isFrom: false),
      onDateChanged: (date) {
        setState(() => draft.transactionDate = date);
      },
      onNotesChanged: (text) {
        draft.note = text;
      },
      onSubscriptionSuggestionAccepted: () {
        SnackHelper.showSuccess(
          context,
          context.l10n.voice_confirm_subscription_suggest,
        );
        setState(() => _subscriptionDismissed[index] = true);
      },
      onSubscriptionSuggestionDismissed: () {
        setState(() => _subscriptionDismissed[index] = true);
      },
      onCreateWalletFromHint: draft.unmatchedHint != null
          ? () => _createWalletFromHint(draft)
          : null,
    );
  }

  // ── Bottom bar with Save / Save & Next button ─────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final draft = _editableDrafts[_currentPage];
    final canSave = draft.amountPiastres > 0 &&
        (draft.categoryId != null || _isCashType(draft.type)) &&
        draft.walletId != null;

    final isLast = _currentPage == _editableDrafts.length - 1;
    final allSaved = _savedFlags.every((s) => s);

    if (_isMultiDraft && allSaved) {
      // All drafts saved — auto-pop
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SnackHelper.showSuccess(
            context,
            context.l10n.voice_confirm_all_saved,
          );
          context.pop();
        }
      });
      return const SizedBox.shrink();
    }

    final label = _isMultiDraft
        ? (_savedFlags[_currentPage]
            ? (isLast
                ? context.l10n.common_save
                : context.l10n.voice_confirm_save_next)
            : (isLast
                ? context.l10n.common_save
                : context.l10n.voice_confirm_save_next))
        : context.l10n.common_save;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSizes.md),
        child: AppButton(
          label: label,
          onPressed: _saving || _savedFlags[_currentPage]
              ? null
              : (canSave
                  ? () => _isMultiDraft
                      ? _saveAndNext(context)
                      : _saveSingle(context)
                  : null),
          isLoading: _saving,
        ),
      ),
    );
  }

  // ── Save single draft (single-draft mode) ─────────────────────────────

  Future<void> _saveSingle(BuildContext ctx) async {
    if (_saving) return;
    final draft = _editableDrafts[0];

    // Validate
    if (draft.amountPiastres <= 0) {
      SnackHelper.showError(ctx, ctx.l10n.error_amount_zero);
      return;
    }
    if (draft.categoryId == null && !_isCashType(draft.type)) {
      SnackHelper.showError(ctx, ctx.l10n.error_category_required);
      return;
    }
    if (draft.walletId == null) {
      SnackHelper.showError(ctx, ctx.l10n.error_wallet_required);
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.heavyImpact();

    final nav = GoRouter.of(ctx);
    final l10n = ctx.l10n;

    try {
      await _saveDraft(draft);
      if (!mounted) return;

      final goalName = draft.matchedGoalName;
      if (goalName != null) {
        SnackHelper.showInfo(
          context,
          l10n.goal_link_prompt(goalName),
          duration: AppDurations.snackbarLong,
        );
      } else {
        SnackHelper.showSuccess(context, l10n.transaction_saved);
      }
      nav.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackHelper.showError(context, l10n.common_error_generic);
    }
  }

  // ── Save & Next (multi-draft mode) ────────────────────────────────────

  Future<void> _saveAndNext(BuildContext ctx) async {
    if (_saving) return;
    final index = _currentPage;
    final draft = _editableDrafts[index];

    // Validate
    if (draft.amountPiastres <= 0) {
      SnackHelper.showError(ctx, ctx.l10n.error_amount_zero);
      return;
    }
    if (draft.categoryId == null && !_isCashType(draft.type)) {
      SnackHelper.showError(ctx, ctx.l10n.error_category_required);
      return;
    }
    if (draft.walletId == null) {
      SnackHelper.showError(ctx, ctx.l10n.error_wallet_required);
      return;
    }

    setState(() => _saving = true);
    HapticFeedback.lightImpact();

    final errorMsg = ctx.l10n.common_error_generic;

    try {
      await _saveDraft(draft);
      if (!mounted) return;

      setState(() {
        _savedFlags[index] = true;
        _saving = false;
      });

      // Advance to next unsaved draft
      final nextUnsaved = _savedFlags.indexWhere((s) => !s);
      if (nextUnsaved >= 0) {
        _pageController.animateToPage(
          nextUnsaved,
          duration: AppDurations.pageTransition,
          curve: Curves.easeOutCubic,
        );
      }
      // If all saved, bottom bar will auto-pop
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      SnackHelper.showError(context, errorMsg);
    }
  }

  // ── Core save logic (shared by single and multi-draft) ────────────────

  Future<void> _saveDraft(EditableDraft draft) async {
    if (_isCashType(draft.type)) {
      // Cash types saved as transfers
      final cashWallet = ref.read(systemWalletProvider).valueOrNull;
      if (cashWallet == null) throw StateError('No system wallet');

      final transferRepo = ref.read(transferRepositoryProvider);
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
    } else {
      // Regular transaction
      final txRepo = ref.read(transactionRepositoryProvider);
      await txRepo.createBatch([
        CreateTransactionParams(
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
      ]);
    }
  }

  // ── Category picker bottom sheet ──────────────────────────────────────

  Future<void> _showCategoryPicker(
    BuildContext context,
    EditableDraft draft,
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

  // ── Wallet picker bottom sheet ────────────────────────────────────────

  Future<void> _showWalletPicker(
    BuildContext context,
    EditableDraft draft, {
    bool isFrom = true,
  }) async {
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
                  final selected = isFrom
                      ? w.id == draft.walletId
                      : w.id == draft.toWalletId;
                  return ListTile(
                    leading: const Icon(AppIcons.wallet, size: AppSizes.iconMd),
                    title: Text(w.name),
                    selected: selected,
                    onTap: () {
                      setState(() {
                        if (isFrom) {
                          draft.walletId = w.id;
                        } else {
                          draft.toWalletId = w.id;
                        }
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

  // ── Create wallet from unmatched hint ─────────────────────────────────

  Future<void> _createWalletFromHint(EditableDraft draft) async {
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
