---
description: Full 9-category surgical codebase audit with parallel agents
argument-hint: <'full' for all categories, or category number 1-9, or 'quick' for sweep>
---

# Codebase Audit Mode

## Audit Scope: $ARGUMENTS

### 9 Categories

| # | Category | Tool |
|---|----------|------|
| 1 | Dead code & unused files | `bash scripts/analyze.sh dcm-unused` + Grep |
| 2 | Unused dependencies | Grep `pubspec.yaml` vs `lib/` imports |
| 3 | Hardcoded styles (non-tokenized) | Grep for `Color(0x`, `Colors.`, raw `EdgeInsets`, etc. |
| 4 | Hardcoded text (non-l10n) | Grep for Arabic chars, hardcoded English UI strings |
| 5 | Architecture violations | Grep for `Navigator.push`, `setState`, Flutter imports in `domain/` |
| 6 | File & folder structure | Feature-first structure, import ordering |
| 7 | Code quality | BuildContext after async, missing const, empty catch |
| 8 | `flutter analyze lib/` | Zero issues required |
| 9 | `flutter test` | All tests pass |

**Quick Sweep:** categories 3, 5, 8 only.

### Execution
- Run independent categories in parallel (1-2, 3-4, 5-7, then 8, then 9)
- Fix in place, use existing tokens, commit each batch

### Exceptions (not violations)
- Definition files: `app_colors.dart`, `app_sizes.dart`, `app_durations.dart`, `app_theme.dart`, `app_theme_extension.dart`
- Generated: `*.g.dart`, `*.freezed.dart`, l10n files
- Data: `egyptian_sms_patterns.dart`, `voice_dictionary.dart`
- Non-UI: log messages, route paths, enum values, JSON keys, regex
