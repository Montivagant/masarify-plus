---
description: Flutter development workflow — analyzer, DCM metrics, context7 docs, live inspector
argument-hint: <task description or file path>
---

# Flutter Dev Mode

## Tool Selection
1. **Before coding:** Use `context7` to look up API docs for any package you're unsure about
2. **While coding:** Run `flutter analyze lib/` via Bash (dart MCP analyzer broken on Windows)
3. **For metrics:** Run `bash scripts/analyze.sh dcm` via Bash
4. **For debugging:** Use `flutter-inspector` MCP if the app is running
5. **For packages:** Use `dart` MCP's `pub_dev_search`

## After Every Change
- `flutter analyze lib/` — zero issues
- If `.g.dart` files affected: `dart run build_runner build --delete-conflicting-outputs`

## Task: $ARGUMENTS
