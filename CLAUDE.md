# Masarify-Plus — Claude Code Configuration

## Project
**Masarify (مصاريفي)** — Offline-first personal finance tracker for Android/iOS.
Flutter + Dart | Clean Architecture + Riverpod 2.x | Drift (SQLite) | Material Design 3.

## MCP Tools (Windows workarounds)
- `dart` MCP: only `pub_dev_search` works. Analyzer broken — use `flutter analyze lib/` via Bash
- `dcm` MCP: ALL broken — use `bash scripts/analyze.sh dcm` instead

## The 5 Critical Rules
1. **Money = INTEGER piastres.** `100 EGP = 10000`. Never double. `MoneyFormatter` for display.
2. **100% offline-first.** No Firebase/internet for core features.
3. **RTL-first.** Every screen validated in Arabic RTL.
4. **Design tokens are LAW.** `context.colors`, `AppIcons.*`, `AppSizes.*`, `context.appTheme.*` — NEVER hardcode.
5. **MasarifyDS components always.** Never build layout primitives inline in screen files.

## Architecture Rules
- `domain/` = pure Dart only (zero Flutter/Drift imports)
- Provider flow: `StreamProvider`/`FutureProvider` → Repository → DAO → Drift stream
- NEVER `setState` in screens (except AnimationController and ephemeral form state)
- NEVER `Navigator.push()` — use `context.go()` / `context.push()`
- Every screen: `ConsumerWidget` or `ConsumerStatefulWidget`
- Import ordering: `../../` before `../`
