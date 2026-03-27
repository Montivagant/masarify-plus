---
phase: 1
plan: 1
title: "SDK & Manifest Compliance"
wave: 1
depends_on: []
requirements: [STORE-01, CLEAN-03]
files_modified:
  - android/app/build.gradle.kts
  - android/app/src/main/res/values/styles.xml
  - android/app/src/main/res/values-v35/styles.xml (NEW)
  - android/app/src/main/AndroidManifest.xml
  - lib/main.dart
autonomous: true
---

<plan>
<meta>
<phase>1</phase>
<plan_number>1</plan_number>
<title>SDK & Manifest Compliance</title>
</meta>

<objective>
Bump targetSdk from 34 to 35 to meet Google Play's August 2025 deadline, opt out of edge-to-edge enforcement on API 35 to avoid UI regressions in the glassmorphic nav bar, remove the unnecessary SCHEDULE_EXACT_ALARM permission that triggers Play Store scrutiny, and disable GoogleFonts runtime fetching to enforce offline-first.
</objective>

<must_haves>
- targetSdk is 35 in the release build
- No SCHEDULE_EXACT_ALARM permission in the merged manifest
- Edge-to-edge opted out on API 35 (preserving current nav bar rendering)
- GoogleFonts runtime fetching disabled before runApp()
- `flutter build appbundle --release` succeeds
</must_haves>

<tasks>
<task id="1.1.1">
<title>Bump targetSdk from 34 to 35</title>
<read_first>
- android/app/build.gradle.kts (line 36 — current targetSdk = 34)
</read_first>
<action>
In `android/app/build.gradle.kts`, change line 36 from:

```kotlin
targetSdk = 34
```

to:

```kotlin
targetSdk = 35
```

No change to compileSdk (already `flutter.compileSdkVersion` which resolves to 36).
No change to minSdk (remains 24).
</action>
<acceptance_criteria>
- grep for `targetSdk = 35` in `android/app/build.gradle.kts` returns exactly 1 match
- grep for `targetSdk = 34` in `android/app/build.gradle.kts` returns 0 matches
</acceptance_criteria>
</task>

<task id="1.1.2">
<title>Add edge-to-edge opt-out to values/styles.xml</title>
<read_first>
- android/app/src/main/res/values/styles.xml (current LaunchTheme and NormalTheme definitions)
</read_first>
<action>
In `android/app/src/main/res/values/styles.xml`, add the `windowOptOutEdgeToEdgeEnforcement` item to BOTH theme styles. The file should become:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- Theme applied to the Android Window while the process is starting when the OS's Dark Mode setting is off -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <!-- Show a splash screen on the activity. Automatically removed when
             the Flutter engine draws its first frame -->
        <item name="android:windowBackground">@drawable/launch_background</item>
        <!-- Opt out of edge-to-edge on API 35 to preserve glassmorphic nav bar rendering.
             Full edge-to-edge adoption deferred to Phase 3 Home Screen Overhaul. -->
        <item name="android:windowOptOutEdgeToEdgeEnforcement">true</item>
    </style>
    <!-- Theme applied to the Android Window as soon as the process has started.
         This theme determines the color of the Android Window while your
         Flutter UI initializes, as well as behind your Flutter UI while its
         running.

         This Theme is only used starting with V2 of Flutter's Android embedding. -->
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
        <item name="android:windowOptOutEdgeToEdgeEnforcement">true</item>
    </style>
</resources>
```
</action>
<acceptance_criteria>
- grep for `windowOptOutEdgeToEdgeEnforcement` in `android/app/src/main/res/values/styles.xml` returns exactly 2 matches (one per theme)
</acceptance_criteria>
</task>

<task id="1.1.3">
<title>Create values-v35/styles.xml WITHOUT opt-out for API 36+ safety</title>
<read_first>
- android/app/src/main/res/values/styles.xml (as reference for theme names)
</read_first>
<action>
Create the directory `android/app/src/main/res/values-v35/` and create `styles.xml` inside it with the following content. This file does NOT include the opt-out attribute because `windowOptOutEdgeToEdgeEnforcement` was removed in API 36 and would cause a crash:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <!-- API 35+: windowOptOutEdgeToEdgeEnforcement is removed in API 36.
         This override prevents a crash on API 36+ devices by omitting the attribute.
         The base values/styles.xml has the opt-out for API 35 specifically. -->
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
```
</action>
<acceptance_criteria>
- File `android/app/src/main/res/values-v35/styles.xml` exists
- grep for `windowOptOutEdgeToEdgeEnforcement` in `android/app/src/main/res/values-v35/styles.xml` returns 0 matches
- grep for `LaunchTheme` in `android/app/src/main/res/values-v35/styles.xml` returns 1 match
- grep for `NormalTheme` in `android/app/src/main/res/values-v35/styles.xml` returns 1 match
</acceptance_criteria>
</task>

<task id="1.1.4">
<title>Delete SCHEDULE_EXACT_ALARM from AndroidManifest.xml</title>
<read_first>
- android/app/src/main/AndroidManifest.xml (line 25-26 — the scheduling comment and permission)
</read_first>
<action>
In `android/app/src/main/AndroidManifest.xml`, delete the following 2 lines (the section comment and the permission declaration):

```xml
    <!-- ── Scheduling (Android 12+ / API 31+) ─────────────────────────── -->
    <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

This is a direct deletion, not a `tools:node="remove"`, because research confirmed no transitive dependency (including `flutter_local_notifications`) declares this permission. The app already uses `AndroidScheduleMode.inexactAllowWhileIdle` in `NotificationService.scheduleDaily()` which does not require exact alarm permission.
</action>
<acceptance_criteria>
- grep for `SCHEDULE_EXACT_ALARM` in `android/app/src/main/AndroidManifest.xml` returns 0 matches
- grep for `Scheduling` in `android/app/src/main/AndroidManifest.xml` returns 0 matches
</acceptance_criteria>
</task>

<task id="1.1.5">
<title>Disable GoogleFonts runtime fetching in main.dart</title>
<read_first>
- pubspec.yaml (confirm `google_fonts` dependency exists — currently line 33: `google_fonts: ^6.2.1`)
- lib/main.dart (lines 1-30 — imports and start of main() function)
</read_first>
<action>
In `lib/main.dart`, add the GoogleFonts import at the top of the file (after the existing package imports, before the relative imports):

```dart
import 'package:google_fonts/google_fonts.dart';
```

Then, inside the `main()` function, add the following line immediately after `WidgetsFlutterBinding.ensureInitialized();` (after line 26, before the crash log init):

```dart
  // Disable runtime font fetching — offline-first requirement.
  // Fonts are bundled via google_fonts asset directory or cached on first use.
  GoogleFonts.config.allowRuntimeFetching = false;
```

The resulting main() start should read:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable runtime font fetching — offline-first requirement.
  // Fonts are bundled via google_fonts asset directory or cached on first use.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize crash log service before anything else.
  await CrashLogService.initialize();
```
</action>
<acceptance_criteria>
- grep for `allowRuntimeFetching = false` in `lib/main.dart` returns exactly 1 match
- grep for `import 'package:google_fonts/google_fonts.dart'` in `lib/main.dart` returns exactly 1 match
</acceptance_criteria>
</task>

<task id="1.1.6">
<title>Verify build succeeds with all changes</title>
<read_first>
- android/app/build.gradle.kts (confirm targetSdk = 35)
- android/app/src/main/AndroidManifest.xml (confirm no SCHEDULE_EXACT_ALARM)
</read_first>
<action>
Run the following verification commands in sequence:

```bash
# 1. Verify analysis passes
flutter analyze lib/

# 2. Verify release build succeeds
flutter build appbundle --release

# 3. Verify merged manifest (after build)
grep -c "SCHEDULE_EXACT_ALARM" build/app/intermediates/merged_manifest/release/AndroidManifest.xml
# Expected: 0 (no matches)

grep -c "targetSdkVersion" build/app/intermediates/merged_manifest/release/AndroidManifest.xml
# Expected: 1 match containing "35"
```

If `flutter analyze lib/` reports issues, fix them before proceeding. If the release build fails, investigate the error — do NOT revert targetSdk.
</action>
<acceptance_criteria>
- `flutter analyze lib/` reports "No issues found!"
- `flutter build appbundle --release` exits with code 0
- Merged manifest contains no `SCHEDULE_EXACT_ALARM` permission
</acceptance_criteria>
</task>
</tasks>

<verification>
```bash
# Full verification sequence:
flutter analyze lib/
flutter build appbundle --release

# Merged manifest audit:
grep "SCHEDULE_EXACT_ALARM" build/app/intermediates/merged_manifest/release/AndroidManifest.xml && echo "FAIL: SCHEDULE_EXACT_ALARM still present" || echo "PASS: no SCHEDULE_EXACT_ALARM"

grep "targetSdk" android/app/build.gradle.kts
# Expected: targetSdk = 35

grep "allowRuntimeFetching" lib/main.dart
# Expected: GoogleFonts.config.allowRuntimeFetching = false;

ls android/app/src/main/res/values-v35/styles.xml
# Expected: file exists
```
</verification>
</plan>
