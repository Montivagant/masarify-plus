#!/bin/bash
# PostToolUse hook: Auto-format Dart files after Edit/Write
# Reads the tool input from stdin, extracts file_path, runs dart format if it's a .dart file

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only format .dart files (skip generated files)
if [[ "$FILE_PATH" == *.dart ]] && [[ "$FILE_PATH" != *.g.dart ]] && [[ "$FILE_PATH" != *.freezed.dart ]]; then
  if [ -f "$FILE_PATH" ]; then
    dart format "$FILE_PATH" 2>/dev/null
  fi
fi

exit 0
