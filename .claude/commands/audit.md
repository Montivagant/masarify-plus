---
description: Full 9-category surgical codebase audit with parallel agents
argument-hint: <'full' for all categories, or category number 1-9, or 'quick' for sweep>
---

# Codebase Audit Mode

Run the Masarify surgical audit. See `.claude/ralph-loop.local.md` for the full audit specification.

## Audit Scope: $ARGUMENTS

### Full Audit (9 Categories)

| # | Category | Primary Tool |
|---|----------|-------------|
| 1 | Dead code & unused files | `bash scripts/analyze.sh dcm-unused` + Grep |
| 2 | Unused dependencies | Grep `pubspec.yaml` vs `lib/` imports |
| 3 | Hardcoded styles (non-tokenized) | Grep for `Color(0x`, `Colors.`, raw `EdgeInsets`, raw `TextStyle`, etc. |
| 4 | Hardcoded text (non-l10n) | Grep for Arabic chars, hardcoded English UI strings |
| 5 | Architecture violations | Grep for `Navigator.push`, `setState` in ConsumerWidget, Flutter imports in `domain/` |
| 6 | File & folder structure | Verify feature-first structure, import ordering |
| 7 | Code quality | BuildContext after async, missing const, empty catch blocks |
| 8 | `flutter analyze lib/` | Bash — zero issues required (dart MCP broken on Windows) |
| 9 | `flutter test` | Run all tests, fix failures |

### Quick Sweep (categories 3, 5, 8 only)
For iterations 4+, run only hardcoded values check, architecture violations, and analyzer.

### Execution Strategy
- Run independent categories in **parallel** using agents where possible
- Categories 1-2: can run in parallel
- Categories 3-4: can run in parallel
- Categories 5-7: can run in parallel
- Category 8: run after fixes
- Category 9: run last

### Fix Rules
- Fix issues **in place** — no new wrapper files
- Use existing tokens: `AppSizes.*`, `AppColors.*`, `AppIcons.*`, `AppDurations.*`, `context.appTheme.*`, `context.l10n.*`
- New l10n keys → add to BOTH `app_en.arb` AND `app_ar.arb`, then `flutter gen-l10n`
- Run `flutter analyze lib/` after each fix batch
- Run `build_runner` if modifying files with `.g.dart` counterparts
- Commit each logical batch with a descriptive message

### Exceptions (not violations)
- Files: `app_colors.dart`, `app_sizes.dart`, `app_durations.dart`, `app_theme.dart`, `app_theme_extension.dart` (definitions)
- Generated: `*.g.dart`, `*.freezed.dart`, l10n files
- Data: `egyptian_arabic_finance.json`, `egyptian_sms_patterns.dart`
- Non-UI: log messages, route paths, enum values, JSON keys, asset paths, regex
