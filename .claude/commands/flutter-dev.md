---
description: Flutter development workflow — analyzer, DCM metrics, context7 docs, live inspector
argument-hint: <task description or file path>
---

# Flutter Dev Mode

You are in Flutter development mode for **Masarify**. Use the full MCP toolkit.

## Tool Selection
1. **Before coding:** Use `context7` to look up API docs for any package you're unsure about (Riverpod, Drift, go_router, fl_chart, etc.)
2. **While coding:** Run `flutter analyze lib/` via Bash for real-time analysis
3. **For metrics:** Run `bash scripts/analyze.sh dcm` via Bash (CLI workaround — dart/dcm MCP tools broken on Windows, see Known Issues in CLAUDE.md)
4. **For debugging:** Use `flutter-inspector` MCP if the app is running (screenshots, errors, view details)
5. **For packages:** Use `dart` MCP's `pub_dev_search` for package lookups (non-filesystem tools still work)

## After Every Change
- Run `flutter analyze lib/` — must show **zero issues**
- Or run `bash scripts/analyze.sh` for full analysis (analyzer + DCM)
- If you modified `.dart` files with `.g.dart` counterparts: `dart run build_runner build --delete-conflicting-outputs`

## Compliance Checklist
- [ ] Design tokens used (`AppSizes.*`, `AppIcons.*`, `context.colors`, `context.appTheme.*`) — no hardcoded values
- [ ] L10n keys for all user-facing strings (both `app_en.arb` and `app_ar.arb`)
- [ ] `ConsumerWidget` or `ConsumerStatefulWidget` — never raw `StatefulWidget`
- [ ] `context.go()` / `context.push()` — never `Navigator.push()`
- [ ] Integer piastres for money — never `double`
- [ ] RTL validated — layout works in Arabic

## Task: $ARGUMENTS
