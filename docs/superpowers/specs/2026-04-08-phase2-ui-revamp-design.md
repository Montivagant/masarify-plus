# Phase 2: UI Revamp — 5 Screens Design Spec

**Date:** 2026-04-08
**Stitch Project:** `4288853659133708986` (Masarify — Design Reference & Revamp)
**Model:** GEMINI_3_1_PRO

---

## Item 1: Hero/Balance Section Redesign

**Stitch Screen:** `f49245c25e03429bacbebbb41c21c8bb`
**File:** `lib/features/dashboard/presentation/widgets/balance_header.dart`

**Layout (top to bottom):**
1. Total Balance — 32sp bold centered + eye-toggle + "Net +4,300" green label
2. Income/Expense pills — two horizontal tinted pill chips
3. **Cash Wallet Banner (STANDALONE)** — separate card above wallet row, green-tinted glass, tap to select
4. Account selector — "All Accounts" dropdown + gear icon
5. Wallet cards row — horizontal scroll, 120x70px cards with accent bars. Cash NOT in this row.

**Key change from current:** Cash wallet is already a separate banner in the code. The redesign refines spacing, adds the Net label prominently, and ensures the editorial spacing feel.

---

## Item 3: Voice Review List View Redesign

**Stitch Screen:** `a80bf43bbf4d445a8c27df3d33181a46`
**File:** `lib/features/voice_input/presentation/widgets/draft_list_item.dart`

**Design:** Cards match the Tinder-style swipe cards but stacked vertically:
- Full-width glassmorphic card (16px radius, ambient shadow, 16px padding)
- Top: Category icon (40px colored circle) + category name (bold) + amount (22sp bold, color-coded)
- Middle: Transaction title + raw transcript in muted italic
- Chips: Wallet, date, type pills
- Suggestion banner if applicable
- Bottom: Include toggle + Edit button
- Cards spaced 12px apart — substantial visual weight per card

---

## Item 6: Planning Hub Grid (Approved as-is)

**Stitch Screen:** `15d2c66e64f54a6ab5074649dc03ffea`
**File:** `lib/features/hub/presentation/screens/hub_screen.dart`
**Status:** Already implemented in Phase 1. No additional changes needed.

---

## Item 7: Subscriptions & Bills Revamp

**Stitch Screen:** `36ada30f21f349488a19e4f47fc96fe2`
**File:** `lib/features/recurring/presentation/screens/recurring_screen.dart`

**Design:**
- Summary header card: Monthly total + "due this week" badge
- Status-grouped cards with color tints (overdue/upcoming/active/paid)
- Each card: brand icon/category icon + title + frequency + amount + action (Mark Paid / toggle)
- Swipeable edit/delete

**Additional features (user feedback):**
1. **"View All" button** — shows flat list with no status grouping, quick access to each
2. **"Mark Paid" fully functional** — creates transaction, updates nextDueDate, marks isPaid
3. **"Auto Mark Paid" option** in Create/Edit recurring screen:
   - Checkbox: "Automatically mark as paid"
   - When checked: select which wallet to deduct from
   - On app open: check for overdue auto-pay bills, create transactions retroactively
   - Schema: Add `autoMarkPaid` (bool) and `autoPayWalletId` (int?) to RecurringRules table

---

## Item 8: Unified Transaction Detail Screen

**Stitch Screen:** `fdbb66cf00184f948967a7b266e92db3`
**Files:**
- `lib/features/transactions/presentation/screens/transaction_detail_screen.dart`
- `lib/features/wallets/presentation/screens/transfer_detail_screen.dart`

**Design:**
- Hero card: glassmorphic, icon in 48px tinted circle, amount (32sp bold color-coded), title, type+date badges
- For transfers: FROM → TO wallet flow with arrow
- Detail rows: icon badge + label + value, 16px spacing, no dividers
- Edit + delete in app bar
- **Location map: Use `flutter_map` + OpenStreetMap** (open-source) instead of Google Maps

---

## Verification

- `flutter analyze lib/` — zero issues
- Visual testing on device for all 5 screens
- RTL validation for Arabic layout
- Dark mode check for glass tiers
