---
description: Code review with DCM metrics, dart analyzer, and 9-category architecture audit
argument-hint: <file path, feature name, or 'all' for full audit>
---

# Code Review Mode

Perform a comprehensive code review using MCP tools and architecture rules.

## Review Pipeline

### Step 1: Static Analysis
Run `flutter analyze lib/` via Bash. Flag all warnings and errors.
(Note: `dart` MCP analyzer tools broken on Windows — see Known Issues in CLAUDE.md)

### Step 2: DCM Metrics
Run `bash scripts/analyze.sh dcm` via Bash to analyze:
- Cyclomatic complexity (flag >10)
- Lines of executable code per method (flag >50)
- Unused code: `bash scripts/analyze.sh dcm-unused`
- Anti-patterns (long parameter lists, nested conditionals)
(Note: `dcm` MCP tools broken on Windows — use CLI workaround script)

### Step 3: Architecture Audit
Scan for violations of Masarify's architecture rules:

| Category | What to Check |
|----------|--------------|
| **Design tokens** | No hardcoded `Color(0x`, `Colors.`, `EdgeInsets` numbers, `TextStyle` with raw fontSize, `BorderRadius.circular` with raw numbers, `SizedBox` with raw dimensions, `Duration` with raw values |
| **L10n** | No hardcoded Arabic/English UI text outside `.arb` files |
| **Navigation** | No `Navigator.push()` / `Navigator.pop()` — only `context.go()` / `context.push()` / `context.pop()` |
| **State** | No `setState` in `ConsumerWidget`. No direct DB access outside repositories |
| **Domain purity** | No Flutter/Drift imports in `domain/` layer |
| **Money** | No `double` for monetary values — integer piastres only |

### Step 4: Severity Classification
Report each issue as:
- **[CRITICAL]** — Breaks a core rule, causes bugs, or violates architecture
- **[WARNING]** — Code smell, potential issue, or maintainability concern
- **[INFO]** — Suggestion for improvement, minor style issue

## Target: $ARGUMENTS
