import 'dart:convert';
import 'dart:developer' as dev;

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
import '../../../../core/utils/subscription_detector.dart';
import '../../../../core/utils/voice_transaction_parser.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/draft_edit_sheet.dart';
import '../widgets/draft_list_item.dart';
import '../widgets/swipe_card.dart';

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

  // ── Dual-mode state ──────────────────────────────────────────────────
  bool _isSwipeView = true;
  int _currentIndex = 0;

  // ── Swipe hint state ────────────────────────────────────────────────
  bool _showSwipeHint = false;

  @override
  void initState() {
    super.initState();
    _editableDrafts = widget.drafts.map((d) => _EditableDraft.from(d)).toList();
    _checkSwipeHint();
  }

  Future<void> _checkSwipeHint() async {
    final prefs = await ref.read(preferencesFutureProvider.future);
    if (!prefs.swipeHintShown && mounted) {
      setState(() => _showSwipeHint = true);
    }
  }

  void _dismissSwipeHint() {
    if (!_showSwipeHint) return;
    setState(() => _showSwipeHint = false);
    ref.read(preferencesFutureProvider.future).then((prefs) {
      prefs.setSwipeHintShown();
    });
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
      if (draft.categoryId == null && draft.type != 'transfer') {
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

      // Final fallback: assign "Other Expense" / "Other Income" so the user
      // doesn't get blocked by "please select a category" on confirm.
      // Transfers and cash types don't need a category (saved as transfers).
      // Match by iconName ('more_horiz') — not user-editable, unlike name.
      if (draft.categoryId == null &&
          draft.type != 'transfer' &&
          !_isCashType(draft.type)) {
        final other = categories
            .where(
              (c) =>
                  c.iconName == 'more_horiz' &&
                  (c.type == draft.type || c.type == 'both'),
            )
            .firstOrNull;
        if (other != null) draft.categoryId = other.id;
      }

      // Wallet hint matching: exact → contains → fuzzy → default.
      // Every draft ALWAYS gets a walletId — never null, never blocking.
      // Match against non-system wallets only — Cash is a payment method.
      if (draft.walletHint != null && draft.walletHint!.isNotEmpty) {
        final hintLower = draft.walletHint!.toLowerCase();
        // 1. Exact case-insensitive match
        final exactMatch = nonSystem
            .where((w) => w.name.toLowerCase() == hintLower)
            .firstOrNull;
        if (exactMatch != null) {
          draft.walletId = exactMatch.id;
        } else {
          // 2. Contains match — only auto-assign if exactly one match
          final containsMatches = nonSystem
              .where(
                (w) =>
                    w.name.toLowerCase().contains(hintLower) ||
                    hintLower.contains(w.name.toLowerCase()),
              )
              .toList();
          if (containsMatches.length == 1) {
            draft.walletId = containsMatches.first.id;
          } else {
            // 3. Fuzzy match (≥50% overlap) — auto-assign directly
            final hintChars = draft.walletHint!.toLowerCase();
            WalletEntity? closest;
            int bestScore = 0;
            for (final w in nonSystem) {
              final score = _similarityScore(hintChars, w.name.toLowerCase());
              final threshold =
                  (hintChars.length * 0.5).ceil().clamp(3, hintChars.length);
              if (score > bestScore && score >= threshold) {
                bestScore = score;
                closest = w;
              }
            }
            if (closest != null) {
              // 3b. Fuzzy match found — auto-assign directly (no suggestion)
              draft.walletId = closest.id;
            } else {
              // 4. No match in user accounts. Check if the user explicitly
              // said "cash" — if so, assign to the system Cash wallet.
              final systemWallet =
                  wallets.where((w) => w.isSystemWallet).firstOrNull;
              if (systemWallet != null &&
                  VoiceDictionary.cashWalletKeywordSet
                      .contains(hintLower.trim())) {
                draft.walletId = systemWallet.id;
              } else {
                // 5. No match at all — assign to Default account + flag hint
                draft.walletId = defaultAccountId;
                draft.unmatchedHint = draft.walletHint;
              }
            }
          }
        }
      }
      draft.walletId ??= defaultAccountId;

      // Transfer "To" wallet matching (D-15)
      if (_isCashType(draft.type) || draft.type == 'transfer') {
        final toHint = draft.toWalletHint;
        if (toHint != null && toHint.isNotEmpty) {
          final toHintLower = toHint.toLowerCase();
          // Match against non-system wallets only.
          final exactMatch = nonSystem
              .where((w) => w.name.toLowerCase() == toHintLower)
              .firstOrNull;
          if (exactMatch != null) {
            draft.toWalletId = exactMatch.id;
          } else {
            final containsMatches = nonSystem
                .where(
                  (w) =>
                      w.name.toLowerCase().contains(toHintLower) ||
                      toHintLower.contains(w.name.toLowerCase()),
                )
                .toList();
            if (containsMatches.length == 1) {
              draft.toWalletId = containsMatches.first.id;
            } else {
              // 3. Fuzzy match (≥50% overlap) for destination wallet
              final toChars = toHintLower;
              WalletEntity? closestTo;
              int bestToScore = 0;
              for (final w in nonSystem) {
                final score = _similarityScore(toChars, w.name.toLowerCase());
                final threshold =
                    (toChars.length * 0.5).ceil().clamp(3, toChars.length);
                if (score > bestToScore && score >= threshold) {
                  bestToScore = score;
                  closestTo = w;
                }
              }
              if (closestTo != null) {
                draft.toWalletId = closestTo.id;
              } else {
                // 4. No match — flag hint for "Create wallet" suggestion
                draft.unmatchedToHint = toHint;
              }
            }
          }
        }
      }

      // Goal inline suggestion: check rawText against active goal keywords.
      if (draft.matchedGoalName == null) {
        for (final goal in goals) {
          final List<String> kws;
          try {
            kws = (jsonDecode(goal.keywords) as List).cast<String>();
          } catch (e) {
            dev.log(
              'Bad goal keywords for ${goal.id}: $e',
              name: 'VoiceConfirm',
            );
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

      // Subscription detection: check if this looks like a recurring payment.
      final catName = categories
          .where((c) => c.id == draft.categoryId)
          .firstOrNull
          ?.displayName('en');
      draft.isSubscriptionLike = SubscriptionDetector.isSubscriptionLike(
        categoryName: catName,
        transactionText: draft.rawText,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

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
        actions: [
          IconButton(
            icon: Icon(
              _isSwipeView ? AppIcons.listView : AppIcons.cardStack,
            ),
            onPressed: () => setState(() => _isSwipeView = !_isSwipeView),
          ),
        ],
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
          : _isSwipeView
              ? _buildSwipeView(context)
              : _buildListView(context),
      bottomNavigationBar: _editableDrafts.isEmpty
          ? null
          : _isSwipeView
              ? _buildSwipeBottomBar(context)
              : _buildListBottomBar(context),
    );
  }

  // ── Swipe view ─────────────────────────────────────────────────────────

  Widget _buildSwipeView(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

    // When all cards have been reviewed, auto-confirm or handle all-skip.
    if (_currentIndex >= _editableDrafts.length) {
      final hasIncluded = _editableDrafts.any((d) => d.isIncluded);
      if (hasIncluded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _confirmAll(context);
        });
        return Center(
          child: SizedBox(
            width: AppSizes.spinnerSize,
            height: AppSizes.spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: AppSizes.spinnerStrokeWidth,
              color: context.colors.primary,
            ),
          ),
        );
      }
      // All drafts were skipped — show message and allow switching to list.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.warning,
              size: AppSizes.iconXl,
              color: context.colors.outline,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              context.l10n.voice_no_results,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.outline,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            OutlinedButton(
              onPressed: () => setState(() {
                _currentIndex = 0;
                for (final d in _editableDrafts) {
                  d.isIncluded = true;
                }
              }),
              child: Text(context.l10n.voice_select_all),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: AppSizes.md),
        // Counter text
        Text(
          '${_currentIndex + 1} / ${_editableDrafts.length}',
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSizes.md),
        // Card stack
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: _buildCardStack(context, categories, wallets),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),
      ],
    );
  }

  Widget _buildCardStack(
    BuildContext context,
    List<dynamic> categories,
    List<dynamic> wallets,
  ) {
    // Show up to 3 cards: current + 2 behind.
    final visibleCount = (_editableDrafts.length - _currentIndex).clamp(0, 3);
    if (visibleCount == 0) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Render back-to-front so the current card is on top.
        for (int i = visibleCount - 1; i >= 0; i--) ...[
          if (i > 0)
            // Behind cards: scaled down and offset.
            Transform.translate(
              offset: Offset(0, -AppSizes.cardStackOffset * i),
              child: Transform.scale(
                scale: _pow(AppSizes.cardStackScale, i),
                child: Opacity(
                  opacity: 1.0 - (i * 0.15),
                  child: IgnorePointer(
                    child: _buildSingleCard(
                      context,
                      _currentIndex + i,
                      categories,
                      wallets,
                      isFront: false,
                    ),
                  ),
                ),
              ),
            )
          else
            // Front card: fully interactive.
            _buildSingleCard(
              context,
              _currentIndex,
              categories,
              wallets,
              isFront: true,
            ),
        ],
        // ── Swipe hint overlay (first-time only) ─────────────────────
        if (_showSwipeHint && !context.reduceMotion)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragStart: (_) => _dismissSwipeHint(),
              onTap: _dismissSwipeHint,
              child: _SwipeHintOverlay(onComplete: _dismissSwipeHint),
            ),
          ),
      ],
    );
  }

  /// Exponentiation helper for scale calculations.
  static double _pow(double base, int exp) {
    double result = 1.0;
    for (int i = 0; i < exp; i++) {
      result *= base;
    }
    return result;
  }

  Widget _buildSingleCard(
    BuildContext context,
    int index,
    List<dynamic> categories,
    List<dynamic> wallets, {
    required bool isFront,
  }) {
    if (index >= _editableDrafts.length) return const SizedBox.shrink();
    final draft = _editableDrafts[index];
    final cat = categories.where((c) => c.id == draft.categoryId).firstOrNull;
    final wallet = wallets.where((w) => w.id == draft.walletId).firstOrNull;
    final isCash = _isCashType(draft.type);

    return SwipeCard(
      key: ValueKey('swipe_card_$index'),
      categoryIcon: cat != null
          ? CategoryIconMapper.fromName(cat.iconName)
          : AppIcons.category,
      categoryColor: cat != null
          ? ColorUtils.fromHex(cat.colorHex)
          : context.colors.outline,
      categoryName: cat?.displayName(context.languageCode),
      walletName: wallet?.name,
      amount: draft.amountPiastres,
      type: draft.type,
      title: draft.noteController.text.trim().isNotEmpty
          ? draft.noteController.text.trim()
          : draft.rawText,
      rawTranscript: draft.rawText,
      transactionDate: draft.transactionDate,
      matchedGoalName: draft.matchedGoalName,
      isSubscriptionLike: draft.isSubscriptionLike,
      subscriptionAdded: draft.subscriptionAdded,
      unmatchedHint: draft.unmatchedHint,
      unmatchedToHint: draft.unmatchedToHint,
      onApprove: () => _approveDraft(index),
      onSkip: () => _skipDraft(index),
      onTypeTap: isCash
          ? null
          : () => _openEditSheet(context, draft, initialField: 'type'),
      onCategoryTap: () =>
          _openEditSheet(context, draft, initialField: 'category'),
      onWalletTap: () => _openEditSheet(context, draft, initialField: 'wallet'),
      onAmountTap: () => _openEditSheet(context, draft, initialField: 'amount'),
      onTitleTap: () => _openEditSheet(context, draft, initialField: 'title'),
      onSubscriptionTap: draft.isSubscriptionLike && draft.categoryId != null
          ? () => _createSubscriptionFromDraft(draft)
          : null,
      onCreateWallet: draft.unmatchedHint != null
          ? () => _createWalletFromHint(draft)
          : null,
      onCreateToWallet: draft.unmatchedToHint != null
          ? () => _createToWalletFromHint(draft)
          : null,
    );
  }

  Widget _buildSwipeBottomBar(BuildContext context) {
    if (_currentIndex >= _editableDrafts.length) return const SizedBox.shrink();

    final theme = context.appTheme;
    final cs = context.colors;
    final remainingCount = _editableDrafts.length - _currentIndex;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenHPadding),
        child: Row(
          children: [
            // Skip button (left)
            SizedBox(
              width: AppSizes.iconContainerLg,
              height: AppSizes.iconContainerLg,
              child: OutlinedButton(
                onPressed: _saving ? null : () => _skipDraft(_currentIndex),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: theme.expenseColor),
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  AppIcons.close,
                  color: theme.expenseColor,
                  size: AppSizes.iconMd,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Approve All (center)
            Expanded(
              child: FilledButton(
                onPressed: _saving
                    ? null
                    : () {
                        setState(() {
                          for (final d in _editableDrafts) {
                            d.isIncluded = true;
                          }
                        });
                        _confirmAll(context);
                      },
                child: _saving
                    ? SizedBox(
                        width: AppSizes.spinnerSize,
                        height: AppSizes.spinnerSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppSizes.spinnerStrokeWidth,
                          color: cs.onPrimary,
                        ),
                      )
                    : Text(
                        '${context.l10n.voice_confirm_accept_all} ($remainingCount)',
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Approve button (right)
            SizedBox(
              width: AppSizes.iconContainerLg,
              height: AppSizes.iconContainerLg,
              child: OutlinedButton(
                onPressed: _saving ? null : () => _approveDraft(_currentIndex),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: theme.incomeColor),
                  shape: const CircleBorder(),
                ),
                child: Icon(
                  AppIcons.check,
                  color: theme.incomeColor,
                  size: AppSizes.iconMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Swipe actions ──────────────────────────────────────────────────────

  void _approveDraft(int index) {
    if (index >= _editableDrafts.length) return;
    _dismissSwipeHint();
    final previousState = _editableDrafts[index].isIncluded;
    final isLast = index == _editableDrafts.length - 1;
    setState(() {
      _editableDrafts[index].isIncluded = true;
      _currentIndex = index + 1;
    });
    // No undo on last card — auto-confirm fires before undo can take effect.
    if (!isLast) {
      SnackHelper.showInfo(
        context,
        context.l10n.sms_review_approve,
        action: SnackBarAction(
          label: context.l10n.common_undo,
          onPressed: () {
            setState(() {
              _currentIndex = index;
              _editableDrafts[index].isIncluded = previousState;
            });
          },
        ),
      );
    }
  }

  void _skipDraft(int index) {
    if (index >= _editableDrafts.length) return;
    _dismissSwipeHint();
    final previousState = _editableDrafts[index].isIncluded;
    final isLast = index == _editableDrafts.length - 1;
    setState(() {
      _editableDrafts[index].isIncluded = false;
      _currentIndex = index + 1;
    });
    if (!isLast) {
      SnackHelper.showInfo(
        context,
        context.l10n.sms_review_skip,
        action: SnackBarAction(
          label: context.l10n.common_undo,
          onPressed: () {
            setState(() {
              _currentIndex = index;
              _editableDrafts[index].isIncluded = previousState;
            });
          },
        ),
      );
    }
  }

  // ── Edit sheet (shared by both views) ──────────────────────────────────

  Future<void> _openEditSheet(
    BuildContext context,
    _EditableDraft draft, {
    String? initialField,
  }) async {
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];

    await DraftEditSheet.show(
      context,
      amountPiastres: draft.amountPiastres,
      type: draft.type,
      categoryId: draft.categoryId,
      walletId: draft.walletId,
      noteController: draft.noteController,
      isCashType: _isCashType(draft.type),
      onAmountChanged: (piastres) {
        setState(() => draft.amountPiastres = piastres);
      },
      onTypeChanged: (newType) {
        setState(() {
          draft.type = newType;
          // Clear category if it doesn't match the new type
          if (draft.categoryId != null) {
            final cat =
                categories.where((c) => c.id == draft.categoryId).firstOrNull;
            if (cat != null && cat.type != draft.type && cat.type != 'both') {
              draft.categoryId = null;
            }
          }
        });
      },
      onCategoryChanged: (catId) {
        setState(() => draft.categoryId = catId);
      },
      onWalletChanged: (walletId) {
        setState(() => draft.walletId = walletId);
      },
    );
    // Rebuild after sheet closes to reflect changes.
    if (mounted) setState(() {});
  }

  // ── List view ──────────────────────────────────────────────────────────

  Widget _buildListView(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

    return Column(
      children: [
        // ── Batch selection controls ──────────────────────────────
        _buildBatchControls(context),

        // ── Transaction list ─────────────────────────────────────
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSizes.xs,
              bottom: AppSizes.bottomScrollPadding,
            ),
            itemCount: _editableDrafts.length,
            itemBuilder: (context, index) {
              final draft = _editableDrafts[index];
              final cat =
                  categories.where((c) => c.id == draft.categoryId).firstOrNull;
              final wallet =
                  wallets.where((w) => w.id == draft.walletId).firstOrNull;

              final item = DraftListItem(
                id: index,
                categoryIcon: cat != null
                    ? CategoryIconMapper.fromName(cat.iconName)
                    : AppIcons.category,
                categoryColor: cat != null
                    ? ColorUtils.fromHex(cat.colorHex)
                    : context.colors.outline,
                categoryName: cat?.displayName(context.languageCode),
                walletName: wallet?.name,
                amount: draft.amountPiastres,
                type: draft.type,
                title: draft.noteController.text.trim().isNotEmpty
                    ? draft.noteController.text.trim()
                    : draft.rawText,
                isIncluded: draft.isIncluded,
                rawTranscript: draft.rawText,
                transactionDate: draft.transactionDate,
                matchedGoalName: draft.matchedGoalName,
                isSubscriptionLike: draft.isSubscriptionLike,
                subscriptionAdded: draft.subscriptionAdded,
                unmatchedHint: draft.unmatchedHint,
                unmatchedToHint: draft.unmatchedToHint,
                onSubscriptionTap:
                    draft.isSubscriptionLike && draft.categoryId != null
                        ? () => _createSubscriptionFromDraft(draft)
                        : null,
                onCreateWallet: draft.unmatchedHint != null
                    ? () => _createWalletFromHint(draft)
                    : null,
                onCreateToWallet: draft.unmatchedToHint != null
                    ? () => _createToWalletFromHint(draft)
                    : null,
                onToggle: () {
                  setState(() => draft.isIncluded = !draft.isIncluded);
                },
                onEdit: () => _openEditSheet(context, draft),
                onDecline: () {
                  final removedDraft = draft;
                  final removedIndex = index;
                  setState(() {
                    removedDraft.isIncluded = false;
                    _editableDrafts.removeAt(removedIndex);
                  });
                  SnackHelper.showInfo(
                    context,
                    context.l10n.sms_review_skip,
                    action: SnackBarAction(
                      label: context.l10n.common_undo,
                      onPressed: () {
                        setState(() {
                          removedDraft.isIncluded = true;
                          _editableDrafts.insert(
                            removedIndex.clamp(0, _editableDrafts.length),
                            removedDraft,
                          );
                        });
                      },
                    ),
                  );
                },
              );

              if (context.reduceMotion) return item;
              return item
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
        ),
      ],
    );
  }

  Widget _buildBatchControls(BuildContext context) {
    final allSelected = _editableDrafts.every((d) => d.isIncluded);
    final selectedCount = _editableDrafts.where((d) => d.isIncluded).length;
    final totalCount = _editableDrafts.length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                final newValue = !allSelected;
                for (final d in _editableDrafts) {
                  d.isIncluded = newValue;
                }
              });
            },
            child: Text(
              allSelected
                  ? context.l10n.voice_deselect_all
                  : context.l10n.voice_select_all,
            ),
          ),
          Text(
            context.l10n.voice_selected_count(selectedCount, totalCount),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListBottomBar(BuildContext context) {
    final includedCount = _editableDrafts.where((d) => d.isIncluded).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.screenHPadding),
        child: FilledButton(
          onPressed:
              _saving || includedCount == 0 ? null : () => _confirmAll(context),
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
  }

  // ── Utility methods ────────────────────────────────────────────────────

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

  // ── Confirm all ────────────────────────────────────────────────────────

  Future<void> _confirmAll(BuildContext ctx) async {
    // R5-I7 fix: prevent double-tap race condition
    if (_saving) return;

    // Only save included drafts
    final included = _editableDrafts.where((d) => d.isIncluded).toList();
    if (included.isEmpty) return;

    // Separate drafts by type: cash transfers, account-to-account transfers, regular transactions.
    final cashDrafts = included.where((d) => _isCashType(d.type)).toList();
    final transferDrafts = included.where((d) => d.type == 'transfer').toList();
    final txDrafts = included
        .where((d) => !_isCashType(d.type) && d.type != 'transfer')
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
      // Cash types and transfers don't need a category.
      if (draft.categoryId == null &&
          !_isCashType(draft.type) &&
          draft.type != 'transfer') {
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
      // Transfers require a destination wallet.
      if (draft.type == 'transfer' && draft.toWalletId == null) {
        SnackHelper.showError(ctx, '$prefix${ctx.l10n.error_wallet_required}');
        return;
      }
      // M-8 fix: reject same-wallet transfers
      if (draft.type == 'transfer' && draft.walletId == draft.toWalletId) {
        SnackHelper.showError(
          ctx,
          '$prefix${ctx.l10n.chat_action_transfer_same_wallet}',
        );
        return;
      }
    }

    setState(() => _saving = true);
    HapticFeedback.heavyImpact();

    final nav = GoRouter.of(ctx);
    final l10n = ctx.l10n;
    final savedMsg = l10n.transaction_saved;
    final errorMsg = l10n.common_error_generic;

    // M-10 fix: per-draft error handling with partial success reporting.
    int totalSuccess = 0;
    int totalFail = 0;

    // Save cash drafts as transfers (use already-loaded walletsProvider
    // instead of systemWalletProvider to avoid stream race condition).
    if (cashDrafts.isNotEmpty) {
      final allWallets = ref.read(walletsProvider).valueOrNull ?? [];
      final cashWallet = allWallets.where((w) => w.isSystemWallet).firstOrNull;
      if (cashWallet == null) {
        // Cash wallet missing — count all cash drafts as failed but don't abort.
        totalFail += cashDrafts.length;
      } else {
        final transferRepo = ref.read(transferRepositoryProvider);
        for (final draft in cashDrafts) {
          try {
            final bankWalletId = draft.walletId!;
            if (draft.type == 'cash_withdrawal') {
              await transferRepo.create(
                fromWalletId: bankWalletId,
                toWalletId: cashWallet.id,
                amount: draft.amountPiastres,
                note: draft.noteController.text.trim().isNotEmpty
                    ? draft.noteController.text.trim()
                    : draft.note,
                transferDate: draft.transactionDate,
              );
            } else {
              // cash_deposit
              await transferRepo.create(
                fromWalletId: cashWallet.id,
                toWalletId: bankWalletId,
                amount: draft.amountPiastres,
                note: draft.noteController.text.trim().isNotEmpty
                    ? draft.noteController.text.trim()
                    : draft.note,
                transferDate: draft.transactionDate,
              );
            }
            totalSuccess++;
          } catch (_) {
            totalFail++;
          }
        }
      }
    }

    // Save account-to-account transfers via transferRepo.
    if (transferDrafts.isNotEmpty) {
      final transferRepo = ref.read(transferRepositoryProvider);
      for (final draft in transferDrafts) {
        try {
          await transferRepo.create(
            fromWalletId: draft.walletId!,
            toWalletId: draft.toWalletId!,
            amount: draft.amountPiastres,
            note: draft.note,
            transferDate: draft.transactionDate,
          );
          totalSuccess++;
        } catch (_) {
          totalFail++;
        }
      }
    }

    // Save regular transaction drafts individually (expense/income only).
    if (txDrafts.isNotEmpty) {
      final txRepo = ref.read(transactionRepositoryProvider);
      final learningService = ref.read(categorizationLearningServiceProvider);
      for (final draft in txDrafts) {
        try {
          await txRepo.create(
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
          );
          totalSuccess++;
          // H-1: Wire category learning for successfully saved voice transactions.
          if (draft.categoryId != null) {
            final title = draft.noteController.text.trim().isNotEmpty
                ? draft.noteController.text.trim()
                : draft.rawText;
            learningService.recordMapping(title, draft.categoryId!);
          }
        } catch (_) {
          totalFail++;
        }
      }
    }

    if (!mounted) return;

    // Report result based on success/failure counts.
    if (totalSuccess == 0 && totalFail > 0) {
      // All failed — show error, don't pop.
      setState(() => _saving = false);
      SnackHelper.showError(context, errorMsg);
      return;
    }

    if (totalFail > 0) {
      // Partial success — inform user.
      SnackHelper.showInfo(
        context,
        l10n.voice_saved_partial(totalSuccess, totalSuccess + totalFail),
      );
    } else {
      // All succeeded — check for goal match.
      final matchedGoalName = txDrafts.map((d) => d.matchedGoalName).firstWhere(
            (n) => n != null,
            orElse: () => null,
          );
      if (matchedGoalName != null) {
        SnackHelper.showInfo(
          context,
          l10n.goal_link_prompt(matchedGoalName),
          duration: AppDurations.snackbarLong,
        );
      } else {
        SnackHelper.showSuccess(context, savedMsg);
      }
    }
    nav.pop();
  }

  // ── Wallet/subscription creation helpers ───────────────────────────────

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

  Future<void> _createToWalletFromHint(_EditableDraft draft) async {
    final duplicateMsg = context.l10n.wallet_name_duplicate;
    final genericMsg = context.l10n.common_error_generic;
    final hintName = draft.unmatchedToHint!;
    try {
      final newId = await ref.read(walletRepositoryProvider).create(
            name: hintName,
            type: 'bank',
            initialBalance: 0,
          );
      if (mounted) {
        setState(() {
          for (final d in _editableDrafts) {
            if (d.unmatchedToHint == hintName) {
              d.toWalletId = newId;
              d.unmatchedToHint = null;
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

  /// One-tap inline subscription creation — mirrors _createWalletFromHint
  /// pattern: no navigation, instant feedback.
  Future<void> _createSubscriptionFromDraft(_EditableDraft draft) async {
    try {
      final title = draft.noteController.text.trim().isNotEmpty
          ? draft.noteController.text.trim()
          : draft.rawText;
      final now = DateTime.now();
      await ref.read(recurringRuleRepositoryProvider).create(
            walletId: draft.walletId!,
            categoryId: draft.categoryId!,
            amount: draft.amountPiastres,
            type: draft.type,
            title: title,
            frequency: 'monthly',
            startDate: now,
            nextDueDate: now.add(AppDurations.subscriptionDefaultCycle),
          );
      if (mounted) {
        HapticFeedback.selectionClick();
        setState(() {
          draft.isSubscriptionLike = false;
          draft.subscriptionAdded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    }
  }
}

// ── Editable draft (mutable copy of VoiceTransactionDraft) ────────────────

class _EditableDraft {
  _EditableDraft({
    required this.rawText,
    required this.amountPiastres,
    this.aiTitle,
    this.categoryHint,
    this.walletHint,
    this.toWalletHint,
    this.note,
    required this.type,
    required this.transactionDate,
  }) : noteController = TextEditingController(text: aiTitle ?? note ?? rawText);

  factory _EditableDraft.from(VoiceTransactionDraft d) => _EditableDraft(
        rawText: d.rawText,
        amountPiastres: d.amountPiastres ?? 0,
        aiTitle: d.title,
        categoryHint: d.categoryHint,
        walletHint: d.walletHint,
        toWalletHint: d.toWalletHint,
        note: d.note,
        type: d.type,
        transactionDate: d.transactionDate,
      );

  final String rawText;
  final String? aiTitle;
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

  /// Set when wallet hint had no match — transaction defaulted to Default account.
  /// Enables inline "Create '{hint}' instead?" option on the draft card.
  String? unmatchedHint;

  /// Set when TO wallet hint had no match (transfer-only, D-15).
  String? unmatchedToHint;

  /// Whether this draft looks like a recurring subscription/bill.
  bool isSubscriptionLike = false;

  /// True after user tapped "Add to Subscriptions" and it succeeded.
  bool subscriptionAdded = false;

  /// Editable title/note for refining the transaction description.
  final TextEditingController noteController;
}

// ── Swipe hint overlay (first-time education) ─────────────────────────────

class _SwipeHintOverlay extends StatefulWidget {
  const _SwipeHintOverlay({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_SwipeHintOverlay> createState() => _SwipeHintOverlayState();
}

class _SwipeHintOverlayState extends State<_SwipeHintOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Phase timings (normalised 0→1 over ~3s total):
  // 0.00–0.20 : slide right + "approve" fade in
  // 0.20–0.37 : hold right
  // 0.37–0.57 : slide left + "skip" fade in
  // 0.57–0.73 : hold left
  // 0.73–1.00 : fade out everything

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.swipeHintTotal,
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final textStyles = context.textStyles;
    final cs = context.colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        // ── Phase calculations ───────────────────────────────────
        // Slide offset: positive = right, negative = left.
        double slideOffset;
        double approveOpacity;
        double skipOpacity;
        double globalOpacity;

        if (t < 0.20) {
          // Slide right
          slideOffset = (t / 0.20) * 60;
          approveOpacity = (t / 0.20).clamp(0, 1);
          skipOpacity = 0;
          globalOpacity = 1;
        } else if (t < 0.37) {
          // Hold right
          slideOffset = 60;
          approveOpacity = 1;
          skipOpacity = 0;
          globalOpacity = 1;
        } else if (t < 0.57) {
          // Slide left (from right to left)
          final phase = (t - 0.37) / 0.20;
          slideOffset = 60 - (phase * 120); // 60 → -60
          approveOpacity = 1.0 - phase;
          skipOpacity = phase.clamp(0, 1);
          globalOpacity = 1;
        } else if (t < 0.73) {
          // Hold left
          slideOffset = -60;
          approveOpacity = 0;
          skipOpacity = 1;
          globalOpacity = 1;
        } else {
          // Fade out
          final phase = (t - 0.73) / 0.27;
          slideOffset = -60;
          approveOpacity = 0;
          skipOpacity = 1.0 - phase;
          globalOpacity = 1.0 - phase;
        }

        if (globalOpacity <= 0) return const SizedBox.shrink();

        return Opacity(
          opacity: globalOpacity.clamp(0, 1),
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: cs.scrim.withValues(alpha: AppSizes.opacityLight3),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hand icon
                  Transform.translate(
                    offset: Offset(slideOffset, 0),
                    child: Icon(
                      AppIcons.handPointing,
                      size: AppSizes.iconXl,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  // Labels
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(
                        opacity: approveOpacity.clamp(0, 1),
                        child: Text(
                          context.l10n.hint_swipe_right,
                          style: textStyles.bodyMedium?.copyWith(
                            color: theme.incomeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: skipOpacity.clamp(0, 1),
                        child: Text(
                          context.l10n.hint_swipe_left,
                          style: textStyles.bodyMedium?.copyWith(
                            color: theme.expenseColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
