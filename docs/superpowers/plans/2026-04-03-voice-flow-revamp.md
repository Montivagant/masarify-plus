# Voice Flow Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the voice input bottom sheet with a hold-to-record overlay, and replace the review screen with a swipe-card + list-view dual-mode experience.

**Architecture:** The overlay is a modal route (ModalBarrier + animated panel) triggered from the FAB. On Gemini success, it navigates to a new VoiceReviewScreen that supports two modes: a swipeable card stack (default) and a checkbox list view, toggleable via an app bar icon. All existing draft matching, save logic, and provider wiring are preserved — only the presentation layer changes.

**Tech Stack:** Flutter, Riverpod, flutter_animate, go_router, record package, Gemini API (existing).

**Spec:** `docs/superpowers/specs/2026-04-03-voice-flow-revamp-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `lib/features/voice_input/presentation/widgets/voice_input_sheet.dart` | **Rewrite** | Recording overlay (was bottom sheet) |
| `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` | **Rewrite** | Swipe card + list view review screen |
| `lib/features/voice_input/presentation/widgets/voice_input_button.dart` | **Modify** | Update `handleVoiceInput` to use new overlay |
| `lib/features/voice_input/presentation/widgets/swipe_card.dart` | **Create** | Single swipeable transaction card widget |
| `lib/features/voice_input/presentation/widgets/draft_list_item.dart` | **Create** | Compact list-view row for a draft |
| `lib/features/voice_input/presentation/widgets/draft_edit_sheet.dart` | **Create** | Edit bottom sheet for modifying a draft's fields |
| `lib/core/constants/app_sizes.dart` | **Modify** | Add swipe card + overlay dimension constants |
| `lib/core/constants/app_durations.dart` | **Modify** | Add swipe animation duration constants |

**Unchanged files (logic preserved, not touched):**
- `voice_wave_bars.dart`, `voice_transaction_parser.dart`, `voice_dictionary.dart`
- `gemini_audio_service.dart`, all providers, all repositories
- `app_router.dart` (route path unchanged, widget swap is transparent)
- `speed_dial_fab.dart`, `app_nav_bar.dart` (FAB trigger stays as tap → handleVoiceInput)

---

## Task 1: Add Dimension & Duration Constants

**Files:**
- Modify: `lib/core/constants/app_sizes.dart`
- Modify: `lib/core/constants/app_durations.dart`

- [ ] **Step 1: Add swipe card and overlay constants to app_sizes.dart**

Add after the `speedDialLabelGap` line (~line 201):

```dart
// ── Voice overlay ────────────────────────────────────────────────────
static const double voiceOverlayMinHeight = 0.65; // fraction of screen
static const double voiceOverlayMaxHeight = 1.0;
static const double voiceMicSize = 72.0;
static const double voiceMicIconSize = 32.0;

// ── Swipe card ──────────────────────────────────────────────────────
static const double swipeCardHPadding = 24.0;
static const double swipeCardMaxWidth = 340.0;
static const double swipeRotationAngle = 0.26; // ~15 degrees in radians
static const double swipeDragThreshold = 0.3; // fraction of screen width
static const double swipeStampOpacity = 0.7;
static const double cardStackOffset = 8.0; // vertical offset per ghost card
static const double cardStackScale = 0.95; // scale per ghost card
static const double draftListItemHeight = 80.0;
```

- [ ] **Step 2: Add animation durations to app_durations.dart**

Add after existing voice constants:

```dart
// ── Voice overlay & swipe ─────────────────────────────────────────
static const Duration overlayExpand = Duration(milliseconds: 350);
static const Duration overlayCollapse = Duration(milliseconds: 250);
static const Duration swipeOut = Duration(milliseconds: 300);
static const Duration swipeReturn = Duration(milliseconds: 200);
static const Duration cardSpringUp = Duration(milliseconds: 400);
static const Duration undoSnackbar = Duration(seconds: 3);
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/core/constants/`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/core/constants/app_sizes.dart lib/core/constants/app_durations.dart
git commit -m "feat: add swipe card and voice overlay dimension constants"
```

---

## Task 2: Create Draft Edit Sheet

**Files:**
- Create: `lib/features/voice_input/presentation/widgets/draft_edit_sheet.dart`

This sheet is shared by both swipe and list views — opened when tapping a card/row to edit amount, title, type, category, or wallet.

- [ ] **Step 1: Create draft_edit_sheet.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';

/// Bottom sheet for editing a single voice-parsed transaction draft.
///
/// Exposes callbacks for every mutable field. The parent (swipe view or
/// list view) owns the [_EditableDraft] state — this widget only fires
/// callbacks, never mutates data directly.
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

  /// Show this sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required DraftEditSheet sheet,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: AppSizes.sheetInitialSize,
        minChildSize: AppSizes.sheetMinSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, controller) => sheet,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final cs = context.colors;
    final theme = context.appTheme;

    final typeCats = categories
        .where((c) => c.type == type || c.type == 'both')
        .toList();
    final nonSystemWallets =
        wallets.where((w) => !w.isSystemWallet).toList();

    final currentCat =
        categories.where((c) => c.id == categoryId).firstOrNull;
    final currentWallet =
        wallets.where((w) => w.id == walletId).firstOrNull;

    final typeColor = switch (type) {
      'income' => theme.incomeColor,
      'cash_withdrawal' || 'cash_deposit' => theme.transferColor,
      _ => theme.expenseColor,
    };

    return Column(
      children: [
        const DragHandle(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Text(
            context.l10n.common_edit,
            style: context.textStyles.titleMedium,
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Amount
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: AmountInput(
            initialPiastres: amountPiastres,
            onAmountChanged: onAmountChanged,
            autofocus: false,
            compact: true,
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Title / Note
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
          ),
          child: TextField(
            controller: noteController,
            style: context.textStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: context.l10n.voice_edit_title_hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: AppSizes.md),

        // Type chips (only for non-cash types)
        if (!isCashType)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  selected: type == 'expense',
                  label: Text(context.l10n.transaction_type_expense),
                  avatar: Icon(AppIcons.expense, size: AppSizes.iconXs),
                  selectedColor:
                      theme.expenseColor.withValues(alpha: AppSizes.opacityLight2),
                  onSelected: (_) => onTypeChanged('expense'),
                  showCheckmark: false,
                ),
                const SizedBox(width: AppSizes.sm),
                ChoiceChip(
                  selected: type == 'income',
                  label: Text(context.l10n.transaction_type_income),
                  avatar: Icon(AppIcons.income, size: AppSizes.iconXs),
                  selectedColor:
                      theme.incomeColor.withValues(alpha: AppSizes.opacityLight2),
                  onSelected: (_) => onTypeChanged('income'),
                  showCheckmark: false,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSizes.md),

        // Category selector
        if (!isCashType)
          ListTile(
            leading: Icon(
              currentCat != null
                  ? CategoryIconMapper.fromName(currentCat.iconName)
                  : AppIcons.category,
              color: currentCat != null
                  ? ColorUtils.fromHex(currentCat.colorHex)
                  : cs.outline,
            ),
            title: Text(
              currentCat?.displayName(context.languageCode) ??
                  context.l10n.transaction_category,
            ),
            trailing: const Icon(AppIcons.chevronRight),
            onTap: () async {
              final picked = await _pickCategory(context, typeCats);
              if (picked != null) onCategoryChanged(picked);
            },
          ),

        // Wallet selector
        ListTile(
          leading: Icon(AppIcons.wallet, color: cs.primary),
          title: Text(
            currentWallet?.name ?? context.l10n.voice_select_wallet,
          ),
          trailing: const Icon(AppIcons.chevronRight),
          onTap: () async {
            final picked =
                await _pickWallet(context, nonSystemWallets);
            if (picked != null) onWalletChanged(picked);
          },
        ),

        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  Future<int?> _pickCategory(
    BuildContext context,
    List<dynamic> typeCats,
  ) async {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: AppSizes.sheetInitialSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                context.l10n.transaction_category_picker,
                style: ctx.textStyles.titleMedium,
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
                      color: color,
                    ),
                    title: Text(
                      cat.displayName(context.languageCode),
                    ),
                    selected: cat.id == categoryId,
                    onTap: () => ctx.pop(cat.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int?> _pickWallet(
    BuildContext context,
    List<dynamic> wallets,
  ) async {
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const DragHandle(),
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                context.l10n.voice_select_wallet,
                style: ctx.textStyles.titleMedium,
              ),
            ),
            ...wallets.map(
              (w) => ListTile(
                leading: Icon(AppIcons.wallet, color: ctx.colors.primary),
                title: Text(w.name),
                selected: w.id == walletId,
                onTap: () => ctx.pop(w.id),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/features/voice_input/presentation/widgets/draft_edit_sheet.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/voice_input/presentation/widgets/draft_edit_sheet.dart
git commit -m "feat: create DraftEditSheet for voice review editing"
```

---

## Task 3: Create Swipe Card Widget

**Files:**
- Create: `lib/features/voice_input/presentation/widgets/swipe_card.dart`

Standalone swipeable card with drag physics, rotation, stamp overlays, and tap targets for type/category/wallet.

- [ ] **Step 1: Create swipe_card.dart**

This is the core widget. It handles:
- Horizontal drag with rotation proportional to drag distance.
- Green "APPROVE" / Red "SKIP" stamp overlays that fade in.
- Tap targets for type badge, category, wallet, amount, title — all fire callbacks.
- Card content: type badge → icon + title → amount → transcript → metadata → banners.
- Card stack depth (2 ghost cards behind, scaled and offset).

The widget takes an `_EditableDraft` (from the existing model), resolved category/wallet info, and callbacks for approve/skip/edit actions. Full implementation with GestureDetector, Transform.rotate, animated stamp overlays.

Key constants used: `AppSizes.swipeRotationAngle`, `swipeDragThreshold`, `swipeStampOpacity`, `cardStackOffset`, `cardStackScale`.

Animation: On swipe past threshold, `AnimationController` drives card off-screen (300ms). On release before threshold, spring back (200ms). After exit animation, `onApprove` or `onSkip` callback fires.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/features/voice_input/presentation/widgets/swipe_card.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/voice_input/presentation/widgets/swipe_card.dart
git commit -m "feat: create SwipeCard widget with drag physics and stamp overlays"
```

---

## Task 4: Create Draft List Item Widget

**Files:**
- Create: `lib/features/voice_input/presentation/widgets/draft_list_item.dart`

Compact list row for the list-view mode.

- [ ] **Step 1: Create draft_list_item.dart**

Layout: `GlassCard` → Row:
- Left: category icon in 24dp colored circle.
- Middle (Expanded): title (bodyMedium semibold, maxLines 1, ellipsis) + subtitle "Category • Wallet" with optional goal/subscription/warning icons (bodySmall muted).
- Right: amount text in type color (bodyMedium bold) + Checkbox.
- onTap → fires `onEdit` callback (opens DraftEditSheet).
- Checkbox → fires `onToggle` callback.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/features/voice_input/presentation/widgets/draft_list_item.dart`
Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/voice_input/presentation/widgets/draft_list_item.dart
git commit -m "feat: create DraftListItem for list-view mode"
```

---

## Task 5: Rewrite VoiceConfirmScreen (Review Screen)

**Files:**
- Rewrite: `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart`

This is the biggest task. Preserves ALL existing logic (`_EditableDraft`, `_applyDefaults`, `_confirmAll`, `_createWalletFromHint`, `_createToWalletFromHint`, `_createSubscriptionFromDraft`, `_showCategoryPicker`, `_showWalletPicker`, `_CreateAccountTile`). Only the `build()` method and card widgets change.

- [ ] **Step 1: Rewrite voice_confirm_screen.dart**

Key structural changes:
1. Add `_isSwipeView = true` state toggle.
2. `build()` renders either `_buildSwipeView()` or `_buildListView()` based on toggle.
3. Swipe view: `Stack` with card stack (SwipeCard widgets), bottom action row.
4. List view: `ListView.builder` with DraftListItem widgets, bottom confirm button.
5. `_currentIndex` tracks which card is on top in swipe mode.
6. Swipe right → `_approveDraft(index)` sets `isIncluded = true`, advances index.
7. Swipe left → `_skipDraft(index)` sets `isIncluded = false`, advances index.
8. When `_currentIndex >= drafts.length` → auto-call `_confirmAll`.
9. "Approve All" → sets all included, calls `_confirmAll`.
10. Undo snackbar after each swipe (3s timer, reverses last action).

Preserved logic (copy from existing file, no changes):
- `_EditableDraft` class (all fields).
- `_applyDefaults()` method (category/wallet/goal matching).
- `_confirmAll()` method (save logic with partial success).
- `_createWalletFromHint()`, `_createToWalletFromHint()`.
- `_createSubscriptionFromDraft()`.
- `_isCashType()`, `_similarityScore()`.

Removed:
- Old `_DraftCard` widget (replaced by SwipeCard + DraftListItem).
- Old `_ChipBadge` widget (replaced by simpler chips inside SwipeCard).
- Old `_InfoBanner` widget (replaced by banners inside SwipeCard).

New widgets in the file:
- `_SwipeView` — stateful widget managing the card stack and animations.
- `_ListView` — stateless widget rendering DraftListItems.
- `_BottomActionBar` — the skip/approve-all/approve row for swipe mode.

App bar: back arrow, counter text ("2 of 4" in swipe / "4 transactions" in list), toggle icon button.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/features/voice_input/`
Expected: No issues found.

- [ ] **Step 3: Verify route still works**

Check that `app_router.dart:297-303` still compiles — `VoiceConfirmScreen(drafts: ...)` constructor is unchanged.

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
git commit -m "feat: rewrite VoiceConfirmScreen with swipe card + list view"
```

---

## Task 6: Rewrite Voice Input Overlay

**Files:**
- Rewrite: `lib/features/voice_input/presentation/widgets/voice_input_sheet.dart`
- Modify: `lib/features/voice_input/presentation/widgets/voice_input_button.dart`

Changes VoiceInputSheet from a `showModalBottomSheet` to an animated overlay panel. Keeps all recording/processing/Gemini logic. Changes the UI container and adds hold-to-record plus processing→review transition.

- [ ] **Step 1: Rewrite voice_input_sheet.dart**

Key changes:
1. `show()` → uses `showGeneralDialog` with custom `AnimatedBuilder` instead of `showModalBottomSheet`.
2. Overlay is a `Column` in a glassmorphic `Container` that animates height from 65% to 100%.
3. Recording state uses existing amplitude stream + VoiceWaveBars.
4. Processing state: VoiceWaveBars in shimmer + CircularProgressIndicator.
5. On Gemini success: navigate to `/voice/confirm` with drafts (same as before).
6. On error: show error message + retry/cancel in the overlay.
7. Hold-to-record: `GestureDetector` with `onLongPressStart` → start recording, `onLongPressEnd` → stop and process. Also keep tap-to-toggle as fallback for accessibility.

Preserved logic (copy from existing file):
- `_startRecording()`, `_stopAndProcess()` methods.
- Audio config (WAV 16kHz mono).
- Amplitude stream and normalization.
- `_cancelled` flag, `_isStopping` guard.
- Connectivity check before Gemini call.
- Error handling (timeout, socket, rate limit).
- Duration ticker (1s intervals).
- File size validation (min 32KB).

- [ ] **Step 2: Update voice_input_button.dart**

`handleVoiceInput()` currently calls `VoiceInputSheet.show(context)`. This still works — just the internal implementation of `show()` changes. No changes needed to `voice_input_button.dart` unless the `show()` signature changes.

Verify the import and call still compile.

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/features/voice_input/`
Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/voice_input/presentation/widgets/voice_input_sheet.dart
git add lib/features/voice_input/presentation/widgets/voice_input_button.dart
git commit -m "feat: rewrite VoiceInputSheet as animated overlay with hold-to-record"
```

---

## Task 7: Full Build & Install Verification

**Files:** None (verification only).

- [ ] **Step 1: Run full analyzer**

Run: `flutter analyze lib/`
Expected: No issues found.

- [ ] **Step 2: Build release APK**

```bash
flutter build apk --release \
  --dart-define=OPENROUTER_API_KEY=sk-or-v1-... \
  --dart-define=GOOGLE_AI_API_KEY=AIza...
```

Expected: Build succeeds.

- [ ] **Step 3: Install on device**

```bash
adb -s 192.168.1.54:39325 install build/app/outputs/flutter-apk/app-release.apk
```

Expected: Success.

- [ ] **Step 4: Manual test checklist**

1. Tap FAB → Voice → hold mic → speak → release → see processing → see swipe cards.
2. Swipe right on a card → card flies out with green stamp → next card appears.
3. Swipe left → card flies out with red stamp → next card appears.
4. Tap "Approve All" → all remaining confirmed at once.
5. Toggle to list view → see all drafts with checkboxes.
6. Uncheck one → "Confirm Selected (N)" updates count.
7. Tap a list row → edit sheet opens → change amount → close → row updates.
8. Tap type badge on swipe card → type toggles.
9. Tap category chip on swipe card → category picker opens.
10. Tap wallet chip → wallet picker opens.
11. Confirm → transactions appear on dashboard.
12. Test with Arabic voice input → RTL transcript displays correctly.

- [ ] **Step 5: Commit any fixes from testing**

```bash
git add -A
git commit -m "fix: address issues found during voice flow manual testing"
```
