# P4 Overhaul Design — Masarify Plus
_Date: 2026-03-03_

## Overview

Major restructuring of Masarify Plus before Play Store launch. Covers feature removals, a Bills/Recurring merge, UI visual changes, AI model swap, parsing bug fixes, home screen carousel, and a Wallet→Account rename.

---

## 1. Feature Removals

### 1.1 Smart Insights — Complete Purge

**Delete files:**
- `lib/features/insights/` (entire directory)
- `lib/core/services/insight_engine.dart`
- `lib/core/utils/insight_presenter.dart`
- `lib/shared/providers/insight_provider.dart`
- `lib/shared/widgets/cards/insight_card.dart`
- `lib/features/dashboard/presentation/widgets/insights_zone.dart`

**Modify:**
- Remove insights l10n keys from `app_en.arb` / `app_ar.arb`
- Remove insights route from `app_router.dart`
- Remove insights imports/references from dashboard screen
- Remove "Smart Insights" section header and quick action from dashboard

### 1.2 Net Worth — Complete Purge

**Delete files:**
- `lib/features/net_worth/` (entire directory)
- `lib/shared/providers/net_worth_provider.dart`

**Modify:**
- Remove net worth l10n keys from both ARB files
- Remove net worth route from `app_router.dart`
- Remove net worth references from Hub screen and any navigation

### 1.3 Auto-Log Removal (from Recurring)

- Remove `autoLog` field from `RecurringRuleEntity`
- Remove `autoLog` column from `recurring_rules_table.dart` (handled in DB migration v4)
- Remove auto-log toggle from `add_recurring_screen.dart`
- Update `recurring_scheduler.dart`: all rules now send reminder notifications only — never auto-create transactions

---

## 2. Bills & Recurring Merge → "Recurring & Bills"

### Approach: Extend RecurringRules table

RecurringRules already has 90% of what we need. Add bill-specific payment tracking columns.

### Unified Entity (RecurringRuleEntity extended)

```
Fields kept:     id, title, amount, type, walletId, categoryId,
                 startDate, endDate, nextDueDate, isActive, lastProcessedDate
Fields added:    isPaid (bool), paidAt (DateTime?), linkedTransactionId (int?)
Fields removed:  autoLog
Field modified:  frequency → enum: once | daily | weekly | monthly | yearly | custom
```

### Frequency Behavior

| Frequency | Behavior |
|-----------|----------|
| `once` | Bill-like: due on `startDate`, no recurrence. `endDate` = `startDate`. |
| `daily/weekly/monthly/yearly` | `startDate` = first occurrence. `endDate` = optional (null = forever). `nextDueDate` advances by period. |
| `custom` | User picks explicit `startDate` and `endDate`. `nextDueDate` = `startDate`. |

Frequency selection auto-fills date fields. User can then optionally override end date.

### DB Migration v4

1. Add `isPaid` (bool, default false), `paidAt` (nullable), `linkedTransactionId` (nullable) to `recurring_rules`
2. Add `'once'` as valid frequency value
3. Migrate all `bills` rows → `recurring_rules` (frequency='once', map fields)
4. Drop `bills` table

### Files to Delete

- `lib/features/bills/` (entire directory)
- `lib/domain/entities/bill_entity.dart`
- `lib/data/database/daos/bill_dao.dart` + `.g.dart`
- `lib/data/database/tables/bills_table.dart`
- `lib/data/repositories/bill_repository_impl.dart`
- `lib/domain/repositories/i_bill_repository.dart`
- `lib/shared/providers/bill_provider.dart`

### Files to Modify

- `recurring_rule_entity.dart` — add bill fields, new frequency enum
- `recurring_rules_table.dart` — add columns
- `recurring_rule_dao.dart` — add bill queries (watchUnpaid, markPaid, etc.)
- `recurring_rule_repository_impl.dart` — add bill methods
- `recurring_screen.dart` → rename, sectioned UI: Overdue | Upcoming | Recurring | Paid
- `add_recurring_screen.dart` → unified form with frequency picker (including "once")
- `app_database.dart` — migration v4
- `app_router.dart` — remove bill routes, update recurring routes
- `hub_screen.dart` — single "Recurring & Bills" entry
- L10n files — rename/add strings

### Scheduler Update

- Skip `once` items where `isPaid == true`
- For `once` items past due and not paid: show as overdue in UI (no auto-advance)
- For recurring items: advance `nextDueDate`, send reminder notification only

---

## 3. UI / Visual Changes

### 3.1 Transaction Color Coding

Already implemented (`incomeColor`, `expenseColor`, `transferColor` in `AppThemeExtension`). **Audit pass:** ensure ALL transaction displays consistently use these semantic colors. Fix any inconsistencies.

### 3.2 Category Visuals — Remove Colored Squares

**Current:** 44×44dp glass inset container with `categoryColor.withOpacity(0.15)` background + colored icon inside.

**New:** Plain icon only, tinted with the category's `colorHex`. No background container. Icon size ~24dp.

**Rationale:** Prevents user confusion between a red category background and expense coloring.

**Files affected:** `transaction_card.dart`, `categories_tab.dart` (reports), `add_transaction_screen.dart`, `parser_review_screen.dart`, `categories_screen.dart`, `add_category_screen.dart`, and any widget rendering a category badge.

### 3.3 FAB Position — Lower It

Use a custom `FloatingActionButtonLocation` subclass that reduces the vertical gap between FAB and bottom nav bar by ~8–12dp.

### 3.4 "Wallet" → "Account" Rename

- **L10n:** Rename all 28 wallet-related keys in both ARB files. English: "Wallet"→"Account", "Wallets"→"Accounts". Arabic: "محفظة"→"حساب", "محافظ"→"حسابات".
- **Code variables:** Keep `wallet` internally (avoids massive refactor). Only user-facing strings change via l10n.
- **DB table name:** Keep `wallets` as-is (internal, no user impact).

---

## 4. Home Screen Account Carousel

### Architecture

```
PageView (horizontal scroll, viewportFraction: 0.92)
├── Page 0: Total Balance Card (enhanced BalanceCard)
├── Page 1: Account 1 card (same glass hero style, account-specific data)
├── Page 2: Account 2 card
└── ...

selectedAccountIndexProvider (StateProvider<int>)
  └── 0 = "all" (total), 1+ = specific account

selectedAccountIdProvider (derived)
  └── null = all, int = specific wallet ID
```

### State Chaining

All dashboard providers watch `selectedAccountIdProvider` and filter accordingly:
- Recent transactions → filtered by account
- Monthly income/expense → filtered by account
- Spending breakdown → filtered by account

### Visual Details

- Page indicator dots below carousel
- Cards use existing glass hero gradient style
- `viewportFraction: 0.92` for peek-ahead effect
- Smooth `PageController` with snap

---

## 5. AI & Parsing Overhaul

### 5.1 Remove Gemini (All Paid Models)

**Delete:** `lib/core/services/ai/gemini_audio_service.dart`

**Modify:**
- `ai_config.dart` — remove Gemini API key, remove `gemini-2.5-flash` from fallback chain
- `env.dart` — remove Gemini key
- `ai_provider.dart` — remove `geminiAudioServiceProvider`
- New fallback chain: `gemma-3-27b-it:free` → `qwen3-4b:free`

### 5.2 Replace Voice Input with Device STT

**Add package:** `speech_to_text`

**New service:** `SpeechRecognitionService` in `lib/core/services/`

**Voice flow:**
1. Start listening via device STT (Google STT on Android)
2. Device transcribes audio to text (on-device, free, works offline)
3. Send transcript to free OpenRouter models for structured parsing
4. If offline: transcription works, parsing queues until online

**Modify:** `voice_input_sheet.dart` — replace Gemini audio API call with `speech_to_text` recording + free model parsing.

### 5.3 Offline Handling

**Add package:** `connectivity_plus`

**New service:** `ConnectivityService` with `Stream<bool>` (online/offline)

**New provider:** `connectivityProvider` (StreamProvider)

**Behavior:**
- Offline: AI parsing disabled. Show banner: "AI features need internet. Add transactions manually."
- SMS/notification regex parsing continues offline (local)
- Queue items needing AI enrichment with `parsedStatus='pending_enrichment'`
- Back online: auto-process queue, show brief "Syncing..." indicator

### 5.4 Notification Parser Crash Fix

- Add try/catch guards around entire notification processing pipeline in `notification_listener_wrapper.dart`
- Ensure lifecycle observer properly starts/stops listener
- Guard against null/missing fields in notification payloads

### 5.5 SMS in "Parsed Notifications" Tab (Conflict)

**Solution:** Unify into a single "Parsed Transactions" tab. The user doesn't care about the source — they just want to review and approve. Remove separate SMS/notification tabs.

### 5.6 SMS Not Analyzed with AI

Verify `SmsParserService.scanInbox()` actually calls AI enrichment path. The 20-item cap exists — ensure the enrichment loop executes.

### 5.7 Double-Click to Confirm Fix

- Add per-item loading state in `parser_review_screen.dart`
- Disable confirm button during processing
- Ensure `ref.invalidate()` fires after successful approval

### 5.8 Analytics Categories Language Bug

The code correctly uses `localeProvider` and `displayName(lang)`. Investigate:
- Is `localeProvider` returning correct value after language switch?
- Is the `categoryBreakdownProvider` invalidated on locale change?
- May need to add explicit `ref.watch(localeProvider)` in the categories tab widget

---

## 6. Remaining P4 (Unchanged)

After this overhaul, these P4 items remain:
- **4.3** Home Widget (Android widget)
- **4.4** Microinteractions (Lottie animations)
- **4.5** Onboarding Polish
- **4.9** Performance & Quality
- **4.10** Play Store Release Prep

---

## New Dependencies

| Package | Purpose |
|---------|---------|
| `speech_to_text` | Device-native STT for voice input |
| `connectivity_plus` | Network state monitoring |

## Dependencies to Remove

| Package | Reason |
|---------|--------|
| (Gemini direct API usage removed) | Replaced by device STT + free models |

## DB Changes

- **Migration v4:** Add columns to `recurring_rules`, migrate `bills` data, drop `bills` table, remove `autoLog` column
