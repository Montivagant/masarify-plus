---
phase: quick
plan: 260328-nv1
subsystem: core
tags: [bugfix, audit, backup, subscription, notification, database]
dependency_graph:
  requires: []
  provides: [mounted-check-fix, pro-status-guard, notification-routing, backup-schema-v14]
  affects: [backup_export_screen, subscription_service, app, main, backup_service_impl, notification_service, app_database]
tech_stack:
  added: []
  patterns: [isRestoring-guard, splash-reinitialization, notification-deep-link]
key_files:
  created:
    - lib/data/database/tables/subscription_records_table.dart
    - lib/data/database/daos/subscription_record_dao.dart
    - lib/data/database/daos/subscription_record_dao.g.dart
  modified:
    - lib/features/settings/presentation/screens/backup_export_screen.dart
    - lib/core/services/subscription_service.dart
    - lib/app/app.dart
    - lib/main.dart
    - lib/data/services/backup_service_impl.dart
    - lib/data/database/app_database.dart
    - lib/data/database/app_database.g.dart
    - lib/data/database/tables/wallets_table.dart
    - lib/core/services/notification_service.dart
decisions:
  - "C-3: Added _silentRestore method to app.dart on resume (method did not exist in worktree)"
  - "Synced DB schema to v14 with SubscriptionRecords table and migrations v12-v14 (worktree was at v11)"
  - "Updated NotificationService from main repo to include onNotificationTap, scheduleDaily, scheduleOnce"
metrics:
  duration_seconds: 749
  completed_date: "2026-03-28T15:28:38Z"
---

# Quick Task 260328-nv1: Fix 7 Critical Audit Bugs (C-1 through C-7) Summary

**One-liner:** Mounted check after double-await, Pro status flicker guard with isRestoring flag, PIN lock restore race condition guard, notification deep-link routing, and backup schema v14 with subscription_records table.

## Tasks Completed

| Task | Name | Commit | Key Changes |
|------|------|--------|-------------|
| 1 | C-1 mounted check, C-6 stale UI, C-7 encryption warning | `853fe88` | Added mounted check after second await in _checkDriveStatus; both restore paths navigate to splash for full re-init; C-7 verified as already present |
| 2 | C-2 Pro status flicker, C-3 PIN lock restore race | `4cdbad1` | Added _isRestoring flag to SubscriptionService; removed preemptive setBool(false); hasProAccess returns cached during restore; added _silentRestore with PIN lock guard |
| 3 | C-4 notification tap routing, C-5 backup schema v14 | `8c57691` | Wired NotificationService.onNotificationTap in main.dart; bumped backup _schemaVersion to 14; added subscription_records to export/import/clear/validation |

## Bug Fix Details

### C-1: Missing mounted check in _checkDriveStatus
- **File:** `backup_export_screen.dart`
- **Issue:** setState called after second await without mounted check
- **Fix:** Added `if (!mounted) return;` between preferences await and setState

### C-2: Pro status reset during restore
- **File:** `subscription_service.dart`
- **Issue:** `_restorePurchases()` set `_kProActive = false` before IAP stream settled, causing Pro UI flicker
- **Fix:** Added `_isRestoring` flag, removed preemptive false reset, `hasProAccess` returns cached `isPro` during restore

### C-3: Race condition - app resume + PIN lock + restore
- **File:** `app.dart`
- **Issue:** Subscription restore could fire while PIN lock screen is active
- **Fix:** Added `_silentRestore()` method called on resume with `AppLockService` guard

### C-4: Notification tap callback dead (never wired)
- **File:** `main.dart`, `notification_service.dart`
- **Issue:** `NotificationService.onNotificationTap` was never assigned, so notification taps were no-ops
- **Fix:** Wired callback in main.dart: "recap" payload routes to chat, "recurring:" routes to recurring screen

### C-5: Backup schema missing subscription_records
- **File:** `backup_service_impl.dart`, `app_database.dart`
- **Issue:** `_schemaVersion` was 11, subscription_records table not included in export/import/clear/validation
- **Fix:** Bumped to v14, added subscription_records to all 4 backup operations with proper mapper functions

### C-6: Stale UI after backup restore
- **File:** `backup_export_screen.dart`
- **Issue:** After importFromJson(), providers still held stale data from old database
- **Fix:** Both `_restoreJson()` and `_restoreFromDrive()` now navigate to splash for full re-initialization

### C-7: Encryption warning (no-op)
- **File:** N/A
- **Issue:** Already present -- `backup_encryption_warning` l10n key exists and is displayed in build method
- **Fix:** Verified as already implemented, no changes needed

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree DB schema at v11, needed v14 for SubscriptionRecords**
- **Found during:** Task 3
- **Issue:** The worktree branched before SubscriptionRecords table was added. `_db.subscriptionRecords` would not compile.
- **Fix:** Copied subscription_records_table.dart, subscription_record_dao.dart, .g.dart files from main repo. Updated app_database.dart with SubscriptionRecords table, SubscriptionRecordDao, and v12-v14 migrations. Added wallets.sortOrder column (required by generated code).
- **Files modified:** app_database.dart, wallets_table.dart, + 3 new files
- **Commit:** `8c57691`

**2. [Rule 3 - Blocking] NotificationService missing onNotificationTap in worktree**
- **Found during:** Task 3
- **Issue:** Worktree's NotificationService lacked the `onNotificationTap` static callback, `_onResponse` handler, and scheduling methods that existed in main repo.
- **Fix:** Replaced worktree's notification_service.dart with main repo version (includes tap callback, scheduleDaily, scheduleOnce, cancelScheduled).
- **Files modified:** notification_service.dart
- **Commit:** `8c57691`

**3. [Rule 3 - Blocking] Missing env.dart stub**
- **Found during:** Full analyze verification
- **Issue:** `env.dart` is gitignored, worktree didn't have it, causing 3 analyzer errors in ai_config.dart.
- **Fix:** Created env.dart from main repo (uses String.fromEnvironment for dart-define injection).
- **Files modified:** env.dart (gitignored, not committed)

**4. [Rule 2 - Missing functionality] _silentRestore method did not exist**
- **Found during:** Task 2
- **Issue:** Plan referenced `_silentRestore()` in app.dart but the method didn't exist in the worktree. The subscription revalidation on app resume was not implemented.
- **Fix:** Created the method with PIN lock guard and wired it to `didChangeAppLifecycleState(resumed)`.
- **Files modified:** app.dart
- **Commit:** `4cdbad1`

## Verification

- `flutter analyze lib/` -- **No issues found** (zero errors, zero warnings, zero infos on committed code)
- C-1: Confirmed mounted check after every await in _checkDriveStatus
- C-2: Confirmed _isRestoring flag, no preemptive false reset in _restorePurchases
- C-3: Confirmed AppLockService guard in _silentRestore
- C-4: Confirmed NotificationService.onNotificationTap assigned in main.dart
- C-5: Confirmed _schemaVersion=14, subscription_records in export, import, clear, and validation
- C-6: Confirmed context.go(AppRoutes.splash) in both _restoreJson and _restoreFromDrive
- C-7: Confirmed backup_encryption_warning displayed at line 544 (no change needed)

## Known Stubs

None -- all fixes are complete implementations with no placeholder logic.

## Self-Check: PASSED

- All 9 modified/created files exist on disk
- All 3 task commits (853fe88, 4cdbad1, 8c57691) found in git log
- `flutter analyze lib/` returns zero issues
