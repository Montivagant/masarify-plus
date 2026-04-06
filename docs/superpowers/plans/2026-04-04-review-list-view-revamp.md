# Review Transactions — List View Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Revamp the list view of the voice transaction review screen for better scannability, visual consistency, interaction polish, and premium aesthetics.

**Architecture:** Replace `DraftListItem` layout (currently `[Icon | Text | Amount+Checkbox stacked]`) with `[Checkbox | Icon | Text | Amount]` + left-edge accent bar + compact suggestion chips. Replace `Dismissible` with `flutter_slidable`. Add batch selection controls.

**Tech Stack:** Flutter, flutter_slidable (existing dep), flutter_animate (existing dep), Riverpod

**Spec:** `docs/superpowers/specs/2026-04-04-review-list-view-revamp-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/l10n/app_en.arb` | Modify | Add 2 new l10n keys |
| `lib/l10n/app_ar.arb` | Modify | Add 2 matching Arabic keys |
| `lib/features/voice_input/presentation/widgets/draft_list_item.dart` | Rewrite | New row layout, accent bar, leading checkbox, suggestion chip, flutter_slidable |
| `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` | Modify | Add batch selection row, simplify list builder (swipe logic moved to widget) |

---

### Task 1: Add L10n Keys

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

- [ ] **Step 1: Add keys to app_en.arb**

Add these entries (near the existing `voice_select_all` key around line 680):

```json
  "voice_deselect_all": "Deselect All",
  "voice_selected_count": "{selected} of {total} selected",
  "@voice_selected_count": {
    "placeholders": {
      "selected": { "type": "int" },
      "total": { "type": "int" }
    }
  },
```

- [ ] **Step 2: Add matching keys to app_ar.arb**

Add near the existing `voice_select_all` key:

```json
  "voice_deselect_all": "إلغاء تحديد الكل",
  "voice_selected_count": "{selected} من {total} محدد",
  "@voice_selected_count": {
    "placeholders": {
      "selected": { "type": "int" },
      "total": { "type": "int" }
    }
  },
```

- [ ] **Step 3: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: Completes without errors.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/l10n/`
Expected: No issues found.

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/
git commit -m "feat(l10n): add voice_deselect_all and voice_selected_count keys"
```

---

### Task 2: Rewrite DraftListItem Widget

**Files:**
- Rewrite: `lib/features/voice_input/presentation/widgets/draft_list_item.dart`

**Reference for Slidable pattern:** `lib/shared/widgets/cards/transaction_card.dart:97-130` — uses `BehindMotion()`, `ActionPane`, `SlidableAction`.

- [ ] **Step 1: Rewrite draft_list_item.dart with new layout**

Replace the entire file with:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Compact list row for the voice transaction review screen (list-view mode).
///
/// New layout: [AccentBar | Checkbox | CategoryIcon | Title+Subtitle | Amount]
/// With optional single suggestion chip below the main row.
class DraftListItem extends StatelessWidget {
  const DraftListItem({
    super.key,
    required this.id,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryName,
    required this.walletName,
    required this.amount,
    required this.type,
    required this.title,
    required this.isIncluded,
    required this.onToggle,
    required this.onEdit,
    this.onDecline,
    this.matchedGoalName,
    this.isSubscriptionLike = false,
    this.subscriptionAdded = false,
    this.unmatchedHint,
    this.onSubscriptionTap,
    this.onCreateWallet,
  });

  final int id;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? categoryName;
  final String? walletName;
  final int amount;
  final String type;
  final String title;
  final bool isIncluded;
  final String? matchedGoalName;
  final bool isSubscriptionLike;
  final bool subscriptionAdded;
  final String? unmatchedHint;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDecline;
  final VoidCallback? onSubscriptionTap;
  final VoidCallback? onCreateWallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final theme = context.appTheme;

    final typeColor = switch (type) {
      'income' || 'cash_deposit' => theme.incomeColor,
      'transfer' => theme.transferColor,
      _ => theme.expenseColor,
    };

    final prefix = switch (type) {
      'income' || 'cash_deposit' => '+',
      'expense' || 'cash_withdrawal' => '-',
      _ => '',
    };

    final formattedAmount = '$prefix${MoneyFormatter.formatAmount(amount)}';

    // ── Determine suggestion chip (max 1, priority order) ───────────
    final suggestionChip = _buildSuggestionChip(context, colors, textStyles, theme);

    final cardBody = Opacity(
      opacity: isIncluded ? 1.0 : AppSizes.opacityLight5,
      child: GlassCard(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
          vertical: AppSizes.xs,
        ),
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          child: Row(
            children: [
              // ── Left-edge accent bar ───────────────────────────
              Container(
                width: AppSizes.voiceBarWidth,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: const Radius.circular(AppSizes.borderRadiusMd),
                    bottomStart: const Radius.circular(AppSizes.borderRadiusMd),
                  ),
                ),
              ),

              // ── Card content ───────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Leading checkbox
                          SizedBox(
                            width: AppSizes.minTapTarget,
                            height: AppSizes.minTapTarget,
                            child: Checkbox(
                              value: isIncluded,
                              onChanged: (_) => onToggle(),
                            ),
                          ),

                          // Category icon
                          Container(
                            width: AppSizes.iconContainerMd,
                            height: AppSizes.iconContainerMd,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(
                                alpha: AppSizes.opacityLight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              categoryIcon,
                              size: AppSizes.iconSm,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),

                          // Title + subtitle
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: textStyles.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: AppSizes.xxs),
                                Text(
                                  '${categoryName ?? '\u2014'} \u2022 ${walletName ?? '\u2014'}',
                                  style: textStyles.bodySmall?.copyWith(
                                    color: colors.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),

                          // Amount (right-aligned)
                          Text(
                            formattedAmount,
                            style: textStyles.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),

                      // Suggestion chip (if any)
                      if (suggestionChip != null) suggestionChip,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Slidable if decline callback provided
    if (onDecline == null) return cardBody;

    return Slidable(
      key: ValueKey('draft_$id'),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            icon: AppIcons.edit,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (_) => onDecline?.call(),
            backgroundColor: theme.expenseColor,
            foregroundColor: colors.surface,
            icon: AppIcons.close,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
        ],
      ),
      child: cardBody,
    );
  }

  /// Builds the highest-priority suggestion chip, or null.
  /// Priority: wallet create > subscription > goal match.
  Widget? _buildSuggestionChip(
    BuildContext context,
    ColorScheme colors,
    TextTheme textStyles,
    dynamic theme,
  ) {
    // Priority 1: Unmatched wallet
    if (unmatchedHint != null) {
      return _chip(
        context: context,
        icon: AppIcons.add,
        label: context.l10n.voice_create_wallet_instead(unmatchedHint!),
        bgColor: colors.primary.withValues(alpha: AppSizes.opacityXLight),
        fgColor: colors.primary,
        onTap: onCreateWallet,
      );
    }

    // Priority 2: Subscription suggestion
    if (isSubscriptionLike && !subscriptionAdded) {
      return _chip(
        context: context,
        icon: AppIcons.recurring,
        label: context.l10n.voice_confirm_subscription_suggest,
        bgColor: colors.tertiaryContainer,
        fgColor: colors.onTertiaryContainer,
        onTap: onSubscriptionTap,
      );
    }

    // Priority 3: Goal match
    if (matchedGoalName != null) {
      return _chip(
        context: context,
        icon: AppIcons.goals,
        label: matchedGoalName!,
        bgColor: theme.incomeColor.withValues(alpha: AppSizes.opacityXLight),
        fgColor: theme.incomeColor,
        onTap: null, // informational — tap card to edit
      );
    }

    return null;
  }

  Widget _chip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    VoidCallback? onTap,
  }) {
    final textStyles = context.textStyles;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSizes.xs,
        start: AppSizes.minTapTarget, // align with text, past checkbox
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xxs,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconXxs2, color: fgColor),
              const SizedBox(width: AppSizes.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.labelSmall?.copyWith(color: fgColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `flutter analyze lib/features/voice_input/presentation/widgets/draft_list_item.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/voice_input/presentation/widgets/draft_list_item.dart
git commit -m "feat(voice): rewrite DraftListItem — accent bar, leading checkbox, suggestion chips, slidable"
```

---

### Task 3: Update voice_confirm_screen.dart — Batch Controls + List Builder

**Files:**
- Modify: `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart`

- [ ] **Step 1: Remove `onAccept` from list builder and simplify swipe callbacks**

In `_buildListView` (around line 710), the `DraftListItem` constructor call currently passes `onAccept`. The new `DraftListItem` no longer has `onAccept` — remove it.

Find the `DraftListItem(` constructor call in `_buildListView` and replace the entire item builder block. Replace the `_buildListView` method (lines 710-810) with:

```dart
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
              final cat = categories
                  .where((c) => c.id == draft.categoryId)
                  .firstOrNull;
              final wallet = wallets
                  .where((w) => w.id == draft.walletId)
                  .firstOrNull;

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
                matchedGoalName: draft.matchedGoalName,
                isSubscriptionLike: draft.isSubscriptionLike,
                subscriptionAdded: draft.subscriptionAdded,
                unmatchedHint: draft.unmatchedHint,
                onSubscriptionTap:
                    draft.isSubscriptionLike && draft.categoryId != null
                        ? () => _createSubscriptionFromDraft(draft)
                        : null,
                onCreateWallet: draft.unmatchedHint != null
                    ? () => _createWalletFromHint(draft)
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
```

- [ ] **Step 2: Add `_buildBatchControls` method**

Add this method right after `_buildListView`:

```dart
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
```

- [ ] **Step 3: Verify everything compiles**

Run: `flutter analyze lib/`
Expected: No issues found.

- [ ] **Step 4: Run tests**

Run: `flutter test`
Expected: All 202 tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
git commit -m "feat(voice): add batch selection controls and update list view builder"
```

---

### Task 4: Final Verification

- [ ] **Step 1: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: Completes without errors.

- [ ] **Step 2: Full analysis**

Run: `flutter analyze lib/`
Expected: No issues found.

- [ ] **Step 3: Full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Commit all remaining generated files**

```bash
git add lib/l10n/app_localizations*.dart
git commit -m "chore: regenerate l10n after review list view revamp"
```
