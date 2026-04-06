# Dashboard UX Revamp — Design Spec

**Date:** 2026-04-04
**Scope:** 6 UI/UX changes to the Home screen and Voice Input flow
**Status:** Approved

---

## 1. Net Info Popover

### Current state
`month_summary_inline.dart:87-118` wraps the Net section in a `Tooltip` widget. The info icon (`AppIcons.infoFilled`) exists but the tooltip requires long-press — low discoverability.

### Change
Replace the `Tooltip` wrapper with a tap-triggered inline popover using a `PopupMenuButton` or `OverlayEntry` anchored to the info icon.

### Behavior
- **Tap** the "i" icon → a small speech-bubble popover appears anchored below/above the icon
- **Content:** `context.l10n.home_net_tooltip` ("Income minus expenses this month, transfers excluded")
- **Dismiss:** Tap anywhere outside the popover, or tap the "i" again
- **Style:** Glassmorphic surface (`context.colors.surfaceContainerHigh`), `AppSizes.borderRadiusMd` corners, max width 240dp, `context.textStyles.bodySmall`
- **Arrow:** Small triangular notch pointing to the icon

### Files to modify
- `lib/features/dashboard/presentation/widgets/month_summary_inline.dart` — replace `Tooltip` with `GestureDetector` + `OverlayEntry`

### No new l10n keys needed
Existing `home_net_tooltip` is sufficient for both EN and AR.

---

## 2. Cash Wallet Reordering

### Current state
- `wallet_dao.dart:16` forces system wallet first via `OrderingTerm.desc(w.isSystemWallet)`
- `account_manage_sheet.dart:44-45` filters out system wallet from the reorder list
- Cash wallet can never be reordered or moved from position 1

### Change
Allow Cash to participate in ordering like any other wallet.

### Behavior
- Cash wallet appears in the manage sheet alongside user wallets
- Cash can be dragged to any position
- The `sortOrder` field determines position for ALL wallets (no special-casing)
- Cash is still visually distinguishable (system wallet badge or subtle indicator)
- Cash still cannot be archived or deleted (existing protection stays)

### Files to modify
- `lib/data/database/daos/wallet_dao.dart` — remove `OrderingTerm.desc(w.isSystemWallet)` from `watchAll()`, order purely by `sortOrder` then `id`
- `lib/features/dashboard/presentation/widgets/account_manage_sheet.dart` — remove the `!w.isSystemWallet` filter; add visual indicator that Cash cannot be archived (disable archive button for system wallet)

### Migration note
Existing users: Cash has `sortOrder = 0` (or whatever it was assigned). It will naturally sort among other wallets. No migration needed — the removal of the forced-first sort is sufficient.

---

## 3. All Accounts → Balance Header Dropdown

### Current state
- `balance_header.dart:103-112` renders "All Accounts" as the first `AccountChip` in the horizontal row
- `selectedAccountIdProvider` = `null` means "all accounts"
- The chip row shows: [All Accounts] [Wallet1] [Wallet2] [+Add] [Gear]

### Change
Move "All Accounts" out of the chip row. The balance header itself becomes a tappable account selector via dropdown.

### Behavior

**Balance header area:**
- Shows total balance (when "All Accounts" selected) or selected wallet balance
- Below the balance amount: a tappable row showing the current selection — e.g., "All Accounts ▾" or "HSBC Savings ▾"
- Tapping this row opens a dropdown/popup menu listing:
  - "All Accounts" (with checkmark if selected)
  - Each non-archived wallet (name + mini balance)
- Selecting "All Accounts" sets `selectedAccountIdProvider = null`
- Selecting a wallet sets `selectedAccountIdProvider = walletId`

**Chip row:**
- Only visible when a specific wallet is selected (not "All Accounts")
- When visible, shows the wallet chips for quick switching between wallets
- No longer contains "All Accounts" chip
- Still contains [+Add] and [Gear] buttons

**When "All Accounts" is selected:**
- Balance header shows total balance with "All Accounts ▾" selector
- Chip row is hidden
- Transaction list shows all transactions across all wallets

**When a specific wallet is selected:**
- Balance header shows that wallet's balance with "Wallet Name ▾" selector
- Chip row is visible for quick wallet switching
- Transaction list filters to that wallet

### Files to modify
- `lib/features/dashboard/presentation/widgets/balance_header.dart` — add dropdown selector, conditionally show chip row
- `lib/features/dashboard/presentation/widgets/account_chip.dart` — remove `isAllAccounts` special case
- `lib/shared/providers/selected_account_provider.dart` — no changes (null = all accounts stays)

### L10n
Existing `dashboard_all_accounts` key is sufficient.

---

## 4. Voice Input — Floating Pill Bar

### Current state
- `voice_input_sheet.dart` opens a `showGeneralDialog` covering ~65% of the screen
- Contains: mic button, wave visualization, duration timer, status text, action buttons
- After recording + processing, navigates to `VoiceConfirmScreen`

### Change
Replace the large overlay with a compact 56dp floating pill bar above the nav bar.

### Behavior

**Idle → Recording:**
1. User taps Voice on FAB speed dial
2. Mic permission check (existing logic)
3. Pill bar slides up from bottom with `SlideTransition` (250ms)
4. Recording starts automatically (no separate "tap mic to start")
5. Pill bar shows: [pulsing red dot] [wave bars] [duration timer "0:00"] [stop button]

**Recording state:**
- Red dot pulses with `AnimationController` (scale 0.8↔1.0, 600ms loop)
- Wave bars: 5-7 vertical bars animating heights based on mic amplitude (existing `_amplitudeStream`)
- Timer: counts up from 0:00 in `MM:SS` format
- Stop button: circular, red background, white square icon
- The entire dashboard behind is visible and scrollable (no scrim/overlay)
- Tapping stop or pressing back → stops recording

**Processing state:**
- Pill bar content transitions to: [mint spinner] ["Processing..." text]
- Same pill dimensions, content cross-fades

**Completion:**
- On success: pill bar slides down, `context.push(AppRoutes.voiceConfirm, extra: drafts)`
- On error: pill bar shows error state briefly (red text), then slides down
- On cancel (back button): pill bar slides down, recording discarded

**Auto-stop:**
- Existing max duration logic triggers stop → processing

### Layout
- Pill bar: 56dp height, horizontal margin 16dp (AppSizes.screenHPadding), positioned above the nav bar
- Glassmorphic surface: `surfaceContainerHigh` with blur, ghost border
- Border radius: `AppSizes.borderRadiusFull` (pill shape)
- Internal padding: 8dp vertical, 12dp horizontal

### Files to modify
- `lib/features/voice_input/presentation/widgets/voice_input_sheet.dart` — complete rewrite: from `showGeneralDialog` to a widget that renders as an overlay/positioned element
- `lib/features/voice_input/presentation/widgets/voice_input_button.dart` — update to show pill bar instead of calling `VoiceInputSheet.show()`
- `lib/shared/widgets/navigation/app_nav_bar.dart` — provide a slot/overlay area above the nav bar for the pill bar to dock into

### New widget
`lib/features/voice_input/presentation/widgets/voice_recording_pill.dart` — the new compact recording UI

### Preserved
- `VoiceConfirmScreen` (review screen) stays exactly the same
- All recording logic (recorder, amplitude stream, Gemini API call) stays the same
- Permission handling stays the same

---

## 5. Horizontal Drag-to-Reorder Wallet Chips

### Current state
- `balance_header.dart:98-155` renders chips in a `SingleChildScrollView` with `Axis.horizontal`
- Reordering only works in the vertical `AccountManageSheet` via `ReorderableListView`
- No horizontal drag-to-reorder exists

### Change
Add direct long-press → drag-to-reorder in the horizontal chip row.

### Behavior
1. **Long-press (300ms)** on any wallet chip → haptic feedback (`HapticFeedback.mediumImpact`)
2. Chip lifts: scale 1.05x, elevation increase, slight opacity reduction on the "ghost" placeholder
3. **Drag horizontally** — finger movement moves the lifted chip; other chips animate aside with 200ms spring animation
4. **Drop** — chip settles into new position with spring animation; `sortOrder` persisted to DB via `walletRepository.updateSortOrders()`
5. Scroll view auto-scrolls when dragging near edges (left/right 40dp threshold)

### Gesture conflict resolution
- **Tap** (< 300ms, < 8dp movement) → select wallet (existing behavior)
- **Long-press** (>= 300ms) → enter drag mode
- **Horizontal scroll** (fast swipe) → scroll the row (existing behavior)
- These are naturally separated by the long-press delay

### Implementation approach
Since Flutter's `ReorderableListView` doesn't support horizontal orientation, implement using:
- `GestureDetector` with `onLongPressStart` / `onLongPressMoveUpdate` / `onLongPressEnd`
- `AnimatedPositioned` or manual offset tracking for the dragged chip
- `AnimatedPadding` or `AnimatedContainer` for the gap insertion
- OR: use the `reorderable_grid` or similar package if it supports horizontal single-row

### Files to modify
- `lib/features/dashboard/presentation/widgets/balance_header.dart` — replace `SingleChildScrollView` + `Row` with a custom `HorizontalReorderableRow` widget
- New widget: `lib/shared/widgets/lists/horizontal_reorderable_row.dart` — generic reusable horizontal reorder widget
- `lib/shared/providers/wallet_provider.dart` — no changes (existing `updateSortOrders` used)

---

## 6. Upcoming Bills Rethink

### Current state
- `insight_cards_zone.dart:94-112` creates an insight card for upcoming bills
- Card shows title + count, taps to `/recurring`, dismissible for the day via `NudgeService`
- `upcomingBillsProvider` in `background_ai_provider.dart:32-61` queries rules due within 7 days

### Change
Three-part rethink: richer content, persistent badge, conditional dashboard section.

### Part A: Rich "Due Soon" dashboard section (conditional)

**Visibility:** Only when `upcomingBillsProvider` returns non-empty list (bills due within 7 days).

**Layout:**
- Section header: "Due Soon" with bill icon, positioned after the balance header + chip row area and before the transaction list (inside the sliver scroll)
- Shows up to 3 bill mini-cards in a horizontal scroll row:
  - Each card: bill title, amount (formatted), "in X days" or "Tomorrow" or "Today" label
  - Color-coded: green if >3 days, amber if 2-3 days, red if today/tomorrow
  - Tap → navigates to that specific bill's detail/pay action
- If more than 3 bills: a "+N more" chip at the end that navigates to `/recurring`

**No dismiss button.** The section naturally disappears when all bills are paid or past due.

**Removal of old insight card:** Remove the "upcoming_bills" entry from the insight cards zone to avoid duplication.

### Part B: Badge on Recurring tab

- The bottom nav "Recurring" tab icon shows a small red badge circle with the count of upcoming bills (due within 7 days)
- Badge uses `upcomingBillsProvider.length`
- Badge is always visible when count > 0, no dismiss
- Standard Material badge pattern: small red circle with white number, positioned top-right of tab icon

### Part C: Existing insight card removal

Remove the upcoming bills insight card from `insight_cards_zone.dart` since it's replaced by the richer "Due Soon" section.

### Files to modify
- New widget: `lib/features/dashboard/presentation/widgets/due_soon_section.dart` — the conditional bill section
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — add `DueSoonSection` between balance header and transaction list
- `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart` — remove upcoming bills card
- `lib/shared/widgets/navigation/app_nav_bar.dart` — add badge to Recurring tab using `upcomingBillsProvider`
- `lib/shared/providers/background_ai_provider.dart` — no changes (existing provider is sufficient)

### L10n keys needed
- `home_due_soon_title`: "Due Soon" / "مستحقة قريبا"
- `home_due_soon_today`: "Today" / "اليوم"
- `home_due_soon_tomorrow`: "Tomorrow" / "بكرة"
- `home_due_soon_in_days`: "In {count} days" / "بعد {count} يوم"
- `home_due_soon_more`: "+{count} more" / "+{count} كمان"

---

## File Impact Summary

| File | Changes |
|------|---------|
| `month_summary_inline.dart` | Tooltip → tap popover |
| `wallet_dao.dart` | Remove forced system-wallet-first sort |
| `account_manage_sheet.dart` | Include Cash wallet, disable archive for system wallet |
| `balance_header.dart` | Add dropdown selector, conditional chip row, horizontal reorder |
| `account_chip.dart` | Remove `isAllAccounts` special case |
| `voice_input_sheet.dart` | Rewrite → pill bar widget |
| `voice_input_button.dart` | Show pill bar instead of dialog |
| `app_nav_bar.dart` | Pill bar slot + Recurring tab badge |
| `dashboard_screen.dart` | Add DueSoonSection |
| `insight_cards_zone.dart` | Remove upcoming bills card |

### New files
| File | Purpose |
|------|---------|
| `voice_recording_pill.dart` | Compact recording pill bar widget |
| `horizontal_reorderable_row.dart` | Generic horizontal drag-to-reorder widget |
| `due_soon_section.dart` | Conditional upcoming bills section |

### L10n additions
5 new keys in both `app_en.arb` and `app_ar.arb`.
