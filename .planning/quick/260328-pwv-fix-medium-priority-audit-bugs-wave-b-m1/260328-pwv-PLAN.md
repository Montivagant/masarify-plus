---
phase: quick
plan: 260328-pwv
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/data/services/backup_service_impl.dart
  - lib/core/services/backup_service.dart
  - lib/features/settings/presentation/screens/backup_export_screen.dart
  - lib/features/settings/presentation/screens/settings_screen.dart
  - lib/shared/providers/preferences_provider.dart
  - lib/data/services/pdf_export_service.dart
  - lib/core/services/notification_service.dart
  - lib/main.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ar.arb
autonomous: true
requirements: [M-11, M-12, M-13, M-14, M-15, M-16, M-17, M-18, M-19]
must_haves:
  truths:
    - "CSV export includes transfer records with from/to wallet names"
    - "CSV headers respect current app locale"
    - "CSV opens correctly in Excel on Windows (Arabic text not garbled)"
    - "Settings screen has theme mode picker (Light/Dark/System)"
    - "Changing first day of month in settings propagates without cold restart"
    - "PDF report renders Arabic glyphs correctly"
    - "Drive file ID is saved after upload for future reference"
    - "After DB restore, subscription state is revalidated"
    - "Cold-start from notification taps routes to the correct screen"
  artifacts:
    - path: "lib/data/services/backup_service_impl.dart"
      provides: "CSV with transfers, localized headers, UTF-8 BOM"
    - path: "lib/features/settings/presentation/screens/settings_screen.dart"
      provides: "Theme mode picker row in Appearance section"
    - path: "lib/shared/providers/preferences_provider.dart"
      provides: "firstDayOfMonthProvider reactive provider"
    - path: "lib/data/services/pdf_export_service.dart"
      provides: "Arabic-capable font loading for PDF"
    - path: "lib/main.dart"
      provides: "Cold-start notification payload check"
  key_links:
    - from: "settings_screen.dart"
      to: "theme_provider.dart"
      via: "themeModeProvider watch + setMode()"
      pattern: "ref\\.watch\\(themeModeProvider\\)"
    - from: "settings_screen.dart"
      to: "preferences_provider.dart"
      via: "firstDayOfMonthProvider invalidation"
      pattern: "ref\\.invalidate\\(firstDayOfMonthProvider\\)"
    - from: "backup_export_screen.dart"
      to: "backup_service_impl.dart"
      via: "exportTransactionsToCsv with headers param"
      pattern: "exportTransactionsToCsv"
---

<objective>
Fix 9 medium-priority audit bugs (M-11 through M-19) covering CSV export completeness, settings reactivity, PDF Arabic support, Drive backup state persistence, post-restore subscription reconciliation, and cold-start notification routing.

Purpose: Resolve remaining medium-severity issues from the comprehensive audit to improve export quality, settings UX, and startup robustness.
Output: All 9 bugs fixed across 8 source files + 2 l10n files.
</objective>

<execution_context>
@D:/Masarify-Plus/.claude/get-shit-done/workflows/execute-plan.md
@D:/Masarify-Plus/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@lib/data/services/backup_service_impl.dart
@lib/core/services/backup_service.dart
@lib/features/settings/presentation/screens/backup_export_screen.dart
@lib/features/settings/presentation/screens/settings_screen.dart
@lib/shared/providers/preferences_provider.dart
@lib/shared/providers/theme_provider.dart
@lib/data/services/pdf_export_service.dart
@lib/core/services/notification_service.dart
@lib/core/services/preferences_service.dart
@lib/main.dart
@lib/l10n/app_en.arb
@lib/l10n/app_ar.arb

<interfaces>
<!-- From lib/shared/providers/theme_provider.dart -->
```dart
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) { ... });

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  Future<void> setMode(ThemeMode mode) async { ... }
}
```

<!-- From lib/core/services/preferences_service.dart -->
```dart
class PreferencesService {
  int get firstDayOfMonth;
  Future<void> setFirstDayOfMonth(int day);
  Future<void> setDriveFileId(String? id);
  String? get driveFileId;
}
```

<!-- From lib/core/services/google_drive_backup_service.dart -->
```dart
Future<String> uploadBackup(String jsonData) async { ... } // Returns file ID
```

<!-- From lib/core/services/subscription_service.dart -->
```dart
Future<void> revalidate() async { ... } // Restores purchases from store
```

<!-- From lib/core/services/notification_service.dart -->
```dart
static final _plugin = FlutterLocalNotificationsPlugin();
static NotificationTapCallback? onNotificationTap;
```

<!-- Existing l10n keys -->
```
settings_theme, settings_theme_light, settings_theme_dark, settings_theme_system
```

<!-- Existing AppIcons -->
```dart
static const IconData theme = PhosphorIconsFill.moon;
static const IconData themeLight = PhosphorIconsFill.sun;
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: CSV export fixes — transfers, localized headers, UTF-8 BOM (M-11, M-12, M-19)</name>
  <files>
    lib/data/services/backup_service_impl.dart,
    lib/core/services/backup_service.dart,
    lib/features/settings/presentation/screens/backup_export_screen.dart,
    lib/l10n/app_en.arb,
    lib/l10n/app_ar.arb
  </files>
  <action>
**M-11: Include transfers in CSV export.**

In `backup_service_impl.dart`, update `exportTransactionsToCsv()`:

1. After querying `_db.transactions`, also query `_db.transfers` for the same date range:
   ```dart
   final transfers = await (_db.select(_db.transfers)
     ..where((t) => t.transferDate.isBiggerOrEqualValue(start) &
                     t.transferDate.isSmallerThanValue(end))
     ..orderBy([(t) => OrderingTerm.asc(t.transferDate)]))
     .get();
   ```

2. After building the transaction rows, append transfer rows. For each transfer, create a CSV row:
   - Date: `transfer.transferDate` formatted same as transactions
   - Title: `"${walletMap[transfer.fromWalletId] ?? '?'} → ${walletMap[transfer.toWalletId] ?? '?'}"`
   - Amount: `(transfer.amount / 100).toStringAsFixed(2)` (same as transactions — raw decimal)
   - Currency: Use the fromWallet's currency if available, else 'EGP'
   - Type: `'transfer'`
   - Category: empty string
   - Account: `walletMap[transfer.fromWalletId] ?? ''`
   - Tags: empty string
   - Source: `'manual'`
   - Location: empty string
   - Notes: `transfer.note ?? ''`
   - If `transfer.fee > 0`, add fee info to Notes: `"Fee: ${(transfer.fee / 100).toStringAsFixed(2)}"`

3. Sort combined rows by date to interleave transactions and transfers chronologically. Easiest approach: build a list of `(DateTime, List<dynamic>)` tuples, sort by DateTime, then extract the row lists.

**M-12: Localized CSV headers.**

1. Update `BackupService` abstract class — add optional `headers` parameter to `exportTransactionsToCsv`:
   ```dart
   Future<String> exportTransactionsToCsv({
     required int year,
     required int month,
     List<String>? headers,
   });
   ```

2. In `BackupServiceImpl.exportTransactionsToCsv`, use `headers` parameter if provided, otherwise fall back to the current English defaults.

3. Add l10n keys to BOTH `app_en.arb` and `app_ar.arb`:
   ```
   "csv_header_date": "Date" / "التاريخ"
   "csv_header_title": "Title" / "العنوان"
   "csv_header_amount": "Amount" / "المبلغ"
   "csv_header_currency": "Currency" / "العملة"
   "csv_header_type": "Type" / "النوع"
   "csv_header_category": "Category" / "الفئة"
   "csv_header_account": "Account" / "الحساب"
   "csv_header_tags": "Tags" / "العلامات"
   "csv_header_source": "Source" / "المصدر"
   "csv_header_location": "Location" / "الموقع"
   "csv_header_notes": "Notes" / "الملاحظات"
   ```

4. In `backup_export_screen.dart`, update `_exportCsv()` to pass localized headers:
   ```dart
   final l10n = context.l10n;
   path = await ref.read(backupServiceProvider).exportTransactionsToCsv(
     year: picked.year,
     month: picked.month,
     headers: [
       l10n.csv_header_date, l10n.csv_header_title, l10n.csv_header_amount,
       l10n.csv_header_currency, l10n.csv_header_type, l10n.csv_header_category,
       l10n.csv_header_account, l10n.csv_header_tags, l10n.csv_header_source,
       l10n.csv_header_location, l10n.csv_header_notes,
     ],
   );
   ```

**M-19: UTF-8 BOM for Excel compatibility.**

In `exportTransactionsToCsv`, after `const ListToCsvConverter().convert(rows)`, prepend BOM:
```dart
final csvWithBom = '\uFEFF$csv';
await file.writeAsString(csvWithBom);
```

After adding l10n keys, run `flutter gen-l10n` to regenerate localizations.
  </action>
  <verify>
    <automated>flutter analyze lib/data/services/backup_service_impl.dart lib/core/services/backup_service.dart lib/features/settings/presentation/screens/backup_export_screen.dart</automated>
  </verify>
  <done>
    - CSV export includes transfer rows with type "transfer" and from/to wallet names
    - CSV headers accept localized strings from the caller
    - CSV output starts with UTF-8 BOM (\uFEFF)
    - All 11 CSV header l10n keys exist in both app_en.arb and app_ar.arb
    - `flutter analyze` passes on all modified files
  </done>
</task>

<task type="auto">
  <name>Task 2: Settings reactivity — theme mode picker and firstDayOfMonth provider (M-13, M-16)</name>
  <files>
    lib/features/settings/presentation/screens/settings_screen.dart,
    lib/shared/providers/preferences_provider.dart
  </files>
  <action>
**M-13: Add theme mode picker to Settings.**

In `settings_screen.dart`, add a theme mode picker tile in the Appearance section (between the existing `_SectionHeader(title: l10n.settings_appearance)` and the Language tile):

1. Add a `_SettingsTile` for theme:
   ```dart
   Builder(
     builder: (context) {
       final mode = ref.watch(themeModeProvider);
       return _SettingsTile(
         icon: AppIcons.theme,
         label: l10n.settings_theme,
         subtitle: switch (mode) {
           ThemeMode.light => l10n.settings_theme_light,
           ThemeMode.dark => l10n.settings_theme_dark,
           ThemeMode.system => l10n.settings_theme_system,
         },
         onTap: () => _showThemePicker(),
       );
     },
   ),
   ```

2. Add `_showThemePicker()` method (follow exact pattern of `_showLanguagePicker`):
   ```dart
   void _showThemePicker() {
     final l10n = context.l10n;
     final current = ref.read(themeModeProvider);
     final options = [
       (mode: ThemeMode.light, label: l10n.settings_theme_light),
       (mode: ThemeMode.dark, label: l10n.settings_theme_dark),
       (mode: ThemeMode.system, label: l10n.settings_theme_system),
     ];
     showModalBottomSheet<void>(
       context: context,
       builder: (ctx) => SafeArea(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             Padding(
               padding: const EdgeInsets.all(AppSizes.md),
               child: Text(l10n.settings_theme, style: ctx.textStyles.titleMedium),
             ),
             ...options.map(
               (o) => ListTile(
                 title: Text(o.label),
                 trailing: o.mode == current
                     ? Icon(AppIcons.check, color: ctx.colors.primary)
                     : null,
                 onTap: () {
                   ref.read(themeModeProvider.notifier).setMode(o.mode);
                   ctx.pop();
                 },
               ),
             ),
             const SizedBox(height: AppSizes.sm),
           ],
         ),
       ),
     );
   }
   ```

   No new l10n keys needed — `settings_theme`, `settings_theme_light`, `settings_theme_dark`, `settings_theme_system` already exist.

**M-16: Create reactive firstDayOfMonthProvider.**

1. In `preferences_provider.dart`, add:
   ```dart
   /// M-16 fix: reactive first day of month preference (1-28, budget cycle start).
   final firstDayOfMonthProvider = FutureProvider<int>((ref) async {
     final prefsFuture = ref.watch(preferencesFutureProvider.future);
     final prefs = await prefsFuture;
     return prefs.firstDayOfMonth;
   });
   ```

2. In `settings_screen.dart`, update `_setFirstDayOfMonth()` to invalidate the provider:
   ```dart
   Future<void> _setFirstDayOfMonth(int day) async {
     setState(() => _firstDayOfMonth = day);
     final prefs = await ref.read(preferencesFutureProvider.future);
     if (!mounted) return;
     await prefs.setFirstDayOfMonth(day);
     ref.invalidate(firstDayOfMonthProvider);  // M-16 fix
   }
   ```

   Ensure the import for `firstDayOfMonthProvider` is available (it's in the same `preferences_provider.dart` already imported).
  </action>
  <verify>
    <automated>flutter analyze lib/features/settings/presentation/screens/settings_screen.dart lib/shared/providers/preferences_provider.dart</automated>
  </verify>
  <done>
    - Theme mode picker visible in Settings > Appearance section with Light/Dark/System options
    - Selecting a theme mode instantly changes the app theme (no restart needed)
    - `firstDayOfMonthProvider` exists and is invalidated when user changes setting
    - `flutter analyze` passes on all modified files
  </done>
</task>

<task type="auto">
  <name>Task 3: PDF Arabic font, Drive file ID, post-restore revalidation, cold-start notification (M-14, M-15, M-17, M-18)</name>
  <files>
    lib/data/services/pdf_export_service.dart,
    lib/features/settings/presentation/screens/backup_export_screen.dart,
    lib/core/services/notification_service.dart,
    lib/main.dart
  </files>
  <action>
**M-14: Arabic-capable font for PDF.**

The `pdf` package's default font (Helvetica) has no Arabic glyphs. Since the app already bundles Google Fonts via the `google_fonts` package, load the font data at runtime.

In `pdf_export_service.dart`:

1. Add imports:
   ```dart
   import 'package:flutter/services.dart' show rootBundle;
   import 'package:google_fonts/google_fonts.dart';
   ```

2. Add a static font cache and a method to load the font. Use Noto Sans Arabic (bundled by google_fonts, wide Unicode coverage) for Arabic locales and the default for others:
   ```dart
   static pw.Font? _cachedFont;
   static pw.Font? _cachedArabicFont;

   Future<pw.Font> _loadFont(String? locale) async {
     if (locale == 'ar') {
       if (_cachedArabicFont != null) return _cachedArabicFont!;
       // Load Noto Sans Arabic from google_fonts
       final fontFile = GoogleFonts.notoSansArabic().fontFamily;
       // Fallback: load from asset bundle
       try {
         final data = await GoogleFonts.notoSansArabicTextTheme()
             .bodyMedium!.fontFamily;
         // Actually, google_fonts downloads fonts at runtime which isn't reliable.
         // Use rootBundle with a bundled TTF file instead.
       } catch (_) {}
     }
   }
   ```

   **Simpler practical approach:** Since `google_fonts` downloads fonts at runtime (unreliable for offline-first app), bundle a Noto Sans Arabic TTF in `assets/fonts/`. However, that adds app size. The SIMPLEST fix: use the `pdf` package's built-in `pw.Font.helvetica()` for Latin and load a TTF only when locale is 'ar'.

   **Recommended approach (minimal complexity):**
   - Add `assets/fonts/NotoSansArabic-Regular.ttf` to the project (download from Google Fonts, ~320KB)
   - Register in `pubspec.yaml` under `flutter.assets`
   - In `PdfExportService.generate()`, if `locale == 'ar'`:
     ```dart
     pw.ThemeData? pdfTheme;
     if (locale == 'ar') {
       final fontData = await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf');
       final arabicFont = pw.Font.ttf(fontData);
       pdfTheme = pw.ThemeData.withFont(
         base: arabicFont,
         bold: arabicFont,
       );
     }
     ```
   - Pass `theme: pdfTheme` to `pw.Document()` constructor
   - Set `textDirection: pw.TextDirection.rtl` on the `pw.MultiPage` when locale is 'ar'

   If the font asset is not available (hasn't been bundled yet), wrap the rootBundle.load in try/catch and fall back to default. Add a TODO comment for the user to download and add the font file.

   **IMPORTANT:** Since this is an offline-first app and bundling a font adds complexity, take the following pragmatic approach:
   - Create the code that loads the font from assets IF the file exists
   - Add the asset path to pubspec.yaml
   - Add a comment that the font file must be downloaded and placed at `assets/fonts/NotoSansArabic-Regular.ttf`
   - If the font fails to load, fall back gracefully to the default font (Arabic will show as boxes but won't crash)

**M-15: Save drive_file_id after upload.**

In `backup_export_screen.dart`, in `_backupToDrive()`, the line `await driveService.uploadBackup(jsonData)` returns a `String` (the file ID). Capture it:

```dart
// Upload to Drive
final driveService = ref.read(googleDriveBackupProvider);
final fileId = await driveService.uploadBackup(jsonData);  // M-15 fix: capture file ID

// Save backup date + file ID
final now = DateTime.now().toIso8601String();
final prefs = await ref.read(preferencesFutureProvider.future);
await prefs.setLastBackupDate(now);
await prefs.setDriveFileId(fileId);  // M-15 fix: persist file ID
```

**M-17: Revalidate subscription after restore.**

In `backup_export_screen.dart`, in both `_restoreJson()` and `_restoreFromDrive()`, after the `importFromJson()` call and before navigating to splash, call `subscriptionService.revalidate()`:

For `_restoreJson()`:
```dart
await ref.read(backupServiceProvider).importFromJson(filePath);
// M-17 fix: reconcile subscription state after DB restore
await ref.read(subscriptionServiceProvider).revalidate();
if (!mounted) return;
```

For `_restoreFromDrive()`:
```dart
await ref.read(backupServiceProvider).importFromJson(tempFile.path);
// M-17 fix: reconcile subscription state after DB restore
await ref.read(subscriptionServiceProvider).revalidate();
if (!mounted) return;
```

Add import for `subscriptionServiceProvider` from `../../../../shared/providers/subscription_provider.dart`.

**M-18: Cold-start notification handling.**

In `notification_service.dart`, add a static method:
```dart
/// Check if app was launched from a notification tap (cold start).
/// Returns the payload string, or null if not launched from notification.
static Future<String?> getLaunchPayload() async {
  final details = await _plugin.getNotificationAppLaunchDetails();
  if (details == null || !details.didNotificationLaunchApp) return null;
  return details.notificationResponse?.payload;
}
```

In `main.dart`, after the existing `NotificationService.onNotificationTap = ...` block, add cold-start check:
```dart
// M-18 fix: handle cold-start from notification tap
final launchPayload = await NotificationService.getLaunchPayload();
if (launchPayload != null) {
  if (launchPayload == 'recap') {
    appRouter.go(AppRoutes.chat);
  } else if (launchPayload.startsWith('recurring:')) {
    appRouter.go(AppRoutes.recurring);
  }
}
```

Note: This must run AFTER `runApp()` and AFTER the `onNotificationTap` callback is set, so the router is ready. Since `appRouter` is the global router instance, calling `go()` here is safe. Do NOT wrap in `unawaited` since we want to await the payload check before processing.
  </action>
  <verify>
    <automated>flutter analyze lib/data/services/pdf_export_service.dart lib/features/settings/presentation/screens/backup_export_screen.dart lib/core/services/notification_service.dart lib/main.dart</automated>
  </verify>
  <done>
    - PdfExportService loads Arabic-capable font when locale is 'ar' (graceful fallback if font file missing)
    - PDF page has RTL text direction for Arabic locale
    - pubspec.yaml lists the Arabic font asset path
    - Drive backup saves fileId to preferences after successful upload
    - Both JSON restore and Drive restore call subscriptionService.revalidate() before navigating
    - NotificationService has getLaunchPayload() static method
    - main.dart checks launch payload on cold start and routes accordingly
    - `flutter analyze` passes on all modified files
  </done>
</task>

</tasks>

<verification>
After all 3 tasks complete:
1. `flutter analyze lib/` passes with zero issues
2. CSV export method queries both transactions and transfers tables
3. CSV output begins with \uFEFF BOM character
4. Settings screen shows theme picker in Appearance section
5. `firstDayOfMonthProvider` is exported from preferences_provider.dart
6. PdfExportService handles Arabic locale with custom font + RTL direction
7. backup_export_screen.dart captures and saves Drive file ID
8. Both restore flows call subscriptionService.revalidate()
9. main.dart checks getNotificationAppLaunchDetails on startup
</verification>

<success_criteria>
All 9 medium-priority audit bugs (M-11 through M-19) are resolved. `flutter analyze lib/` reports zero issues. No regressions in existing export, settings, or startup behavior.
</success_criteria>

<output>
After completion, create `.planning/quick/260328-pwv-fix-medium-priority-audit-bugs-wave-b-m1/260328-pwv-SUMMARY.md`
</output>
