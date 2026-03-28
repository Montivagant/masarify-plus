---
phase: quick
plan: 260328-pwv
subsystem: export, settings, notifications, PDF
tags: [audit-bugs, medium-priority, CSV, PDF, settings, notifications]
dependency_graph:
  requires: []
  provides: [csv-transfer-export, localized-csv-headers, utf8-bom-csv, theme-mode-picker, first-day-of-month-provider, arabic-pdf-font, drive-file-id-persist, post-restore-subscription-revalidation, cold-start-notification-routing]
  affects: [backup_service_impl, backup_export_screen, settings_screen, preferences_provider, pdf_export_service, notification_service, main]
tech_stack:
  added: []
  patterns: [font-asset-loading, notification-launch-detection]
key_files:
  created:
    - assets/fonts/.gitkeep
  modified:
    - lib/core/services/backup_service.dart
    - lib/data/services/backup_service_impl.dart
    - lib/features/settings/presentation/screens/backup_export_screen.dart
    - lib/features/settings/presentation/screens/settings_screen.dart
    - lib/shared/providers/preferences_provider.dart
    - lib/data/services/pdf_export_service.dart
    - lib/core/services/notification_service.dart
    - lib/main.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ar.arb
    - pubspec.yaml
decisions:
  - Used restorePurchases() instead of plan-specified revalidate() (M-17) since that is the actual API
  - Arabic PDF font loaded from assets/fonts/ with graceful fallback if TTF not bundled yet
  - Cold-start notification routing delayed 500ms to let router initialize after splash
metrics:
  duration: 14m 25s
  completed: "2026-03-28T16:58:45Z"
  tasks: 3/3
  files: 12
---

# Quick Task 260328-pwv: Fix Medium-Priority Audit Bugs Wave B (M-11 through M-19)

CSV export with transfers and localized headers, theme mode picker in settings, Arabic PDF font support, Drive file ID persistence, post-restore subscription revalidation, cold-start notification routing.

## Task Summary

| # | Task | Commit | Key Changes |
|---|------|--------|-------------|
| 1 | CSV export fixes (M-11, M-12, M-19) | d7ed9fd | Transfers in CSV, localized headers, UTF-8 BOM |
| 2 | Settings reactivity (M-13, M-16) | 7853d0d | Theme mode picker, firstDayOfMonthProvider |
| 3 | PDF Arabic, Drive ID, restore revalidation, cold-start notif (M-14, M-15, M-17, M-18) | 767925d | Arabic font loading, Drive fileId persist, restorePurchases after restore, getLaunchPayload |

## Bug Fix Details

### M-11: Include transfers in CSV export
- Query `transfers` table for same date range as transactions
- Build transfer rows with "fromWallet -> toWallet" title, type "transfer", fee in notes
- Sort all rows chronologically for interleaved output

### M-12: Localized CSV headers
- Added optional `headers` parameter to `BackupService.exportTransactionsToCsv()`
- 11 new l10n keys: `csv_header_date` through `csv_header_notes` in both EN and AR
- `backup_export_screen.dart` passes localized headers from `context.l10n`

### M-13: Theme mode picker in Settings
- Added `_SettingsTile` for theme in Appearance section (before Language)
- Bottom sheet with Light/Dark/System options matching existing picker pattern
- Uses `ref.watch(themeModeProvider)` for reactive display

### M-14: Arabic-capable font for PDF
- Static font cache with `_loadArabicFont()` loading from `assets/fonts/NotoSansArabic-Regular.ttf`
- Graceful fallback to default font if TTF not bundled (Arabic shows as boxes but no crash)
- RTL `textDirection` on `pw.MultiPage` when locale is 'ar'
- Added `assets/fonts/` to pubspec.yaml with TODO comment for font download

### M-15: Save Drive file ID after upload
- Capture return value from `driveService.uploadBackup(jsonData)`
- Call `prefs.setDriveFileId(fileId)` after successful upload

### M-16: Reactive firstDayOfMonth provider
- Created `firstDayOfMonthProvider` (FutureProvider<int>) in preferences_provider.dart
- Settings `_setFirstDayOfMonth()` now calls `ref.invalidate(firstDayOfMonthProvider)`

### M-17: Post-restore subscription revalidation
- Both `_restoreJson()` and `_restoreFromDrive()` call `subscriptionServiceProvider.restorePurchases()` after import
- Used `restorePurchases()` (actual API) instead of plan-specified `revalidate()` (does not exist)

### M-18: Cold-start notification routing
- Added `NotificationService.getLaunchPayload()` static method using `getNotificationAppLaunchDetails()`
- `main.dart` checks launch payload after runApp, routes to chat (recap) or recurring screen
- 500ms delay to allow router initialization after splash

### M-19: UTF-8 BOM for Excel compatibility
- Prepend `\uFEFF` to CSV output before writing to file
- Ensures Arabic text renders correctly when opened in Excel on Windows

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SubscriptionService.revalidate() does not exist**
- **Found during:** Task 3 (M-17)
- **Issue:** Plan specified `subscriptionService.revalidate()` but actual API is `restorePurchases()`
- **Fix:** Used `restorePurchases()` which resets Pro status and queries Play Store for valid purchases
- **Files modified:** backup_export_screen.dart
- **Commit:** 767925d

**2. [Rule 1 - Bug] Trailing comma lint warnings in backup_service_impl.dart**
- **Found during:** Task 1 verification
- **Issue:** Record tuple literals missing required trailing commas
- **Fix:** Added trailing commas to `dataRows.add((...))` calls
- **Files modified:** backup_service_impl.dart
- **Commit:** d7ed9fd

**3. [Rule 1 - Bug] BuildContext used across async gap in _exportCsv**
- **Found during:** Task 1 verification
- **Issue:** `context.l10n` accessed after await on `_pickMonth()`
- **Fix:** Captured `l10n` before first await
- **Files modified:** backup_export_screen.dart
- **Commit:** d7ed9fd

## Known Stubs

| File | Line | Stub | Reason |
|------|------|------|--------|
| `lib/data/services/pdf_export_service.dart` | ~51 | TODO: NotoSansArabic-Regular.ttf not bundled | Font file must be downloaded from Google Fonts and placed at `assets/fonts/NotoSansArabic-Regular.ttf`. Code gracefully falls back to default font. |

## Verification

- `flutter analyze lib/` -- zero issues (env.dart stub created for worktree)
- CSV export queries both transactions and transfers tables
- CSV output begins with \uFEFF BOM character
- Settings screen shows theme picker in Appearance section
- `firstDayOfMonthProvider` exported from preferences_provider.dart
- PdfExportService handles Arabic locale with custom font + RTL direction
- backup_export_screen.dart captures and saves Drive file ID
- Both restore flows call subscriptionService.restorePurchases()
- main.dart checks getNotificationAppLaunchDetails on startup

## Self-Check: PASSED

- All 10 modified/created files exist on disk
- All 3 task commits (d7ed9fd, 7853d0d, 767925d) found in git log
- `flutter analyze lib/` reports zero issues
