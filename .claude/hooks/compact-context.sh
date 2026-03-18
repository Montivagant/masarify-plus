#!/bin/bash
# SessionStart hook (compact matcher): Re-inject critical context after compaction
# This ensures key project rules survive context window compaction

cat << 'EOF'
COMPACTION CONTEXT RELOAD — Masarify-Plus:
- Money: INTEGER piastres always (100 EGP = 10000). Never double. MoneyFormatter for display.
- Offline-first: No internet required for core features.
- RTL-first: Arabic RTL validation on every screen.
- Design tokens: context.colors, AppIcons.*, AppSizes.*, context.appTheme.* — NEVER hardcode.
- Navigation: go_router ONLY (context.go/push). NEVER Navigator.push().
- State: ConsumerWidget/ConsumerStatefulWidget. NEVER setState (except AnimationController).
- Domain layer: pure Dart only (zero Flutter/Drift imports).
- After edits: flutter analyze lib/ must be zero issues.
- MCP tools available: dart (analyzer), dcm (metrics), flutter-inspector (live app), context7 (docs), sequential-thinking (reasoning).
EOF

exit 0
