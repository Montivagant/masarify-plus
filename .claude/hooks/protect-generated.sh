#!/bin/bash
# PreToolUse hook: Block edits to generated files, lock files, and build outputs
# Exit 2 = block the action

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

PROTECTED_PATTERNS=(
  ".g.dart"
  ".freezed.dart"
  "pubspec.lock"
  ".dart_tool/"
  "build/"
  ".flutter-plugins"
  "app_localizations.dart"
  "app_localizations_en.dart"
  "app_localizations_ar.dart"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: $FILE_PATH is a generated/protected file. Modify the source instead." >&2
    exit 2
  fi
done

exit 0
