---
phase: 05
plan: 02
status: complete
started: "2026-03-27T23:40:00Z"
completed: "2026-03-27T23:49:29Z"
---

## Plan: Paywall UI & Restore Flow

### One-liner
Reordered paywall features to lead with AI, added pricing terms, restore/manage subscription buttons, Pro status in Settings, and silent restore on app resume.

### Tasks Completed
| # | Task | Status |
|---|------|--------|
| 1 | Reorder PaywallScreen feature list to lead with AI features | done |
| 2 | Add pricing terms text above purchase buttons on PaywallScreen | done |
| 3 | Add url_launcher dependency and Manage Subscription button to SubscriptionScreen | done |
| 4 | Add Pro status row to SettingsScreen | done |
| 5 | Wire silent restorePurchases() on app resume with throttling | done |

### Key Files
**Created:** (none)
**Modified:**
- `lib/features/monetization/presentation/screens/paywall_screen.dart` — reordered features, added pricing terms
- `lib/features/monetization/presentation/screens/subscription_screen.dart` — added restore + manage subscription buttons
- `lib/features/settings/presentation/screens/settings_screen.dart` — added Pro status row
- `lib/app/app.dart` — silent restore on resume with 60-min throttle
- `lib/l10n/app_en.arb` — added paywall_pricing_terms, subscription_manage, settings_pro_status, settings_pro_trial_days, settings_pro_free
- `lib/l10n/app_ar.arb` — Arabic translations for all new keys
- `pubspec.yaml` — added url_launcher ^6.3.1

### Deviations
None

### Self-Check
`flutter analyze lib/` — 3 pre-existing errors (env.dart stub, gitignored file not found) + 0 new issues. All new code is clean.
