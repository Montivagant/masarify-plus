# P5 Polish & Monetize — Design Spec

**Date:** 2026-03-20
**Author:** Claude (brainstorming session with Omar)
**Status:** Draft — awaiting user approval

---

## Context

Masarify is a mature, feature-rich offline-first personal finance app targeting Egyptian young professionals (English-leaning) and budget-conscious families (Arabic-first). With 19 screens, 12 DB tables, 4 input methods, and 6 AI services, the codebase is production-grade — but user-facing friction undermines retention:

- **Too many taps** to log an expense (7 interactions minimum)
- **Features feel hidden** — AI insights, goals, recurring, voice input are buried in the Hub
- **Onboarding doesn't hook** — 3-page flow doesn't demonstrate value fast enough
- **No monetization** — `kMonetizationEnabled = false` with only scaffold stubs
- **Notification Parser dead weight** — feature to be removed entirely
- **FAB/SnackBar bug** — toast notifications push FAB to mid-screen

**Goal:** Polish the experience layer and establish a subscription-based revenue model. Ship the app that retains users and generates recurring revenue.

---

## 1. Onboarding Redesign — "Value Preview + Quick Setup"

### Current State
3-page flow: Welcome (language toggle) → Feature highlights (text cards) → Wallet setup (name, type, balance). Creates Physical Cash system wallet.

### Target State
**Flow:** Welcome (language built-in) → 3 animated slides → Pick main account type (1 tap) → Dashboard

#### Slide Content
1. **"Track in 2 taps"** — Animation: finger taps FAB → amount appears → save. Shows speed.
2. **"Just say it"** — Animation: mic icon pulses → voice wave → transaction appears. Shows voice input.
3. **"Auto-detect SMS"** — Animation: phone receives SMS → transaction card slides in. Shows SMS parser.

#### Design Rules
- Each slide: full-bleed Lottie animation (5 seconds auto-advance)
- Skip button always visible (top-right)
- Page indicators (dots) at bottom
- Final step: "What's your main account?" — 3 large tappable cards: Bank / Cash / Mobile Wallet
  - Single tap creates wallet with default name (e.g., "Bank Account") and balance 0
  - Currency defaults to EGP (changeable in Settings)
  - Physical Cash system wallet auto-created silently in background
- Default categories auto-seeded (unchanged from current behavior)

#### Files to Modify
- `lib/features/onboarding/presentation/screens/onboarding_screen.dart` — rewrite flow
- `lib/l10n/app_en.arb` / `app_ar.arb` — update/add onboarding strings
- `assets/animations/` — new Lottie files (3 animations)

---

## 2. Faster Expense Logging — Hybrid Streamlined Screen

### Current State
AddTransactionScreen: Type chips → Amount → Category (scrollable chips) → Wallet dropdown → Optional (date, note, location) → Save. 7+ interactions.

### Target State
**Flow:** FAB tap → keyboard auto-opens → type amount → glance at pre-selected category → Save. 2-3 interactions.

#### Changes
1. **Auto-focus amount input** — keyboard opens immediately on screen entry (already partially done)
2. **Smart category pre-selection** — auto-select based on:
   - CategorizationLearningService patterns (title → category)
   - Time-of-day heuristics (existing SmartDefaultsProvider)
   - Most frequent category for this day-of-week
3. **Frequency-sorted category chips** — already built, ensure it's the primary display
4. **Collapse optional fields** — title, note, date hidden in expandable "Details" section by default
5. **Wallet selector hidden if only 1 wallet** — reduce visual noise
6. **Sticky Save button** — always visible at bottom (already done)

#### Brand/Merchant Icons
- **New system:** Map merchant names (from SMS enrichment / AI parsing) to brand icons
- **Local bundle:** Top 50-100 Egyptian brands (Vodafone, Orange, Etisalat, Netflix, Uber, Careem, Fawry, Carrefour, Instashop, Talabat, etc.)
- **Assets:** `assets/brand_icons/` directory with PNG/SVG icons (~24x24 or 32x32)
- **Mapping:** `lib/core/constants/brand_icons.dart` — merchant name → asset path lookup
- **Fallback:** If no match, show category icon (current behavior)
- **Display:** On TransactionCard in transaction list, and in transaction detail
- **Optional internet fetch:** For long-tail merchants not in local bundle, fetch favicon from clearbit/google (only if online). Cache locally after first fetch.

#### Files to Modify
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` — restructure layout
- `lib/shared/providers/smart_defaults_provider.dart` — enhance with learning patterns
- `lib/core/services/ai/categorization_learning_service.dart` — ensure it's wired to manual saves
- New: `lib/core/constants/brand_icons.dart` — merchant→icon mapping
- New: `assets/brand_icons/` — local brand icon bundle
- `lib/shared/widgets/transaction_card.dart` — display brand icon when available

---

## 3. Feature Discoverability — Dashboard Cards + Contextual Nudges

### Smart Dashboard Cards

**Location:** Dashboard screen, between Month Summary zone and Recent Transactions zone.

**Card Types (priority order):**
1. **Budget Alert** — "You've spent 85% of your Food budget" (when any budget > 80%)
2. **Over-Budget Prediction** — "At this pace, you'll exceed Dining by 2,400 EGP" (from SpendingPredictor)
3. **Recurring Due** — "Netflix due tomorrow (149 EGP)" (next upcoming recurring rule)
4. **Budget Suggestion** — "You spend avg 1,200 EGP/mo on Transport — set a budget?" (from BudgetSuggestionService)
5. **AI Insight** — Rotating insight from background AI providers

**Display Rules:**
- Maximum **2 cards** visible at once
- Cards are GlassCard (Tier 2) with accent color left-border
- Each card has: icon, title, subtitle, CTA button, dismiss (X) button
- Dismissed cards don't return for that data point (stored in SharedPreferences)
- Cards refresh on dashboard load (not real-time)
- **No streak card**

**Anti-Fatigue:**
- Max 2 cards visible simultaneously
- Same category of card (e.g., budget alert) shows max once per day
- If user dismisses 3+ cards in a session, stop showing new ones until next day
- Insight cards rotate (1 new per day, not all at once)

### Contextual Nudges

**Nudge Types (one-time, dismissable):**
1. **After 5th expense in same category (no budget):** "Set a budget for [Category]?" → links to SetBudgetScreen
2. **After first income transaction:** "Start a savings goal?" → links to AddGoalScreen
3. **After 3rd manual entry in one session:** "Try voice input — just say it" → bottom banner with mic icon
4. **After first SMS transaction approved:** "Link your bank account for auto-routing" → links to wallet SMS settings
5. **Coach marks on first dashboard visit:** Highlight FAB ("Tap to add expense, long-press for voice"), Quick Add zone ("Your frequent transactions appear here")

**Nudge Rules:**
- Each nudge fires **once ever** (flag stored in SharedPreferences)
- Nudge = small bottom banner (not dialog, not notification)
- Auto-dismiss after 8 seconds OR tap dismiss
- Never show nudge AND card for same feature simultaneously
- Max 1 nudge per session

#### Files to Modify
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — add card zone
- New: `lib/features/dashboard/presentation/widgets/insight_card.dart` — smart card widget
- New: `lib/features/dashboard/presentation/widgets/contextual_nudge.dart` — nudge widget
- New: `lib/core/services/nudge_service.dart` — nudge trigger logic + preferences
- `lib/shared/providers/background_ai_provider.dart` — wire to dashboard cards
- `lib/core/services/preferences_service.dart` — add nudge/card dismiss flags

---

## 4. Monetization — Subscription-Only (No Ads)

### Tier Structure

#### Free Tier (Forever Free)
- Unlimited transactions (manual, voice, SMS — all input methods)
- Unlimited categories and wallets/accounts
- 2 budgets + 1 savings goal
- Basic monthly summary + category breakdown (pie chart)
- PIN / biometric security
- Local backup (JSON)
- No ads

#### Masarify Pro
- **Monthly:** 59-79 EGP/mo (~$1.20-1.60 USD)
- **Annual:** 499-699 EGP/yr (~$10-14 USD, ~30-40% savings vs monthly)
- **14-day free trial** (no credit card required)

**Pro Features:**
- Unlimited budgets and savings goals
- AI Insights dashboard cards (spending predictions, budget alerts, recurring detection, budget suggestions)
- Advanced analytics (trends over time, category comparisons, forecasting)
- Brand/merchant icons on transactions
- Cloud backup (Google Drive auto-backup)
- CSV / PDF export
- AI Chat assistant
- Future premium features included

### Paywall Design

**Trigger points (soft paywall):**
- User tries to create 3rd budget → "Upgrade to Pro for unlimited budgets"
- User tries to create 2nd goal → "Upgrade to Pro for unlimited goals"
- Dashboard insight cards show with blur + lock icon → "Unlock AI Insights with Pro"
- Export button → "Export with Pro"
- AI Chat → "Chat with your financial assistant — Pro feature"

**Paywall screen:**
- Feature comparison (Free vs Pro) in a clean list
- Price display with annual savings highlighted
- "Start 14-Day Free Trial" primary CTA
- "Restore Purchase" secondary link
- Testimonial/social proof (can add later)

### Implementation
- **Package:** `purchases_flutter` (RevenueCat) for subscription management
- **Provider:** `subscriptionProvider` — exposes `isPro`, `trialDaysRemaining`, `expiresAt`
- **Guard:** `ProFeatureGuard` widget — wraps premium features, shows paywall if not Pro
- **Flag:** Replace `kMonetizationEnabled` with actual RevenueCat integration

#### Files to Modify/Create
- `pubspec.yaml` — add `purchases_flutter` dependency
- New: `lib/core/services/subscription_service.dart` — RevenueCat wrapper
- New: `lib/shared/providers/subscription_provider.dart` — `isPro` state
- New: `lib/shared/widgets/pro_feature_guard.dart` — gate premium features
- `lib/features/settings/presentation/screens/subscription_screen.dart` — rewrite from stub
- New: `lib/features/settings/presentation/screens/paywall_screen.dart` — rewrite from stub
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — gate insight cards
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` — gate brand icons (display only)
- Budget/goal creation screens — gate at limit (2 budgets, 1 goal)

---

## 5. Remove Notification Parser — Complete Excision

### Files to Delete (3)
1. `lib/core/services/notification_listener_wrapper.dart`
2. `lib/core/services/notification_transaction_parser.dart`
3. `lib/shared/providers/notification_listener_provider.dart`

### Files to Edit (8+)

#### `lib/main.dart`
- Remove imports: `notification_listener_wrapper.dart`, `notification_service.dart`, `persistent_notification_service.dart`, `notification_listener_provider.dart`
- Remove: `NotificationService.initialize()` block
- Remove: `PersistentNotificationService.onActionTapped` handler
- Remove: notification listener startup block
- Remove: notification permission recovery block

#### `lib/features/settings/presentation/screens/settings_screen.dart`
- Remove imports: `notification_listener_wrapper.dart`, `notification_service.dart`, `persistent_notification_service.dart`, `notification_listener_provider.dart`
- Remove state variables: `_notificationParserEnabled`, `_awaitingNotificationPermission`
- Remove methods: `_toggleNotificationParser()`, `_finishNotificationPermission()`
- Remove UI: notification parser toggle in Smart Detection section
- Update subtitle for Smart Detection section (remove "notifications" mention)

#### `lib/features/sms_parser/presentation/screens/parser_review_screen.dart`
- Remove import: `notification_transaction_parser.dart`
- Remove source filter state (`_sourceFilter`)
- Remove source filter UI chips (All / SMS / Notifications)
- Remove notification source filtering logic
- Rename screen context from "Auto-detected" to "SMS Transactions" if appropriate

#### `lib/l10n/app_en.arb` — Remove ~7 notification keys:
- `transaction_source_notification`, `settings_notification_parser`, `permission_notification_title`, `permission_notification_body`, `parser_source_notification`, `settings_notification_parser_subtitle`
- Update `settings_smart_detection_subtitle` to remove "notifications" mention

#### `lib/l10n/app_ar.arb` — Same keys as above (Arabic equivalents)

#### `android/app/src/main/AndroidManifest.xml`
- Remove notification permissions: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK`, `FOREGROUND_SERVICE`
- Remove NotificationListenerService declaration

#### `pubspec.yaml`
- Remove: `notification_listener_service: ^0.3.5`

#### `lib/core/services/preferences_service.dart`
- Remove: `isNotificationParserEnabled`, `setNotificationParserEnabled`
- Remove: `isNotificationPermissionPending`, `setNotificationPermissionPending`

### Database
- **No migration needed** — `SmsParserLogs.source` column stays. Existing notification logs remain in DB but are inert (no UI displays them). Future DB migration can clean up if desired.

### Transaction Source
- Keep `notification` value in source enum/constants for backward compatibility with existing data. Just won't be used for new entries.

---

## 6. Fix FAB/SnackBar Toast Issue

### Problem
When a SnackBar appears, the FAB shifts upward to mid-screen instead of staying in its docked position.

### Root Cause
Flutter's default Scaffold behavior pushes the FAB above SnackBars. The custom `RaisedCenterDockedFabLocation` adds +24dp offset but doesn't account for SnackBar height.

### Fix Options
1. **SnackBar behavior override:** Set `SnackBarBehavior.floating` with a bottom margin that doesn't overlap the FAB zone
2. **Custom SnackBar positioning:** Use `snackBarTheme` in app theme to position SnackBars above the bottom nav but below the FAB
3. **Overlay-based toast:** Replace SnackBar with a custom overlay toast that doesn't interact with Scaffold layout

### Recommended Fix
Use `SnackBarBehavior.floating` with proper margins in the app theme, ensuring the SnackBar floats above the bottom nav bar but doesn't push the FAB.

#### Files to Modify
- `lib/app/theme/app_theme.dart` — add `snackBarTheme` with floating behavior + margin
- `lib/shared/widgets/feedback/snack_helper.dart` — ensure all SnackBars use floating behavior

---

## 7. Execution Notes

### Plugin/Skill Usage During Implementation
Use these skills/plugins during execution:
- `/flutter-dev` — for all code changes (analyzer, context7 docs)
- `/review` — after each major section completion
- `/audit` — final pass before completion
- `/think` — for complex architecture decisions (paywall guard, nudge service)
- `/commit` — for structured commits after each section

### Implementation Order
1. **Notification Parser Removal** — clean slate first (removes dead code before adding new)
2. **FAB/SnackBar Fix** — quick win, high visibility
3. **Expense Logging Streamline** — highest user impact (friction reduction)
4. **Onboarding Redesign** — second highest impact (first impressions)
5. **Dashboard Cards + Nudges** — feature discoverability
6. **Brand/Merchant Icons** — visual polish
7. **Monetization (Paywall + RevenueCat)** — revenue layer on top of polished experience

### Verification
- `flutter analyze lib/` — zero issues after each section
- `flutter test` — all 64+ tests pass
- Manual testing: complete onboarding flow, add 5 expenses, verify smart defaults, check dashboard cards, test paywall triggers
- RTL testing: verify all new UI in Arabic RTL mode
- Offline testing: verify all free-tier features work without internet
