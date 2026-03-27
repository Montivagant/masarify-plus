---
phase: 01-compliance-billing-foundation
plan: 3
subsystem: payments
tags: [in_app_purchase, drift, billing, trial, subscription]

requires:
  - phase: 01-compliance-billing-foundation (plans 1-2)
    provides: SDK 35, manifest cleanup, package cleanup
provides:
  - subscription_records Drift table (v14 schema)
  - SubscriptionRecordDao with upsert/query methods
  - SubscriptionService persists purchases to Drift
  - Trial duration fixed to 7 days
  - Premature trial start removed from main.dart
affects: [phase-5-monetization-onboarding]

tech-stack:
  added: []
  patterns: [drift-dao-upsert-by-token, optional-dao-injection]

key-files:
  created:
    - lib/data/database/tables/subscription_records_table.dart
    - lib/data/database/daos/subscription_record_dao.dart
    - lib/data/database/daos/subscription_record_dao.g.dart
  modified:
    - lib/core/services/subscription_service.dart
    - lib/main.dart
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart
    - lib/data/database/tables/wallets_table.dart
    - lib/shared/providers/subscription_provider.dart

key-decisions:
  - "BL7 (in_app_purchase_android 0.4.0+8) is compliant through Aug 2026 -- no BL8 migration needed"
  - "Optional DAO injection pattern: SubscriptionService accepts recordDao as nullable named parameter, SharedPreferences remains as fallback"
  - "Schema bumped from v11 to v14 (incorporating uncommitted v12/v13 migrations from prior P5 work)"

patterns-established:
  - "Optional DAO injection: services accept nullable DAO for gradual Drift integration"

requirements-completed: [PAYWALL-02, PAYWALL-04, PAYWALL-05]

duration: 13min
completed: 2026-03-27
---

# Phase 1 Plan 3: Billing & Trial Fix Summary

**Verified BL7 billing compliance through Aug 2026, fixed 7-day trial duration, removed premature trial start, created subscription_records Drift table (v14), and wired SubscriptionService to persist purchases to Drift**

## Performance

- **Duration:** 13 min
- **Started:** 2026-03-27T16:50:21Z
- **Completed:** 2026-03-27T17:04:20Z
- **Tasks:** 9 (1 verification-only, 8 code tasks)
- **Files modified:** 10 (3 created, 7 modified)

## Accomplishments
- Verified in_app_purchase_android 0.4.0+8 bundles BL 7.1.1, compliant until Aug 31, 2026 -- no migration needed
- Fixed trial duration from 14 days to 7 days in SubscriptionService
- Removed premature ensureTrialStarted() call from main.dart (deferred to Phase 5 onboarding)
- Created subscription_records Drift table with purchaseToken, productId, purchaseDate, expiryDate, status fields
- Created SubscriptionRecordDao with upsert, getActiveSubscription, updateStatus, and getAll methods
- Bumped DB schema to v14 with proper migration chain (v12: category seeding, v13: wallet sortOrder, v14: subscription_records table)
- Wired SubscriptionService to persist purchase records to Drift via optional DAO injection

## Task Commits

Each task was committed atomically:

1. **Task 1.3.1: Verify billing library BL7 compliance** - verification only, no commit needed
2. **Task 1.3.2: Fix _trialDays from 14 to 7** - `7e0245a` (fix)
3. **Task 1.3.3: Remove ensureTrialStarted() from main.dart** - `e0d07f0` (fix)
4. **Task 1.3.4: Create subscription_records Drift table** - `389e096` (feat)
5. **Task 1.3.5: Create SubscriptionRecordDao** - `5f5ba20` (feat)
6. **Task 1.3.6: Register table and DAO, bump to v14** - `973079a` (feat)
7. **Task 1.3.7: Run build_runner + fix blocking issues** - `02973d0` (feat)
8. **Task 1.3.8: Wire SubscriptionService to Drift** - `4eab162` (feat)
9. **Task 1.3.9: Final verification** - verification only, no commit needed

## Files Created/Modified
- `lib/data/database/tables/subscription_records_table.dart` - New Drift table for IAP purchase records
- `lib/data/database/daos/subscription_record_dao.dart` - DAO with upsert/query/status-update methods
- `lib/data/database/daos/subscription_record_dao.g.dart` - Generated Drift mixin
- `lib/core/services/subscription_service.dart` - Fixed trial to 7 days, added Drift persistence
- `lib/main.dart` - Removed premature ensureTrialStarted() call
- `lib/data/database/app_database.dart` - Schema v14, new table/DAO registration, v12-v14 migrations
- `lib/data/database/app_database.g.dart` - Regenerated Drift code
- `lib/data/database/tables/wallets_table.dart` - Added sortOrder column
- `lib/shared/providers/subscription_provider.dart` - Passes DAO to SubscriptionService

## Decisions Made
- BL7 is sufficient for launch (valid through Aug 31, 2026). No RevenueCat or BL8 migration needed.
- Used optional DAO injection pattern (`{this.recordDao}`) so SubscriptionService works with or without Drift.
- Schema bumped from v11 directly to v14, incorporating the uncommitted v12 (categories) and v13 (sortOrder) migrations from prior P5 work along with the new v14 (subscription_records) migration.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Schema was v11, not v13 as plan assumed**
- **Found during:** Task 1.3.6 (register table in app_database.dart)
- **Issue:** Plan assumed committed schema was v13, but actual committed state was v11. The v12 (category seeding) and v13 (wallet sortOrder) migrations existed only as uncommitted changes in the main worktree.
- **Fix:** Added v12 and v13 migration blocks from the main worktree alongside the new v14 migration, creating a complete migration chain from v11 to v14.
- **Files modified:** lib/data/database/app_database.dart
- **Verification:** `grep "schemaVersion => 14"` returns 1 match; all migration guards present
- **Committed in:** 973079a (Task 1.3.6 commit)

**2. [Rule 3 - Blocking] Missing sortOrder column in wallets_table.dart**
- **Found during:** Task 1.3.7 (build_runner)
- **Issue:** The v13 migration references `wallets.sortOrder` but the column was not in the committed wallets_table.dart (only in the uncommitted main worktree).
- **Fix:** Added `sortOrder` IntColumn to wallets_table.dart.
- **Files modified:** lib/data/database/tables/wallets_table.dart
- **Verification:** `flutter analyze lib/` shows zero new errors after rebuild
- **Committed in:** 02973d0 (Task 1.3.7 commit)

**3. [Rule 1 - Bug] Import ordering lint**
- **Found during:** Task 1.3.7 (flutter analyze)
- **Issue:** `subscription_record_dao.dart` import was placed before `sms_parser_log_dao.dart` (not alphabetical).
- **Fix:** Reordered imports alphabetically.
- **Files modified:** lib/data/database/app_database.dart
- **Verification:** `directives_ordering` lint resolved
- **Committed in:** 02973d0 (Task 1.3.7 commit)

**4. [Rule 1 - Bug] Redundant argument value lint**
- **Found during:** Task 1.3.8 (flutter analyze)
- **Issue:** `status: 'active'` in _persistPurchaseRecord matched the default parameter value.
- **Fix:** Removed the redundant named argument.
- **Files modified:** lib/core/services/subscription_service.dart
- **Verification:** `avoid_redundant_argument_values` lint resolved
- **Committed in:** 4eab162 (Task 1.3.8 commit)

---

**Total deviations:** 4 auto-fixed (2 blocking, 2 bug)
**Impact on plan:** All fixes were necessary for compilation and lint compliance. No scope creep. The v12/v13 migration incorporation was unavoidable given the divergence between committed and uncommitted state.

## Issues Encountered

- **Pre-existing env.dart errors:** 3 analyzer errors in `lib/core/config/ai_config.dart` (missing `env.dart` file, undefined `Env` name) exist in the committed codebase and are unrelated to this plan. These prevented the release build verification step (`flutter build appbundle --release`). All other verifications (analyze for new issues, tests) passed.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Phase 1 is now complete (all 3 plans executed)
- Billing infrastructure verified and wired
- Ready for Phase 2: Verification Sweep (all P5 features need testing)
- The env.dart issue in ai_config.dart should be resolved before Phase 2 to enable clean analyzer runs

---
*Phase: 01-compliance-billing-foundation*
*Completed: 2026-03-27*
