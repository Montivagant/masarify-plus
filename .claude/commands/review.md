---
description: Code review with DCM metrics, dart analyzer, and architecture audit
argument-hint: <file path, feature name, or 'all' for full audit>
---

# Code Review Mode

## Review Pipeline

### Step 1: Static Analysis
Run `flutter analyze lib/` via Bash. Flag all warnings and errors.

### Step 2: DCM Metrics
Run `bash scripts/analyze.sh dcm` — flag cyclomatic complexity >10, methods >50 LOC.
Unused code: `bash scripts/analyze.sh dcm-unused`

### Step 3: Architecture Audit
Scan for violations of rules in `CLAUDE.md` and `.claude/rules/dart-conventions.md`.

### Step 4: Severity Classification
- **[CRITICAL]** — Breaks a core rule or causes bugs
- **[WARNING]** — Code smell or maintainability concern
- **[INFO]** — Suggestion for improvement

## Target: $ARGUMENTS
