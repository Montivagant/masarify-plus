---
phase: 05
plan: 04
status: complete
started: "2026-03-28T00:10:00.000Z"
completed: "2026-03-28T00:25:00.000Z"
---

## Plan: Trial Activation Wiring

### One-liner
Moved trial activation from main.dart (every launch) to OnboardingScreen._finish() (once after account creation), added a "7-day Pro trial started" snackbar, and fixed the trial duration from 14 to 7 days.

### Tasks Completed
| # | Task | Status |
|---|------|--------|
| 1 | Remove ensureTrialStarted() from main.dart | done |
| 2 | Wire ensureTrialStarted() in OnboardingScreen._finish() with snackbar | done |
| 3 | Verify trial countdown displays on SubscriptionScreen and PaywallScreen | done |

### Key Files
**Created:** (none)
**Modified:**
- `lib/main.dart` — Removed `unawaited(subService.ensureTrialStarted())` line
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — Added ensureTrialStarted() call after wallet creation + trial snackbar after success overlay
- `lib/core/services/subscription_service.dart` — Fixed _trialDays from 14 to 7, updated comment
- `lib/l10n/app_en.arb` — Added `trial_started_message` key
- `lib/l10n/app_ar.arb` — Added `trial_started_message` key
- `lib/l10n/app_localizations*.dart` — Regenerated via flutter gen-l10n

### Deviations
- Task 3 (verification) found `_trialDays = 14` in SubscriptionService, which contradicted the documented 7-day trial requirement. Fixed to `_trialDays = 7`.

### Self-Check
`flutter analyze lib/` — No issues found.
