---
description: Verification checks required before claiming any Dart/Flutter change is complete
globs: "lib/**/*.dart"
---

# Verification Before Completion

Evidence before assertions. Run verification commands and show results before claiming code works, compiles, or passes.

## Required Checks
1. Run `flutter analyze lib/` — zero errors required. Warnings acceptable only if pre-existing.
2. If `.arb` files modified — run `flutter gen-l10n` and confirm success.
3. If `pubspec.yaml` modified — run `flutter pub get` and confirm success.
4. If `@freezed` or `part '*.g.dart'` modified — run `dart run build_runner build --delete-conflicting-outputs`.

## When to Skip
- Documentation-only changes (`.md`, `.arb` content review).
- Configuration changes (`.json`, `.yaml` that don't affect Dart).
- Reading/exploring code without modifications.
