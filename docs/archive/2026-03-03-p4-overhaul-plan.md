# P4 Overhaul Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Restructure Masarify Plus before Play Store launch — remove dead features, merge Bills into Recurring, overhaul AI/parsing, add home carousel, rename Wallet→Account, fix UI bugs.

**Architecture:** Clean Architecture + Feature-first. Riverpod 2.x state. Drift (SQLite) DB with code-gen. Material Design 3 glass UI. All money in integer piastres.

**Tech Stack:** Flutter/Dart, Drift, Riverpod, go_router, speech_to_text, connectivity_plus, OpenRouter (free models only)

**Design doc:** `docs/plans/2026-03-03-p4-overhaul-design.md`

---

## Pre-flight

Before starting, run:
```bash
cd D:/Masarify-Plus
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/
```
Expected: No issues found.

---

## Phase 1: Feature Removals (Tasks 1–3 are independent — can be parallelized)

### Task 1: Remove Smart Insights

**Files to delete:**
- `lib/features/insights/` (entire directory)
- `lib/core/services/insight_engine.dart`
- `lib/core/utils/insight_presenter.dart`
- `lib/shared/providers/insight_provider.dart`
- `lib/shared/widgets/cards/insight_card.dart`
- `lib/features/dashboard/presentation/widgets/insights_zone.dart`

**Files to modify:**

**Step 1:** Remove InsightsZone from dashboard screen
- File: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Remove import on line ~20: `import '../widgets/insights_zone.dart';`
- Remove Zone 6 usage on line ~135: `const InsightsZone(),`
- Remove the insight_provider import if present

**Step 2:** Remove insights route from router
- File: `lib/app/router/app_router.dart`
- Remove the GoRoute for `/insights` (lines ~281-283)
- Remove InsightsScreen import

**Step 3:** Remove insights route constant
- File: `lib/core/constants/app_routes.dart`
- Remove `static const insights = '/insights';` (line ~53-54)

**Step 4:** Remove insights entry from Hub screen
- File: `lib/features/hub/presentation/screens/hub_screen.dart`
- Remove the insights `_tile()` call (line ~84)
- Remove the "Reports" section entirely if insights was the only item, or just the insights tile

**Step 5:** Remove insights l10n keys from both ARB files
- Files: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Remove all keys prefixed with `insights_` or `insight_`
- Run `flutter gen-l10n` or let build_runner handle it

**Step 6:** Delete the files listed above

**Step 7:** Run `flutter analyze lib/` — fix any dangling imports

**Step 8:** Commit
```bash
git add -A && git commit -m "feat: remove Smart Insights feature completely"
```

---

### Task 2: Remove Net Worth

**Files to delete:**
- `lib/features/net_worth/` (entire directory)
- `lib/shared/providers/net_worth_provider.dart`

**Files to modify:**

**Step 1:** Remove net worth route from router
- File: `lib/app/router/app_router.dart`
- Remove GoRoute for `/net-worth` (lines ~277-279)
- Remove NetWorthScreen import

**Step 2:** Remove net worth route constant
- File: `lib/core/constants/app_routes.dart`
- Remove `static const netWorth = '/net-worth';`

**Step 3:** Remove net worth from Hub screen
- File: `lib/features/hub/presentation/screens/hub_screen.dart`
- Remove the Net Worth `_tile()` call (line ~50)

**Step 4:** Remove net worth l10n keys
- Files: `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb`
- Remove keys: `net_worth_title`, `net_worth_assets`, `net_worth_liabilities`, `net_worth_wallet_breakdown`, and any other `net_worth_*` keys

**Step 5:** Delete the files listed above

**Step 6:** Run `flutter analyze lib/` — fix any dangling imports

**Step 7:** Commit
```bash
git add -A && git commit -m "feat: remove Net Worth feature completely"
```

---

### Task 3: Remove auto-log from Recurring (code only — DB column stays until migration in Task 6)

**Step 1:** Update entity — remove autoLog field
- File: `lib/domain/entities/recurring_rule_entity.dart`
- Remove `required this.autoLog,` from constructor
- Remove `final bool autoLog;` field
- Remove any reference to autoLog in the class

**Step 2:** Update add_recurring_screen — remove auto-log toggle
- File: `lib/features/recurring/presentation/screens/add_recurring_screen.dart`
- Remove `bool _autoLog = false;` state variable (line ~40)
- Remove the GlassCard SwitchListTile for auto-log (lines ~507-516)
- Remove autoLog from save/submit logic

**Step 3:** Update recurring_scheduler — remove auto-log branch
- File: `lib/core/services/recurring_scheduler.dart`
- Remove the `if (rule.autoLog)` branch that auto-creates transactions
- All rules now only send reminder notifications
- Keep the nextDueDate advancement logic

**Step 4:** Update recurring_rule_dao — stop reading autoLog
- File: `lib/data/database/daos/recurring_rule_dao.dart`
- The Drift-generated code still has the column (DB hasn't migrated yet)
- Entity mapping should default autoLog to false or ignore it

**Step 5:** Update any repository/provider that references autoLog

**Step 6:** Run `flutter analyze lib/` — fix issues

**Step 7:** Commit
```bash
git add -A && git commit -m "feat: remove auto-log from recurring rules (notification-only)"
```

---

## Phase 2: Bills & Recurring Merge (Sequential — each task depends on previous)

### Task 4: DB Migration v4 — Extend recurring_rules table

**Step 1:** Update recurring_rules_table.dart — add new columns
- File: `lib/data/database/tables/recurring_rules_table.dart`
- Add after existing columns:
```dart
BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
DateTimeColumn get paidAt => dateTime().nullable()();
IntColumn get linkedTransactionId => integer().nullable().references(Transactions, #id)();
```
- Remove: `BoolColumn get autoLog => ...` line

**Step 2:** Update app_database.dart — bump schema version and add migration
- File: `lib/data/database/app_database.dart`
- Change `schemaVersion => 3` to `schemaVersion => 4`
- Add migration block in `onUpgrade`:
```dart
if (from < 4) {
  // Add bill-tracking columns to recurring_rules
  await m.addColumn(recurringRules, recurringRules.isPaid);
  await m.addColumn(recurringRules, recurringRules.paidAt);
  await m.addColumn(recurringRules, recurringRules.linkedTransactionId);

  // Migrate bills → recurring_rules
  final billRows = await customSelect('SELECT * FROM bills').get();
  for (final row in billRows) {
    await customInsert(
      'INSERT INTO recurring_rules (wallet_id, category_id, amount, type, title, frequency, start_date, end_date, next_due_date, is_paid, paid_at, linked_transaction_id, is_active, last_processed_date) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable.withInt(row.read<int>('wallet_id')),
        Variable.withInt(row.read<int>('category_id')),
        Variable.withInt(row.read<int>('amount')),
        Variable.withString('expense'),
        Variable.withString(row.read<String>('name')),
        Variable.withString('once'),
        Variable<DateTime>(row.read<DateTime>('due_date')),
        Variable<DateTime>(row.read<DateTime>('due_date')),
        Variable<DateTime>(row.read<DateTime>('due_date')),
        Variable.withBool(row.read<bool>('is_paid')),
        Variable<DateTime?>(row.readNullable<DateTime>('paid_at')),
        Variable<int?>(row.readNullable<int>('linked_transaction_id')),
        Variable.withBool(true),
        Variable<DateTime?>(null),
      ],
    );
  }

  // Drop bills table
  await customStatement('DROP TABLE IF EXISTS bills');

  // Remove autoLog column (SQLite doesn't support DROP COLUMN before 3.35,
  // but Drift handles this — if needed, recreate table)
  // For safety: just leave the column, it's ignored by the entity.
}
```
- Remove `Bills` from the tables list in `@DriftDatabase`
- Remove `BillDao` from the daos list

**Step 3:** Run build_runner
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 4:** Commit
```bash
git add -A && git commit -m "feat: DB migration v4 — merge bills into recurring_rules"
```

---

### Task 5: Update entity, DAO, repository for merged Recurring & Bills

**Step 1:** Update RecurringRuleEntity — add bill fields
- File: `lib/domain/entities/recurring_rule_entity.dart`
- Add to constructor and fields:
```dart
required this.isPaid,
this.paidAt,
this.linkedTransactionId,
```
```dart
final bool isPaid;
final DateTime? paidAt;
final int? linkedTransactionId;
```
- Update `isDue` getter to also check `!isPaid` for once-frequency items
- Add `bool get isOverdue` getter (from BillEntity logic):
```dart
bool get isOverdue {
  if (isPaid || frequency != 'once') return false;
  final now = DateTime.now();
  final endOfDueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day + 1);
  return now.isAfter(endOfDueDate);
}
```

**Step 2:** Update RecurringRuleDao — add bill queries
- File: `lib/data/database/daos/recurring_rule_dao.dart`
- Add methods:
```dart
Stream<List<RecurringRule>> watchUnpaid() =>
    (select(recurringRules)
          ..where((r) => r.isPaid.not() & r.frequency.equals('once'))
          ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]))
        .watch();

Future<bool> markPaid(int id, DateTime paidAt, {int? transactionId}) =>
    (update(recurringRules)..where((r) => r.id.equals(id)))
        .write(RecurringRulesCompanion(
          isPaid: const Value(true),
          paidAt: Value(paidAt),
          linkedTransactionId: Value(transactionId),
        ))
        .then((count) => count > 0);
```

**Step 3:** Update repository interface
- File: `lib/domain/repositories/i_recurring_rule_repository.dart`
- Add: `Stream<List<RecurringRuleEntity>> watchUnpaid();`
- Add: `Future<bool> markPaid(int id, DateTime paidAt, {int? transactionId});`

**Step 4:** Update repository implementation
- File: `lib/data/repositories/recurring_rule_repository_impl.dart`
- Implement the new methods, mapping DB rows to entity with the new fields
- Update existing mapping to include `isPaid`, `paidAt`, `linkedTransactionId`

**Step 5:** Update provider
- File: `lib/shared/providers/recurring_rule_provider.dart`
- Add: `final unpaidBillsProvider = StreamProvider(...)` that calls `watchUnpaid()`

**Step 6:** Run build_runner + analyze
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/
```

**Step 7:** Commit
```bash
git add -A && git commit -m "feat: extend recurring entity/DAO/repo with bill fields"
```

---

### Task 6: Delete all Bill files and clean up references

**Files to delete:**
- `lib/features/bills/` (entire directory)
- `lib/domain/entities/bill_entity.dart`
- `lib/data/database/daos/bill_dao.dart`
- `lib/data/database/daos/bill_dao.g.dart`
- `lib/data/database/tables/bills_table.dart`
- `lib/data/repositories/bill_repository_impl.dart`
- `lib/domain/repositories/i_bill_repository.dart`
- `lib/shared/providers/bill_provider.dart`

**Step 1:** Delete all bill files listed above

**Step 2:** Remove bill-related providers from repository_providers.dart
- File: `lib/shared/providers/repository_providers.dart`
- Remove `billRepositoryProvider` (lines ~70-77)
- Remove `billDaoProvider` from database_provider.dart

**Step 3:** Remove bill DAO provider from database_provider.dart
- File: `lib/shared/providers/database_provider.dart`
- Remove `billDaoProvider` definition

**Step 4:** Remove bill routes from router
- File: `lib/app/router/app_router.dart`
- Remove GoRoutes for `/bills`, `/bills/add`, `/bills/:id/edit` (lines ~241-253)
- Remove bill screen imports

**Step 5:** Remove bill route constants
- File: `lib/core/constants/app_routes.dart`
- Remove `bills`, `billAdd`, `billEdit` constants

**Step 6:** Remove bill l10n keys from both ARB files
- Remove keys prefixed with `bill_` or `bills_`
- Keep any keys that are reused (check carefully)

**Step 7:** Update Hub screen — replace separate Bills + Recurring tiles with single "Recurring & Bills"
- File: `lib/features/hub/presentation/screens/hub_screen.dart`
- Replace the two tiles (lines ~73-74) with one:
```dart
_tile(context, context.l10n.recurring_and_bills_title, AppIcons.recurring, AppRoutes.recurring),
```

**Step 8:** Update backup_service_impl.dart — remove bills backup/restore
- File: `lib/data/services/backup_service_impl.dart`
- Remove `_billToMap()` helper
- Remove `_mapToBill()` helper
- Remove bills from export JSON
- Remove bills from restore logic
- Add recurring_rules isPaid/paidAt/linkedTransactionId to backup map

**Step 9:** Run analyze
```bash
flutter analyze lib/
```

**Step 10:** Commit
```bash
git add -A && git commit -m "feat: delete all Bill files, unify under Recurring & Bills"
```

---

### Task 7: Update Recurring Screen UI — sectioned Recurring & Bills view

**File:** `lib/features/recurring/presentation/screens/recurring_screen.dart`

**Step 1:** Rename screen title and restructure sections
- Change AppBar title to `context.l10n.recurring_and_bills_title`
- Restructure ListView into 4 sections:
  1. **Overdue** (once-frequency, not paid, past due) — red header
  2. **Upcoming Bills** (once-frequency, not paid, not overdue) — default header
  3. **Active Recurring** (non-once frequency, isActive) — default header
  4. **Paid / Completed** (isPaid == true) — collapsed, grey header

**Step 2:** Update `_RecurringCard` to show bill-specific UI
- For once-frequency items: show due date prominently, "Mark Paid" action button
- For recurring items: show frequency badge and next due date
- Overdue items: red tint/border

**Step 3:** Add "Mark Paid" action (for once-frequency items)
- On tap: call `recurringRuleRepository.markPaid(id, DateTime.now())`
- Optionally create a linked transaction

**Step 4:** Run analyze

**Step 5:** Commit
```bash
git add -A && git commit -m "feat: redesign recurring screen with bill sections"
```

---

### Task 8: Update add_recurring_screen — unified form with frequency picker

**File:** `lib/features/recurring/presentation/screens/add_recurring_screen.dart`

**Step 1:** Update frequency options
- Replace `_frequencies` list:
```dart
static const _frequencies = ['once', 'daily', 'weekly', 'monthly', 'yearly', 'custom'];
```
- Update `_frequencyLabel()` to handle `'once'` and `'custom'`
- Add l10n keys: `recurring_frequency_once`, `recurring_frequency_custom`

**Step 2:** Auto-fill dates based on frequency selection
- When frequency is `'once'`: show single date picker for due date. Set `startDate = endDate = selectedDate`.
- When frequency is `'daily'/'weekly'/'monthly'/'yearly'`: show start date picker. End date optional.
- When frequency is `'custom'`: show both start and end date pickers.

**Step 3:** Remove biweekly/quarterly from frequency options and l10n

**Step 4:** Update save logic to include `isPaid: false` for new items

**Step 5:** Run analyze

**Step 6:** Commit
```bash
git add -A && git commit -m "feat: unified recurring/bill form with new frequency options"
```

---

### Task 9: Update Recurring Scheduler for merged model

**File:** `lib/core/services/recurring_scheduler.dart`

**Step 1:** Update scheduler logic:
- Skip `once`-frequency items where `isPaid == true`
- For `once`-frequency items past due but not paid: do nothing (UI shows overdue)
- For recurring items: advance `nextDueDate`, send reminder notification only (no auto-create)
- Remove all auto-log transaction creation code

**Step 2:** Run analyze

**Step 3:** Commit
```bash
git add -A && git commit -m "feat: update scheduler for merged recurring/bills model"
```

---

## Phase 3: UI Changes (Tasks 10–13 are independent — can be parallelized)

### Task 10: Category Visuals — Remove colored squares

**Step 1:** Update transaction_card.dart
- File: `lib/shared/widgets/cards/transaction_card.dart`
- Replace the GlassCard category badge (lines ~148-163) with a plain icon:
```dart
Icon(
  categoryIcon,
  size: AppSizes.iconMd,
  color: categoryColor,
),
```
- Remove the GlassCard wrapper, SizedBox container, and tintColor background

**Step 2:** Update all other files that render category badges the same way:
- `lib/features/reports/presentation/widgets/categories_tab.dart` — category icon in list
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` — category picker display
- `lib/features/sms_parser/presentation/screens/parser_review_screen.dart` — parsed item icon
- `lib/features/categories/presentation/screens/categories_screen.dart` — category list
- `lib/features/categories/presentation/screens/add_category_screen.dart` — icon preview

For each: replace colored-background container with plain `Icon(icon, color: color, size: AppSizes.iconMd)`

**Step 3:** Search for any remaining `GlassTier.inset` category badge patterns
```bash
grep -r "categoryColor" lib/ --include="*.dart" | grep -v ".g.dart"
```

**Step 4:** Run analyze

**Step 5:** Commit
```bash
git add -A && git commit -m "feat: simplify category icons — plain colored icons, no squares"
```

---

### Task 11: FAB Position — Lower it

**Step 1:** Create a custom FAB location
- File: `lib/shared/widgets/navigation/app_nav_bar.dart`
- Add a custom class:
```dart
class _LowerCenterFloatFabLocation extends FloatingActionButtonLocation {
  const _LowerCenterFloatFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Start from centerFloat position
    final centerFloat = FloatingActionButtonLocation.centerFloat;
    final baseOffset = centerFloat.getOffset(scaffoldGeometry);
    // Move down by 10dp (closer to nav bar)
    return Offset(baseOffset.dx, baseOffset.dy + 10);
  }
}
```
- Replace `FloatingActionButtonLocation.centerFloat` (line ~241) with:
```dart
floatingActionButtonLocation: const _LowerCenterFloatFabLocation(),
```

**Step 2:** Test visually — adjust the 10dp offset if needed

**Step 3:** Commit
```bash
git add -A && git commit -m "fix: lower FAB closer to bottom nav bar"
```

---

### Task 12: Wallet → Account rename (l10n only)

**Step 1:** Update `lib/l10n/app_en.arb`
- Find-replace all user-facing wallet strings:
  - `"Wallets"` → `"Accounts"`, `"Wallet"` → `"Account"`
  - `"wallets"` → `"accounts"` (in descriptions/subtitles)
  - Keep l10n KEY names as `wallet_*` (just change the values)
  - Examples: `"wallets_title": "Accounts"`, `"transaction_wallet": "Account"`, `"wallets_add": "Add Account"`

**Step 2:** Update `lib/l10n/app_ar.arb`
- Find-replace Arabic wallet strings:
  - `"محفظة"` → `"حساب"`, `"محافظ"` → `"حسابات"`, `"المحفظة"` → `"الحساب"`, `"المحافظ"` → `"الحسابات"`
  - Keep l10n KEY names as `wallet_*`

**Step 3:** Run `flutter gen-l10n` or build_runner to regenerate

**Step 4:** Commit
```bash
git add -A && git commit -m "feat: rename Wallet to Account in all user-facing text"
```

---

### Task 13: Transaction color audit

**Step 1:** Search all transaction display widgets for hardcoded or missing color usage:
```bash
grep -rn "transaction.type\|txType\|\.type ==" lib/ --include="*.dart" | grep -v ".g.dart"
```

**Step 2:** Verify each location uses `context.appTheme.incomeColor/expenseColor/transferColor`

Key files to check:
- `lib/shared/widgets/cards/transaction_card.dart` — amount color
- `lib/features/transactions/presentation/screens/transaction_detail_screen.dart` — detail view
- `lib/features/transactions/presentation/screens/transaction_list_screen.dart` — list items
- `lib/features/reports/presentation/widgets/overview_tab.dart` — charts
- `lib/features/sms_parser/presentation/screens/parser_review_screen.dart` — parsed items

**Step 3:** Fix any inconsistencies found

**Step 4:** Commit (if changes made)
```bash
git add -A && git commit -m "fix: ensure consistent income/expense/transfer color usage"
```

---

## Phase 4: Home Screen Account Carousel

### Task 14: Create selectedAccount providers

**Step 1:** Create new provider file
- File: `lib/shared/providers/selected_account_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Index in the carousel: 0 = total (all accounts), 1+ = specific account.
final selectedAccountIndexProvider = StateProvider<int>((ref) => 0);

/// Derived: null = show all, int = specific wallet ID.
final selectedAccountIdProvider = Provider<int?>((ref) {
  final index = ref.watch(selectedAccountIndexProvider);
  if (index == 0) return null;
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  if (index - 1 < wallets.length) return wallets[index - 1].id;
  return null;
});
```

**Step 2:** Commit
```bash
git add -A && git commit -m "feat: add selectedAccount providers for carousel state"
```

---

### Task 15: Create Account Carousel widget

**Step 1:** Create new widget file
- File: `lib/features/dashboard/presentation/widgets/account_carousel.dart`
- PageView.builder with:
  - Page 0: Total balance card (existing BalanceCard params)
  - Pages 1–N: Per-account cards (same glass hero style, account-specific income/expense)
- Page indicator dots below
- `viewportFraction: 0.92` for peek-ahead
- On page change: update `selectedAccountIndexProvider`

**Step 2:** Update BalanceCard to accept optional account-specific data
- File: `lib/shared/widgets/cards/balance_card.dart`
- Add optional `accountName` parameter to show account name instead of "Total Balance"
- The card widget stays the same, just the label changes

**Step 3:** Commit
```bash
git add -A && git commit -m "feat: add account carousel widget with PageView"
```

---

### Task 16: Wire dashboard to selectedAccount

**Step 1:** Update dashboard_screen.dart
- File: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Replace BalanceZone (Zone 1) with AccountCarousel widget
- Remove old BalanceCard direct usage

**Step 2:** Update dashboard providers to filter by selected account
- Files in `lib/shared/providers/`:
  - `transaction_provider.dart` — add account-filtered variants or modify existing
  - `analytics_provider.dart` — monthlySpending should accept optional walletId filter
- Each provider watches `selectedAccountIdProvider`:
  - If null → return all data (current behavior)
  - If int → filter by walletId

**Step 3:** Update dashboard zones that display data:
- Recent transactions zone → use filtered provider
- Spending summary → use filtered provider
- Quick actions zone → hide "Transfer" when specific account is selected (optional)

**Step 4:** Run analyze

**Step 5:** Commit
```bash
git add -A && git commit -m "feat: wire dashboard data to selected account carousel"
```

---

## Phase 5: AI & Parsing Overhaul (Sequential)

### Task 17: Remove Gemini — delete service, update config

**Step 1:** Delete `lib/core/services/ai/gemini_audio_service.dart`

**Step 2:** Update ai_config.dart
- File: `lib/core/config/ai_config.dart`
- Remove: `geminiApiKey` getter, `geminiBaseUrl`, `geminiAudioModel`, `modelGeminiFlash`, `hasGeminiKey`
- Remove: Gemini env override
- Update `defaultModel` to `modelGemma27b`
- Update `fallbackChain` to `[modelGemma27b, modelQwen3_4b]`

**Step 3:** Update env.dart
- File: `lib/core/config/env.dart`
- Remove Gemini API key

**Step 4:** Update ai_provider.dart
- File: `lib/shared/providers/ai_provider.dart`
- Remove `geminiAudioServiceProvider`
- Remove GeminiAudioService import

**Step 5:** Run analyze — fix any remaining Gemini references

**Step 6:** Commit
```bash
git add -A && git commit -m "feat: remove Gemini paid model, keep free models only"
```

---

### Task 18: Add connectivity_plus and ConnectivityService

**Step 1:** Add package
```bash
flutter pub add connectivity_plus
```

**Step 2:** Create ConnectivityService
- File: `lib/core/services/connectivity_service.dart`
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _connectivity = Connectivity();

  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.map(
        (results) => results.any((r) => r != ConnectivityResult.none),
      );

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }
}
```

**Step 3:** Create provider
- File: `lib/shared/providers/connectivity_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/connectivity_service.dart';

final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onlineStream;
});
```

**Step 4:** Commit
```bash
git add -A && git commit -m "feat: add connectivity service with online/offline stream"
```

---

### Task 19: Update voice input — replace Gemini with device STT + free models

**Note:** `speech_to_text` package is already in pubspec.yaml (line 77).

**Step 1:** Rewrite voice_input_sheet.dart
- File: `lib/features/voice_input/presentation/widgets/voice_input_sheet.dart`
- Replace Gemini audio path (lines ~170-192) with:
  1. Use `SpeechToText` to listen and transcribe (on-device)
  2. Show live transcription text to user
  3. When done, send transcript to `aiVoiceParserProvider` (which uses free OpenRouter models)
  4. If offline: show transcription only, notify user "AI parsing needs internet"

**Step 2:** Remove `record` package usage for audio file recording (no longer needed — STT is live)
- Remove temp file creation/deletion logic
- Remove `AudioRecorder` usage

**Step 3:** Update the UI states:
- Idle → Listening (show waveform/pulse) → Transcribing → Parsing (AI) → Done
- Show real-time transcript text as user speaks
- If no internet: show banner and skip AI parsing step

**Step 4:** Add offline check before AI parsing:
```dart
final online = ref.read(isOnlineProvider).valueOrNull ?? true;
if (!online) {
  // Show message: AI features need internet
  // User can still see transcript and add manually
  return;
}
```

**Step 5:** Run analyze

**Step 6:** Commit
```bash
git add -A && git commit -m "feat: replace Gemini audio with device STT + free models"
```

---

### Task 20: Offline handling for SMS/notification parsing

**Step 1:** Update notification_listener_wrapper.dart
- Before AI enrichment call, check connectivity:
```dart
final online = await _connectivityService.isOnline;
if (!online) {
  // Skip AI enrichment — item stays in 'pending' with no enrichment
  // Will be enriched when back online (Task 21 handles sync)
  return;
}
```

**Step 2:** Update sms_parser_service.dart — same offline guard before AI enrichment

**Step 3:** Create offline sync mechanism
- On connectivity change (back online), process pending items without AI enrichment:
```dart
// In a provider or service that watches isOnlineProvider:
// When transitions from offline → online:
//   1. Fetch all pending logs where aiEnrichmentJson is null
//   2. Run AI enrichment on each (with cap)
//   3. Notify user "Syncing AI enrichment..."
```
- Add this to `main.dart` or as a Riverpod listener

**Step 4:** Add offline banner to dashboard
- When `isOnlineProvider` is false, show a small banner:
  `"Offline — AI features unavailable. Add transactions manually."`

**Step 5:** Commit
```bash
git add -A && git commit -m "feat: offline handling for AI parsing with sync-on-reconnect"
```

---

## Phase 6: Bug Fixes (Tasks 21–25 are independent — can be parallelized)

### Task 21: Fix notification parser crash

**File:** `lib/core/services/notification_listener_wrapper.dart`

**Step 1:** Wrap `_onNotification` handler body in try/catch
- The current handler (lines ~124-181) may crash on null fields
- Add outer try/catch:
```dart
Future<void> _onNotification(ServiceNotificationEvent event) async {
  try {
    // ... existing logic ...
  } catch (e, stack) {
    CrashLogService.log(e, stack);
  }
}
```

**Step 2:** Add null guards for all event fields
```dart
final packageName = event.packageName ?? '';
final title = event.title ?? '';
final body = event.content ?? '';
if (body.isEmpty) return;
```

**Step 3:** Guard the stream subscription with lifecycle awareness
- Ensure `stop()` is called in `dispose()` / `deactivate()`
- Add `_isDisposed` flag to prevent processing after dispose

**Step 4:** Commit
```bash
git add -A && git commit -m "fix: guard notification parser against crashes"
```

---

### Task 22: Unify SMS/notification into single "Parsed Transactions" tab

**File:** `lib/features/sms_parser/presentation/screens/parser_review_screen.dart`

**Step 1:** Remove source-based tab filtering
- If there are separate tabs for SMS and notifications, merge into one list
- The `pendingParsedTransactionsProvider` should return ALL pending items regardless of source
- Show a small source indicator badge (SMS icon or notification icon) on each card

**Step 2:** Update l10n — change tab/screen title from "Parsed Notifications" to "Parsed Transactions"
- Add key: `parsed_transactions_title` in both ARB files

**Step 3:** Commit
```bash
git add -A && git commit -m "fix: unify SMS and notification parsed items into single view"
```

---

### Task 23: Fix SMS AI enrichment not executing

**File:** `lib/core/services/sms_parser_service.dart`

**Step 1:** Debug the enrichment path (lines ~94-111):
- Check that `aiParser` is not null (it's injected — verify injection in provider/main)
- Check that `categories` is not null
- Add logging to confirm the enrichment block is reached:
```dart
dev.log('SMS enrichment: aiParser=${aiParser != null}, categories=${categories?.length}, calls=$enrichmentCalls/$maxEnrichmentCalls');
```

**Step 2:** Verify the service is instantiated with AI parser
- Check where `SmsParserService` is created — ensure `aiParser` is passed
- File: likely in main.dart or a provider

**Step 3:** Fix any null injection issues found

**Step 4:** Commit
```bash
git add -A && git commit -m "fix: ensure SMS AI enrichment executes during inbox scan"
```

---

### Task 24: Fix double-click to confirm in parser review

**File:** `lib/features/sms_parser/presentation/screens/parser_review_screen.dart`

**Step 1:** Add per-item processing state
```dart
final _processingIds = <int>{};

bool _isProcessing(int logId) => _processingIds.contains(logId);
```

**Step 2:** Disable button during processing
```dart
FilledButton.tonal(
  onPressed: _isProcessing(log.id) ? null : () => _approve(context, ref, log),
  child: _isProcessing(log.id)
      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
      : Text(context.l10n.sms_review_approve),
),
```

**Step 3:** Wrap `_approve` with state management
```dart
setState(() => _processingIds.add(log.id));
try {
  await _approveLogic(context, ref, log);
} finally {
  if (mounted) setState(() => _processingIds.remove(log.id));
}
```

**Step 4:** Commit
```bash
git add -A && git commit -m "fix: prevent double-click on parser review confirm button"
```

---

### Task 25: Fix analytics categories showing Arabic in English mode

**File:** `lib/features/reports/presentation/widgets/categories_tab.dart`

**Step 1:** Investigate — check if the widget watches locale
- The `categoryBreakdownProvider` watches `localeProvider` via the analytics provider
- Check: does `CategoriesTab` widget have `ref.watch(localeProvider)`?
- If NOT watching locale, the widget may not rebuild on language switch

**Step 2:** Likely fix — ensure the categories tab rebuilds on locale change
```dart
// In the build method, add:
final locale = ref.watch(localeProvider);
```
This forces the widget to rebuild when locale changes, which triggers `categoryBreakdownProvider` to recompute with the new language.

**Step 3:** If the provider itself doesn't watch locale, fix in:
- File: `lib/shared/providers/analytics_provider.dart`
- Ensure `categoryBreakdownProvider` has `ref.watch(localeProvider)` (it should — verify line numbers)

**Step 4:** Commit
```bash
git add -A && git commit -m "fix: analytics categories now display in correct language"
```

---

## Phase 7: Finalize

### Task 26: Build runner + full verify

**Step 1:** Regenerate all code
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 2:** Generate l10n
```bash
flutter gen-l10n
```

**Step 3:** Full analyze
```bash
flutter analyze lib/
```
Expected: No issues found.

**Step 4:** Run tests
```bash
flutter test
```
Fix any failures.

**Step 5:** Build release to verify
```bash
flutter build appbundle --release
```

**Step 6:** Final commit
```bash
git add -A && git commit -m "chore: regenerate code, verify zero warnings after P4 overhaul"
```

---

## Parallelization Map

```
Phase 1 (parallel):  Task 1 ─┐
                     Task 2 ─┤── all independent
                     Task 3 ─┘
                        │
Phase 2 (sequential): Task 4 → Task 5 → Task 6 → Task 7 → Task 8 → Task 9
                        │
Phase 3 (parallel):  Task 10 ─┐
                     Task 11 ─┤── all independent
                     Task 12 ─┤
                     Task 13 ─┘
                        │
Phase 4 (sequential): Task 14 → Task 15 → Task 16
                        │
Phase 5 (sequential): Task 17 → Task 18 → Task 19 → Task 20
                        │
Phase 6 (parallel):  Task 21 ─┐
                     Task 22 ─┤── all independent
                     Task 23 ─┤
                     Task 24 ─┤
                     Task 25 ─┘
                        │
Phase 7:              Task 26 (final verify)
```

Phases 1, 3, and 6 can be dispatched as parallel subagents within their phase.
Phases 2, 4, and 5 must be sequential.
