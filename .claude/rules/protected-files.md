---
description: Files that should never be manually edited — they are generated or managed by tooling
globs: "**/*.g.dart,**/*.freezed.dart,**/app_localizations*.dart,pubspec.lock"
---

# Protected Files — Do Not Edit

These files are auto-generated. Edit the source instead:

- `*.g.dart` → Edit the source `.dart` file, then run `dart run build_runner build --delete-conflicting-outputs`
- `*.freezed.dart` → Edit the source `.dart` file with `@freezed` annotation, then run build_runner
- `app_localizations*.dart` → Edit `app_en.arb` / `app_ar.arb`, then run `flutter gen-l10n`
- `pubspec.lock` → Modify `pubspec.yaml` and run `flutter pub get`
