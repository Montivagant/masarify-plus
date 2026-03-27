#!/usr/bin/env bash
# Stop hook: run flutter analyze if .dart files were modified in the working tree.
# Exits 0 (allow stop) always — warns but never blocks.
# This prevents the hook from trapping the user in a session they can't close.

cd "$CLAUDE_PROJECT_DIR" || exit 0

# Check if any .dart files have uncommitted changes (staged or unstaged)
if ! git diff --name-only HEAD --diff-filter=ACMR 2>/dev/null | grep -q '\.dart$'; then
  # No modified dart files — allow stop
  exit 0
fi

# Run flutter analyze — warn if issues found, but always allow stop
output=$(flutter analyze lib/ 2>&1)
if echo "$output" | grep -q "No issues found"; then
  exit 0
else
  echo "⚠ flutter analyze found issues (session still closing):"
  echo "$output" | tail -20
  exit 0
fi
