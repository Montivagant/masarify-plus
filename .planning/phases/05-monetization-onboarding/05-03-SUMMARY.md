---
phase: 05
plan: 03
status: complete
started: "2026-03-28T00:00:00.000Z"
completed: "2026-03-28T00:30:00.000Z"
---

## Plan: Onboarding Polish

### One-liner
Fixed missing l10n keys, updated onboarding slide 3 to AI-first branding, added financial disclaimers to onboarding and AI chat, and verified transition polish.

### Tasks Completed
| # | Task | Status |
|---|------|--------|
| 1 | Fix missing onboarding_demo_chat l10n keys and update slide 3 text | done |
| 2 | Add financial disclaimer to onboarding page 3 (AI slide) | done |
| 3 | Add hasSeenAiDisclaimer flag to PreferencesService | done |
| 4 | Add AI disclaimer banner to ChatScreen on first visit | done |
| 5 | Remove dead AccountTypePicker code from onboarding_pages.dart | skipped |
| 6 | Verify and polish onboarding transitions | done (no changes needed) |

### Key Files
**Created:** (none besides gitignored env.dart stub for analyzer)
**Modified:**
- `lib/l10n/app_en.arb` (added onboarding_demo_chat_user, onboarding_demo_chat_ai, disclaimer_financial, disclaimer_ai_content; updated onboarding_slide3_title/body)
- `lib/l10n/app_ar.arb` (same keys in Arabic)
- `lib/features/onboarding/presentation/widgets/onboarding_pages.dart` (added footerWidget parameter to ValuePreviewSlide)
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` (page 3 updated: AI icon, disclaimer footer)
- `lib/core/services/preferences_service.dart` (added hasSeenAiDisclaimer flag)
- `lib/features/ai_chat/presentation/screens/chat_screen.dart` (added dismissible disclaimer banner)

### Deviations
- **Task 05-03-05 skipped:** Plan stated AccountTypePicker is dead code, but it is actively used as page 4 of the onboarding flow (referenced in onboarding_screen.dart line 221). Removing it would break the 5-page onboarding. The plan's research was based on a different codebase state where this page had been removed.

### Self-Check
- `flutter analyze lib/` -- No issues found (ran in 3.6s)
- `flutter gen-l10n` -- No errors
- All 4 new l10n keys present in both ARB files
- Onboarding slide 3 title updated from "SMS Auto-Detect" to "Your AI Financial Advisor"
- Financial disclaimer visible on onboarding page 3 via footerWidget
- Dismissible disclaimer banner on ChatScreen controlled by hasSeenAiDisclaimer preference
- Page count still 5, skip/back/indicator all verified correct
