---
phase: 01-compliance-billing-foundation
plan: 02
subsystem: compliance
tags: [sms-cleanup, another-telephony, l10n, settings, play-store]

requires:
  - phase: none
    provides: n/a
provides:
  - another_telephony package removed from dependency tree
  - SMS-related UI, state, and l10n strings cleaned from settings screen
  - SmsParserService stubbed (returns 0, constructor preserved)
  - Clean compilation (zero new analyzer issues)
affects: [phase-02-verification-sweep, phase-05-monetization]

tech-stack:
  added: []
  patterns:
    - "Stub disabled service methods instead of deleting classes (preserve re-enablement path)"

key-files:
  created: []
  modified:
    - pubspec.yaml
    - pubspec.lock
    - lib/core/services/sms_parser_service.dart
    - lib/features/settings/presentation/screens/settings_screen.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ar.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_en.dart
    - lib/l10n/app_localizations_ar.dart

key-decisions:
  - "Kept notification_transaction_parser.dart — it has no telephony dependency and is referenced by parser_review_screen.dart (still routed in app_router.dart)"
  - "Simplified SmsParserService constructor to single positional parameter instead of keeping unused named params"

patterns-established:
  - "Feature-flagged dead code: stub method body, keep class shell for future re-enablement"

requirements-completed: [CLEAN-01, CLEAN-02]

duration: 16min
completed: 2026-03-27
---

# Phase 1 Plan 2: Package & Settings Cleanup Summary

**Removed `another_telephony` SMS package, cleaned all import sites, stubbed SmsParserService, and removed 6 orphaned l10n strings from both locales**

## Performance

- **Duration:** 16 min
- **Started:** 2026-03-27T16:27:28Z
- **Completed:** 2026-03-27T16:43:29Z
- **Tasks:** 6 (5 executed, 1 modified)
- **Files modified:** 9

## Accomplishments
- `another_telephony` fully removed from pubspec.yaml and pubspec.lock — no SMS package in dependency tree
- Settings screen cleaned: removed Telephony import, SMS state fields, toggle/permission methods, Smart Detection UI section, and orphaned icon widget
- SmsParserService stubbed to return 0 immediately — class shell preserved for Pro tier re-enablement
- 6 SMS-related l10n keys removed from both app_en.arb and app_ar.arb, l10n regenerated
- `flutter analyze lib/` shows only pre-existing env.dart errors (not introduced by this plan)

## Task Commits

Each task was committed atomically:

1. **Task 1.2.1: Remove another_telephony from pubspec.yaml** - `0e813a8` (chore)
2. **Task 1.2.2: Clean settings_screen.dart** - `e963e9a` (fix)
3. **Task 1.2.3: Stub sms_parser_service.dart** - `d10d269` (fix)
4. **Task 1.2.4: Delete notification_transaction_parser.dart** - SKIPPED (see Deviations)
5. **Task 1.2.5: Clean orphaned SMS l10n strings** - `f326ef2` (fix)
6. **Task 1.2.6: Verify and fix remaining analyzer issues** - `d79715c` (fix)

## Files Created/Modified
- `pubspec.yaml` - Removed another_telephony dependency line
- `pubspec.lock` - Auto-updated by flutter pub get
- `lib/core/services/sms_parser_service.dart` - Stubbed scanInbox(), removed all telephony imports
- `lib/features/settings/presentation/screens/settings_screen.dart` - Removed SMS imports, state, methods, UI section, and orphaned widget
- `lib/l10n/app_en.arb` - Removed 6 SMS-related keys
- `lib/l10n/app_ar.arb` - Removed 6 SMS-related keys
- `lib/l10n/app_localizations*.dart` - Regenerated (auto-generated files)

## Decisions Made
- Kept `notification_transaction_parser.dart` instead of deleting it — the file has zero dependency on `another_telephony` (uses only `dart:convert` and `package:crypto`), and is actively referenced by `parser_review_screen.dart` which is still routed in `app_router.dart`. Deleting it would break compilation.
- Simplified `SmsParserService` constructor to a single positional `SmsParserLogDao` parameter (no longer stores unused named params) since the method body is stubbed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Kept notification_transaction_parser.dart instead of deleting**
- **Found during:** Task 1.2.4 (Delete notification_transaction_parser.dart)
- **Issue:** Plan specified deleting this file, but it has no `another_telephony` dependency and is referenced by `parser_review_screen.dart` (6 call sites) which is still routed in `app_router.dart`. Deleting would cause compilation failure.
- **Fix:** Retained the file. Cleaned its import from `sms_parser_service.dart` in Task 1.2.3 as planned.
- **Files modified:** None (file kept as-is)
- **Verification:** `flutter analyze lib/` compiles without errors

**2. [Rule 1 - Bug] Restored dart:io import in settings_screen.dart**
- **Found during:** Task 1.2.6 (Verification)
- **Issue:** Initially removed `dart:io` thinking it was only used by SMS code, but `_clearAllData` uses `File()` from dart:io
- **Fix:** Restored `import 'dart:io';`
- **Files modified:** `lib/features/settings/presentation/screens/settings_screen.dart`
- **Verification:** `flutter analyze` no longer shows `undefined_method 'File'` error

**3. [Rule 1 - Bug] Removed orphaned _SettingsIconBox widget**
- **Found during:** Task 1.2.6 (Verification)
- **Issue:** `_SettingsIconBox` was only used by the deleted SMS SwitchListTile — became unreferenced dead code
- **Fix:** Deleted the widget class
- **Files modified:** `lib/features/settings/presentation/screens/settings_screen.dart`
- **Verification:** `flutter analyze` no longer shows `unused_element` warning

**4. [Rule 1 - Bug] Removed orphaned crash_log_service.dart import**
- **Found during:** Task 1.2.6 (Verification)
- **Issue:** `CrashLogService` was only used in the deleted `_toggleSmsParser` and `_finishSmsPermission` methods
- **Fix:** Removed the import line
- **Files modified:** `lib/features/settings/presentation/screens/settings_screen.dart`
- **Verification:** `flutter analyze` no longer shows `unused_import` warning

---

**Total deviations:** 4 auto-fixed (4 Rule 1 bugs)
**Impact on plan:** All auto-fixes necessary for correctness. Task 1.2.4 (file deletion) was correctly skipped to prevent compilation failure. No scope creep.

## Issues Encountered
- Pre-existing `env.dart` errors in `ai_config.dart` (3 errors) — these exist on the base branch and are caused by a gitignored secrets file. Not related to this plan's changes.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Ready for Plan 3 (Billing Library Verification & Purchase Token Storage)
- The `another_telephony` package is fully removed; merged AndroidManifest will no longer request SMS permissions from this dependency
- Settings screen compiles cleanly with all SMS UI removed

---
*Phase: 01-compliance-billing-foundation*
*Completed: 2026-03-27*
