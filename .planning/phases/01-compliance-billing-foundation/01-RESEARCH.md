# Phase 1: Compliance & Billing Foundation -- Research

**Researched:** 2026-03-27
**Researcher:** Claude Opus 4.6 (1M context)
**Sources:** pub.dev, GitHub flutter/flutter, GitHub flutter/packages, developer.android.com, docs.flutter.dev, local codebase analysis

---

## 1. Billing Library BL8 Compatibility

**Confidence: HIGH -- fully resolved, no blocker**

### Current State

| Component | Version | Billing Library |
|-----------|---------|-----------------|
| `in_app_purchase` (pubspec.yaml) | `^3.2.0` | -- |
| `in_app_purchase` (pubspec.lock resolved) | `3.2.3` | -- |
| `in_app_purchase_android` (pubspec.lock resolved) | `0.4.0+8` | **7.1.1** |
| `in_app_purchase_android` (latest on pub.dev) | `0.4.0+10` (published 2026-03-25) | **7.1.1** |

### Google Play Billing Library Deprecation Schedule

Source: [developer.android.com/google/play/billing/deprecation-faq](https://developer.android.com/google/play/billing/deprecation-faq)

| Billing Library Version | Deprecated (no new apps/updates) | Extension Deadline |
|------------------------|----------------------------------|-------------------|
| BL6 and earlier | **August 31, 2025** | November 1, 2025 |
| BL7 | August 31, **2026** | November 1, 2026 |
| BL8 | August 31, **2027** | November 1, 2027 |

### Key Finding: BL7 is sufficient for launch

The prior STACK.md research stated "February 2026 -- All apps must use BL8+". This was **incorrect**. The actual deadline schedule is:

- **BL7 is valid until August 31, 2026** (with extension to November 1, 2026)
- **BL8 is not mandatory until August 31, 2027**
- Masarify's current resolved `in_app_purchase_android: 0.4.0+8` bundles **BL 7.1.1**, which is compliant for the entire 2026 calendar year

### BL8 Status in Flutter Ecosystem

- GitHub issue [flutter/flutter#171523](https://github.com/flutter/flutter/issues/171523) tracks BL8 adoption (status: **OPEN**, priority P2)
- PR [flutter/packages#10816](https://github.com/flutter/packages/pull/10816) "[in_app_purchase_android] Update Play Billing Library to 8.0.0" is **OPEN, not merged** (opened ~2026-01-20, last activity 2026-02-13)
- No version of `in_app_purchase_android` on pub.dev bundles BL8 as of 2026-03-27
- BL8 brings new APIs for one-time products and external content links, but removes some deprecated query APIs

### Recommendation

**No action needed on BL version for Phase 1.** The current `in_app_purchase_android: 0.4.0+8` (BL 7.1.1) is fully compliant. However:

1. Run `flutter pub upgrade in_app_purchase` to pick up `0.4.0+10` (latest patch, still BL 7.1.1) for any bug fixes
2. Monitor [flutter/flutter#171523](https://github.com/flutter/flutter/issues/171523) -- when BL8 lands in the plugin (expected mid-2026), upgrade before the August 2026 BL7 deprecation
3. **Do NOT attempt a native BL8 override** in `build.gradle.kts` -- the PR is not merged because the Kotlin/Java interface layer needs updates; a manual dependency override will crash at runtime
4. RevenueCat migration is unnecessary -- the official plugin is compliant

---

## 2. Edge-to-Edge on API 35

**Confidence: HIGH -- well-documented migration path**

### Background

- **Current state:** `targetSdk = 34`, `compileSdk = flutter.compileSdkVersion` (resolves to **36** on Flutter 3.38.6)
- **Required change:** Bump `targetSdk` to **35** in `android/app/build.gradle.kts` line 36
- **Impact:** Android 15 (API 35) enforces edge-to-edge by default -- app content renders behind status bar and navigation bar

### Flutter's Built-in Edge-to-Edge Support

Source: [docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge](https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge)

Since Flutter 3.27, Flutter apps targeting Android 15 automatically opt into edge-to-edge. Since Masarify's Flutter SDK is 3.38.6, the framework already handles the basic edge-to-edge setup. The key behaviors:

1. **Status bar becomes transparent** -- content renders behind it
2. **Navigation bar becomes transparent** -- content renders behind it (both gesture nav and 3-button nav)
3. **`SafeArea` still works** for basic inset protection, but must be verified for custom bottom navigation

### Risk Areas for Masarify

| Component | Risk | Reason |
|-----------|------|--------|
| `AppNavBar` (glassmorphic floating bottom nav) | **MEDIUM** | Uses `BackdropFilter` + `ClipRRect` -- content may render behind the system nav bar AND behind the custom nav bar simultaneously, causing double-overlap |
| Center-docked FAB | **LOW** | FAB position is relative to the `Scaffold.floatingActionButtonLocation` -- should auto-adjust |
| Dashboard zones | **LOW** | Content in `ListView` will be inset by `SafeArea` at top/bottom |
| Voice input bottom sheet | **LOW** | `showModalBottomSheet` respects system insets natively |

### Known Flutter Issues

- [flutter/flutter#169746](https://github.com/flutter/flutter/issues/169746) -- `systemNavigationBarColor` not working after Flutter 3.32.1 (regression)
- [flutter/flutter#169258](https://github.com/flutter/flutter/issues/169258) -- Bottom navigation bar background color remains black
- [flutter/flutter#165379](https://github.com/flutter/flutter/issues/165379) -- BackdropFilter with blur crashes app with Impeller enabled (Masarify already has Impeller disabled)
- [flutter/flutter#168635](https://github.com/flutter/flutter/issues/168635) -- Edge-to-edge rendering issues at inset boundaries

### Migration Strategy

**Short-term (Phase 1):** Opt out on API 35, accept edge-to-edge on API 36+

1. Bump `targetSdk` to 35
2. Add `android:windowOptOutEdgeToEdgeEnforcement` to `values/styles.xml` (both LaunchTheme and NormalTheme) -- this preserves current behavior on API 35 devices
3. Create `values-v35/styles.xml` **without** the opt-out attribute -- prevents crash on API 36+ where opt-out is removed
4. Test on API 35 emulator -- with the opt-out, the app should render identically to API 34

**This approach is safe because:**
- Masarify's `AppNavBar` uses `BackdropFilter` with sigma 20, which is the highest-risk component for edge-to-edge overlap
- Fixing edge-to-edge properly requires padding adjustments in the custom nav bar, which is UI work outside Phase 1's scope
- The opt-out is valid for Android 15 (API 35) -- it was only removed in Android 16 (API 36)
- Play Store requires `targetSdk = 35`, not edge-to-edge rendering

**Long-term (Phase 3 or 6):** When doing the Home Screen Overhaul (Phase 3), adopt full edge-to-edge:
- Set `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)` explicitly
- Add `MediaQuery.of(context).padding.bottom` to `AppNavBar` height
- Test with both gesture navigation and 3-button navigation
- Remove the opt-out from `values/styles.xml`

### Recommendation

Bump `targetSdk` to 35 and opt out of edge-to-edge enforcement via Android styles. This is the lowest-risk path that satisfies STORE-01 without requiring UI changes. Full edge-to-edge adoption should be deferred to the Home Screen Overhaul phase.

---

## 3. Transitive Permission Analysis

**Confidence: HIGH -- verified from source**

### flutter_local_notifications (v17.2.4)

**Verified by reading the actual package AndroidManifest.xml from pub cache:**

```xml
<!-- flutter_local_notifications-17.2.4/android/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

**SCHEDULE_EXACT_ALARM is NOT declared by flutter_local_notifications.** The permission in Masarify's manifest (line 26) was added manually. It can be removed with a simple deletion -- no `tools:node="remove"` needed for this permission since there is no transitive source to override.

### another_telephony (v0.4.1)

**Verified via GitHub source (thanhdang198/Telephony):** The library-level manifest declares:

```xml
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

The SMS permissions (`READ_SMS`, `RECEIVE_SMS`, `SEND_SMS`) are **not** declared in the library manifest -- they must be added by the app developer. Masarify already has `tools:node="remove"` on `READ_SMS` and `RECEIVE_SMS` in its own manifest.

**Impact of removing `another_telephony`:** The transitive `ACCESS_COARSE_LOCATION` will be removed from the merged manifest. However, Masarify declares its own `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` (lines 14-15), so the merged manifest will be unchanged.

### NotificationService Analysis

The `NotificationService.scheduleDaily()` method (line 129) already uses `AndroidScheduleMode.inexactAllowWhileIdle`, which does **not** require `SCHEDULE_EXACT_ALARM`. The permission declaration on line 26 of AndroidManifest.xml is unnecessary dead weight that could trigger Play Store scrutiny.

### Recommendation

1. **Delete** `SCHEDULE_EXACT_ALARM` from AndroidManifest.xml line 26 (simple removal, not `tools:node="remove"`, since no transitive source declares it)
2. **Remove** `another_telephony: ^0.4.1` from pubspec.yaml -- its transitive `ACCESS_COARSE_LOCATION` is redundant with Masarify's own declaration
3. **Run** `./gradlew app:processReleaseManifest` after changes and inspect the merged manifest at `build/intermediates/merged_manifest/release/AndroidManifest.xml` to verify no unexpected permissions remain
4. **Audit targets:** After cleanup, the merged manifest should contain only: `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `USE_BIOMETRIC`, `USE_FINGERPRINT`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `INTERNET`, `ACCESS_NETWORK_STATE`, `VIBRATE`

---

## 4. Drift v14 Migration Pattern

**Confidence: HIGH -- pattern well-established in codebase**

### Current Schema State

- **Schema version:** 13 (defined in `app_database.dart` line 67)
- **13 tables:** Wallets, Categories, Transactions, Transfers, Budgets, SavingsGoals, GoalContributions, RecurringRules, SmsParserLogs, ExchangeRates, CategoryMappings, ChatMessages, ParsedEventGroups
- **Migration chain:** v1 through v13, all in `onUpgrade` switch-case pattern
- **Drift version:** `^2.20.0`

### Pattern for Adding a New Table (v13 to v14)

Based on the established pattern in the codebase (e.g., `CategoryMappings` added at v5, `ChatMessages` at v6):

**Step 1: Create table definition file**

Create `lib/data/database/tables/subscription_records_table.dart`:

```dart
import 'package:drift/drift.dart';

class SubscriptionRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get purchaseToken => text()();
  TextColumn get productId => text()();
  DateTimeColumn get purchaseDate => dateTime()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  // status values: 'active', 'cancelled', 'expired', 'grace_period'
}
```

**Step 2: Register table in `@DriftDatabase` annotation**

Add `SubscriptionRecords` to the `tables:` list in `app_database.dart` line 33-47.

**Step 3: Add migration in `onUpgrade`**

```dart
if (from < 14) {
  await m.createTable(subscriptionRecords);
}
```

**Step 4: Bump `schemaVersion`**

Change line 67 from `int get schemaVersion => 13;` to `int get schemaVersion => 14;`.

**Step 5: Create DAO (optional for Phase 1)**

Create `lib/data/database/daos/subscription_record_dao.dart` with basic CRUD operations. Register it in the `daos:` list.

**Step 6: Run build_runner**

```bash
dart run build_runner build --delete-conflicting-outputs
```

This regenerates `app_database.g.dart` with the new table's generated code.

### Important Notes

- The `m.createTable()` call in `onUpgrade` is the standard pattern used for all table additions (v5, v6, v8)
- Indexes for the new table should be added to `_createIndexes()` (idempotent with `IF NOT EXISTS`)
- The `beforeOpen` callback already enables foreign keys (`PRAGMA foreign_keys = ON`)
- No data migration is needed -- the table starts empty
- Fresh installs use `onCreate: (m) => m.createAll()` which creates all tables at once

---

## 5. Implementation Recommendations

### Requirement-by-Requirement Guidance

#### STORE-01: Bump targetSdk to 35

- **File:** `android/app/build.gradle.kts` line 36
- **Change:** `targetSdk = 34` to `targetSdk = 35`
- **compileSdk:** Already `flutter.compileSdkVersion` = 36. No change needed.
- **Edge-to-edge:** Opt out via `values/styles.xml` (see Section 2). Create `values-v35/styles.xml` without opt-out for API 36+ safety.
- **Verification:** Build release AAB, run on API 35 emulator, confirm no visual regressions.

#### CLEAN-01: Remove Notification Parsing from Settings

- **File:** `lib/features/settings/presentation/screens/settings_screen.dart`
- The section (lines 721-731) is already hidden via `kSmsEnabled = false`, but the `another_telephony` import on line 3 will cause a compile error when the package is removed.
- **Action:** Remove the import, remove the entire guarded code block, verify with `flutter analyze lib/`.

#### CLEAN-02: Remove another_telephony package

- **File:** `pubspec.yaml` line 87
- **Import sites to clean:** `settings_screen.dart` line 3, `sms_parser_service.dart` line 5 (2 files confirmed by grep)
- **Also delete:** `lib/core/services/notification_transaction_parser.dart` (dead code file)
- **Verification:** `flutter pub get`, `flutter analyze lib/`, grep for "another_telephony" returns zero matches.

#### CLEAN-03: Fix SCHEDULE_EXACT_ALARM

- **File:** `android/app/src/main/AndroidManifest.xml` line 26
- **Action:** Delete the entire line `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>`. No `tools:node="remove"` needed because no transitive dependency declares it.
- **Verification:** Merged manifest audit shows no SCHEDULE_EXACT_ALARM.

#### PAYWALL-02: Billing library functional

- **Current state:** `in_app_purchase_android: 0.4.0+8` bundles BL 7.1.1 -- fully compliant through August 2026.
- **Action:** Run `flutter pub upgrade in_app_purchase` to pick up `0.4.0+10` (latest). Verify `SubscriptionService.initialize()` connects to Play Billing without errors on a test device/emulator.
- **No migration to RevenueCat or BL8 override needed.**

#### PAYWALL-04: Fix trial duration (7 vs 14 days)

- **File:** `lib/core/services/subscription_service.dart` line 28
- **Change:** `static const _trialDays = 14;` to `static const _trialDays = 7;`
- **Also fix:** Remove `unawaited(subService.ensureTrialStarted());` from `lib/main.dart` line 81. The trial must NOT start on every app launch -- it should be called once from `OnboardingScreen._finish()` in Phase 5.
- **Verify:** `trialDaysRemaining` returns 7 after calling `ensureTrialStarted()` once, and returns the correct countdown on subsequent reads.

#### PAYWALL-05: Subscription purchase token storage in Drift

- **Action:** Create `subscription_records` table (see Section 4 for exact pattern), wire `SubscriptionService` to persist purchase records to this table in addition to (or replacing) SharedPreferences.
- **Schema bump:** v13 to v14.
- **Build:** Run `build_runner` after table creation.

### Additional Recommended Changes (from codebase analysis)

1. **GoogleFonts offline config:** Add `GoogleFonts.config.allowRuntimeFetching = false;` in `lib/main.dart` before `runApp()`. Currently missing -- fonts could attempt network fetch, violating offline-first (D-09 from CONTEXT.md).

2. **L10n cleanup:** After removing `another_telephony` and notification parsing UI, audit `app_en.arb` and `app_ar.arb` for orphaned keys related to SMS/notification parsing.

3. **SmsParserService cleanup:** The `_scanSmsInBackground()` function in `main.dart` (lines 125-131) is dead code when `kSmsEnabled = false`. Consider removing or adding a comment noting it is preserved for future Pro tier.

### Ordering of Changes

Recommended implementation order to minimize risk:

1. **Package cleanup first** (CLEAN-02, CLEAN-01) -- removing `another_telephony` and cleaning imports is low-risk and unblocks the permission audit
2. **Permission cleanup** (CLEAN-03) -- delete `SCHEDULE_EXACT_ALARM`, run merged manifest audit
3. **SDK bump** (STORE-01) -- bump `targetSdk` to 35, add edge-to-edge opt-out styles, test on emulator
4. **GoogleFonts config** -- one-line addition in `main.dart`
5. **Trial fix** (PAYWALL-04) -- fix `_trialDays`, remove `ensureTrialStarted()` from `main.dart`
6. **Drift migration** (PAYWALL-05) -- create `subscription_records` table, bump to v14, run `build_runner`
7. **Wire SubscriptionService** (PAYWALL-02) -- persist purchases to Drift table
8. **Final verification** -- `flutter analyze lib/`, `flutter build appbundle --release`, emulator test

---

## 6. Validation Architecture

### How to Verify Each Change

#### STORE-01 (targetSdk 35)
```bash
# 1. Build succeeds
flutter build appbundle --release

# 2. Check the merged manifest
cd android && ./gradlew app:processReleaseManifest && cd ..
# Inspect: build/app/intermediates/merged_manifest/release/AndroidManifest.xml
# Verify: targetSdkVersion="35" present

# 3. Visual verification on API 35 emulator
# - AppNavBar renders without overlap
# - FAB positioned correctly
# - Status bar text visible (not hidden behind content)
```

#### CLEAN-01 + CLEAN-02 (Notification Parsing + another_telephony removal)
```bash
# 1. No compile errors
flutter analyze lib/

# 2. No references remain
grep -r "another_telephony" lib/    # Should return nothing
grep -r "notification_transaction_parser" lib/  # Should return nothing

# 3. Package absent from dependency tree
flutter pub deps | grep another_telephony  # Should return nothing
```

#### CLEAN-03 (SCHEDULE_EXACT_ALARM removal)
```bash
# After processReleaseManifest, inspect merged manifest:
grep "SCHEDULE_EXACT_ALARM" build/app/intermediates/merged_manifest/release/AndroidManifest.xml
# Should return nothing

# Notification still works:
# Manual test: enable daily recap in Settings, verify notification fires at scheduled time
```

#### PAYWALL-02 (Billing library functional)
```bash
# 1. Check resolved version
flutter pub outdated | grep in_app_purchase
# in_app_purchase_android should show 0.4.0+10

# 2. No billing-related compile errors
flutter analyze lib/

# 3. Integration test (requires device or emulator with Play Store)
# - App launches without crash
# - SubscriptionService.initialize() completes without exception
# - getProducts() returns empty list (no products configured in Play Console yet) -- not an error
```

#### PAYWALL-04 (Trial duration fix)
```dart
// Unit test:
// 1. Fresh SharedPreferences (no trial_start_date key)
// 2. Call ensureTrialStarted()
// 3. Assert trialDaysRemaining == 7 (not 14)
// 4. Assert isInTrial == true
// 5. Assert hasProAccess == true
// 6. Call ensureTrialStarted() again -- should be no-op
// 7. Manually set trial_start_date to 8 days ago
// 8. Assert trialDaysRemaining == 0
// 9. Assert isInTrial == false
```

#### PAYWALL-05 (Subscription records in Drift)
```bash
# 1. build_runner succeeds
dart run build_runner build --delete-conflicting-outputs

# 2. No analysis issues
flutter analyze lib/

# 3. Fresh install test
# - Delete app data / fresh install
# - App launches without migration error
# - Schema version is 14

# 4. Upgrade test
# - Install previous version (schema 13)
# - Add some transactions
# - Upgrade to new version
# - Verify data intact + subscription_records table exists
```

#### Full Phase 1 Exit Criteria
```bash
# 1. Release build succeeds
flutter build appbundle --release

# 2. Zero analysis issues
flutter analyze lib/

# 3. All tests pass
flutter test

# 4. Merged manifest clean
# - No SCHEDULE_EXACT_ALARM
# - No READ_SMS / RECEIVE_SMS
# - targetSdkVersion = 35
# - another_telephony absent from dependency tree

# 5. Visual verification on API 35 emulator
# - Nav bar renders correctly
# - FAB positioned correctly
# - Daily notification fires at scheduled time
```

---

## Sources

- [in_app_purchase_android changelog (pub.dev)](https://pub.dev/packages/in_app_purchase_android/changelog)
- [in_app_purchase_android all versions (pub.dev)](https://pub.dev/packages/in_app_purchase_android/versions)
- [Google Play Billing Library deprecation FAQ (developer.android.com)](https://developer.android.com/google/play/billing/deprecation-faq)
- [Google Play Billing Library release notes (developer.android.com)](https://developer.android.com/google/play/billing/release-notes)
- [Migrate to Google Play Billing Library 8 (developer.android.com)](https://developer.android.com/google/play/billing/migrate-gpblv8)
- [flutter/flutter#171523 -- Update to BL8 (GitHub)](https://github.com/flutter/flutter/issues/171523)
- [flutter/packages#10816 -- BL8 PR, OPEN (GitHub)](https://github.com/flutter/packages/pull/10816)
- [flutter/flutter#173394 -- BL8 migration product query error (GitHub)](https://github.com/flutter/flutter/issues/173394)
- [Flutter edge-to-edge migration guide (docs.flutter.dev)](https://docs.flutter.dev/release/breaking-changes/default-systemuimode-edge-to-edge)
- [flutter/website#12211 -- Edge-to-edge documentation (GitHub)](https://github.com/flutter/website/issues/12211)
- [flutter/flutter#169746 -- systemNavigationBarColor regression (GitHub)](https://github.com/flutter/flutter/issues/169746)
- [flutter/flutter#90098 -- Streamline edge-to-edge across Android versions (GitHub)](https://github.com/flutter/flutter/issues/90098)
- [flutter_local_notifications-17.2.4 AndroidManifest.xml (local pub cache)](file:///C:/Users/omarw/AppData/Local/Pub/Cache/hosted/pub.dev/flutter_local_notifications-17.2.4/android/src/main/AndroidManifest.xml)
- [another_telephony AndroidManifest.xml (GitHub)](https://github.com/thanhdang198/Telephony)

---

*Research completed: 2026-03-27*
*Phase: 01-compliance-billing-foundation*
