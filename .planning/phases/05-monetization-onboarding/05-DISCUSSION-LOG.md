# Phase 5: Monetization & Onboarding - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-03-28
**Phase:** 05-monetization-onboarding
**Mode:** assumptions
**Areas analyzed:** Free Tier Enforcement, Paywall UI & Restore Flow, Onboarding Polish, Trial Activation Wiring, Financial Disclaimer

## Assumptions Presented

### Free Tier Enforcement
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Budget/goal providers have zero pro gating; gate at save-time | Confident | budget_provider.dart, goal_provider.dart — no hasProAccessProvider reference |
| SetBudgetScreen._save() and AddGoalScreen._save() call repos directly without count checks | Confident | set_budget_screen.dart lines 119-160, add_goal_screen.dart lines 112-150 |
| ProFeatureGuard exists but not deployed on ChatScreen | Confident | pro_feature_guard.dart (107 lines) exists; chat_screen.dart has no reference |
| Transaction logging never gated | Confident | Core value constraint — no gate on AddTransactionScreen |

### Paywall UI & Restore Flow
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| Feature list puts budgets before AI; needs reorder | Confident | paywall_screen.dart line 89 (budgets) vs line 113 (AI chat) |
| No explicit pricing/trial terms above purchase button | Likely | L10n has paywall_monthly(price) but no trial terms string |
| No "Manage subscription" deep link button | Confident | Only "Restore Purchases" TextButton at line 279 |
| Restore button on PaywallScreen but not SubscriptionScreen | Confident | subscription_screen.dart lines 26-96 — no restore button |
| No Pro status row in SettingsScreen | Confident | Settings has no subscription section |
| restorePurchases() not wired to AppLifecycleState.resumed | Confident | app.dart resumed only calls _checkAutoLock() |

### Onboarding Polish
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| 5th page ("account selection") may already be removed; current page 4 = Starting Balance | Likely | onboarding_screen.dart line 37: _pageCount = 5, comments list pages 0-4 |
| Auto-creation of default bank account already in _finish() | Confident | Lines 85-108: walletRepo.ensureSystemWalletExists() + create(isDefaultAccount: true) |
| Skip/back/indicator exist but may need polish | Likely | Skip buttons (lines 150-169), PageController (lines 66-78), SmoothPageIndicator (lines 227-240) |
| No financial disclaimer anywhere in codebase | Confident | Zero grep hits for disclaimer/regulated financial/budgeting guidance |

### Trial Activation Wiring
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| ensureTrialStarted() still in main.dart line 87; must move to _finish() | Confident | unawaited(subService.ensureTrialStarted()) at main.dart line 87 |
| OnboardingScreen._finish() does not call ensureTrialStarted() | Confident | Lines 85-125: creates wallet, marks done, no trial start |
| No trial-started snackbar after onboarding | Likely | _SuccessOverlay shows generic "Ready to go", no trial message |
| Trial countdown in SubscriptionScreen/PaywallScreen already works | Confident | trialDaysRemainingProvider defined, PaywallScreen displays it |

### Financial Disclaimer
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| No disclaimer text exists in codebase or l10n | Confident | Zero grep results |
| Onboarding page 3 = AI slide — intended disclaimer location | Likely | Page 3 shows ChatDemo widget per code |
| ChatScreen has no disclaimer banner | Confident | No banner widget in build method |
| First-entry detection via PreferencesService flag | Likely | Established pattern for hasCompletedOnboarding |

## Corrections Made

No corrections — all assumptions confirmed.

---

*Phase: 05-monetization-onboarding*
*Discussion logged: 2026-03-28*
