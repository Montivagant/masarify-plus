# Roadmap: Masarify Play Store Launch
**Created:** 2026-03-27
**Granularity:** Standard (5-8 phases)
**Total Requirements:** 66

## Design Rationale

This roadmap is ordered by **risk elimination speed** — not by feature grouping. The most expensive mistake is building 6 phases of features only to discover at submission time that the billing library rejects, the targetSdk is wrong, or the trial never starts. Therefore:

- **Phase 1** resolves every item that would cause a Play Store rejection or a broken revenue pipeline. This includes SDK compliance, billing library verification, alarm permission fixes, and package cleanup — all in one pass before any UI work.
- **Phase 2** verifies that features already shipped (P5 Phases 2-4) actually work. Many of these were "done" but reported broken. Verification before new features prevents building on a broken foundation.
- **Phases 3-4** run in parallel: Phase 3 handles the home screen overhaul (the screenshot hero), while Phase 4 handles AI/voice/subscriptions polish (the conversion hero). Neither depends on the other.
- **Phase 5** covers monetization wiring. It comes after the features it gates (AI, budgets, home) are polished, so users feel value before hitting a paywall — but early enough that billing can be tested on Internal Testing track while Phase 6 prepares store assets.
- **Phase 6** is performance, positioned after all UI is stable (profiling moving targets wastes time) but before store submission (Play Store vitals affect ranking).
- **Phase 7** is store submission — privacy policy, Data Safety form, screenshots, and the AAB upload. It requires everything else to be done.

## Overview

| # | Phase | Goal | Requirements | Plans |
|---|-------|------|-------------|-------|
| 1 | Compliance & Billing Foundation | Eliminate every Play Store rejection trigger and verify the billing stack works | 7 | 2/3 In Progress |
| 2 | Verification Sweep | Prove every P5 feature works; fix what is broken | 23 | 4 |
| 3 | Home Screen Overhaul | Build the hero screen that users screenshot and share | 10 | 3 |
| 4 | AI, Voice & Subscriptions Polish | Make the differentiator features seamless end-to-end | 10 | 3 |
| 5 | Monetization & Onboarding | Wire revenue, enforce free tier, polish first-run | 6 | 4 |
| 6 | Performance & Device Optimization | Hit 2s cold start and 60fps scroll on Egypt's mid-range devices | 5 | 3 |
| 7 | Store Submission | Build, sign, list, and ship to Play Store | 5 | 3 |
| | | **Total** | **66** (verified — see Traceability in REQUIREMENTS.md) | **23** |

---

## Phase Details

### Phase 1: Compliance & Billing Foundation
**Goal:** Resolve every known Play Store rejection trigger and confirm the billing library is functional — before touching any UI or feature code.
**Requirements:** STORE-01, CLEAN-01, CLEAN-02, CLEAN-03, PAYWALL-02, PAYWALL-04, PAYWALL-05
**UI hint:** no

**Plans:**

1. **SDK & Manifest Compliance** — Bump `targetSdk` and `compileSdk` to 35 in `android/app/build.gradle.kts`. Test edge-to-edge enforced display against the glassmorphic `AppNavBar` (`lib/shared/widgets/navigation/app_nav_bar.dart`) and center-docked FAB. Fix any inset/padding issues caused by API 35's mandatory edge-to-edge. Switch `SCHEDULE_EXACT_ALARM` to inexact alarm or WorkManager for the daily recap notification in `lib/core/services/notification_service.dart`. Set `GoogleFonts.config.allowRuntimeFetching = false` in `lib/main.dart`. (STORE-01, CLEAN-03)

2. **Package & Settings Cleanup** — Remove `another_telephony` from `pubspec.yaml` and verify zero import sites remain via `grep -r "another_telephony" lib/`. Audit `geolocator`/`geocoding` — if no live feature uses location, remove both packages and their permissions. Remove the "Notification Parsing" row from `lib/features/settings/presentation/screens/settings_screen.dart`; confirm zero remnant UI or l10n strings referencing notification parsing in `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`. Run merged manifest audit: `./gradlew app:processReleaseManifest` and inspect for unexpected permissions. (CLEAN-01, CLEAN-02)

3. **Billing Library Verification & Purchase Token Storage** — Check `in_app_purchase_android` version via `flutter pub outdated`; confirm it bundles Play Billing Library 8+. If BL8 is not supported, evaluate migration to `purchases_flutter` (RevenueCat free tier) which already supports BL8. Create a `subscription_records` table in Drift (`lib/data/database/tables/`) to store `purchaseToken`, `productId`, `expiryDate`, and `purchaseDate` — replacing the SharedPreferences-only approach for subscription persistence. Wire `SubscriptionService` (`lib/core/services/subscription_service.dart`) to persist purchases to this table. Fix `ensureTrialStarted()` — verify it is callable (currently never invoked) and resolve the 7-day vs 14-day trial mismatch (`_trialDays` constant vs PROJECT.md). Do NOT wire the call site yet (that is Phase 5); just ensure the method works correctly when called. (PAYWALL-02, PAYWALL-04, PAYWALL-05)

**Success criteria:**
1. `flutter build appbundle --release` succeeds on targetSdk 35; the nav bar and FAB render correctly with no visual overlap on an API 35 emulator.
2. `flutter pub deps` shows `another_telephony` absent; merged AndroidManifest contains no `SCHEDULE_EXACT_ALARM`, no `READ_SMS`, no `RECEIVE_SMS` permissions.
3. `flutter pub outdated` confirms `in_app_purchase_android` supports BL8; OR RevenueCat migration is complete and `purchases_flutter` is in pubspec.
4. `SubscriptionService.ensureTrialStarted()` correctly writes a trial start date and `trialDaysRemaining` returns the expected value; subscription purchase records persist to Drift, not only SharedPreferences.

---

### Phase 2: Verification Sweep
**Goal:** Systematically verify every feature shipped in P5 Phases 2-4 actually works as specified; fix all breakage before building new features.
**Requirements:** TXN-02, TXN-03, TXN-04, TXN-05, AI-03, AI-04, VOICE-01, VOICE-02, VOICE-04, ACCT-01, ACCT-02, ACCT-03, ACCT-04, ACCT-05, ACCT-06, ACCT-07, ACCT-08, ACCT-09, SUB-01, CAT-01, CAT-02, CAT-03, CAT-04
**UI hint:** yes (fixes only, no new design)

**Plans:**

1. **Transaction & Transfer Verification** — Verify category-first bold display in `lib/shared/widgets/cards/transaction_card.dart` (TXN-02). Test cash withdrawal/deposit transactions appear in the correct account's transaction list, not just in "All Accounts" (TXN-03). Verify transfer cards show the full route label "CIB --> NBE" on both source and destination entries in `lib/domain/adapters/transfer_adapter.dart` (TXN-04). Verify new transactions from `lib/features/transactions/presentation/screens/add_transaction_screen.dart` respect `selectedAccountIdProvider` from the dashboard carousel (TXN-05). Fix any breakage found. (TXN-02, TXN-03, TXN-04, TXN-05)

2. **Account Management Verification** — Walk through all 9 account management features on a fresh install: Cash wallet hidden from `lib/features/wallets/presentation/screens/wallets_screen.dart` (ACCT-01); default account editable name, delete button disabled (ACCT-02); archive flow with 2-step dialog in `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` (ACCT-03, ACCT-04); archived accounts rendered with strikethrough under "Archived" section (ACCT-05); unarchive restores visibility in home carousel, transaction lists, analytics, and AI context (ACCT-06); starting balance field present during account creation and in onboarding page 4 (ACCT-07); drag-and-drop reorder modal in `lib/features/dashboard/presentation/widgets/account_manage_sheet.dart` (ACCT-08); quick archive accessible from the reorder modal (ACCT-09). Fix any breakage found. (ACCT-01 through ACCT-09)

3. **AI & Voice Verification** — Test AI chat 3-layer JSON parser in `lib/core/services/ai/chat_response_parser.dart` — send 10 varied prompts, confirm no raw JSON leaks to the user in `lib/features/ai_chat/presentation/widgets/message_bubble.dart` (AI-03). Verify `flutter_markdown` renders responses without raw asterisks or hashtags (AI-04). Test voice input: say "Cash" and "كاش" — confirm `lib/core/utils/wallet_resolver.dart` maps to the system Cash wallet without suggesting "Create Cash account" (VOICE-01). Test inter-account voice transfer "transfer 2000 from CIB to NBE" — confirm correct +/- signs on each leg (VOICE-02). Test voice subscription suggestion: say "paid Vodafone 100" — confirm `lib/core/utils/subscription_detector.dart` shows "Add to Subscriptions?" on `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` (VOICE-04). Fix any breakage found. (AI-03, AI-04, VOICE-01, VOICE-02, VOICE-04)

4. **Subscriptions & Categories Verification** — Search the entire codebase for any remnant "Recurring" labels that should be "Subscriptions & Bills" — check l10n files, navigation tabs, screen titles, and `lib/core/constants/app_navigation.dart` (SUB-01). Verify 34 default categories seeded on fresh install via `lib/data/seed/category_seed.dart`; confirm "Installments" category exists for the Egyptian market (CAT-01). Test category search picker filters correctly by both Arabic and English names (CAT-02). Verify most-used categories appear first in the picker via `lib/core/services/ai/categorization_learning_service.dart` frequency data (CAT-03). Verify typing a transaction title triggers category suggestion (CAT-04). Fix any breakage found. (SUB-01, CAT-01, CAT-02, CAT-03, CAT-04)

**Success criteria:**
1. A fresh-install walkthrough of all 23 requirements passes with zero failures; each requirement has a manual test script documented in the plan.
2. Transfer cards show "CIB --> NBE" (not "-->  NBE" / "<-- CIB") on both sides; new transactions land in the carousel-selected account, not always in the default account.
3. Voice input of "كاش" resolves to system Cash wallet; voice input of "paid my Netflix" shows the subscription suggestion card.
4. Zero raw JSON fragments or unrendered markdown appear in AI chat responses in both Arabic and English.
5. No instance of the word "Recurring" appears in any user-visible string (l10n, nav tabs, screen titles).

---

### Phase 3: Home Screen Overhaul
**Goal:** Redesign the home screen into a modern, high-density layout that becomes the app's hero screenshot — merging all transaction functionality into a single view.
**Requirements:** HOME-01, HOME-02, HOME-03, HOME-04, HOME-05, HOME-06, HOME-07, TXN-01, TXN-06, TXN-07
**UI hint:** yes

**Plans:**

1. **Home Screen Redesign & Tab Merge** — Redesign `lib/features/dashboard/presentation/screens/dashboard_screen.dart`: replace bulky hero cards with a modern, sleek balance area. Make the "All Accounts" summary card visually distinct (different shape, color treatment, or icon) from individual account cards in `lib/features/dashboard/presentation/widgets/account_carousel.dart` (HOME-01, HOME-02). Eliminate all phantom whitespace — audit every zone widget in `lib/features/dashboard/presentation/widgets/` for conditional blank space (HOME-05). Remove the Transactions tab from `lib/shared/widgets/navigation/app_nav_bar.dart` and `lib/core/constants/app_navigation.dart`; merge all transaction list, filter, and search functionality into the home screen. Update `lib/app/router/app_router.dart` to remove the transactions tab route. (HOME-06) Verify the upcoming bills insight card in `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart` correctly surfaces when a subscription is due within 7 days (HOME-07).

2. **Transaction Controls & Swipe Actions** — Add filter and search actions to the home screen transaction list: implement a search bar and Expense/Income/Transfer/All quick filter chips above the transaction list (HOME-03, HOME-04). Implement swipe-to-edit and swipe-to-delete on all transaction types (regular transactions and transfers) in `lib/shared/widgets/lists/transaction_list_section.dart` and `lib/shared/widgets/cards/transaction_card.dart`, with 2-step confirmation dialogs (TXN-01). Add a description/notes/memo field to `lib/features/transactions/presentation/screens/add_transaction_screen.dart` if not already present (TXN-06).

3. **Review/Confirm Screen Revamp** — Full UX/UI redesign of `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` for clarity: ensure amount signs (+/-) are clearly displayed, category and account are prominent, date is visible, and the layout works cleanly in Arabic RTL with no overflow. This screen is the gateway for all voice and AI-created transactions — it must inspire confidence that the parsed data is correct (TXN-07).

**Success criteria:**
1. Home screen renders with zero blank/whitespace zones in both Light and Dark themes, in both English LTR and Arabic RTL.
2. The "All Accounts" card is visually distinguishable from named account cards at a glance — a first-time user would not confuse it for a regular account.
3. The Transactions tab no longer exists in the bottom nav; all transaction functionality (list, filter, search, swipe actions) is accessible from the home screen.
4. Swiping left on a transfer transaction shows a 2-step "Delete both legs?" confirmation; swiping on a regular transaction shows a single-step confirmation.
5. The voice confirm screen renders cleanly in Arabic RTL with correct amount signs, no text overflow, and clear category/account labels.

---

### Phase 4: AI, Voice & Subscriptions Polish
**Goal:** Make the AI Financial Advisor and voice input into a seamless, differentiated experience that justifies the Pro paywall.
**Requirements:** AI-01, AI-02, AI-05, AI-06, VOICE-03, SUB-02, SUB-03, SUB-04, SUB-05, CAT-05
**UI hint:** yes

**Plans:**

1. **AI Language, Date & Action Completeness** — Enforce single-language responses: audit the system prompt in `lib/core/services/ai/ai_chat_service.dart` to include an explicit instruction "Reply ONLY in {locale language}. Never mix languages." (AI-01). Inject `DateTime.now()` formatted as "Today is {weekday}, {date} {year}" into every system prompt so the AI has correct temporal context — the current prompt likely references 2024 training data (AI-02). Wire `ChatActionExecutor` (`lib/core/services/ai/chat_action_executor.dart`) to detect recurring/subscription-type transactions in AI chat and suggest creating a subscription record via `ChatAction.createRecurring` (AI-05). Fix the transfer intent: ensure "paid CIB to settle NBE" or "transfer 2000 from X to Y" in AI chat always routes to `CreateTransferAction` in `lib/core/services/ai/chat_action.dart`, never creates an expense — test with 5+ transfer phrasings in both languages (AI-06). (AI-01, AI-02, AI-05, AI-06)

2. **Voice Brand Matching & Cross-Feature Subscription Suggestions** — Improve brand icon resolution in `lib/core/constants/brand_registry.dart` and `lib/core/utils/category_icon_mapper.dart` — verify that audio transcriptions of Egyptian brand names (Vodafone, CIB, Carrefour, Netflix) map to the correct icon and color (VOICE-03). Wire subscription suggestion from AI chat context to match what voice already does via `lib/core/utils/subscription_detector.dart` — both voice AND chat should prompt "Add to Subscriptions & Bills?" for recurring-pattern transactions (SUB-05). Add category suggestion dropdown to budget creation (`lib/features/budgets/presentation/screens/set_budget_screen.dart`), goal creation, and recurring/subscription creation (`lib/features/recurring/presentation/screens/add_recurring_screen.dart`) forms — reusing the category suggestion logic from `lib/core/services/ai/categorization_learning_service.dart` (CAT-05). (VOICE-03, SUB-05, CAT-05)

3. **Subscriptions & Bills Enhancement** — Add a `dueDate` field to the recurring rules schema if not already present; wire it into `lib/features/recurring/presentation/screens/add_recurring_screen.dart` as a date picker (SUB-02). Implement upcoming-bill notifications: when a subscription has a due date within 3 days, fire a device notification via `lib/core/services/notification_service.dart` (SUB-03). Wire the `RecurringPatternDetector` (`lib/core/services/ai/recurring_pattern_detector.dart`) to automatically suggest monthly bills from spending patterns — surface these as an insight card or inline suggestion when detected confidence exceeds the threshold (SUB-04). (SUB-02, SUB-03, SUB-04)

**Success criteria:**
1. AI responds entirely in Arabic when locale is Arabic, entirely in English when locale is English — tested with 10 prompts per language, zero mixed-language sentences.
2. AI chat correctly identifies "transfer 2000 from CIB to NBE" as a transfer (not expense) in both languages; the transfer card shows correct +/- on both accounts.
3. Saying "paid Netflix 200" in voice creates a transaction AND shows "Add to Subscriptions?"; typing "I pay Netflix every month" in AI chat shows the same prompt.
4. A subscription with due date set to tomorrow triggers a device notification today; the notification text includes the subscription name and amount.
5. Category suggestion dropdowns appear in budget, goal, and subscription creation screens, populated from the user's most-used categories.

---

### Phase 5: Monetization & Onboarding
**Goal:** Wire the revenue pipeline correctly, enforce free-tier limits gracefully, and polish the first-run experience including the financial disclaimer.
**Requirements:** PAYWALL-01, PAYWALL-03, PAYWALL-06, ONBOARD-01, ONBOARD-02, ONBOARD-03
**UI hint:** yes

Note: PAYWALL-02, PAYWALL-04, and PAYWALL-05 are in Phase 1 (billing infrastructure). This phase wires the user-facing gates and purchase flow.

**Plans:**

1. **Free Tier Enforcement** — Wire `hasProAccessProvider` gate in `budgetsProvider` (`lib/shared/providers/`) to clamp budget list to 2 for free users; same for `goalsProvider` (clamp to 1). Add lock badge overlays on `lib/features/budgets/presentation/screens/budgets_screen.dart` and the goals screen when the limit is reached. Add paywall redirect in `SetBudgetScreen` save handler and goal creation save handler — if `!hasPro && count >= limit`, push `AppRoutes.paywall` instead of saving. Gate AI chat entry for non-trial, non-Pro users behind `ProFeatureGuard`. Transaction logging must NEVER be gated. (PAYWALL-01)

2. **Paywall UI & Restore Flow** — Reorder `PaywallScreen` (`lib/features/monetization/presentation/screens/paywall_screen.dart`) feature list: AI Financial Assistant first, then AI spending insights, unlimited budgets, unlimited goals, advanced analytics, cloud backup, export. Show explicit price and trial terms BEFORE the purchase button: "59 EGP/month -- 7 days free -- Cancel anytime". Add "Manage subscription" deep-link button opening `https://play.google.com/store/account/subscriptions?package=com.masarify.app`. Add "Restore Purchases" button to both `PaywallScreen` and `SubscriptionScreen`; also add a "Masarify Pro" status row to `lib/features/settings/presentation/screens/settings_screen.dart` with badge (Pro/Trial/Free) and chevron navigating to SubscriptionScreen. Wire `restorePurchases()` silently on every `AppLifecycleState.resumed` in `lib/app/app.dart`. (PAYWALL-03, PAYWALL-06)

3. **Onboarding Polish** — Remove the 5th onboarding page ("What's Your Main Account") from `lib/features/onboarding/presentation/widgets/onboarding_pages.dart` and auto-create the default bank account in `_finish()` of `lib/features/onboarding/presentation/screens/onboarding_screen.dart` (ONBOARD-01). Polish transitions: ensure skip/back buttons work correctly on all pages, add smooth `PageController` animations, add or verify animated progress indicator via `smooth_page_indicator` (ONBOARD-02). Add financial disclaimer: "Masarify provides budgeting guidance only, not regulated financial, investment, or tax advice" — display on the AI Advisor onboarding page (page 3) and as a persistent header/banner on first entry to `lib/features/ai_chat/presentation/screens/chat_screen.dart` (ONBOARD-03).

4. **Trial Activation Wiring** — Call `ensureTrialStarted()` from `OnboardingScreen._finish()` immediately after account creation. Show a one-time "Your 7-day Pro trial has started!" snackbar via `SnackHelper.showSuccess`. This is the single call site that activates the trial clock. Verify the trial countdown displays correctly in `SubscriptionScreen` and the PaywallScreen trial banner. (PAYWALL-04 wiring -- method was fixed in Phase 1, call site wired here)

**Success criteria:**
1. Completing onboarding auto-creates a bank account, starts a 7-day Pro trial, and shows a "Trial started" snackbar. Verifiable via `trialDaysRemainingProvider` returning 7.
2. Attempting to create a 3rd budget redirects to PaywallScreen; attempting to create a 2nd savings goal redirects to PaywallScreen. Transaction logging is always accessible regardless of subscription state.
3. PaywallScreen lists AI features first; shows "59 EGP/month -- 7 days free -- Cancel anytime" above the purchase button; "Manage subscription" link opens Google Play.
4. Both Arabic and English show the financial disclaimer before the user's first AI Chat interaction.
5. Settings screen shows a "Masarify Pro" row with correct status badge (Pro/Trial X days/Free).

---

### Phase 6: Performance & Device Optimization
**Goal:** Deliver sub-2-second cold start and smooth 60fps scrolling on Egypt's dominant mid-range Android devices (Samsung A14, Xiaomi Redmi 12).
**Requirements:** PERF-01, PERF-02, PERF-03, PERF-04, PERF-05
**UI hint:** no

**Plans:**

1. **Database & Stream Optimization** — Add composite index `idx_transactions_wallet_date` on `(wallet_id, transaction_date DESC)` in `lib/data/database/app_database.dart` (PERF-03). Paginate `watchAll()` queries for the dashboard to return the first 50 transactions with load-more on scroll; update `lib/shared/providers/transaction_provider.dart` or the relevant DAO method (PERF-04). Debounce `recentActivityProvider` (`lib/shared/providers/activity_provider.dart`) `Rx.combineLatest3` stream by 100ms to prevent UI thrashing during bulk operations (PERF-04). Add `ref.select()` narrowing in `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart` and `lib/features/dashboard/presentation/widgets/month_summary_zone.dart` to avoid full-list rebuilds on unrelated wallet changes.

2. **Rendering & Glass Performance** — Add `RepaintBoundary` to `GlassCard` build method to contain `BackdropFilter` compositing layer repaint costs. Verify `GlassConfig.deviceFallback` activation threshold: test on a 3GB RAM / Helio G80 emulator profile — confirm blur is disabled and replaced with `Color.withOpacity()` fallback (PERF-05). Ensure `TransactionCard` in list views does NOT use `BackdropFilter` — use solid semi-transparent background instead. Profile scrolling a 500-item transaction list via `flutter run --profile` and DevTools Frame chart; target zero red (jank) frames (PERF-02).

3. **Cold Start Optimization** — Profile with `flutter run --trace-startup --profile`; identify where time is spent in the 8-step startup sequence. Move `NotificationService.initialize()` from blocking in `main()` to post-`runApp()` via `WidgetsBinding.instance.addPostFrameCallback` — saves 50-100ms. Lazy-initialize `brand_registry.dart` map with `late final`. Verify cold start `timeToFirstFrameMicros` under 2,000,000 on a Xiaomi Redmi 12 (Helio G88, 4GB) emulator profile (PERF-01).

**Success criteria:**
1. Cold start measured via `--trace-startup` on a mid-range emulator profile (4GB RAM, Helio G88) is under 2 seconds to first interactive frame.
2. Scrolling a 500-item transaction list maintains 60fps (zero jank frames in DevTools) on the same device profile.
3. Dashboard loads the first 50 transactions instantly; further items load on scroll without visible stutter.
4. `GlassConfig.deviceFallback` activates on a <3GB RAM device and the dashboard renders with opaque card backgrounds instead of blur — no grey overlay or visual artifacts.

---

### Phase 7: Store Submission
**Goal:** Build, sign, list, and submit the app to Google Play with zero compliance gaps. Get through review on the first attempt.
**Requirements:** STORE-02, STORE-03, STORE-04, STORE-05, STORE-06
**UI hint:** no

**Plans:**

1. **Privacy Policy & AI Disclosure** — Write and publish a privacy policy at a permanent HTTPS URL (GitHub Pages or static hosting). Content must declare: (a) audio data sent to Google AI Studio (Gemini) for voice transcription, (b) chat messages sent to OpenRouter for AI responses, (c) Google Drive backup is user-initiated and user-controlled, (d) all financial data stored locally only, (e) contact information, (f) data deletion = uninstall. Link the privacy policy from Settings screen and from the Play Store listing. Add "AI-powered" / "Suggested by AI" micro-labels on insight cards in `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart` and on AI chat messages in `lib/features/ai_chat/presentation/widgets/message_bubble.dart`. (STORE-03, STORE-06)

2. **Store Assets & Listing** — Write Play Store title ("Masarify -- AI Budget Tracker"), short description (80 chars max), and full description (EN + AR) using "AI budgeting assistant" phrasing (not "financial advisor") to avoid policy triggers. Include the financial disclaimer in the store description. Produce feature graphic (1024x500) and 4+ phone screenshots including at least one Arabic RTL screenshot — screenshots must be taken AFTER all UI work (Phases 3-5) is complete. Complete the IARC content rating questionnaire (expected: Everyone). Declare target audience (adults 18+, finance category). (STORE-02, STORE-05)

3. **Build, Data Safety & Submission** — Run `flutter build appbundle --release` and sign with the upload keystore. Upload AAB to Internal Testing track. Complete the Data Safety form: declare audio (collected, shared with Google AI Studio), chat messages (collected, shared with OpenRouter), financial data (collected, stored on-device only, not shared), Google Drive backup (user-controlled). Add licence tester accounts for billing sandbox. Test end-to-end: purchase --> restore --> cancel --> expiry flow. Graduate through testing tracks: Internal --> Closed --> Production, with a 2-week buffer for Finance app review. (STORE-04)

**Success criteria:**
1. Privacy policy URL resolves over HTTPS, is linked from Settings and the Store listing, and correctly declares Gemini + OpenRouter data sharing.
2. AAB uploads to Internal Testing track with zero Play Console warnings about targetSdk, permissions, billing library, or Data Safety completeness.
3. A licence tester can: purchase Pro --> verify features unlock --> cancel --> verify access persists until expiry --> reinstall --> restore purchases successfully.
4. All screenshots include at least one Arabic RTL screenshot; the feature graphic passes Play Console's asset validator.
5. Content rating questionnaire yields "Everyone" rating; target audience declaration passes automated checks.

---

## Dependency Graph

```
                    ┌─────────────────────┐
                    │  Phase 1            │
                    │  Compliance &       │
                    │  Billing Foundation  │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Phase 2            │
                    │  Verification       │
                    │  Sweep              │
                    └──┬──────────────┬───┘
                       │              │
          ┌────────────▼───┐  ┌───────▼────────────┐
          │  Phase 3       │  │  Phase 4            │
          │  Home Screen   │  │  AI, Voice &        │
          │  Overhaul      │  │  Subscriptions      │
          └────────┬───────┘  └───────┬────────────┘
                   │                  │
                   └──────┬───────────┘
                          │
               ┌──────────▼──────────┐
               │  Phase 5            │
               │  Monetization &     │
               │  Onboarding         │
               └──────────┬──────────┘
                          │
               ┌──────────▼──────────┐
               │  Phase 6            │
               │  Performance &      │
               │  Device Opt.        │
               └──────────┬──────────┘
                          │
               ┌──────────▼──────────┐
               │  Phase 7            │
               │  Store Submission   │
               └─────────────────────┘

PARALLEL OPPORTUNITIES:
  - Phase 3 and Phase 4 run concurrently after Phase 2 completes.
    They share no file dependencies:
      Phase 3 = dashboard_screen, app_nav_bar, transaction_list_section, voice_confirm_screen
      Phase 4 = ai_chat_service, chat_action_executor, brand_registry, add_recurring_screen

SEQUENTIAL CONSTRAINTS:
  - Phase 1 → Phase 2: SDK bump may break UI; must verify before auditing features.
  - Phase 2 → Phases 3/4: Verified foundation required before building new UI or polishing features.
  - Phases 3+4 → Phase 5: Monetization gates features that must be polished first.
                           Paywall reorder needs AI features done (Phase 4).
                           Onboarding polish needs home screen done (Phase 3).
  - Phase 5 → Phase 6: Performance profiling on a moving UI target wastes effort.
                        All UI must be stable before measuring and optimizing.
  - Phase 6 → Phase 7: Performance must meet targets before store submission.
                        Screenshots must come from the final, optimized app.

CRITICAL PATH: 1 → 2 → 3 → 5 → 6 → 7
              (Phase 4 runs parallel to 3, so it is off the critical path
               unless it finishes later than Phase 3)
```

---
*Roadmap created: 2026-03-27*
*Last updated: 2026-03-27 (Plan 01-1 complete)*
