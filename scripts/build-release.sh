#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Load API keys from .env file if it exists.
# Uses array to avoid shell injection from unquoted expansion.
DART_DEFINES=()
if [ -f .env ]; then
  while IFS= read -r line || [ -n "$line" ]; do
    # Strip Windows CRLF line endings
    line="${line%$'\r'}"
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    # Skip lines without '='
    [[ "$line" != *=* ]] && continue
    # Split on first '=' only (preserves '=' in values like base64 tokens)
    key="${line%%=*}"
    value="${line#*=}"
    DART_DEFINES+=("--dart-define=${key}=${value}")
  done < .env
  echo "Loaded API keys from .env"
else
  echo "WARNING: No .env file found. AI features will be disabled."
fi

echo "Building Masarify release APK (arm64-v8a only, fast sideload)..."
# ${DART_DEFINES[@]+...} avoids 'unbound variable' error on empty array (bash <4.4 + set -u).
# Single-ABI + no obfuscation = ~3x faster than split-per-abi + obfuscate.
# For Play Store builds, use `flutter build appbundle --release --obfuscate ...` instead.
flutter build apk --release \
  --target-platform android-arm64 \
  ${DART_DEFINES[@]+"${DART_DEFINES[@]}"}

APK="build/app/outputs/flutter-apk/app-release.apk"

echo ""
echo "=== Release APK ==="
if [ -f "$APK" ]; then
  size=$(du -h "$APK" | cut -f1)
  echo "  $(basename "$APK")  ($size)"
fi

echo ""
echo "=== Install ==="
echo "  adb install -r $APK"
echo ""
echo "  NOTE: This build targets arm64-v8a only (covers 95%+ of modern phones)."
echo "  For Play Store distribution, run: flutter build appbundle --release --obfuscate \\"
echo "                                      --split-debug-info=build/debug_info"
