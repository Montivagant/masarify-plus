#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Building Masarify release APKs (split by ABI)..."
flutter build apk --release --split-per-abi

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
