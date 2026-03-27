# Masarify Play Store Launch — Research Summary

_Synthesized: 2026-03-27 | Sources: STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md_

---

## Key Findings

Ranked by impact on launch success:

**1. Two Play Store blockers require immediate action before submission.**
`targetSdk` is at 34; Google requires 35 for new apps since August 2025. `in_app_purchase` may bundle Billing Library 6.x while BL8 is mandatory as of February 2026. Both must be resolved before the first AAB upload or the submission will be rejected outright. _(STACK §3.1, §2.2)_

**2. The subscription infrastructure is built but not wired — 4 items block launch.**
`SubscriptionService`, `PaywallScreen`, `ProFeatureGuard`, and `hasProAccessProvider` all exist. What is missing: `ensureTrialStarted()` is never called (trial never starts), budget/goal count enforcement has no call sites wired, and AI chat is ungated. These 4 gaps mean monetization ships broken even though the code exists. _(FEATURES §4, ARCHITECTURE §1)_

**3. Financial services "AI Advisor" branding triggers Play Store scrutiny.**
Calling the product an "AI Financial Advisor" in the store listing or onboarding — without an explicit disclaimer that it provides budgeting guidance only, not regulated financial advice — is a named rejection trigger for Finance apps. The current onboarding page 3 and store copy must be audited. _(PITFALLS §1.1)_

**4. Data Safety must declare audio and chat data sent to third-party AI.**
Voice audio is sent to Google AI Studio (Gemini). Chat messages are sent to OpenRouter. Both must be declared as "collected and shared with third parties" in the Data Safety form, or the submission will fail. Declaring "no data collected" is incorrect and flagged during Finance app review. _(PITFALLS §1.2, STACK §3.4)_

**5. BackdropFilter glassmorphism will jank or crash on Egypt's dominant device segment.**
Samsung A14/A04 and Xiaomi Redmi 12 (Helio G80/G85, 2-4GB RAM) are the highest-volume devices in Egypt. Multiple simultaneous `BackdropFilter` calls on the dashboard drop these to 30-45fps. `GlassConfig.deviceFallback` exists but its activation threshold must be verified. Transaction list cards must not use `BackdropFilter` at all. _(PITFALLS §2.4, §4.3)_

**6. Google Play billing edge cases (cancellation, grace period, refund) are not handled.**
`SubscriptionService` handles `purchased/restored/error/canceled` states but does not store an expiry timestamp. Without one, cancelled subscriptions are revoked immediately (policy violation) and refunds cannot be detected without a server. At minimum: store `purchaseToken` + `expiryDate` in Drift; poll `queryPurchases()` on every launch. _(PITFALLS §3.1, ARCHITECTURE §1)_

**7. The paywall feature ordering is wrong — AI must lead, not budgets.**
Current `PaywallScreen` feature list starts with "Budgets" and ends with "AI Chat." Egyptian young professionals are early AI adopters; the hero conversion driver is "AI financial assistant," not "unlimited budgets." Reorder the array. This is a low-effort, high-conversion change. _(FEATURES §2.1)_

---

## Blockers (Must Fix Before Launch)

Items that cause Play Store rejection or critical user-facing bugs:

| # | Issue | Severity | Source |
|---|-------|----------|--------|
| B1 | `targetSdk = 34` — new apps rejected, must be 35 | REJECTION | STACK §3.1 |
| B2 | `in_app_purchase` may bundle Billing Library 6; BL8 mandatory | REJECTION | STACK §2.2 |
| B3 | Privacy policy URL (HTTPS) missing — mandatory for RECORD_AUDIO + Finance | REJECTION | STACK §3.3 |
| B4 | Data Safety form incomplete — audio to Gemini + chat to OpenRouter undeclared | REJECTION | PITFALLS §1.2 |
| B5 | Content rating questionnaire not completed — app cannot publish without it | REJECTION | STACK §3.6 |
| B6 | `ensureTrialStarted()` never called — trial never activates | CRITICAL BUG | FEATURES §1.3 |
| B7 | Budget/goal limits not enforced — free-tier gates ship broken | CRITICAL BUG | FEATURES §1.2, ARCHITECTURE §1 |
| B8 | Subscription price/trial terms not shown before purchase button | REJECTION | PITFALLS §1.5 |
| B9 | "Manage subscription" link to Google Play missing from Settings | REJECTION | PITFALLS §1.5 |
| B10 | Financial services disclaimer absent — "AI Financial Advisor" triggers review | HIGH RISK | PITFALLS §1.1 |

---

## Stack Recommendations

| Decision | Recommendation | Confidence |
|----------|---------------|------------|
| Billing library | Check `in_app_purchase_android` version immediately; if BL8 unsupported, migrate to `purchases_flutter` (RevenueCat) — it already supports BL8 | HIGH |
| Direct IAP vs RevenueCat | Keep direct `in_app_purchase` only if BL8 is confirmed supported; RevenueCat free tier covers launch revenue | HIGH |
| R8 / resource shrinking | Enable cautiously — Flutter 3.29+ has known "missing classes" issues; test the release build before shipping | MEDIUM |
| `another_telephony` package | Remove — SMS disabled (`kSmsEnabled=false`), package adds a native library and risks triggering Play Store SMS policy scrutiny even with manifest removal | HIGH |
| `geolocator` / `geocoding` | Audit use — if not serving a live feature, remove before submission to avoid unused `ACCESS_FINE_LOCATION` permission | HIGH |
| `SCHEDULE_EXACT_ALARM` | Switch daily recap to `WorkManager` or inexact alarm — exact alarm permission faces heightened scrutiny in 2024+ | MEDIUM |
| `GoogleFonts.config.allowRuntimeFetching` | Set to `false` in `main()` — mandatory for offline-first; currently missing | HIGH |
| App size target | 15-20 MB arm64 split APK is achievable; <25 MB is the Egyptian market threshold | HIGH |
| RevenueCat (post-v1) | Plan migration for subscription analytics (MRR, churn, trial conversions) once revenue begins | MEDIUM |

---

## Feature Priorities

### Table Stakes (ship broken = uninstall + 1-star review)
| Feature | Complexity | Status |
|---------|-----------|--------|
| Transaction logging always free, never gated | Low | OK — confirmed in architecture |
| Trial activation on onboarding completion | Low | MISSING — `ensureTrialStarted()` unwired |
| Budget limit (2 max) enforcement | Low | MISSING — call sites not wired |
| Goal limit (1 max) enforcement | Low | MISSING — call sites not wired |
| Subscription price + trial terms visible before purchase | Low | MISSING — paywall copy incomplete |
| "Restore Purchases" in Settings | Low | MISSING — only in PaywallScreen |
| "Manage subscription" link | Low | MISSING |
| Financial services disclaimer | Low | MISSING |

### Differentiators (upgrade drivers)
| Feature | Complexity | Priority |
|---------|-----------|----------|
| AI chat as hero Pro feature (reorder paywall list) | Low | HIGH — reorder array only |
| Trial nudge card at day 8+ ("X days left") | Medium | MEDIUM |
| "Save X%" yearly plan badge + yearly shown first | Low | MEDIUM |
| Egyptian payment method help link in paywall | Low | MEDIUM |
| Onboarding → trial start + "Trial started" snackbar | Low | HIGH |

### Anti-Features (do not build)
- Paywall on app open or during transaction entry
- "Trial expired" modal on launch
- Countdown timer on home screen
- 3+ pricing tiers, micro-payments, lifetime deal
- Gating transaction logging, all categories, multiple wallets, or local backup

---

## Architecture Decisions

### Subscription Gating Pattern
Enforce at two layers: (1) provider layer clamps collection size (`budgetsProvider.map(list => list.take(2))`), (2) UI call site checks `hasProAccessProvider` before navigating to create screens and redirects to paywall. Do not use a global wrapper widget — it creates hidden coupling.

### Offline Entitlement
SharedPreferences for trial (`_kTrialStartDate`) + Pro flag (`_kProActive`) is correct for v1. Add: store `purchaseToken` + `expiryDate` in Drift (not SharedPrefs) for cancellation/refund handling. Call `restorePurchases()` silently on every `AppLifecycleState.resumed`.

### Performance Critical Path
- Add `idx_transactions_wallet_date` composite index (most common dashboard query pattern — missing)
- Add `RepaintBoundary` to `GlassCard` — `BackdropFilter` always forces a compositing layer; without it, parent repaints cascade through every glass card
- Debounce `recentActivityProvider` (Rx.combineLatest3) by 100ms to prevent thrashing during bulk import
- Move `NotificationService.initialize()` to post-`runApp()` to save 50-100ms cold start
- Paginate dashboard transactions (first 50, load more on scroll); full list only on Transactions tab

### Build Order (dependency-ordered)
```
Phase A (foundation, no UI deps):
  A1. hasProAccessProvider gate in budgetsProvider + goalsProvider
  A2. App lifecycle resumed → restorePurchases() hook
  A3. Store purchaseToken + expiryDate in Drift

Phase B (feature gating UI, depends on A1):
  B1. ensureTrialStarted() in OnboardingScreen._finish()
  B2. Budget/goal limit enforcement + paywall redirect
  B3. Lock badges on BudgetsScreen + GoalsScreen
  B4. Backup/export gate in SettingsScreen

Phase C (performance, independent):
  C1. Add idx_transactions_wallet_date index
  C2. RepaintBoundary audit on GlassCard
  C3. Debounce recentActivityProvider stream
  C4. Dashboard transaction pagination (limit 50)

Phase D (store compliance):
  D1. targetSdk + compileSdk → 35
  D2. Billing Library 8 verification / migration
  D3. Remove another_telephony + audit geolocator
  D4. Privacy policy (HTTPS URL)
  D5. Data Safety form completion
  D6. Financial services disclaimer in app + listing
  D7. Paywall: price/trial terms visible + "Manage subscription" link
  D8. Content rating questionnaire
```

Critical path for submission: A1 → B1 → B2 → D1 → D2 → D4 → D5 → D7 → D8

---

## Risk Register

| Risk | Probability | Impact | Mitigation | Phase |
|------|------------|--------|-----------|-------|
| Billing Library 8 not supported by `in_app_purchase` | HIGH | Launch blocker | Check immediately; migrate to RevenueCat if needed | D2 |
| Finance app manual review delay (3-7+ business days) | HIGH | Schedule risk | Submit to Internal Testing 2 weeks before target launch date | D8 |
| GlassConfig fallback not activating on low-end devices | MEDIUM | 1-star reviews from Egypt's dominant device segment | Test on Samsung A14 emulator profile before submission | C2, PERF |
| Data Safety rejection (audio/chat undeclared) | HIGH | Submission rejection | Map all network calls; declare Gemini + OpenRouter sharing | D5 |
| Trial never starts (unwired `ensureTrialStarted`) | CERTAIN | Zero monetization conversions | Wire to onboarding completion — 5-line fix | B1 |
| Egyptian payment friction (no Visa/Meeza) | HIGH | Low conversion rate | Add "How to subscribe" help; ensure free tier has genuine value | PAYWALL |
| BackdropFilter jank on mid-range Android | HIGH | User retention, Play Store rating | Disable blur on devices <3GB RAM via GlassConfig; no BackdropFilter on list cards | C2 |
| RTL layout bugs surface post-launch | MEDIUM | Arabic audience churn | Run full app on Arabic locale emulator before each submission | All screens |
| "AI Financial Advisor" branding triggers policy review | MEDIUM | Submission rejection or takedown | Add disclaimer in app + listing; use "AI budgeting assistant" in copy | D6 |
| Price/trial terms not shown before purchase | HIGH | Google policy rejection | Show "59 EGP/mo — 7 days free — Cancel anytime" before purchase button | D7 |

---

## Recommended Phase Order

Based on dependencies and risk:

**Phase 1 — Compliance Fixes (do first, unblocks everything)**
1. Update `targetSdk`/`compileSdk` to 35 in `build.gradle.kts`
2. Verify/upgrade Billing Library 8 support
3. Remove `another_telephony`; audit `geolocator`
4. Switch `SCHEDULE_EXACT_ALARM` to inexact alarm or WorkManager
5. Set `GoogleFonts.config.allowRuntimeFetching = false`

**Phase 2 — Monetization Wiring (revenue depends on this)**
6. Wire `ensureTrialStarted()` to onboarding completion
7. Align trial days (pick 14; remove "7-day" references)
8. Budget limit enforcement (provider clamp + paywall redirect)
9. Goal limit enforcement (same pattern)
10. Paywall UI: show price + trial terms + "Cancel anytime" + "Manage subscription" link
11. Paywall: reorder features (AI first), yearly plan first with "Best Value" badge
12. Settings: add Pro status row + "Restore Purchases" in SubscriptionScreen
13. App lifecycle resume → silent `restorePurchases()`

**Phase 3 — Performance (affects ratings and retention)**
14. Add `idx_transactions_wallet_date` composite index
15. Add `RepaintBoundary` to `GlassCard`
16. Verify `GlassConfig` disables blur on <3GB RAM devices; test on A14 emulator
17. Debounce `recentActivityProvider`; paginate dashboard to 50 items
18. Cold start profile with `--trace-startup`; move `NotificationService.init()` post-`runApp()`

**Phase 4 — Store Submission Preparation**
19. Write privacy policy (HTTPS URL required); include Gemini + OpenRouter disclosure
20. Complete Data Safety form: declare audio (Gemini), chat (OpenRouter), Drive backup (user-controlled)
21. Add financial services disclaimer in-app (onboarding AI page + AI chat screen) and in store listing
22. Complete IARC content rating questionnaire
23. Prepare store assets: feature graphic (1024×500), 4+ screenshots (include Arabic RTL screenshots)
24. Run full app on Arabic locale device/emulator; fix any RTL issues found

**Phase 5 — Submission**
25. `flutter build appbundle --release` → upload to Internal Testing
26. Add licence tester accounts for billing sandbox
27. Test purchase → restore → expiry flow end-to-end
28. Graduate: Internal → Closed → Production (allow 2-week buffer for review)

---

_This document supersedes individual research files for decision-making. Source files remain for implementation detail reference._
