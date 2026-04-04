# Voice Flow Revamp — Design Spec

**Date:** 2026-04-03
**Scope:** Recording overlay + Swipe/List review screen

---

## 1. Flow Overview

```
FAB long-press → Recording Overlay (70% screen)
  → Release → Processing state (same overlay)
  → Gemini responds → Overlay expands to full-screen Review
  → Swipe Card View (default) ↔ List View (toggle)
  → Confirm → Pop back to dashboard
```

## 2. Recording Overlay

### Trigger
- **Long-press FAB** starts recording. Overlay animates up from FAB position.
- **Release finger** stops recording, enters processing state.
- **Drag away from mic area** cancels — overlay collapses, no action.

### Visual Design
- Glassmorphic panel covering bottom ~70% of screen with scrim above.
- Top: DragHandle + close (X) button.
- Center: Pulsing circular mic button (72dp). Glows primary color while recording.
- Below mic: VoiceWaveBars (existing widget, 24 bars, amplitude-reactive).
- Below waves: MM:SS duration counter in a small glass badge.
- Status text below counter: "Listening..." / "Processing..." / error messages.

### States
| State | Mic Button | Waves | Status Text | Action Area |
|-------|-----------|-------|-------------|-------------|
| Recording | Pulsing primary glow | Amplitude-reactive | "Listening..." | Duration badge |
| Processing | Static, muted | Shimmer sweep | "Analyzing..." | CircularProgressIndicator |
| Error | Red tint | Flat/muted | Error message | "Retry" + "Cancel" buttons |

### Audio Config (unchanged)
- WAV 16kHz mono, autoGain, echoCancel, noiseSuppress.
- Max 60s, min ~1s (32KB).
- Sends to Gemini via existing `GeminiAudioService`.

### Processing → Review Transition
- On success: overlay animates to full-screen (height 70% → 100%, scrim fades).
- Content crossfades from mic/waves to swipe card stack.
- On error: stays in overlay, shows error + retry.
- On empty result: shows "No transactions detected" + close button.

## 3. Review Screen — Swipe Card View (Default)

### Layout
- **Top bar:** Back arrow (left), "2 of 4" counter (center), list-view toggle icon (right).
- **Center:** Card stack (~60% height). Front card + 2 ghost cards behind (scaled, offset).
- **Bottom:** Skip circle (red) | "Approve All (N)" pill button (mint) | Approve circle (green).

### Card Content (front card)
```
┌──────────────────────────────────┐
│ ● Expense                        │  ← type badge (tappable → toggles type)
│                                  │
│ 🛒  Carrefour City Stars         │  ← category icon + enriched title
│     EGP 200.00                   │  ← amount in type color
│     صرفت 200 جنيه في كارفور      │  ← raw transcript, muted italic
│                                  │
│ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ │  ← subtle divider
│ 💳 CIB Bank        📅 Today      │  ← wallet + date metadata
│                                  │
│ 🎯 Linked to: Emergency Fund     │  ← conditional goal banner
│ 🔄 Looks recurring — tap to add  │  ← conditional subscription banner
│ ⚠️ Create 'بنك مصر'?             │  ← conditional unmatched wallet hint
└──────────────────────────────────┘
```

### Card Interactions
| Gesture/Tap | Action |
|-------------|--------|
| Swipe right | Approve → card flies right with green stamp, next card |
| Swipe left | Skip → card flies left with red stamp, next card |
| Tap type badge | Toggle expense ↔ income (locked for cash/transfer types) |
| Tap category chip | Open category picker bottom sheet |
| Tap wallet chip | Open wallet picker bottom sheet |
| Tap amount | Open edit sheet with AmountInput |
| Tap title area | Open edit sheet with title TextField |
| Tap goal banner | No action (informational) |
| Tap subscription banner | Create recurring rule inline, banner updates to "Added ✓" |
| Tap unmatched wallet hint | Create wallet inline, hint disappears, wallet updates |
| Tap "Approve All" | Confirm ALL remaining cards at once |
| Tap skip circle (bottom) | Same as swipe left |
| Tap approve circle (bottom) | Same as swipe right |

### Swipe Animation
- Card rotates ±15° as user drags horizontally.
- Stamp overlay (APPROVE green / SKIP red) fades in proportional to drag distance.
- On release past threshold (30% screen width): card animates out, next card springs up.
- On release before threshold: card springs back to center.

### Edit Bottom Sheet (opened by tapping card fields)
- DragHandle + title "Edit Transaction".
- AmountInput (compact mode).
- Title/note TextField.
- Type chips row (Expense/Income/Withdraw/Deposit) — same Wrap layout as add_transaction_screen.
- Category dropdown trigger.
- Wallet dropdown trigger.
- "Done" button closes sheet, card updates live.

## 4. Review Screen — List View

### Layout
- **Top bar:** Back arrow (left), "4 transactions" subtitle (center), card-view toggle icon (right).
- **Body:** Scrollable list of compact glass cards (~80dp each).
- **Bottom:** "Confirm Selected (N)" full-width filled button.

### List Item Layout
```
┌─────────────────────────────────────────┐
│ [icon]  Title              Amount   [✓] │
│         Subtitle • Wallet               │
└─────────────────────────────────────────┘
```
- Left: Category icon in 24dp colored circle.
- Middle: title (bodyMedium semibold) + "Category • Wallet" (bodySmall muted).
- Right: Amount in type color + checkbox (checked by default).
- Tap row → opens same edit bottom sheet as swipe view.
- Long-press row → unchecks (deselects).

### Conditional indicators on list items
- Goal match: small 🎯 icon after subtitle text.
- Subscription: small 🔄 icon after subtitle text.
- Unmatched wallet: amber ⚠️ icon after wallet name.

## 5. Data Flow (preserved from current implementation)

### Draft Model (_EditableDraft) — unchanged
All fields preserved: rawText, amountPiastres, categoryHint, walletHint, toWalletHint, note, categoryId, walletId, toWalletId, goalId, matchedGoalName, type, transactionDate, isIncluded, unmatchedHint, unmatchedToHint, isSubscriptionLike, subscriptionAdded, noteController.

### Auto-matching (_applyDefaults) — unchanged
- Category: iconName match → keyword fallback → "Other" fallback.
- Wallet: exact → contains → fuzzy → cash keyword → default account.
- Transfer TO wallet: exact → contains → flag hint.
- Goal: keyword matcher against active goals.
- Subscription: SubscriptionDetector.

### Save Logic (_confirmAll) — unchanged
- Separates into cashDrafts, transferDrafts, txDrafts.
- Validates per-draft (amount > 0, category required for non-cash/transfer, wallet required).
- Saves via respective repositories.
- Records category learning.
- Reports partial success/failure.

### Swipe-specific logic (NEW)
- Swipe right = set `isIncluded = true`, move to next card.
- Swipe left = set `isIncluded = false`, move to next card.
- When all cards swiped: auto-trigger `_confirmAll` for included drafts.
- "Approve All" = set all `isIncluded = true`, trigger `_confirmAll`.
- Undo: after swiping, brief undo snackbar (2s) to reverse last swipe.

## 6. File Changes

| File | Action |
|------|--------|
| `voice_input_sheet.dart` | **Rewrite** — becomes recording overlay with hold-to-record + processing state + transition to review |
| `voice_confirm_screen.dart` | **Rewrite** — swipe card stack + list view toggle, edit sheet, preserved logic |
| `voice_input_button.dart` | **Modify** — change from tap to long-press trigger on FAB |
| `speed_dial_fab.dart` | **Modify** — add long-press gesture for voice, keep tap for expand |
| `app_nav_bar.dart` | **Modify** — wire long-press from FAB to voice handler |
| `app_sizes.dart` | **Add** — swipe card dimensions, overlay sizes |
| `app_durations.dart` | **Add** — swipe animation durations |

## 7. What's NOT Changing
- GeminiAudioService, VoiceTransactionParser, VoiceTransactionDraft.
- All repository/DAO/provider wiring.
- Audio recording config (WAV 16kHz).
- Category/wallet/goal matching logic.
- L10n keys (reuse existing, add minimal new ones).
- VoiceWaveBars widget (reused in overlay).
