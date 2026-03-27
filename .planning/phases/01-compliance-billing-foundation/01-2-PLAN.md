---
phase: 1
plan: 2
title: "Package & Settings Cleanup"
wave: 1
depends_on: []
requirements: [CLEAN-01, CLEAN-02]
files_modified:
  - pubspec.yaml
  - lib/features/settings/presentation/screens/settings_screen.dart
  - lib/core/services/sms_parser_service.dart
  - lib/core/services/notification_transaction_parser.dart (DELETE)
  - lib/features/sms_parser/presentation/screens/parser_review_screen.dart
  - lib/main.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ar.arb
autonomous: true
---

<plan>
<meta>
<phase>1</phase>
<plan_number>2</plan_number>
<title>Package & Settings Cleanup</title>
</meta>

<objective>
Remove the `another_telephony` package (SMS dependency that triggers Play Store scrutiny for SMS permissions), clean all import sites that reference it, delete the dead `notification_transaction_parser.dart` file, remove orphaned SMS-related l10n strings, and verify the codebase compiles cleanly. This eliminates the last SMS package dependency and the "Smart Detection" settings section that would break without it.
</objective>

<must_haves>
- `another_telephony` absent from `pubspec.yaml` and `pubspec.lock`
- Zero import sites reference `another_telephony` or `notification_transaction_parser`
- Settings screen compiles without the `Telephony` class
- Orphaned SMS l10n keys removed from both .arb files
- `flutter analyze lib/` reports zero issues
</must_haves>

<tasks>
<task id="1.2.1">
<title>Remove another_telephony from pubspec.yaml</title>
<read_first>
- pubspec.yaml (line 87 — `another_telephony: ^0.4.1`)
</read_first>
<action>
In `pubspec.yaml`, delete line 87 (and the preceding comment line 86 if it exists as a section header). Remove these 2 lines:

```yaml
  # ── SMS Parser ──────────────────────────────────────────────────────────
  another_telephony: ^0.4.1
```

Keep `rxdart: ^0.28.0` and `connectivity_plus: ^7.0.0` on the following lines — they are used by other features (activity providers and connectivity service respectively).

Then run:
```bash
flutter pub get
```

This will also update `pubspec.lock` to remove `another_telephony` and its transitive dependencies.
</action>
<acceptance_criteria>
- grep for `another_telephony` in `pubspec.yaml` returns 0 matches
- grep for `another_telephony` in `pubspec.lock` returns 0 matches
- `flutter pub get` exits with code 0
</acceptance_criteria>
</task>

<task id="1.2.2">
<title>Clean settings_screen.dart — remove Telephony import, SMS state, and SMS methods</title>
<read_first>
- lib/features/settings/presentation/screens/settings_screen.dart (line 3 — Telephony import; lines 50-52 — SMS state fields; lines 329-380 — _toggleSmsParser and _finishSmsPermission methods; lines 721-731 — Smart Detection UI block)
</read_first>
<action>
In `lib/features/settings/presentation/screens/settings_screen.dart`, make the following changes:

**1. Delete line 3** (the `another_telephony` import):
```dart
import 'package:another_telephony/telephony.dart';
```

**2. Delete line 19** (the `sms_parser_service` import):
```dart
import '../../../../core/services/sms_parser_service.dart';
```

**3. Delete lines 50-52** (the SMS state fields in `_SettingsScreenState`):
```dart
  // WS5: Smart Detection state (moved from SmartInputScreen).
  bool _smsParserEnabled = false;
  bool _awaitingSmsPermission = false;
```

**4. Delete line 102** (the SMS parser enabled init in `_loadSettings`):
```dart
      _smsParserEnabled = prefs.isSmsParserEnabled;
```

**5. Delete lines 329-380** (the entire `_toggleSmsParser` and `_finishSmsPermission` methods, plus the section comment):
Delete from:
```dart
  // ── WS5: Smart Detection toggles (from SmartInputScreen) ──────────────
```
through the end of `_finishSmsPermission` method (approximately line 380).

**6. Delete lines 721-731** (the Smart Detection UI section):
```dart
          // ── Smart Detection (WS5: moved from SmartInputScreen) ──────
          if (AppConfig.kSmsEnabled && Platform.isAndroid) ...[
            _SectionHeader(title: l10n.settings_smart_detection),
            SwitchListTile(
              secondary: _SettingsIconBox(icon: AppIcons.sms, cs: cs),
              title: Text(l10n.settings_sms_parser),
              subtitle: Text(l10n.settings_sms_parser_subtitle),
              value: _smsParserEnabled,
              onChanged: _toggleSmsParser,
            ),
          ],
```

**7.** After all deletions, check if the following imports are still used by other code in the file. If they are ONLY used by the deleted SMS code, remove them too:
- `import '../../../../shared/providers/pending_transactions_provider.dart';` — run a grep to verify: the only usage of `pendingParsedTransactionsProvider` is at line 376 inside `_finishSmsPermission` (which was deleted in step 5). If grep confirms no remaining usage of `pendingParsedTransactions` in the file after the SMS deletions, delete this import (line 23).

**8.** Check if `dart:io` (the `Platform.isAndroid` import) is still needed by other code in the file. The SMS section used `Platform.isAndroid`, but the `_clearAllData` method also likely uses `Platform`. Keep `dart:io` if other code uses it.
</action>
<acceptance_criteria>
- grep for `another_telephony` in `lib/features/settings/presentation/screens/settings_screen.dart` returns 0 matches
- grep for `sms_parser_service` in `lib/features/settings/presentation/screens/settings_screen.dart` returns 0 matches
- grep for `_toggleSmsParser` in `lib/features/settings/presentation/screens/settings_screen.dart` returns 0 matches
- grep for `_smsParserEnabled` in `lib/features/settings/presentation/screens/settings_screen.dart` returns 0 matches
- grep for `Smart Detection` in `lib/features/settings/presentation/screens/settings_screen.dart` returns 0 matches
- grep for `Telephony` in `lib/features/settings/presentation/screens/settings_screen.dart` returns 0 matches
- grep for `pending_transactions_provider` in `lib/features/settings/presentation/screens/settings_screen.dart` returns 0 matches (import removed since only usage was in deleted `_finishSmsPermission`)
</acceptance_criteria>
</task>

<task id="1.2.3">
<title>Clean sms_parser_service.dart — remove another_telephony import</title>
<read_first>
- lib/core/services/sms_parser_service.dart (line 5 — `import 'package:another_telephony/telephony.dart';`, full file to understand how Telephony class is used)
</read_first>
<action>
In `lib/core/services/sms_parser_service.dart`, this file heavily uses the `Telephony` class from `another_telephony` to read SMS inbox. Since `kSmsEnabled = false` and the entire SMS feature is hidden, this file is effectively dead code but is preserved for future Pro re-enablement.

**Option A (preferred):** Wrap the `another_telephony` import and all usages behind a conditional compilation guard. Since Dart does not support conditional imports based on feature flags, the simplest approach is:

1. Delete line 5:
```dart
import 'package:another_telephony/telephony.dart';
```

2. Delete line 15:
```dart
import 'notification_transaction_parser.dart';
```

3. Stub out the `scanInbox()` method body to return 0 immediately since kSmsEnabled is false. Replace the method body that calls `Telephony.instance` with:
```dart
  /// Scan SMS inbox for financial messages.
  /// Currently disabled (kSmsEnabled = false) — returns 0.
  /// Preserved for future Pro tier re-enablement.
  Future<int> scanInbox() async {
    // SMS parsing disabled in AI-first pivot.
    // When re-enabling, restore another_telephony dependency
    // and the Telephony.instance.getInboxSms() call.
    return 0;
  }
```

Remove any other methods that reference `Telephony` or `SmsMessage` types from the `another_telephony` package. Keep the class structure and DAO integration intact for future re-enablement.

4. Remove the `NotificationTransactionParser` usage since that file will be deleted in the next task.
</action>
<acceptance_criteria>
- grep for `another_telephony` in `lib/core/services/sms_parser_service.dart` returns 0 matches
- grep for `notification_transaction_parser` in `lib/core/services/sms_parser_service.dart` returns 0 matches
- grep for `Telephony.instance` in `lib/core/services/sms_parser_service.dart` returns 0 matches
</acceptance_criteria>
</task>

<task id="1.2.4">
<title>Delete notification_transaction_parser.dart</title>
<read_first>
- lib/core/services/notification_transaction_parser.dart (confirm this is the dead code file)
</read_first>
<action>
Delete the file entirely:

```bash
rm lib/core/services/notification_transaction_parser.dart
```

Then verify no remaining import sites reference it:

```bash
grep -r "notification_transaction_parser" lib/
```

If any import sites are found (beyond `sms_parser_service.dart` which was already cleaned in task 1.2.3), clean those imports too. Known reference:

- `lib/features/sms_parser/presentation/screens/parser_review_screen.dart` line 14 — delete this import line:
  ```dart
  import '../../../../core/services/notification_transaction_parser.dart';
  ```
  Also check if any code in `parser_review_screen.dart` references classes from the deleted file (e.g., `NotificationTransactionParser`). If so, remove or stub those references.
</action>
<acceptance_criteria>
- File `lib/core/services/notification_transaction_parser.dart` does not exist
- grep for `notification_transaction_parser` across all of `lib/` returns 0 matches
</acceptance_criteria>
</task>

<task id="1.2.5">
<title>Clean orphaned SMS-related l10n strings</title>
<read_first>
- lib/l10n/app_en.arb (lines containing: settings_smart_detection, settings_smart_detection_subtitle, settings_sms_parser, settings_sms_parser_subtitle, permission_sms_title, permission_sms_body)
- lib/l10n/app_ar.arb (same keys)
</read_first>
<action>
Remove the following 6 key-value pairs from BOTH `lib/l10n/app_en.arb` AND `lib/l10n/app_ar.arb`. These keys are ONLY used by the SMS settings UI that was removed in task 1.2.2:

**From `app_en.arb`:**
1. Delete the line containing `"settings_sms_parser": "SMS Parser",` (approximately line 213)
2. Delete the line containing `"settings_smart_detection": "Smart Detection",` (approximately line 340)
3. Delete the line containing `"settings_smart_detection_subtitle": "Auto-detect transactions from SMS messages",` (approximately line 341)
4. Delete the line containing `"settings_sms_parser_subtitle": "Scan SMS inbox for bank transaction messages",` (approximately line 690)
5. Delete the line containing `"permission_sms_title": "SMS Access",` (approximately line 691)
6. Delete the line containing `"permission_sms_body": "Masarify can scan your SMS inbox...` (approximately line 692)

**From `app_ar.arb`:**
1. Delete the line containing `"settings_sms_parser": "تحليل الرسائل",` (approximately line 208)
2. Delete the line containing `"settings_smart_detection": "الكشف الذكي",` (approximately line 334)
3. Delete the line containing `"settings_smart_detection_subtitle": "اكتشاف المعاملات تلقائياً من رسائل SMS",` (approximately line 335)
4. Delete the line containing `"settings_sms_parser_subtitle": "فحص الرسائل النصية لاكتشاف معاملات البنك",` (approximately line 684)
5. Delete the line containing `"permission_sms_title": "صلاحية الرسائل",` (approximately line 685)
6. Delete the line containing `"permission_sms_body": "يمكن لمصاريفي فحص رسائلك النصية...` (approximately line 686)

Ensure no trailing comma issues in the JSON after deletion (the preceding line should have a comma only if there are more entries after it).

Then regenerate l10n:
```bash
flutter gen-l10n
```
</action>
<acceptance_criteria>
- grep for `settings_sms_parser` in `lib/l10n/app_en.arb` returns 0 matches
- grep for `settings_smart_detection` in `lib/l10n/app_en.arb` returns 0 matches
- grep for `permission_sms_title` in `lib/l10n/app_en.arb` returns 0 matches
- grep for `permission_sms_body` in `lib/l10n/app_en.arb` returns 0 matches
- Same 4 checks pass for `lib/l10n/app_ar.arb`
- `flutter gen-l10n` completes without errors
</acceptance_criteria>
</task>

<task id="1.2.6">
<title>Verify clean compilation and no residual references</title>
<read_first>
- lib/main.dart (lines 18, 95-99 — sms_parser_service import and SMS scan block to check if they still compile)
</read_first>
<action>
Run the full verification sequence:

```bash
# 1. Check for any remaining references to removed items
grep -r "another_telephony" lib/
grep -r "notification_transaction_parser" lib/
grep -r "Telephony\.instance" lib/

# 2. Verify no compile errors
flutter analyze lib/

# 3. Verify package is gone from dependency tree
flutter pub deps | grep another_telephony
```

**Note on main.dart:** The `_scanSmsInBackground` function (lines 125-131) and its call site (lines 95-99) are guarded by `AppConfig.kSmsEnabled` which is `false`. The function references `SmsParserService` which was cleaned in task 1.2.3. Verify that the cleaned `SmsParserService` still compiles — the `scanInbox()` method should still exist (returning 0) so the guarded call site remains valid. Do NOT remove the guarded block — it is preserved for future Pro re-enablement.

If `flutter analyze lib/` reports any issues related to the cleanup, fix them before marking this task complete.
</action>
<acceptance_criteria>
- `flutter analyze lib/` reports "No issues found!"
- grep for `another_telephony` across `lib/` returns 0 matches
- grep for `notification_transaction_parser` across `lib/` returns 0 matches
- `flutter pub deps` does not list `another_telephony`
</acceptance_criteria>
</task>
</tasks>

<verification>
```bash
# Package verification:
flutter pub deps | grep another_telephony && echo "FAIL" || echo "PASS: another_telephony removed"

# Import verification:
grep -r "another_telephony" lib/ && echo "FAIL" || echo "PASS: no another_telephony imports"
grep -r "notification_transaction_parser" lib/ && echo "FAIL" || echo "PASS: no parser imports"
grep -r "Telephony" lib/ && echo "FAIL" || echo "PASS: no Telephony references"

# Dead file verification:
test -f lib/core/services/notification_transaction_parser.dart && echo "FAIL: file still exists" || echo "PASS: file deleted"

# L10n verification:
grep "settings_sms_parser" lib/l10n/app_en.arb && echo "FAIL" || echo "PASS: l10n cleaned"
grep "permission_sms" lib/l10n/app_en.arb && echo "FAIL" || echo "PASS: l10n cleaned"

# Compilation verification:
flutter analyze lib/
```
</verification>
</plan>
