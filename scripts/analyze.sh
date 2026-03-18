#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# ── Masarify Code Analysis Script ─────────────────────────────────────────────
#
# Workaround for broken dart/dcm MCP tools on Windows.
# Claude Code registers project roots as file://D:\path (2 slashes, backslashes)
# instead of file:///D:/path (3 slashes, forward slashes per RFC 8089).
# This makes ALL root-dependent MCP tools unusable.
# Bug report: https://github.com/anthropics/claude-code/issues
#
# Usage:
#   bash scripts/analyze.sh              # Full analysis (analyzer + DCM if licensed)
#   bash scripts/analyze.sh quick        # Flutter analyzer only
#   bash scripts/analyze.sh <path>       # Analyze specific path
#   bash scripts/analyze.sh dcm          # DCM only (requires license)
#   bash scripts/analyze.sh dcm-unused   # DCM unused code check
# ──────────────────────────────────────────────────────────────────────────────

MODE="${1:-full}"
TARGET="${2:-lib/}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}=== Masarify Code Analysis ===${NC}"
echo ""

# ── Flutter Analyzer ──────────────────────────────────────────────────────────

run_flutter_analyze() {
  local path="${1:-lib/}"
  echo -e "${CYAN}[1/2] Flutter Analyzer${NC} — ${path}"
  if flutter analyze "$path" 2>&1; then
    echo -e "${GREEN}  ✓ No issues found${NC}"
  else
    echo -e "${RED}  ✗ Issues found — fix before committing${NC}"
    return 1
  fi
  echo ""
}

# ── DCM Analysis ──────────────────────────────────────────────────────────────

run_dcm_analyze() {
  local path="${1:-lib/}"
  echo -e "${CYAN}[2/2] DCM Analyze${NC} — ${path}"

  if ! command -v dcm &>/dev/null; then
    echo -e "${YELLOW}  ⚠ DCM not installed. Install: dart pub global activate dcm${NC}"
    return 0
  fi

  # Run DCM — if it fails with a license error, catch and report.
  local output
  if ! output=$(dcm analyze "$path" \
    --exclude="{**/*.g.dart,**/*.freezed.dart,**/*.mapper.dart}" \
    2>&1); then
    if echo "$output" | grep -qi "not activated\|license"; then
      echo -e "${YELLOW}  ⚠ DCM not activated. Run: dcm activate --license-key=YOUR_KEY${NC}"
      echo -e "${YELLOW}    DCM MCP server works without CLI license — use MCP when URI bug is fixed.${NC}"
      return 0
    fi
    # Non-license failure — show the output
    echo "$output"
  else
    echo "$output"
  fi
  echo ""
}

run_dcm_unused() {
  local path="${1:-lib/}"
  echo -e "${CYAN}[DCM] Unused Code Check${NC} — ${path}"

  if ! command -v dcm &>/dev/null; then
    echo -e "${YELLOW}  ⚠ DCM not installed${NC}"
    return 0
  fi

  dcm check-unused-code "$path" \
    --exclude="{**/*.g.dart,**/*.freezed.dart,**/*.mapper.dart}" \
    2>&1 || true
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────

case "$MODE" in
  full)
    run_flutter_analyze "$TARGET"
    run_dcm_analyze "$TARGET"
    ;;
  quick)
    run_flutter_analyze "$TARGET"
    ;;
  dcm)
    run_dcm_analyze "$TARGET"
    ;;
  dcm-unused)
    run_dcm_unused "$TARGET"
    ;;
  *)
    # Check if argument looks like a path (contains / or \ or ends with .dart)
    if [[ -e "$MODE" || "$MODE" == *.dart || "$MODE" == lib/* ]]; then
      run_flutter_analyze "$MODE"
      run_dcm_analyze "$MODE"
    else
      echo -e "${RED}Unknown mode: ${MODE}${NC}"
      echo ""
      echo "Usage:"
      echo "  bash scripts/analyze.sh              # Full analysis (analyzer + DCM)"
      echo "  bash scripts/analyze.sh quick        # Flutter analyzer only"
      echo "  bash scripts/analyze.sh <path>       # Analyze specific path"
      echo "  bash scripts/analyze.sh dcm          # DCM only (requires license)"
      echo "  bash scripts/analyze.sh dcm-unused   # DCM unused code check"
      exit 1
    fi
    ;;
esac

echo -e "${CYAN}=== Analysis Complete ===${NC}"
