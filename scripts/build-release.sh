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

echo "Building Masarify release APKs (split by ABI)..."
# ${DART_DEFINES[@]+...} avoids 'unbound variable' error on empty array (bash <4.4 + set -u).
# --obfuscate + --split-debug-info: strips symbols → smaller APK + code protection.
# Debug symbols saved to build/debug_info/ for crash symbolication.
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/debug_info \
  ${DART_DEFINES[@]+"${DART_DEFINES[@]}"}

APK_DIR="build/app/outputs/flutter-apk"

echo ""
echo "=== Release APKs ==="
for apk in "$APK_DIR"/app-*-release.apk; do
  name=$(basename "$apk")
  size=$(du -h "$apk" | cut -f1)
  echo "  $name  ($size)"
done

echo ""
echo "=== Distribution Guide ==="
echo "  Modern phones (95%+): app-arm64-v8a-release.apk"
echo "  Old 32-bit phones:    app-armeabi-v7a-release.apk"
echo "  Emulators:            app-x86_64-release.apk"
echo ""
echo "  IMPORTANT: Do NOT send via WhatsApp/Telegram — they corrupt APK files."
echo "  Use Google Drive, GitHub Releases, or direct USB transfer instead."
