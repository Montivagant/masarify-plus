#!/usr/bin/env bash
# Stop hook: run flutter analyze if .dart files were modified in the working tree.
# Exits 0 (allow stop) if no dart changes or analysis passes.
# Exits 2 (block stop) if analysis finds issues.

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Check if any .dart files have uncommitted changes (staged or unstaged)
if ! git diff --name-only HEAD --diff-filter=ACMR 2>/dev/null | grep -q '\.dart$'; then
  # No modified dart files — allow stop
  exit 0
fi

# Run flutter analyze — block stop if issues found
output=$(flutter analyze lib/ 2>&1)
if echo "$output" | grep -q "No issues found"; then
  exit 0
else
  echo "flutter analyze found issues — fix before stopping:"
  echo "$output" | tail -20
  exit 2
fi
