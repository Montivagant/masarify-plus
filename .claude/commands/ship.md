---
description: Release preparation — analyze, test, build, and distribute
argument-hint: <'debug' for test build, 'release' for production, 'store' for Play Store>
---

# Release Preparation Mode

Run the full release checklist for Masarify.

## Pre-Flight Checks
1. **Analyze:** `flutter analyze lib/` → must show **zero issues**
2. **Test:** `flutter test` → all tests must pass
3. **Build Runner:** Ensure all generated files are up to date: `dart run build_runner build --delete-conflicting-outputs`

## Build Target: $ARGUMENTS

### If `debug`:
```bash
flutter run --debug
```

### If `release` (sideload APKs):
```bash
bash scripts/build-release.sh
```
Output: Split APKs by ABI in `build/app/outputs/flutter-apk/`
- Distribute `app-arm64-v8a-release.apk` (~20MB) via **Google Drive** or **GitHub Releases**

### If `store` (Play Store AAB):
```bash
flutter build appbundle --release
```
Output: AAB in `build/app/outputs/bundle/release/`
- Upload to Google Play Console

## Release Rules
- **NEVER** send APK via WhatsApp/Telegram — corrupts V2 signature → "App not installed"
- **NEVER** skip `flutter analyze` before release
- Verify Impeller is **disabled** in `AndroidManifest.xml` (BackdropFilter causes grey overlay)
- Check `pubspec.yaml` version bump if needed
