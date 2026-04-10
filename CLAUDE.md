# Masarify-Plus — Claude Code Configuration

## Project
**Masarify (مصاريفي)** — Offline-first personal finance tracker for Android/iOS.
Flutter + Dart | Clean Architecture + Riverpod 2.x | Drift (SQLite) | Material Design 3.

## MCP Tools (Windows workarounds)
- `dart` MCP: only `pub_dev_search` works. Analyzer broken — use `flutter analyze lib/` via Bash.
- `dcm` MCP: ALL broken — use `bash scripts/analyze.sh dcm` instead.

## The 5 Critical Rules
1. **Money = INTEGER piastres.** `100 EGP = 10000`. Use `MoneyFormatter` for display. (Avoids floating-point rounding errors in financial calculations.)
2. **100% offline-first.** All core features work without internet. (Users may have no connectivity.)
3. **RTL-first.** Validate every screen in Arabic RTL. (Primary market is Egypt/MENA.)
4. **Design tokens for all styling.** Use `context.colors.*`, `AppIcons.*`, `AppSizes.*`, `context.appTheme.*`. (Ensures visual consistency and theme-ability.)
5. **MasarifyDS components for layout.** Use shared design system widgets, not inline layout primitives. (Single source of truth for UI patterns.)

> Dart coding conventions (state management, navigation, imports, tokens) are in `.claude/rules/dart-conventions.md` — auto-attached on every Dart file edit.

## Before Claiming Done
1. Run `flutter analyze lib/` — zero errors required.
2. If `.arb` files changed — run `flutter gen-l10n`.
3. If `pubspec.yaml` changed — run `flutter pub get`.
4. If `@freezed` or `*.g.dart` changed — run `dart run build_runner build --delete-conflicting-outputs`.
