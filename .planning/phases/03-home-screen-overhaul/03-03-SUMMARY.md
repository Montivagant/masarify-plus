---
phase: 03-home-screen-overhaul
plan: 03
subsystem: ui
tags: [voice-input, glassmorphism, rtl, pageview, flutter, riverpod]

requires:
  - phase: 03-01
    provides: "CustomScrollView sliver architecture, GlassCard components, design tokens"
provides:
  - "Revamped VoiceConfirmScreen with glassmorphic full-screen form"
  - "Extracted DraftCard widget for voice transaction review"
  - "Multi-draft PageView with Save & Next flow"
  - "Missing amount handling with disabled Save button"
  - "RTL-aware transfer display with flipped directional arrows"
  - "Subscription suggestion banners on voice drafts"
affects: [voice-input, onboarding, ai-chat]

tech-stack:
  added: []
  patterns:
    - "EditableDraft model extracted to public class for cross-widget sharing"
    - "PageView with page indicator dots for multi-item review flows"
    - "context.isRtl extension for RTL-aware arrow flipping (avoids intl TextDirection shadow)"

key-files:
  created:
    - "lib/features/voice_input/presentation/widgets/draft_card.dart"
  modified:
    - "lib/features/voice_input/presentation/screens/voice_confirm_screen.dart"
    - "lib/l10n/app_en.arb"
    - "lib/l10n/app_ar.arb"
    - "lib/l10n/app_localizations.dart"
    - "lib/l10n/app_localizations_ar.dart"
    - "lib/l10n/app_localizations_en.dart"

key-decisions:
  - "Used context.isRtl instead of Directionality.of(context) == TextDirection.rtl to avoid intl package TextDirection shadowing"
  - "Inline keyword-based subscription detection (no external SubscriptionDetector dependency)"
  - "PageView chosen over stacked list for multi-draft — one draft at a time, full focus, fewer distractions"

patterns-established:
  - "EditableDraft as public class shared between screen and card widget"
  - "Save & Next pattern with page indicator dots for multi-item review"

requirements-completed: [TXN-07]

duration: 8min
completed: 2026-03-27
---

# Phase 03 Plan 03: Voice Confirm Screen Revamp Summary

**Glassmorphic VoiceConfirmScreen with type-colored amounts, tappable fields, multi-draft PageView, missing-amount handling, and RTL-safe transfer arrows**

## Performance

- **Duration:** 8 min
- **Started:** 2026-03-27T20:00:57Z
- **Completed:** 2026-03-27T20:08:57Z
- **Tasks:** 1
- **Files modified:** 7

## Accomplishments
- Complete UI revamp of VoiceConfirmScreen from ~400-line flat list to modern glassmorphic form
- Extracted DraftCard widget with type indicator chips, prominent type-colored amount display (+/- sign), tappable category/account/date/notes fields, subscription suggestion banner
- Multi-draft support via PageView with animated page indicator dots, Save & Next flow, and auto-pop when all drafts saved
- Missing amount handling: error-highlighted field, warning message, auto-focused input, disabled Save button
- RTL-aware transfer display: From/To account fields with directional arrow that flips via Transform.flip in Arabic mode
- 11 new l10n keys added to both English and Arabic ARB files

## Task Commits

Each task was committed atomically:

1. **Task 1: Revamp VoiceConfirmScreen with glassmorphic full-screen form** - `9941474` (feat)

## Files Created/Modified
- `lib/features/voice_input/presentation/widgets/draft_card.dart` - New extracted DraftCard widget with type chips, amount section, category/account/date/notes fields, subscription suggestion, and goal suggestion
- `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` - Complete rewrite: single draft → full-screen form, multi-draft → PageView with Save & Next, extracted save logic into _saveDraft
- `lib/l10n/app_en.arb` - 11 new voice_confirm_* keys
- `lib/l10n/app_ar.arb` - 11 new voice_confirm_* keys (Arabic translations)
- `lib/l10n/app_localizations.dart` - Auto-generated from ARB
- `lib/l10n/app_localizations_en.dart` - Auto-generated from ARB
- `lib/l10n/app_localizations_ar.dart` - Auto-generated from ARB

## Decisions Made
- Used `context.isRtl` extension (from build_context_extensions.dart) instead of direct `Directionality.of(context) == TextDirection.rtl` because the `intl` package import shadows dart:ui's TextDirection enum values
- Inline keyword-based subscription detection instead of importing uncommitted SubscriptionDetector utility (matches Phase 02 decision pattern)
- PageView chosen over stacked list for multi-draft review — one draft at a time provides full focus without scrolling between drafts, and the page indicator gives clear progress feedback

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] intl package TextDirection shadowing**
- **Found during:** Task 1 (DraftCard implementation)
- **Issue:** `TextDirection.rtl` failed analysis because `intl` package has its own `TextDirection` that shadows `dart:ui.TextDirection`
- **Fix:** Used `context.isRtl` extension already defined in `build_context_extensions.dart`
- **Files modified:** `lib/features/voice_input/presentation/widgets/draft_card.dart`
- **Verification:** `flutter analyze lib/features/voice_input/` — no issues
- **Committed in:** 9941474 (Task 1 commit)

**2. [Rule 3 - Blocking] env.dart stub missing in worktree**
- **Found during:** Task 1 (full project analysis verification)
- **Issue:** Gitignored env.dart not present in worktree, causing 3 pre-existing errors in ai_config.dart
- **Fix:** Created env.dart stub with dart-define environment variables (same pattern as main repo)
- **Files modified:** `lib/core/config/env.dart` (gitignored, not committed)
- **Verification:** `flutter analyze lib/` — no issues
- **Committed in:** Not committed (gitignored file)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes necessary for compilation. No scope creep.

## Known Stubs

None — all fields are wired to real data sources via Riverpod providers and save logic.

## Issues Encountered
None beyond the auto-fixed deviations above.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- Voice confirm screen is fully revamped and ready for integration testing
- All Phase 03 plans (01, 02, 03) can now be verified together
- The extracted DraftCard widget can be reused if other screens need similar form patterns

## Self-Check: PASSED

---
*Phase: 03-home-screen-overhaul*
*Completed: 2026-03-27*
