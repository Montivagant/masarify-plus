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
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/repositories/i_transaction_repository.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Rule #7: Voice-parsed transactions MUST pass review — never auto-save.
class VoiceConfirmScreen extends ConsumerStatefulWidget {
  const VoiceConfirmScreen({super.key, required this.drafts});

  final List<VoiceTransactionDraft> drafts;

  @override
  ConsumerState<VoiceConfirmScreen> createState() =>
      _VoiceConfirmScreenState();
}

class _VoiceConfirmScreenState extends ConsumerState<VoiceConfirmScreen> {
  late List<_EditableDraft> _editableDrafts;
  bool _saving = false;
  bool _defaultsApplied = false;

  @override
  void initState() {
    super.initState();
    _editableDrafts = widget.drafts
        .map((d) => _EditableDraft.from(d))
        .toList();
  }

  /// Apply category auto-match and default wallet once when data is available.
  void _applyDefaults(List<CategoryEntity> categories, int? defaultWalletId) {
    if (_defaultsApplied) return;
    _defaultsApplied = true;

    for (final draft in _editableDrafts) {
      if (draft.categoryId == null && draft.categoryHint != null) {
        // WS-4 fix: add type filter to iconName match.
        final match = categories
            .where((c) =>
                c.iconName == draft.categoryHint &&
                (c.type == draft.type || c.type == 'both'),)
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
                .where((c) =>
                    c.iconName == entry.value &&
                    (c.type == draft.type || c.type == 'both'),)
                .firstOrNull;
            if (kwMatch != null) {
              draft.categoryId = kwMatch.id;
              break;
            }
          }
        }
      }
      draft.walletId ??= defaultWalletId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final defaultWalletId = wallets.isNotEmpty ? wallets.first.id : null;

    // Apply auto-matching once when categories/wallets become available.
    if (categories.isNotEmpty && defaultWalletId != null && !_defaultsApplied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _applyDefaults(categories, defaultWalletId);
          setState(() {});
        }
      });
    }

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.voice_confirm_title),
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

                return _DraftCard(
                  draft: draft,
                  categoryName: cat?.displayName(context.languageCode),
                  categoryIcon: cat != null
                      ? CategoryIconMapper.fromName(cat.iconName)
                      : AppIcons.category,
                  categoryColor: cat != null
                      ? ColorUtils.fromHex(cat.colorHex)
                      : context.colors.outline,
                  onRemove: () {
                    setState(() => _editableDrafts.removeAt(index));
                  },
                  onAmountChanged: (piastres) {
                    draft.amountPiastres = piastres;
                  },
                  onTypeToggle: () {
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
                );
              },
            ),
      bottomNavigationBar: _editableDrafts.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenHPadding),
                child: FilledButton(
                  onPressed: _saving ? null : () => _confirmAll(context),
                  child: _saving
                      ? SizedBox(
                          width: AppSizes.spinnerSize,
                          height: AppSizes.spinnerSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.onPrimary,
                          ),
                        )
                      : Text(context.l10n.voice_confirm_all),
                ),
              ),
            )
          : null,
    );
  }

  /// Checks [text] against active goals' keywords.
  /// Returns the first matching goal name, or null.
  String? _matchGoalForDraft(String text) {
    final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];
    for (final goal in goals) {
      final List<String> kws;
      try {
        kws = (jsonDecode(goal.keywords) as List).cast<String>();
      } catch (_) {
        continue;
      }
      final matcher = GoalKeywordMatcher(keywords: kws);
      if (matcher.matches(text)) return goal.name;
    }
    return null;
  }

  Future<void> _confirmAll(BuildContext ctx) async {
    // R5-I7 fix: prevent double-tap race condition
    if (_saving) return;
    // Validate all drafts have amount, category, and wallet
    for (final draft in _editableDrafts) {
      if (draft.amountPiastres <= 0) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(ctx.l10n.error_amount_zero)),
        );
        return;
      }
      if (draft.categoryId == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(ctx.l10n.error_category_required)),
        );
        return;
      }
      if (draft.walletId == null) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(ctx.l10n.error_wallet_required)),
        );
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
      final txRepo = ref.read(transactionRepositoryProvider);

      // Batch all writes in a single DB transaction for atomicity.
      await txRepo.createBatch(
        _editableDrafts
            .map((draft) => CreateTransactionParams(
                  walletId: draft.walletId!,
                  categoryId: draft.categoryId!,
                  amount: draft.amountPiastres,
                  type: draft.type,
                  title: draft.rawText,
                  transactionDate: draft.transactionDate,
                  source: 'voice',
                  rawSourceText: draft.rawText,
                ),)
            .toList(),
      );

      if (!mounted) return;

      // Check goal keyword match across saved drafts.
      String? matchedGoalName;
      for (final draft in _editableDrafts) {
        matchedGoalName = _matchGoalForDraft(draft.rawText);
        if (matchedGoalName != null) break;
      }

      if (matchedGoalName != null) {
        messenger.showSnackBar(
          SnackBar(
            duration: AppDurations.snackbarLong,
            content: Text(l10n.goal_link_prompt(matchedGoalName)),
          ),
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(savedMsg)));
      }
      nav.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
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
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              width: AppSizes.dragHandleWidth,
              height: AppSizes.dragHandleHeight,
              decoration: BoxDecoration(
                color: ctx.colors.outlineVariant,
                borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md, 0, AppSizes.md, AppSizes.sm,
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
}

// ── Editable draft (mutable copy of VoiceTransactionDraft) ────────────────

class _EditableDraft {
  _EditableDraft({
    required this.rawText,
    required this.amountPiastres,
    this.categoryHint,
    required this.type,
    required this.transactionDate,
  });

  factory _EditableDraft.from(VoiceTransactionDraft d) => _EditableDraft(
        rawText: d.rawText,
        amountPiastres: d.amountPiastres ?? 0,
        categoryHint: d.categoryHint,
        type: d.type,
        transactionDate: d.transactionDate,
      );

  final String rawText;
  int amountPiastres;
  String? categoryHint;
  int? categoryId;
  int? walletId;
  String type;
  DateTime transactionDate;
}

// ── Draft card widget ─────────────────────────────────────────────────────

class _DraftCard extends StatelessWidget {
  const _DraftCard({
    required this.draft,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.onRemove,
    required this.onAmountChanged,
    required this.onTypeToggle,
    required this.onCategoryTap,
  });

  final _EditableDraft draft;
  final String? categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final VoidCallback onRemove;
  final ValueChanged<int> onAmountChanged;
  final VoidCallback onTypeToggle;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final typeColor = draft.type == 'income'
        ? context.appTheme.incomeColor
        : context.appTheme.expenseColor;

    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: raw text + remove ───────────────────────
            Row(
              children: [
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
                IconButton(
                  icon: const Icon(AppIcons.close, size: AppSizes.iconXs),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  tooltip: context.l10n.common_delete,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),

            // ── Type toggle + Category picker ──────────────────
            Row(
              children: [
                // Type chip
                GestureDetector(
                  onTap: onTypeToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: AppSizes.opacityLight2),
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusSm),
                    ),
                    child: Text(
                      draft.type == 'income'
                          ? context.l10n.transaction_type_income
                          : context.l10n.transaction_type_expense,
                      style: context.textStyles.bodySmall?.copyWith(
                            color: typeColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),

                // Category chip
                GestureDetector(
                  onTap: onCategoryTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: AppSizes.opacityLight2),
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
                          categoryName ??
                              context.l10n.transaction_category,
                          style: context.textStyles.bodySmall
                              ?.copyWith(
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

            // ── Tappable amount editor ───────────────────────────
            const SizedBox(height: AppSizes.sm),
            AmountInput(
              initialPiastres: draft.amountPiastres,
              onAmountChanged: onAmountChanged,
              autofocus: false,
              compact: true,
            ),
          ],
        ),
    );
  }
}
