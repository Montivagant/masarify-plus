---
phase: quick
plan: 260328-p3k
subsystem: notifications, backup, settings
tags: [flutter_local_notifications, shared_preferences, drift, android-manifest, backup, quiet-hours]

requires:
  - phase: quick/260328-omm
    provides: "Prior audit bug fixes H-1 through H-8"
provides:
  - "Quiet hours enforcement in NotificationService.show()"
  - "Bill reminder preference check in RecurringScheduler"
  - "Boot-completed receiver for scheduled notification survival"
  - "Android 13+ POST_NOTIFICATIONS permission gating on all toggles"
  - "(Coming Soon) suffix on stub notification toggles"
  - "sortOrder preserved in wallet backup export/import"
  - "Transactional export for consistent backup snapshots"
  - "subscription_records included in clearAllData (14 tables)"
affects: [notifications, backup, settings, recurring-scheduler]

tech-stack:
  added: []
  patterns:
    - "Quiet hours check pattern: SharedPreferences read at notification dispatch time"
    - "Permission gating pattern: request permission on first toggle enable, revert on denial"

key-files:
  created: []
  modified:
    - lib/core/services/notification_service.dart
    - lib/core/services/recurring_scheduler.dart
    - lib/features/settings/presentation/screens/notification_preferences_screen.dart
    - lib/features/settings/presentation/screens/settings_screen.dart
    - lib/data/services/backup_service_impl.dart
    - android/app/src/main/AndroidManifest.xml
    - lib/l10n/app_en.arb
    - lib/l10n/app_ar.arb

key-decisions:
  - "Quiet hours use fail-open pattern: if SharedPreferences read fails, notification fires anyway"
  - "Permission check on every toggle enable (not just first) to handle revoked permissions"
  - "sortOrder defaults to 0 for older backups that lack the field"

patterns-established:
  - "Notification permission gating: check before enabling any notification toggle"
  - "Fail-open notification dispatch: prefs errors allow notifications through"

requirements-completed: [H-9, H-10, H-11, H-12, H-13, H-14, H-15, H-16]

duration: 6min
completed: 2026-03-28
---

# Quick Task 260328-p3k: Fix High-Priority Audit Bugs Wave B (H-9 through H-16) Summary

**Notification system integrity (quiet hours, permission gating, boot survival) and backup data consistency (sortOrder, transactional export, 14-table clear)**

## Performance

- **Duration:** 6 min
- **Started:** 2026-03-28T16:08:00Z
- **Completed:** 2026-03-28T16:14:00Z
- **Tasks:** 2
- **Files modified:** 11 (8 source + 3 generated l10n)

## Accomplishments
- Notification toggles for budget warning, budget exceeded, and goal milestone now show "(Coming Soon)" suffix to communicate stub status
- NotificationService.show() enforces quiet hours window, suppressing notifications during user-defined hours
- RecurringScheduler bill reminders respect the bill reminder notification preference toggle
- Android 13+ POST_NOTIFICATIONS permission is requested when user first enables any notification toggle; denied = toggle reverts with error snackbar
- AndroidManifest registers ScheduledNotificationBootReceiver so scheduled notifications survive device reboot
- Wallet sortOrder is preserved through backup export/import cycle
- exportToJson() wraps all SELECT queries in a DB transaction for a consistent read snapshot
- clearAllData() now deletes all 14 tables including subscription_records

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix notification system bugs (H-9, H-10, H-11, H-13, H-14)** - `1c257f0` (fix)
2. **Task 2: Fix backup and data-clearing bugs (H-12, H-15, H-16)** - `0b643a5` (fix)

## Files Created/Modified
- `lib/core/services/notification_service.dart` - Added quiet hours enforcement in show()
- `lib/core/services/recurring_scheduler.dart` - Added bill reminder preference check in _fireReminder()
- `lib/features/settings/presentation/screens/notification_preferences_screen.dart` - "(Coming Soon)" suffix on 3 toggles, permission gating on all 7 toggles
- `lib/features/settings/presentation/screens/settings_screen.dart` - subscription_records in clearAllData, 14-table comment
- `lib/data/services/backup_service_impl.dart` - sortOrder in wallet serialization, transactional export
- `android/app/src/main/AndroidManifest.xml` - ScheduledNotificationBootReceiver registration
- `lib/l10n/app_en.arb` - notif_coming_soon, notif_permission_denied keys
- `lib/l10n/app_ar.arb` - notif_coming_soon, notif_permission_denied keys (Arabic)
- `lib/l10n/app_localizations.dart` - regenerated
- `lib/l10n/app_localizations_en.dart` - regenerated
- `lib/l10n/app_localizations_ar.dart` - regenerated

## Decisions Made
- Quiet hours use fail-open pattern: if SharedPreferences read fails, notification fires anyway (better to over-notify than silently fail)
- Permission check runs on every toggle enable, not just the first, to handle cases where user revokes permission between toggles
- sortOrder defaults to 0 for older backups that lack the field, ensuring backward compatibility

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None - all changes are complete implementations, not placeholders.

## User Setup Required

None - no external service configuration required.

## Verification

```
flutter analyze lib/ -> No issues found!
```

## Self-Check: PASSED

All files exist, both commits verified.

---
*Quick Task: 260328-p3k*
*Completed: 2026-03-28*
