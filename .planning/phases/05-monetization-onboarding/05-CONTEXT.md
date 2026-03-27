# Phase 5: Monetization & Onboarding - Context

**Gathered:** 2026-03-28 (assumptions mode)
**Status:** Ready for planning

<domain>
## Phase Boundary

Wire the revenue pipeline correctly, enforce free-tier limits gracefully, and polish the first-run experience including the financial disclaimer. Requirements: PAYWALL-01, PAYWALL-03, PAYWALL-06, ONBOARD-01, ONBOARD-02, ONBOARD-03. Also: Trial Activation Wiring (PAYWALL-04 call site — method fixed in Phase 1, wired here).

Note: PAYWALL-02, PAYWALL-04, and PAYWALL-05 are in Phase 1 (billing infrastructure). This phase wires the user-facing gates and purchase flow.

</domain>

<decisions>
## Implementation Decisions

### Free Tier Enforcement (PAYWALL-01)
- **D-01:** Gate at save-time, not provider-level. `SetBudgetScreen._save()` must check `if (!hasPro && budgetCount >= 2)` → `context.push(AppRoutes.paywall)` instead of saving. Same pattern for `AddGoalScreen._save()` with limit of 1.
- **D-02:** Add lock badge overlays on `BudgetsScreen` and goals screen when limit is reached. Visual indicator: lock icon on the "Add" FAB or a subtle banner.
- **D-03:** Wrap AI chat entry behind `ProFeatureGuard` for non-trial, non-Pro users. The guard widget already exists at `lib/shared/widgets/guards/pro_feature_guard.dart`. Transaction logging is NEVER gated.
- **D-04:** Count check reads from existing providers (`budgetsByMonthProvider`, `activeGoalsProvider`) at the moment of save. No provider-level clamping — free users can still VIEW all their data if they downgrade.

### Paywall UI & Restore Flow (PAYWALL-03, PAYWALL-06)
- **D-05:** Reorder PaywallScreen feature list: AI Financial Assistant first, then AI spending insights, unlimited budgets, unlimited goals, advanced analytics, cloud backup, export.
- **D-06:** Show explicit pricing and trial terms ABOVE the purchase button: "59 EGP/month — 7 days free — Cancel anytime". Add l10n keys for both EN and AR.
- **D-07:** Add "Manage subscription" button opening `https://play.google.com/store/account/subscriptions?package=com.masarify.app` via `url_launcher`.
- **D-08:** Add "Restore Purchases" button to BOTH PaywallScreen AND SubscriptionScreen.
- **D-09:** Add "Masarify Pro" status row to SettingsScreen with badge (Pro / Trial X days / Free) and chevron navigating to SubscriptionScreen.
- **D-10:** Wire `restorePurchases()` silently on every `AppLifecycleState.resumed` in `app.dart` — alongside existing `_checkAutoLock()`.

### Onboarding Polish (ONBOARD-01, ONBOARD-02)
- **D-11:** Verify current onboarding page count and content. If the "What's Your Main Account" page still exists, remove it. If already removed (page 4 = Starting Balance), confirm auto-create default bank account in `_finish()` is working. This is a verification + cleanup task.
- **D-12:** Polish transitions: verify skip/back buttons work on all pages, smooth PageController animations, verify SmoothPageIndicator renders correctly. Minor refinement, not new features.

### Financial Disclaimer (ONBOARD-03)
- **D-13:** Add disclaimer text to onboarding page 3 (AI Advisor slide): "Masarify provides budgeting guidance only, not regulated financial, investment, or tax advice." Positioned below the ChatDemo widget.
- **D-14:** Add persistent disclaimer banner on first entry to ChatScreen. Use `PreferencesService` flag (`hasSeenAiDisclaimer`) to show a dismissible banner on first visit. After dismissal, show a subtle "AI-generated content" label in the app bar or message area.
- **D-15:** Both AR and EN l10n strings needed for all disclaimer text.

### Trial Activation Wiring (PAYWALL-04 wiring)
- **D-16:** Remove `unawaited(subService.ensureTrialStarted())` from `main.dart` line 87.
- **D-17:** Call `ensureTrialStarted()` from `OnboardingScreen._finish()` immediately after account creation. This is the single call site that activates the trial clock.
- **D-18:** Show a one-time "Your 7-day Pro trial has started!" snackbar via `SnackHelper.showSuccess` after the success overlay dismisses.
- **D-19:** Verify trial countdown displays correctly in SubscriptionScreen and PaywallScreen trial banner via `trialDaysRemainingProvider`.

### Claude's Discretion
- Exact lock badge design (icon overlay vs banner vs disabled state) for budgets/goals at limit
- Whether "Manage subscription" button appears only for active subscribers or for all users
- Animation polish specifics for onboarding (timing curves, durations)
- Whether AI disclaimer banner is dismissible-once or always-visible-subtle
- Exact snackbar timing after onboarding success overlay

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Monetization & Subscription Service
- `lib/core/services/subscription_service.dart` — `ensureTrialStarted()`, `hasProAccess`, `trialDaysRemaining`, `restorePurchases()`, `buyProduct()`
- `lib/shared/providers/subscription_provider.dart` — `hasProAccessProvider`, `trialDaysRemainingProvider`, `subscriptionServiceProvider`
- `lib/data/database/tables/subscription_records_table.dart` — Drift table (Phase 1 deliverable)

### Paywall & Subscription Screens
- `lib/features/monetization/presentation/screens/paywall_screen.dart` — Feature list (reorder), pricing display, restore button, purchase flow
- `lib/features/monetization/presentation/screens/subscription_screen.dart` — Subscription management (add restore button)

### Feature Gating Targets
- `lib/features/budgets/presentation/screens/set_budget_screen.dart` — `_save()` handler: add pro gate before budget creation
- `lib/features/budgets/presentation/screens/budgets_screen.dart` — Add lock badge when at limit
- `lib/shared/providers/budget_provider.dart` — `budgetsByMonthProvider` for count check
- `lib/features/goals/presentation/screens/add_goal_screen.dart` — `_save()` handler: add pro gate before goal creation
- `lib/shared/providers/goal_provider.dart` — `activeGoalsProvider` for count check
- `lib/shared/widgets/guards/pro_feature_guard.dart` — Existing guard widget (deploy on ChatScreen)

### AI Chat
- `lib/features/ai_chat/presentation/screens/chat_screen.dart` — Add disclaimer banner, wrap with ProFeatureGuard

### Onboarding
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — `_finish()` method (wire trial start), page count, success overlay
- `lib/features/onboarding/presentation/widgets/onboarding_pages.dart` — Page definitions, page 3 = AI slide (add disclaimer)

### Settings
- `lib/features/settings/presentation/screens/settings_screen.dart` — Add "Masarify Pro" status row

### App Lifecycle
- `lib/app/app.dart` — `didChangeAppLifecycleState` resumed handler (add silent restore)
- `lib/main.dart` — Remove `ensureTrialStarted()` call (line 87)

### Router
- `lib/app/router/app_router.dart` — `AppRoutes.paywall` route definition

### Design System
- `lib/shared/widgets/feedback/snack_helper.dart` — `showSuccess()` for trial snackbar
- `lib/core/services/preferences_service.dart` — Add `hasSeenAiDisclaimer` flag

### L10n
- `lib/l10n/app_en.arb` — Add disclaimer, trial terms, pricing strings
- `lib/l10n/app_ar.arb` — Arabic equivalents

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ProFeatureGuard` widget — Exists at `lib/shared/widgets/guards/pro_feature_guard.dart` (107 lines), ready to deploy on ChatScreen
- `hasProAccessProvider` — Riverpod provider already computes pro/trial status
- `trialDaysRemainingProvider` — Already computes countdown from trial start date
- `SubscriptionService.ensureTrialStarted()` — Fixed in Phase 1, correct logic for single-call activation
- `SubscriptionService.restorePurchases()` — Method exists, just needs additional call sites
- `SnackHelper.showSuccess()` — Standard success feedback pattern
- `PreferencesService` — Established pattern for boolean flags (`hasCompletedOnboarding`, `theme`, etc.)
- `SmoothPageIndicator` — Already in onboarding, may need style tweaks only
- PaywallScreen `_restore()` method — Exists, can be referenced for SubscriptionScreen

### Established Patterns
- Feature gating: `if (!hasPro) context.push(AppRoutes.paywall)` — pattern to follow
- Settings rows: `_buildSettingsItem()` or similar builder in settings_screen.dart
- L10n: All user-facing strings via `context.l10n.*`, keys in both ARB files
- Preferences flags: `PreferencesService.getBool()` / `setBool()` pattern
- Lifecycle hooks: `WidgetsBindingObserver` mixin in `app.dart`

### Integration Points
- `main.dart` line 87 — Remove `ensureTrialStarted()` (trial moves to onboarding)
- `OnboardingScreen._finish()` — Add `ensureTrialStarted()` + snackbar
- `app.dart` `didChangeAppLifecycleState` — Add `restorePurchases()` on resumed
- `SetBudgetScreen._save()` — Inject count check + paywall redirect
- `AddGoalScreen._save()` — Inject count check + paywall redirect
- `ChatScreen` build — Wrap with ProFeatureGuard + add disclaimer banner
- `paywall_screen.dart` — Reorder features, add pricing terms, add manage link
- `subscription_screen.dart` — Add restore button
- `settings_screen.dart` — Add Pro status row
- `onboarding_pages.dart` page 3 — Add disclaimer text below ChatDemo

</code_context>

<specifics>
## Specific Ideas

- Trial duration is **7 days** (locked in Phase 1 D-13)
- `ensureTrialStarted()` must NOT be called on every app launch (Phase 1 D-14) — single call site in `_finish()`
- Free tier limits: exactly 2 budgets, 1 savings goal (from PROJECT.md monetization spec)
- Paywall pricing: "59 EGP/month" with 7-day free trial (from PROJECT.md context)
- "Manage subscription" deep link: `https://play.google.com/store/account/subscriptions?package=com.masarify.app`
- Disclaimer text: "Masarify provides budgeting guidance only, not regulated financial, investment, or tax advice"

</specifics>

<deferred>
## Deferred Ideas

- **Server-side subscription validation** — Deferred to v2 (SERVER-01). Current implementation uses client-side receipt verification only.
- **Multiple pricing tiers** — Out of scope per PROJECT.md. Keep exactly Free + Pro.
- **Yearly subscription plan** — If buttons already exist in PaywallScreen, keep them. Don't add new IAP products.

</deferred>

---

*Phase: 05-monetization-onboarding*
*Context gathered: 2026-03-28*
