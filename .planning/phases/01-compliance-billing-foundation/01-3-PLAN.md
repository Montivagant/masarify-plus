---
phase: 1
plan: 3
title: "Billing & Trial Fix"
wave: 2
depends_on: [1, 2]
requirements: [PAYWALL-02, PAYWALL-04, PAYWALL-05]
files_modified:
  - lib/core/services/subscription_service.dart
  - lib/main.dart
  - lib/data/database/tables/subscription_records_table.dart (NEW)
  - lib/data/database/daos/subscription_record_dao.dart (NEW)
  - lib/data/database/app_database.dart
  - lib/data/database/app_database.g.dart (GENERATED — do not edit)
  - lib/shared/providers/subscription_provider.dart
autonomous: true
---

<plan>
<meta>
<phase>1</phase>
<plan_number>3</plan_number>
<title>Billing & Trial Fix</title>
</meta>

<objective>
Verify that the current billing library (BL 7.1.1) is compliant through August 2026 (no migration needed), fix the trial duration from 14 days to 7 days, remove the premature `ensureTrialStarted()` call from main.dart that starts the trial on every app launch, create a `subscription_records` Drift table (v14 migration) to persist purchase tokens and expiry dates for cancellation/grace handling, and wire SubscriptionService to persist purchase records to the new Drift table.
</objective>

<must_haves>
- Trial duration is 7 days (not 14)
- `ensureTrialStarted()` is NOT called from main.dart (call site deferred to Phase 5 onboarding)
- `subscription_records` table exists in Drift schema v14
- SubscriptionService persists purchase records (purchaseToken, productId, expiryDate, status) to Drift
- `flutter analyze lib/` reports zero issues after build_runner
</must_haves>

<tasks>
<task id="1.3.1">
<title>Verify billing library BL7 compliance (no action needed)</title>
<read_first>
- pubspec.lock (search for `in_app_purchase_android` — confirm resolved version and BL version)
- .planning/phases/01-compliance-billing-foundation/01-RESEARCH.md (Section 1 — BL8 research findings)
</read_first>
<action>
This is a verification-only task. Run:

```bash
flutter pub outdated | grep in_app_purchase
```

Confirm that `in_app_purchase_android` resolves to `0.4.0+8` or later (any `0.4.0+X` version bundles BL 7.1.1).

**Key finding from research:** BL7 is valid until August 31, 2026 (with extension to November 1, 2026). No BL8 migration is needed for launch. The Flutter team's BL8 PR ([flutter/packages#10816](https://github.com/flutter/packages/pull/10816)) is still open and not merged. A native BL8 override would crash at runtime.

Optionally run `flutter pub upgrade in_app_purchase` to pick up the latest patch version (`0.4.0+10`) for bug fixes. This is a non-breaking minor patch.

**No code changes required for this task.**
</action>
<acceptance_criteria>
- `flutter pub outdated` shows `in_app_purchase_android` at version `0.4.0+8` or later
- No `purchases_flutter` (RevenueCat) added to pubspec.yaml
- No native BL dependency override in `android/app/build.gradle.kts`
</acceptance_criteria>
</task>

<task id="1.3.2">
<title>Fix _trialDays from 14 to 7</title>
<read_first>
- lib/core/services/subscription_service.dart (line 28 — `static const _trialDays = 14;`)
</read_first>
<action>
In `lib/core/services/subscription_service.dart`, change line 28 from:

```dart
  static const _trialDays = 14;
```

to:

```dart
  static const _trialDays = 7;
```

Also update the class doc comment on line 18-19 from:

```dart
/// Trial logic: 14-day free trial from first app launch. Stored locally
```

to:

```dart
/// Trial logic: 7-day free trial from onboarding completion. Stored locally
```
</action>
<acceptance_criteria>
- grep for `_trialDays = 7` in `lib/core/services/subscription_service.dart` returns exactly 1 match
- grep for `_trialDays = 14` in `lib/core/services/subscription_service.dart` returns 0 matches
- grep for `14-day` in `lib/core/services/subscription_service.dart` returns 0 matches
</acceptance_criteria>
</task>

<task id="1.3.3">
<title>Remove ensureTrialStarted() call from main.dart</title>
<read_first>
- lib/main.dart (line 81 — `unawaited(subService.ensureTrialStarted());`)
</read_first>
<action>
In `lib/main.dart`, delete line 81:

```dart
  unawaited(subService.ensureTrialStarted());
```

The trial must NOT start on every app launch. The single call site will be wired in Phase 5 inside `OnboardingScreen._finish()` — only triggered once when the user completes onboarding.

The `ensureTrialStarted()` method itself remains in `SubscriptionService` (it is idempotent and correct). Only the premature call site in `main.dart` is removed.
</action>
<acceptance_criteria>
- grep for `ensureTrialStarted` in `lib/main.dart` returns 0 matches
- grep for `ensureTrialStarted` in `lib/core/services/subscription_service.dart` returns at least 1 match (method still exists)
</acceptance_criteria>
</task>

<task id="1.3.4">
<title>Create subscription_records Drift table definition</title>
<read_first>
- lib/data/database/tables/category_mappings_table.dart (reference for table definition pattern)
- lib/data/database/app_database.dart (lines 32-47 — @DriftDatabase tables list)
</read_first>
<action>
Create a new file `lib/data/database/tables/subscription_records_table.dart` with the following content:

```dart
import 'package:drift/drift.dart';

/// Persists IAP purchase records for subscription state tracking.
///
/// Replaces SharedPreferences-only storage to support:
/// - Purchase token verification on app relaunch
/// - Grace period and cancellation state tracking
/// - Expiry-based access revocation
class SubscriptionRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Google Play purchase token — unique identifier for each purchase.
  TextColumn get purchaseToken => text()();

  /// Product ID (e.g., 'masarify_pro_monthly', 'masarify_pro_yearly').
  TextColumn get productId => text()();

  /// When the purchase was made.
  DateTimeColumn get purchaseDate => dateTime()();

  /// When the subscription expires. Null for lifetime purchases (not applicable yet).
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// Subscription status: 'active', 'cancelled', 'expired', 'grace_period'.
  TextColumn get status =>
      text().withDefault(const Constant('active'))();
}
```
</action>
<acceptance_criteria>
- File `lib/data/database/tables/subscription_records_table.dart` exists
- grep for `class SubscriptionRecords extends Table` in the new file returns 1 match
- grep for `purchaseToken` in the new file returns 1 match
- grep for `expiryDate` in the new file returns 1 match
- grep for `status` in the new file returns at least 1 match
</acceptance_criteria>
</task>

<task id="1.3.5">
<title>Create SubscriptionRecordDao</title>
<read_first>
- lib/data/database/daos/category_mapping_dao.dart (reference for DAO pattern)
</read_first>
<action>
Create a new file `lib/data/database/daos/subscription_record_dao.dart` with the following content:

```dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/subscription_records_table.dart';

part 'subscription_record_dao.g.dart';

@DriftAccessor(tables: [SubscriptionRecords])
class SubscriptionRecordDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionRecordDaoMixin {
  SubscriptionRecordDao(super.db);

  /// Insert or update a subscription record keyed by purchaseToken.
  Future<void> upsertRecord({
    required String purchaseToken,
    required String productId,
    required DateTime purchaseDate,
    DateTime? expiryDate,
    String status = 'active',
  }) async {
    final existing = await (select(subscriptionRecords)
          ..where((r) => r.purchaseToken.equals(purchaseToken)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(subscriptionRecords)
            ..where((r) => r.id.equals(existing.id)))
          .write(
        SubscriptionRecordsCompanion(
          productId: Value(productId),
          expiryDate: Value(expiryDate),
          status: Value(status),
        ),
      );
    } else {
      await into(subscriptionRecords).insert(
        SubscriptionRecordsCompanion.insert(
          purchaseToken: purchaseToken,
          productId: productId,
          purchaseDate: purchaseDate,
          expiryDate: Value(expiryDate),
          status: Value(status),
        ),
      );
    }
  }

  /// Get the most recent active subscription record.
  Future<SubscriptionRecord?> getActiveSubscription() async {
    return (select(subscriptionRecords)
          ..where((r) => r.status.equals('active'))
          ..orderBy([(r) => OrderingTerm.desc(r.purchaseDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Update the status of a subscription by purchaseToken.
  Future<void> updateStatus(String purchaseToken, String status) async {
    await (update(subscriptionRecords)
          ..where((r) => r.purchaseToken.equals(purchaseToken)))
        .write(SubscriptionRecordsCompanion(status: Value(status)));
  }

  /// Get all subscription records (for debugging/settings display).
  Future<List<SubscriptionRecord>> getAll() async {
    return (select(subscriptionRecords)
          ..orderBy([(r) => OrderingTerm.desc(r.purchaseDate)]))
        .get();
  }
}
```
</action>
<acceptance_criteria>
- File `lib/data/database/daos/subscription_record_dao.dart` exists
- grep for `class SubscriptionRecordDao` in the new file returns 1 match
- grep for `@DriftAccessor` in the new file returns 1 match
- grep for `upsertRecord` in the new file returns at least 1 match
- grep for `getActiveSubscription` in the new file returns at least 1 match
</acceptance_criteria>
</task>

<task id="1.3.6">
<title>Register table and DAO in app_database.dart, bump to v14</title>
<read_first>
- lib/data/database/app_database.dart (lines 1-67 — imports, @DriftDatabase annotation, schema version; lines 260-265 — last migration block for v13)
</read_first>
<action>
In `lib/data/database/app_database.dart`, make the following changes:

**1. Add imports** after the existing DAO/table imports (after line 28):

```dart
import 'daos/subscription_record_dao.dart';
import 'tables/subscription_records_table.dart';
```

**2. Add `SubscriptionRecords` to the `tables:` list** in the `@DriftDatabase` annotation. Add it after `ParsedEventGroups` (line 46), so the list becomes:

```dart
  tables: [
    Wallets,
    Categories,
    Transactions,
    Transfers,
    Budgets,
    SavingsGoals,
    GoalContributions,
    RecurringRules,
    SmsParserLogs,
    ExchangeRates,
    CategoryMappings,
    ChatMessages,
    ParsedEventGroups,
    SubscriptionRecords,
  ],
```

**3. Add `SubscriptionRecordDao` to the `daos:` list** after `ParsedEventGroupDao` (line 60):

```dart
  daos: [
    WalletDao,
    CategoryDao,
    TransactionDao,
    TransferDao,
    BudgetDao,
    GoalDao,
    RecurringRuleDao,
    SmsParserLogDao,
    ExchangeRateDao,
    CategoryMappingDao,
    ChatMessageDao,
    ParsedEventGroupDao,
    SubscriptionRecordDao,
  ],
```

**4. Bump schema version** from 13 to 14. Change line 67 from:

```dart
  int get schemaVersion => 13;
```

to:

```dart
  int get schemaVersion => 14;
```

**5. Add v14 migration block** inside the `onUpgrade` callback, between the last migration guard and the idempotent `_createIndexes()` call. The precise insertion point is **after line 265** (closing brace of `if (from < 13) { ... }`) and **before line 266** (the `// Indexes are idempotent` comment). The surrounding code looks like this:

```dart
          // existing — do NOT modify:
          if (from < 13) {
            // Add sortOrder column for carousel drag-and-drop reordering.
            await m.addColumn(wallets, wallets.sortOrder);
            // Initialize sortOrder to match existing id ordering.
            await customStatement('UPDATE wallets SET sort_order = id');
          }
          // ── INSERT NEW BLOCK HERE ──────────────────────────────────
          if (from < 14) {
            await m.createTable(subscriptionRecords);
          }
          // existing — do NOT modify:
          // Indexes are idempotent (IF NOT EXISTS) — always safe to re-run.
          await _createIndexes();
```

The new `if (from < 14)` block MUST be placed inside the `onUpgrade` callback's `async` body, at the same indentation level as the other `if (from < N)` guards. It must NOT be placed outside `onUpgrade` or after `_createIndexes()`.
</action>
<acceptance_criteria>
- grep for `SubscriptionRecords` in `lib/data/database/app_database.dart` returns at least 2 matches (tables list + migration)
- grep for `SubscriptionRecordDao` in `lib/data/database/app_database.dart` returns at least 1 match (daos list)
- grep for `schemaVersion => 14` in `lib/data/database/app_database.dart` returns 1 match
- grep for `schemaVersion => 13` in `lib/data/database/app_database.dart` returns 0 matches
- grep for `from < 14` in `lib/data/database/app_database.dart` returns 1 match
</acceptance_criteria>
</task>

<task id="1.3.7">
<title>Run build_runner to generate Drift code</title>
<read_first>
- lib/data/database/app_database.dart (confirm all changes from task 1.3.6 are in place)
</read_first>
<action>
Run the Drift code generator:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This will generate:
- `lib/data/database/app_database.g.dart` — updated with `SubscriptionRecords` table and `SubscriptionRecordDao` mixin
- `lib/data/database/daos/subscription_record_dao.g.dart` — generated DAO mixin

Verify the generation succeeded:

```bash
flutter analyze lib/
```

If there are errors in the generated code, they typically indicate a mistake in the table definition or DAO annotation. Fix the source file and re-run build_runner.
</action>
<acceptance_criteria>
- `dart run build_runner build --delete-conflicting-outputs` exits with code 0
- File `lib/data/database/daos/subscription_record_dao.g.dart` exists
- `flutter analyze lib/` reports "No issues found!"
</acceptance_criteria>
</task>

<task id="1.3.8">
<title>Wire SubscriptionService to persist purchases to Drift</title>
<read_first>
- lib/core/services/subscription_service.dart (full file — current SharedPreferences-only storage)
- lib/shared/providers/subscription_provider.dart (provider definitions)
- lib/data/database/daos/subscription_record_dao.dart (new DAO API)
</read_first>
<action>
In `lib/core/services/subscription_service.dart`, modify the class to accept an optional `SubscriptionRecordDao` parameter and persist purchase records:

**1. Add import** at the top of the file (after the existing imports). From `lib/core/services/subscription_service.dart`, the relative path goes up 2 levels (`services/` -> `core/` -> `lib/`) then down into `data/database/daos/`:

```dart
import '../../data/database/daos/subscription_record_dao.dart';
```

**2. Add DAO parameter to constructor.** Change the constructor from:

```dart
class SubscriptionService {
  SubscriptionService(this._prefs);

  final SharedPreferences _prefs;
```

to:

```dart
class SubscriptionService {
  SubscriptionService(this._prefs, {this.recordDao});

  final SharedPreferences _prefs;
  final SubscriptionRecordDao? recordDao;
```

**3. Update `_handlePurchaseUpdates`** to persist purchase records to Drift. Change the `PurchaseStatus.purchased` and `PurchaseStatus.restored` case from:

```dart
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _activatePro();
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
```

to:

```dart
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _activatePro();
          _persistPurchaseRecord(purchase);
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
```

**4. Add the `_persistPurchaseRecord` method** after `_activatePro()`:

```dart
  /// Persist purchase record to Drift for offline verification and
  /// cancellation/grace period tracking.
  Future<void> _persistPurchaseRecord(PurchaseDetails purchase) async {
    final dao = recordDao;
    if (dao == null) return;
    try {
      await dao.upsertRecord(
        purchaseToken: purchase.purchaseID ?? '',
        productId: purchase.productID,
        purchaseDate: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(purchase.transactionDate ?? '') ??
              DateTime.now().millisecondsSinceEpoch,
        ),
        status: 'active',
      );
    } catch (_) {
      // Non-fatal — SharedPreferences is the fallback.
    }
  }
```

**5. Update the subscription provider** in `lib/shared/providers/subscription_provider.dart` to pass the DAO. Change:

```dart
final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) {
    final service = SubscriptionService(ref.watch(sharedPreferencesProvider));
    ref.onDispose(service.dispose);
    return service;
  },
);
```

to:

```dart
final subscriptionServiceProvider = Provider<SubscriptionService>(
  (ref) {
    final db = ref.watch(databaseProvider);
    final service = SubscriptionService(
      ref.watch(sharedPreferencesProvider),
      recordDao: db.subscriptionRecordDao,
    );
    ref.onDispose(service.dispose);
    return service;
  },
);
```

**6. Add the database import** in `subscription_provider.dart` if not already present:

```dart
import 'database_provider.dart';
```

Check if `database_provider.dart` is already imported (it may not be since the current provider only uses `sharedPreferencesProvider`). The `databaseProvider` is defined in `lib/shared/providers/database_provider.dart` and provides the `AppDatabase` instance. Access the DAO via `db.subscriptionRecordDao` (this accessor is generated by Drift after build_runner).
</action>
<acceptance_criteria>
- grep for `recordDao` in `lib/core/services/subscription_service.dart` returns at least 2 matches
- grep for `_persistPurchaseRecord` in `lib/core/services/subscription_service.dart` returns at least 2 matches
- grep for `upsertRecord` in `lib/core/services/subscription_service.dart` returns 1 match
- grep for `databaseProvider` in `lib/shared/providers/subscription_provider.dart` returns 1 match
- grep for `subscriptionRecordDao` in `lib/shared/providers/subscription_provider.dart` returns 1 match
- `flutter analyze lib/` reports "No issues found!"
</acceptance_criteria>
</task>

<task id="1.3.9">
<title>Final verification — analyze, test, and build</title>
<read_first>
- lib/core/services/subscription_service.dart (confirm all changes)
- lib/data/database/app_database.dart (confirm schema v14)
</read_first>
<action>
Run the complete verification suite:

```bash
# 1. Static analysis
flutter analyze lib/

# 2. Existing tests still pass
flutter test

# 3. Release build succeeds (catches any runtime-level issues with the new schema)
flutter build appbundle --release
```

If any tests fail related to `SubscriptionService` (e.g., constructor signature changed), update the test to pass `null` for the optional `recordDao` parameter:

```dart
// Old:
final service = SubscriptionService(prefs);

// New:
final service = SubscriptionService(prefs);  // recordDao defaults to null — no change needed
```

The named parameter `recordDao` is optional with a default of `null`, so existing code that creates `SubscriptionService(prefs)` without the DAO will continue to work.
</action>
<acceptance_criteria>
- `flutter analyze lib/` reports "No issues found!"
- `flutter test` reports all tests passing (0 failures)
- `flutter build appbundle --release` exits with code 0
</acceptance_criteria>
</task>
</tasks>

<verification>
```bash
# Billing library version check:
flutter pub outdated | grep in_app_purchase

# Trial duration:
grep "_trialDays = 7" lib/core/services/subscription_service.dart && echo "PASS" || echo "FAIL"
grep "_trialDays = 14" lib/core/services/subscription_service.dart && echo "FAIL: still 14" || echo "PASS"

# ensureTrialStarted removed from main.dart:
grep "ensureTrialStarted" lib/main.dart && echo "FAIL: still in main.dart" || echo "PASS"

# Schema version:
grep "schemaVersion => 14" lib/data/database/app_database.dart && echo "PASS" || echo "FAIL"

# New table exists:
test -f lib/data/database/tables/subscription_records_table.dart && echo "PASS" || echo "FAIL"
test -f lib/data/database/daos/subscription_record_dao.dart && echo "PASS" || echo "FAIL"
test -f lib/data/database/daos/subscription_record_dao.g.dart && echo "PASS" || echo "FAIL"

# Drift persistence wired:
grep "recordDao" lib/core/services/subscription_service.dart && echo "PASS" || echo "FAIL"
grep "subscriptionRecordDao" lib/shared/providers/subscription_provider.dart && echo "PASS" || echo "FAIL"

# Full build:
flutter analyze lib/
flutter test
flutter build appbundle --release
```
</verification>
</plan>
