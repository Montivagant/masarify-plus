# Phase 1: Compliance & Billing Foundation - Context

**Gathered:** 2026-03-27 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Resolve every known Play Store rejection trigger and confirm the billing library is functional — before touching any UI or feature code. Requirements: STORE-01, CLEAN-01, CLEAN-02, CLEAN-03, PAYWALL-02, PAYWALL-04, PAYWALL-05.

</domain>

<decisions>
## Implementation Decisions

### SDK & Edge-to-Edge
- **D-01:** Bump `targetSdk` from 34 to 35 in `android/app/build.gradle.kts` line 36. `compileSdk` is already 36 via Flutter — no change needed.
- **D-02:** Test edge-to-edge display on API 35 emulator. Focus on `AppNavBar` (glassmorphic, BackdropFilter) and center-docked FAB for inset/padding overlap.
- **D-03:** If edge-to-edge causes overlap, fix with `SystemUiMode` and `ViewPadding` adjustments — do NOT revert targetSdk.

### Permission Cleanup
- **D-04:** Remove `SCHEDULE_EXACT_ALARM` from `AndroidManifest.xml` via `tools:node="remove"`. The app already uses `AndroidScheduleMode.inexactAllowWhileIdle` in `NotificationService.scheduleDaily()` line 129.
- **D-05:** Keep `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` — actively used by `LocationService` for optional transaction location tagging.
- **D-06:** Run `./gradlew app:processReleaseManifest` and inspect merged manifest for transitive permissions from `flutter_local_notifications`.

### Package Dependencies
- **D-07:** Remove `another_telephony: ^0.4.1` from `pubspec.yaml` line 87. Clean all 3 import sites: `settings_screen.dart` line 3, `sms_parser_service.dart` line 5, and any other references.
- **D-08:** Keep `geolocator: ^13.0.1` and `geocoding: ^3.0.0` — actively used by `LocationService`.
- **D-09:** Add `GoogleFonts.config.allowRuntimeFetching = false` in `lib/main.dart` before `runApp()` — critical for offline-first.
- **D-10:** Delete dead code file `lib/core/services/notification_transaction_parser.dart`.

### Billing Library
- **D-11:** Check `in_app_purchase_android` BL version via pub.dev changelog. If BL8 not supported by current version, evaluate: (a) native dependency override in `build.gradle.kts`, (b) migrate to `purchases_flutter` (RevenueCat free tier), (c) update to latest `in_app_purchase` if BL8 support was added.
- **D-12:** Decision on BL migration path depends on external research — Claude's discretion on approach, but BL8 compatibility MUST be confirmed before Phase 1 exits.

### Trial & Subscription Storage
- **D-13:** Fix `_trialDays = 14` to `_trialDays = 7` in `subscription_service.dart` line 28. The official trial duration is **7 days**.
- **D-14:** Remove `unawaited(subService.ensureTrialStarted())` from `main.dart` line 81. The method must NOT be called on every app launch. Phase 5 will wire the single call site in `OnboardingScreen._finish()`.
- **D-15:** Create a `subscription_records` Drift table with columns: `id`, `purchaseToken`, `productId`, `expiryDate`, `purchaseDate`, `status`. Add migration v13→v14. Wire `SubscriptionService` to persist to this table instead of SharedPreferences-only.
- **D-16:** Verify `ensureTrialStarted()` method logic is correct when called once — it should write trial start date and return correct `trialDaysRemaining`.

### Settings Cleanup
- **D-17:** The "Notification Parsing" / "Smart Detection" section in `settings_screen.dart` (lines 721-731) is already hidden via `kSmsEnabled = false`. However, the `another_telephony` import on line 3 will break compilation when the package is removed. Fix: remove the import and the entire guarded code block.
- **D-18:** Clean any l10n strings related to notification parsing / SMS that are no longer referenced.

### Claude's Discretion
- Exact Drift migration strategy for `subscription_records` table (v14)
- Whether to use `tools:node="remove"` or direct deletion for SCHEDULE_EXACT_ALARM
- BL8 migration approach (native override vs RevenueCat vs plugin update) — based on research findings
- Cleanup of any orphaned SMS-related files beyond `notification_transaction_parser.dart`

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Build & Manifest
- `android/app/build.gradle.kts` — targetSdk (line 36), compileSdk (line 20)
- `android/app/src/main/AndroidManifest.xml` — permissions, tools:node="remove" declarations

### Billing & Subscription
- `lib/core/services/subscription_service.dart` — trial logic, _trialDays, ensureTrialStarted(), SharedPreferences storage
- `pubspec.yaml` — in_app_purchase version (line ~60), another_telephony (line 87)
- `pubspec.lock` — in_app_purchase_android resolved version

### Notification & Alarm
- `lib/core/services/notification_service.dart` — scheduleDaily(), AndroidScheduleMode usage (line 129)

### Settings & Cleanup
- `lib/features/settings/presentation/screens/settings_screen.dart` — SMS section (lines 721-731), another_telephony import (line 3)
- `lib/core/services/notification_transaction_parser.dart` — dead code, delete entirely

### Database
- `lib/data/database/app_database.dart` — 13-table schema, migration chain, @DriftDatabase annotation (lines 32-47)

### Startup
- `lib/main.dart` — startup sequence, ensureTrialStarted() call (line 81), GoogleFonts config location

### Research
- `.planning/research/STACK.md` — BL8 deadline, targetSdk requirements, app size optimization
- `.planning/research/PITFALLS.md` — SCHEDULE_EXACT_ALARM risk, merged manifest audit

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SubscriptionService` already has `ensureTrialStarted()`, `hasProAccess`, `trialDaysRemaining` — just needs fixing, not rewriting
- `AppConfig.kSmsEnabled` flag pattern can be referenced for how feature flags work in this codebase
- Drift migration pattern is well-established (v1→v13) — adding v14 follows the same `onUpgrade` switch-case pattern

### Established Patterns
- `tools:node="remove"` in AndroidManifest.xml — already used for SMS permissions, same pattern for SCHEDULE_EXACT_ALARM
- `unawaited()` calls in `main.dart` — startup sequence uses this for non-blocking initialization
- Database tables defined in `lib/data/database/tables/` with `@DataClassName` annotation

### Integration Points
- `SubscriptionService` → `SharedPreferences` (current) → needs new path to Drift DAO
- `main.dart` startup → `SubscriptionService.ensureTrialStarted()` (remove this call)
- `settings_screen.dart` → `another_telephony` import (must be cleaned when package removed)
- `build_runner` must be run after adding new Drift table

</code_context>

<specifics>
## Specific Ideas

- Trial duration is **7 days** (not 14) — user confirmed this decision
- BL8 compliance is the highest-risk unknown — external research needed
- When removing `another_telephony`, also clean any test files that import it

</specifics>

<deferred>
## Deferred Ideas

None — analysis stayed within phase scope

</deferred>

---

*Phase: 01-compliance-billing-foundation*
*Context gathered: 2026-03-27*
