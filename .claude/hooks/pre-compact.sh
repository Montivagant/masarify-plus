#!/usr/bin/env bash
# PreCompact hook — injects critical project rules into compaction context
# so they survive context window compression.

cat <<'CONTEXT'
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "CRITICAL RULES TO PRESERVE:\n1. Money = INTEGER piastres (100 EGP = 10000). Never double.\n2. 100% offline-first. No Firebase/internet for core features.\n3. RTL-first. Every screen validated in Arabic RTL.\n4. Design tokens are LAW: context.colors, AppIcons.*, AppSizes.*, context.appTheme.* — NEVER hardcode.\n5. MasarifyDS components always. Never inline layout primitives.\n6. ConsumerWidget/ConsumerStatefulWidget only. Never raw StatefulWidget for screens.\n7. Never Navigator.push() — use context.go() / context.push().\n8. domain/ = pure Dart only (zero Flutter/Drift imports).\n9. VERIFY before claiming done: run flutter analyze lib/ — zero errors required.\n10. Protected files: *.g.dart, *.freezed.dart, app_localizations*.dart — edit sources, not generated files."
  }
}
CONTEXT
