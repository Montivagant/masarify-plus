---
phase: 05
slug: monetization-onboarding
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-28
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Dart) |
| **Config file** | `pubspec.yaml` (dev_dependencies: flutter_test) |
| **Quick run command** | `flutter analyze lib/` |
| **Full suite command** | `flutter analyze lib/ && flutter test` |
| **Estimated runtime** | ~45 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze lib/`
- **After every plan wave:** Run `flutter analyze lib/ && flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 45 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | PAYWALL-01 | manual | Budget gate: create 3rd budget as free user → paywall redirect | N/A | ⬜ pending |
| 05-01-02 | 01 | 1 | PAYWALL-01 | manual | Goal gate: create 2nd goal as free user → paywall redirect | N/A | ⬜ pending |
| 05-01-03 | 01 | 1 | PAYWALL-01 | manual | ProFeatureGuard blocks chat for expired-trial, non-Pro | N/A | ⬜ pending |
| 05-01-04 | 01 | 1 | PAYWALL-01 | analyzer | `flutter analyze lib/` | ✅ | ⬜ pending |
| 05-02-01 | 02 | 1 | PAYWALL-03 | manual | Feature list: AI first in PaywallScreen | N/A | ⬜ pending |
| 05-02-02 | 02 | 1 | PAYWALL-06 | manual | Restore button on both PaywallScreen and SubscriptionScreen | N/A | ⬜ pending |
| 05-02-03 | 02 | 1 | PAYWALL-03 | manual | Pro status row in Settings with correct badge | N/A | ⬜ pending |
| 05-02-04 | 02 | 1 | PAYWALL-03 | analyzer | `flutter analyze lib/` | ✅ | ⬜ pending |
| 05-03-01 | 03 | 2 | ONBOARD-01 | manual | Onboarding 5 pages, auto-create account in _finish() | N/A | ⬜ pending |
| 05-03-02 | 03 | 2 | ONBOARD-02 | manual | Skip/back buttons, smooth transitions, page indicator | N/A | ⬜ pending |
| 05-03-03 | 03 | 2 | ONBOARD-03 | manual | Financial disclaimer on page 3 and ChatScreen | N/A | ⬜ pending |
| 05-03-04 | 03 | 2 | ONBOARD-03 | analyzer | `flutter analyze lib/` | ✅ | ⬜ pending |
| 05-04-01 | 04 | 2 | PAYWALL-04 | manual | ensureTrialStarted() in _finish(), snackbar shown | N/A | ⬜ pending |
| 05-04-02 | 04 | 2 | PAYWALL-04 | manual | Trial countdown in SubscriptionScreen and PaywallScreen | N/A | ⬜ pending |
| 05-04-03 | 04 | 2 | PAYWALL-04 | analyzer | `flutter analyze lib/` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements. No new test framework needed.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Budget create gate | PAYWALL-01 | Requires UI interaction + provider state | Create 2 budgets → verify 3rd redirects to paywall |
| Goal create gate | PAYWALL-01 | Requires UI interaction + provider state | Create 1 goal → verify 2nd redirects to paywall |
| AI chat gate | PAYWALL-01 | Requires trial expiry simulation | Set trial expired in prefs → verify chat blocked |
| Paywall feature order | PAYWALL-03 | Visual verification | Open PaywallScreen → verify AI features listed first |
| Restore purchases | PAYWALL-06 | Requires Google Play sandbox | Tap restore → verify BillingClient call fires |
| Manage subscription link | PAYWALL-03 | Requires device browser | Tap manage → verify Play Store opens |
| Onboarding disclaimer | ONBOARD-03 | Visual verification | Complete onboarding → verify disclaimer on page 3 |
| ChatScreen disclaimer | ONBOARD-03 | Visual verification + prefs | First chat entry → verify banner shown, dismiss persists |
| Trial snackbar | PAYWALL-04 | Requires clean app state | Clear prefs → complete onboarding → verify snackbar |
| Pro status badge | PAYWALL-03 | Visual verification | Check settings → verify badge matches subscription state |
| Silent restore throttle | PAYWALL-06 | Requires lifecycle testing | Resume app twice within 1 hour → verify only 1 restore call |
| RTL disclaimer | ONBOARD-03 | Visual verification | Switch to Arabic → verify disclaimer renders RTL correctly |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 45s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
