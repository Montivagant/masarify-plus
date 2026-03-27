# Paywall & Subscription Feature Research
_Masarify — Play Store Launch, 2026-03-27_

## Context

- **App:** Masarify — offline-first AI financial advisor for Egyptian young professionals
- **Model:** Subscription-only (no ads). Free tier generous; Pro unlocks power features.
- **Free tier:** Unlimited transactions, categories, wallets. 2 budgets, 1 savings goal. Basic analytics. Local backup.
- **Pro tier:** 59–79 EGP/mo | 499–699 EGP/yr. Unlimited budgets/goals, AI chat, advanced analytics, cloud backup, CSV/PDF export, brand icons.
- **Trial:** 14-day free trial (currently coded as 14 days in `SubscriptionService`; PROJECT.md says "7-day" — needs alignment).
- **Implementation:** `in_app_purchase` (direct Google Play Billing). No RevenueCat. `kMonetizationEnabled = true`.
- **Current state:** `PaywallScreen`, `SubscriptionScreen`, `SubscriptionService`, and `ProFeatureGuard` all exist but free-tier enforcement hooks are not yet wired to budget/goal creation screens.

---

## 1. Table Stakes (Must-Have)

### 1.1 Paywall Presentation Patterns

**When to show the paywall:**

The industry standard is a "soft wall" — never interrupt core flows, only gate additive features. For Masarify specifically:

| Trigger | Paywall Type | Notes |
|---------|-------------|-------|
| User attempts to create 3rd budget | Soft wall (inline lock) | Show count: "2/2 budgets used" |
| User attempts to create 2nd savings goal | Soft wall (inline lock) | Show count: "1/1 goals used" |
| User taps Export in settings/analytics | Hard wall (full screen push) | Export is infrequent, full screen OK |
| User taps AI Chat FAB or chat tab | Hard wall (full screen push) | AI is the hero Pro feature |
| User taps backup/restore in Settings | Soft wall (inline lock) | Low urgency |
| User views advanced analytics tab | Soft wall (section-level lock) | Let them see the chart titles, blur content |
| Settings → Subscription | Informational (no wall) | Always navigable |

**Soft wall pattern (already in codebase):**
`ProFeatureGuard` with `inline: false` shows lock icon + "Tap to unlock" CTA in place of the locked widget. This is the right pattern. Apply it contextually, not at screen level.

**Hard wall timing:**
Push `AppRoutes.paywall` as a full screen (`context.push`) only for high-value moments (AI chat, export). Never `context.go` — user must be able to go back.

**Complexity:** Low (infrastructure exists; need to wire call sites)
**Dependencies:** `ProFeatureGuard`, `hasProAccessProvider`, `AppRoutes.paywall`

---

### 1.2 Free Tier Enforcement

**What to enforce and how:**

| Limit | Enforcement Point | Method |
|-------|------------------|--------|
| 2 budgets max | `BudgetsScreen` "Add" button + `SetBudgetScreen` save action | Check count before allowing creation; show inline upsell |
| 1 savings goal max | `GoalsScreen` "Add" button + goal save action | Same pattern |
| AI chat | `ChatScreen` entry guard | Show `ProFeatureGuard` wrapping the chat input, or gate the route |
| Advanced analytics | Analytics tab sections | Wrap specific chart widgets with `ProFeatureGuard` |
| Cloud backup | Settings row | `ProFeatureGuard(inline: true)` on backup tile |
| CSV/PDF export | Export action | `ProFeatureGuard` wrapping export button |
| Brand icons | Icon picker in category/transaction | `ProFeatureGuard(inline: true)` on brand icon grid |

**Enforcement philosophy:**
- NEVER block transaction logging. A user must always be able to record an expense, income, or transfer — regardless of subscription status. This is the app's core value.
- Show the limit *before* it's hit ("1 of 2 budgets used") so users understand the model, not discover it at frustration points.
- Use `kMonetizationEnabled` flag guard everywhere: wrap all enforcement in `if (AppConfig.kMonetizationEnabled && !hasPro)` so the flag remains a single on/off switch during development.

**Complexity:** Low–Medium (pattern exists; need ~6 call sites wired)
**Dependencies:** `hasProAccessProvider`, budget/goal count providers, `ProFeatureGuard`

---

### 1.3 Trial Management (14-Day Free Trial)

**Current implementation gap:**
`SubscriptionService` starts the trial clock via `ensureTrialStarted()` but `ensureTrialStarted()` is never called from `main.dart` or app initialization. The trial does not start until it is explicitly triggered.

**Recommended trial flow:**

1. **Trial start:** Call `ensureTrialStarted()` on first app launch (after onboarding completes — not before, so skipped-onboarding users don't lose trial days). Wire into `OnboardingScreen` completion callback or `main.dart` after onboarding check.
2. **Trial awareness:** On day 1, show no banner — user is exploring. On day 10+ (5+ days remaining), show "X days left in your free trial" banner on home screen insight cards zone. On final day, show persistent yellow banner.
3. **Trial expiry:** When `trialDaysRemaining == 0` and `!isPro`, features revert to free tier silently. Do NOT show a modal. Let the user hit a lock naturally — less hostile than an expiry popup.
4. **Trial banner in paywall:** Already implemented (`paywall_trial_banner` l10n key). Correct.
5. **Trial/pricing alignment:** PROJECT.md says "7-day trial"; `SubscriptionService._trialDays` is `14`. Align these before launch. 14 days is better for conversion in price-sensitive markets.

**Conversion optimization for trial:**
- Send a proactive daily AI recap notification during the trial period (already built via `AI-03`). Frame it as a Pro feature preview.
- On day 12 of trial, push a contextual in-app nudge: "Your AI insights found X things. Keep them with Pro."
- Never show a countdown timer on the home screen — it creates anxiety, not motivation.

**Complexity:** Low (service exists; need init call + expiry nudge)
**Dependencies:** `SubscriptionService.ensureTrialStarted()`, onboarding completion hook, `trialDaysRemainingProvider`

---

### 1.4 Subscription Status UI

**What to build:**

| Screen | What to show |
|--------|-------------|
| Settings → Masarify Pro row | Status badge: "Pro" (green), "Trial (X days)" (amber), "Free" (grey) + chevron |
| `SubscriptionScreen` | Already built. Shows status icon + trial days + Upgrade CTA. Sufficient for v1. |
| `PaywallScreen` | Already built. Shows trial banner + feature list + purchase buttons + restore. Sufficient for v1. |
| Post-purchase | Show success snackbar + pop paywall automatically. Already handled via `SnackHelper.showSuccess` + `context.pop()` in `_restore()`. |
| Expired trial | No dedicated screen. Let the free-tier locks do the talking. |

**Missing piece — Settings row:**
The Settings screen should have a dedicated "Masarify Pro" tile that shows the current status inline (badge + days remaining) and navigates to `SubscriptionScreen`. This is the single most-viewed entry point for subscription awareness.

**Complexity:** Low
**Dependencies:** `hasProAccessProvider`, `trialDaysRemainingProvider`, `SubscriptionScreen`

---

### 1.5 Restore Purchases Flow

**Current implementation:**
`PaywallScreen._restore()` calls `SubscriptionService.restorePurchases()`, waits, reads `hasProAccessProvider`, shows success/failure snackbar, and pops if successful. This is correct and complete.

**Missing touchpoint:**
Restore should also be accessible from `SubscriptionScreen` and from `Settings → Masarify Pro`. Currently it only lives in `PaywallScreen`. Add a secondary "Restore Purchases" text button to `SubscriptionScreen` for users who reinstalled without going through the paywall.

**Google Play requirement:**
Google Play requires that "Restore Purchases" is accessible without forcing users to the purchase flow. The `SubscriptionScreen` is accessible from Settings regardless of subscription status — this satisfies the requirement as long as the restore button is visible there.

**Complexity:** Low
**Dependencies:** `SubscriptionService.restorePurchases()`, `SubscriptionScreen`

---

### 1.6 Grace Period Handling

**What is a grace period:**
Google Play offers a grace period (typically 3–16 days) when a subscription renewal fails due to payment issues. During this period, the user retains access while Google retries the payment. The app must not revoke access during this window.

**Current gap:**
`SubscriptionService._handlePurchaseUpdates` only handles `purchased`, `restored`, `error`, `canceled`, and `pending` states from the `in_app_purchase` package. The `in_app_purchase` package does not surface a distinct "grace period" state — it continues to return `restored` for active subscriptions including grace-period ones.

**Recommended approach for v1:**
Since `in_app_purchase` restores purchases on every app launch (`_restorePurchases()` called in `initialize()`), and since Google Play's billing client returns active subscriptions during the grace period, the current implementation naturally handles grace periods correctly without extra code. No additional work needed for v1.

**Post-v1 improvement:**
Use `google_play_billing` library or server-side verification to detect `PAYMENT_PENDING` subscription state and show a "payment issue" banner rather than revoking access.

**Complexity:** Low (no action for v1; natural behavior is correct)
**Dependencies:** `SubscriptionService.initialize()`, Google Play Billing

---

## 2. Differentiators (Competitive Advantage)

### 2.1 AI-First Upsell — AI Advisor IS the Pro Feature

**Strategic framing:**
The app is positioned as "AI Financial Advisor," not "expense tracker." This means the AI chat (`AI-01`) and AI insights (`AI-02`) should be the primary reasons to upgrade — not secondary features buried behind "unlimited budgets."

**Recommended paywall feature order (current order is wrong):**
Current order in `PaywallScreen`: Budgets → Goals → Insights → Analytics → Backup → Export → AI Chat

Recommended order — lead with the hero:
1. AI financial assistant (chat + voice recap)
2. AI spending insights (pattern detection, predictions)
3. Unlimited budgets
4. Unlimited savings goals
5. Advanced analytics & trends
6. Cloud backup (Google Drive)
7. CSV & PDF export

**Why this matters:** Egyptian young professionals are early AI adopters. "Your personal AI financial advisor" closes sales. "Unlimited budgets" does not.

**Complexity:** Low (reorder array in `PaywallScreen`, update l10n descriptions)
**Dependencies:** `PaywallScreen` feature list, l10n strings

---

### 2.2 Onboarding-to-Paywall Funnel

**Current state:**
Onboarding (5 pages) introduces the AI advisor concept (page 3 ChatDemo) but does not mention Pro or the trial. Users complete onboarding with no awareness of subscription model.

**Recommended funnel:**

```
Onboarding page 3 (AI Advisor intro)
  → ChatDemo shows "AI advisor" conversation
  → Add subtle line: "Full AI access included free for 14 days"
  → This plants the trial seed without pressure

Onboarding completion (page 5 → home)
  → Trigger ensureTrialStarted() HERE
  → Show one-time "Trial started" snackbar: "Your 14-day Pro trial has started"
  → No modal, no friction — just awareness
```

**Do NOT put a paywall in onboarding.** Apps that gate features before the user has seen value have 40–60% higher uninstall rates in the first session. The Egyptian market is particularly sensitive to this — trust must be earned first.

**Complexity:** Low (add trial start call + one snackbar to onboarding completion)
**Dependencies:** `OnboardingScreen` completion callback, `SubscriptionService.ensureTrialStarted()`

---

### 2.3 "Aha Moment" Timing — When to Show the Paywall

**The aha moment for Masarify:**
A user has their "aha moment" when they see the AI correctly predict their Carrefour spending or detect a recurring Netflix subscription. This typically happens after 7–14 transactions.

**Paywall timing heuristics (in priority order):**

| Trigger | Timing | Why |
|---------|--------|-----|
| User creates 3rd budget | Immediate (hit the wall) | Direct value exchange — they want more budgets |
| User creates 2nd goal | Immediate (hit the wall) | Same — direct need |
| User has 10+ transactions + trial day 8+ | Show nudge card on home insight zone | High engagement signal + trial midpoint |
| User taps AI chat (non-trial) | Immediate (hit the wall) | They want the feature NOW |
| User views analytics for the first time with 15+ transactions | Soft tease — show chart preview blurred with lock icon | Show the value, gate the detail |

**What NOT to do:**
- Do not show an upgrade prompt on first launch
- Do not show upgrade prompts on days 1–3 (user is still evaluating)
- Do not show upgrade prompts during transaction entry

**Contextual nudge card (home screen insight zone):**
After day 8 of trial with 5+ transactions, replace one low-priority insight card with: "Your trial ends in X days — your AI has found [N] spending patterns. Keep them with Pro." This is contextual, value-grounded, and non-intrusive.

**Complexity:** Medium (requires transaction count provider + nudge card widget)
**Dependencies:** `insightCardsProvider`, transaction count, `trialDaysRemainingProvider`

---

### 2.4 Egyptian Market Pricing Psychology

**Price anchoring for 59–79 EGP/mo:**

The Egyptian young professional target (25–35) has a median monthly discretionary spend of 2,000–5,000 EGP. At 59–79 EGP/mo, Masarify Pro costs roughly 1–4% of discretionary spending — a low cognitive friction point if framed correctly.

**Framing that works:**
- "Less than a morning coffee at Cilantro per week" (Cilantro coffee ≈ 80–120 EGP)
- "Less than one Swvl ride per month"
- Avoid: "Only 59 EGP" — the word "only" implies you're defensive about the price

**Monthly vs. yearly anchoring:**
Show the yearly plan first and prominently. Egyptian users respond to savings framing: "Save 30% with yearly — pay once, use all year." The yearly plan (499–699 EGP) should be the default/highlighted option with a "BEST VALUE" badge. Monthly should be available but visually subordinate.

**In `PaywallScreen`, the current products are sorted by whatever order the Play Store returns.** Add explicit sorting: yearly first, monthly second. Add a "Save X%" badge on the yearly option.

**Psychological safety:**
Egyptian users are skeptical of recurring charges. The paywall should explicitly state: "Cancel anytime from Google Play. No hidden fees." This is especially important because Egyptian banking has historically had issues with unexpected subscription charges.

**Complexity:** Low (UI copy + sort order in PaywallScreen)
**Dependencies:** `PaywallScreen` product display, l10n

---

## 3. Anti-Features (Things NOT to Build)

### 3.1 Aggressive Paywall Patterns That Cause Uninstalls

**Do NOT build these:**

| Anti-Pattern | Why It's Harmful | Alternative |
|-------------|-----------------|-------------|
| Paywall on app open | User has seen zero value; 60%+ immediate uninstall | Only show on feature access |
| "Your trial has expired" popup/modal on launch | Hostile, creates resentment | Let the locks appear naturally |
| Countdown timer on home screen | Anxiety-inducing, not motivating | Trial badge in settings only |
| Paywall after every action | Spam pattern; feels extortionate | Max 1 paywall prompt per session |
| Disabling core features (transaction entry) when trial expires | Breaks core value proposition; feels punitive | NEVER gate transaction logging |
| "Rate this app" + upgrade prompt on same session | Double interruption — users feel manipulated | Separate these by 48+ hours |
| Email/notification spam as trial expires | Masarify has no email collection; do not add this | Daily AI recap notification is sufficient |

**The one rule that overrides all others:**
A user who cannot record a transaction because they hit a paywall will uninstall immediately and leave a 1-star review. The free tier must always allow unlimited transaction recording. Full stop.

---

### 3.2 Over-Restriction on Free Tier

**Do NOT over-gate these:**

| Feature | Why It Should Stay Free |
|---------|------------------------|
| Transaction logging (all methods: manual, voice, AI chat create) | Core value — never gate |
| All 34 categories | Category diversity is an input feature, not an output feature |
| Multiple accounts/wallets | Users need multiple accounts (salary + savings + cash) — gating this kills daily use |
| Basic transaction list + filters | Reading your own data should always be free |
| Local backup | Users trust the app with financial data; a backup is a safety feature, not a luxury |
| Light/dark theme | Aesthetic preference is never a monetization lever in the Egyptian market |
| Arabic/English toggle | Localization is a right, not a Pro feature |
| Onboarding + AI advisor intro | Lowering acquisition friction is always free |

**The danger of over-gating:**
If the free tier is too restrictive, users won't reach the "aha moment" that motivates upgrade. Masarify's current free tier (unlimited transactions + categories + wallets, 2 budgets, 1 goal) is well-calibrated. Do not tighten it.

---

### 3.3 Complex Pricing Tiers

**Do NOT build:**

| Anti-Pattern | Why |
|-------------|-----|
| 3+ pricing tiers (Free / Plus / Pro / Business) | Decision paralysis; Egyptian users prefer simple choices |
| Per-feature micro-payments ("unlock export for 10 EGP") | Transactional feel destroys trust; feels like a scam |
| Lifetime deal on launch | Undercuts future subscription revenue; attracts deal-hunters not loyal users |
| "Freemium + ads" hybrid | Ads destroy the premium brand positioning; the app is named "Masarify Pro" |
| Annual-only (remove monthly) | Remove the cheaper entry point and conversion drops sharply |
| Family plan / team plan | Adds support complexity; out of scope for v1 |
| Student discount | Complex to verify in Egypt; not worth the segment for v1 |

**Keep it simple:** Two products (`masarify_pro_monthly` + `masarify_pro_yearly`). One paywall screen. One subscription status screen. Done.

---

## 4. Implementation Gap Summary

The following is what the current codebase has vs. what is needed for a complete paywall implementation:

| Capability | Status | Priority |
|-----------|--------|----------|
| `SubscriptionService` (core) | Built | — |
| `PaywallScreen` (UI) | Built | — |
| `SubscriptionScreen` (status) | Built | — |
| `ProFeatureGuard` widget | Built | — |
| `hasProAccessProvider` | Built | — |
| `trialDaysRemainingProvider` | Built | — |
| `ensureTrialStarted()` called on onboarding complete | MISSING | HIGH |
| Trial/paywall days aligned (7 vs 14) | MISSING | HIGH |
| Budget count enforcement (3rd budget = paywall) | MISSING | HIGH |
| Goal count enforcement (2nd goal = paywall) | MISSING | HIGH |
| AI chat gated for non-trial non-Pro users | MISSING | HIGH |
| "X days left" nudge card on home screen | MISSING | MEDIUM |
| Settings → Subscription row with status badge | MISSING | MEDIUM |
| Yearly plan shown first + "Best Value" badge | MISSING | MEDIUM |
| Restore purchases button in SubscriptionScreen | MISSING | MEDIUM |
| AI features listed first in paywall feature list | MISSING | LOW |
| "Cancel anytime" copy on paywall | MISSING | LOW |
| Egyptian price framing copy | MISSING | LOW |

**Total missing items:** 11
**Blocking launch:** Trial start wiring + budget/goal enforcement (items 1–4 above)

---

## 5. Dependencies Between Features

```
ensureTrialStarted()
  └── called from: OnboardingScreen completion
        └── unlocks: trialDaysRemainingProvider accuracy
              └── enables: trial banner in PaywallScreen (already built)
              └── enables: trial nudge card on home (to build)

Budget count provider
  └── called from: BudgetsScreen + SetBudgetScreen
        └── gates: 3rd budget creation → pushes PaywallScreen

Goal count provider
  └── called from: GoalsScreen + add goal screen
        └── gates: 2nd goal creation → pushes PaywallScreen

hasProAccessProvider (already built)
  └── consumed by: ProFeatureGuard (already built)
        └── wraps: AI chat entry, export button, advanced analytics, backup tile

PaywallScreen (already built)
  └── products: masarify_pro_monthly + masarify_pro_yearly
        └── needs: yearly first + "Best Value" badge (UI change only)
```

---

_Research complete. All patterns grounded in current codebase state (`SubscriptionService`, `PaywallScreen`, `ProFeatureGuard`, `AppConfig.kMonetizationEnabled`) and Egyptian market context._
