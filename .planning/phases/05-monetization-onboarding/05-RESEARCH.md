# Phase 5: Monetization & Onboarding — Research

**Researched:** 2026-03-28
**Status:** Complete
**Requirements:** PAYWALL-01, PAYWALL-03, PAYWALL-06, ONBOARD-01, ONBOARD-02, ONBOARD-03

---

## 1. Free Tier Enforcement (PAYWALL-01)

### 1.1 Budget Provider & Count Check

**File:** `lib/shared/providers/budget_provider.dart` (12 lines)

The provider is simple:
```dart
final budgetsByMonthProvider = StreamProvider.family<List<BudgetEntity>, (int, int)>(
  (ref, params) => ref.watch(budgetRepositoryProvider).watchByMonth(params.$1, params.$2),
);
```
- Returns `List<BudgetEntity>` for a given `(year, month)`.
- Count check: `budgets.length >= 2` on the current month's budgets.
- **Gotcha:** The count check must use the SAME month that the user is creating the budget for (stored in `_year`, `_month` on `SetBudgetScreen`), not necessarily the current month. The user can navigate to future months.

### 1.2 SetBudgetScreen._save() — Budget Gate Injection Point

**File:** `lib/features/budgets/presentation/screens/set_budget_screen.dart`
**Method:** `_save()` at line 119
**Current flow:**
1. Validates `_categoryId != null && _limitPiastres > 0` (line 120)
2. Sets loading state (line 121)
3. Reads `budgetRepositoryProvider`
4. If editing (`widget.editId != null`), updates existing budget
5. If creating, checks for upsert on same category+month, then creates

**Gate injection point:** Between lines 120-121 (after basic validation, before loading state). For NEW budgets only (not edits):
```dart
if (widget.editId == null) {
  final hasPro = ref.read(hasProAccessProvider);
  if (!hasPro) {
    final budgets = await ref.read(budgetRepositoryProvider).getByMonth(_year, _month);
    if (budgets.length >= 2) {
      context.push(AppRoutes.paywall);
      return;
    }
  }
}
```

**Imports needed:** `hasProAccessProvider`, `AppRoutes` (already imported on line 4 via go_router, but `AppRoutes` is NOT imported -- need to add it).

**Check:** `AppRoutes` is NOT currently imported in `set_budget_screen.dart`. Must add:
```dart
import '../../../../core/constants/app_routes.dart';
```

### 1.3 Goal Provider & Count Check

**File:** `lib/shared/providers/goal_provider.dart` (32 lines)

```dart
final activeGoalsProvider = StreamProvider<List<SavingsGoalEntity>>(
  (ref) => ref.watch(goalRepositoryProvider).watchActive(),
);
```
- Returns active (incomplete) goals as a stream.
- Count check: `activeGoals.length >= 1` for free tier.

### 1.4 AddGoalScreen._save() — Goal Gate Injection Point

**File:** `lib/features/goals/presentation/screens/add_goal_screen.dart`
**Method:** `_save()` at line 112
**Current flow:**
1. Guards against double-tap (line 113-114)
2. Validates name (line 115-119)
3. Validates target amount (line 121-129)
4. Sets loading state (line 130-133)
5. Creates or updates goal

**Gate injection point:** After name/target validation, before loading. For NEW goals only:
```dart
if (widget.editId == null) {
  final hasPro = ref.read(hasProAccessProvider);
  if (!hasPro) {
    final activeGoals = await ref.read(goalRepositoryProvider).getActive();
    // OR use ref.read(activeGoalsProvider).valueOrNull
    if (activeGoals != null && activeGoals.length >= 1) {
      context.push(AppRoutes.paywall);
      return;
    }
  }
}
```

**Imports needed:** `hasProAccessProvider`, `subscription_provider.dart`, `AppRoutes` (check if already imported -- `go_router` is imported on line 6, but `AppRoutes` is NOT imported). Must add:
```dart
import '../../../../core/constants/app_routes.dart';
import '../../../../shared/providers/subscription_provider.dart';
```

**Note:** The goal repository may not have a synchronous `getActive()` method. Need to check. Alternative: use `ref.read(activeGoalsProvider).valueOrNull ?? []` which returns the last cached value (may be null if the stream hasn't emitted yet). Safer to do:
```dart
final goals = ref.read(activeGoalsProvider).valueOrNull;
if (goals != null && goals.length >= 1) { ... }
```

### 1.5 BudgetsScreen — Lock Badge on Add Button

**File:** `lib/features/budgets/presentation/screens/budgets_screen.dart`
**Add button:** Line 103-110 — `IconButton` in `AppAppBar.actions`
**Empty state CTA:** Line 128-131 — `EmptyState.onCta`

The add button (line 103) and empty state CTA (line 128) both navigate to `AppRoutes.budgetSet`. Need to:
- Watch `hasProAccessProvider` and `budgetsByMonthProvider`
- If `!hasPro && budgets.length >= 2`, change the add button to show a lock icon or redirect to paywall
- **Decision D-02:** Add lock badge overlay. Options:
  - Replace `AppIcons.add` with `AppIcons.lock` when at limit
  - Wrap the IconButton in a Stack with a small lock badge
  - Change `onPressed` to navigate to paywall

**Simplest approach:** When at limit and not Pro, the `onPressed` callback navigates to paywall instead of budgetSet. Add a small lock badge on the icon.

### 1.6 GoalsScreen — Lock Badge on Add Button

**File:** `lib/features/goals/presentation/screens/goals_screen.dart`
**Add button:** Line 33-37 — `IconButton` in `AppAppBar.actions`
**Empty state CTA:** Line 47-48 — `EmptyState.onCta`

Same pattern as BudgetsScreen. Need to watch `activeGoalsProvider` and `hasProAccessProvider`.

### 1.7 ProFeatureGuard Widget

**File:** `lib/shared/widgets/guards/pro_feature_guard.dart` (107 lines)
**API:**
```dart
ProFeatureGuard({
  required Widget child,
  String? featureName,
  bool inline = false,  // true = compact lock badge, false = full placeholder
})
```
- Watches `hasProAccessProvider`
- If Pro: returns child
- If not Pro, `inline=true`: grayed-out child with lock badge overlay, taps navigate to paywall
- If not Pro, `inline=false`: full lock placeholder card with lock icon, feature name, "Tap to unlock" CTA

**For AI Chat gating (D-03):** Wrap the entire `ChatScreen` body with `ProFeatureGuard(featureName: context.l10n.paywall_feature_chat)`. But the decision says "non-trial, non-Pro" -- so the guard already handles this correctly since `hasProAccessProvider` returns `true` during trial.

### 1.8 hasProAccessProvider

**File:** `lib/shared/providers/subscription_provider.dart`
```dart
final hasProAccessProvider = Provider<bool>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  final sub = service.proStatusStream.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return service.hasProAccess;  // isPro || isInTrial
});
```
- `hasProAccess = isPro || isInTrial`
- This means during trial, user has Pro access. After trial expires AND no purchase, access is revoked.
- **Important:** `isInTrial` returns `true` even before `ensureTrialStarted()` is called, because `trialDaysRemaining` returns `_trialDays` (7) when no trial start date is set. This means a user who hasn't onboarded yet would appear to have Pro access. This is fine -- they won't hit the budget/goal limit during onboarding anyway.

---

## 2. Paywall & Subscription UI (PAYWALL-03, PAYWALL-06)

### 2.1 PaywallScreen — Current Feature List Order

**File:** `lib/features/monetization/presentation/screens/paywall_screen.dart`
**Feature list:** Lines 87-116

Current order:
1. Budgets (AppIcons.budget)
2. Goals (AppIcons.goals)
3. Insights (AppIcons.trendingUp)
4. Analytics (AppIcons.analytics)
5. Backup (AppIcons.backup)
6. Export (AppIcons.export_)
7. **AI Chat (AppIcons.ai) -- LAST**

**Required order (D-05):** AI first:
1. AI Financial Assistant (AppIcons.ai)
2. AI Spending Insights (AppIcons.trendingUp)
3. Unlimited Budgets (AppIcons.budget)
4. Unlimited Goals (AppIcons.goals)
5. Advanced Analytics (AppIcons.analytics)
6. Cloud Backup (AppIcons.backup)
7. Export (AppIcons.export_)

### 2.2 PaywallScreen — Pricing Terms

**Current:** Purchase buttons show `"{price}/month"` and `"{price}/year"` (lines 258-273). No explicit "7 days free" or "Cancel anytime" text above.

**Required (D-06):** Add text above purchase buttons: "59 EGP/month -- 7 days free -- Cancel anytime". New l10n keys needed:
- `paywall_pricing_terms`: "7-day free trial -- Cancel anytime"
- `paywall_pricing_terms` (AR): "تجربة مجانية 7 أيام -- إلغاء في أي وقت"

### 2.3 PaywallScreen — Restore Button

**Current:** Restore button EXISTS at line 279-287 (`TextButton` calling `_restore()`). The `_restore()` method (line 60-80) works correctly.

**No changes needed for PaywallScreen restore.**

### 2.4 SubscriptionScreen — Missing Restore Button

**File:** `lib/features/monetization/presentation/screens/subscription_screen.dart` (97 lines)
**Current layout:** Status icon, status label, trial banner (if in trial), upgrade button (if not Pro), and that's it.

**Missing (D-08):** "Restore Purchases" button. Add a `TextButton` similar to PaywallScreen's.

**Missing (D-07):** "Manage subscription" button. Opens Play Store subscription management URL.

**Current imports:** Does NOT import `url_launcher`. Package status: `url_launcher` is NOT in `pubspec.yaml` as a direct dependency. It appears only as transitive dependencies (`url_launcher_linux`, etc.) in `pubspec.lock`. **Must add `url_launcher` to `pubspec.yaml`.**

### 2.5 SettingsScreen — Pro Status Row

**File:** `lib/features/settings/presentation/screens/settings_screen.dart` (1021 lines)
**Current sections:** Appearance, General, Security, Backup & export, Danger zone, About.

**Required (D-09):** Add "Masarify Pro" status row. Best placement: at the TOP of the settings list (before Appearance section) or as a new section "Subscription".

**Pattern to follow:** `_SettingsTile` widget (line 910-963):
```dart
_SettingsTile(
  icon: AppIcons.checkCircle,  // or crown icon
  label: l10n.settings_pro_status,
  subtitle: hasPro ? l10n.pro_badge : (isInTrial ? "Trial: X days" : l10n.subscription_inactive),
  onTap: () => context.push(AppRoutes.settingsSubscription),
)
```

**Imports needed:** `subscription_provider.dart` (NOT currently imported in settings_screen.dart).

### 2.6 Silent Restore on App Resume

**File:** `lib/app/app.dart` (102 lines)
**`didChangeAppLifecycleState`:** Lines 39-44. Currently only handles `paused` (stores `_pausedAt`) and `resumed` (calls `_checkAutoLock()`).

**Required (D-10):** Add `restorePurchases()` call on resumed:
```dart
} else if (state == AppLifecycleState.resumed) {
  _checkAutoLock();
  _silentRestore();
}
```

**Import needed:** `subscription_provider.dart`. Since `MasarifyApp` is a `ConsumerStatefulWidget`, `ref` is available.

**Gotcha:** `restorePurchases()` in `SubscriptionService` calls `_restorePurchases()` which first sets `_kProActive = false` then calls `_iap.restorePurchases()`. This means there's a brief moment where `isPro` is false. If the UI is watching `hasProAccessProvider`, it might flash the free-tier state. However, the `proStatusStream` will emit `true` again once the purchase is re-confirmed, and `isInTrial` still returns true during trial. This is acceptable for silent restore.

**Risk:** Calling `restorePurchases()` on every resume could be too aggressive (rate limiting from Google Play). Consider debouncing or throttling (e.g., only restore if last restore was > 1 hour ago). Use a simple timestamp check.

### 2.7 url_launcher Package

**Status:** NOT in `pubspec.yaml` as direct dependency. Only transitive via other packages.
**Action:** Add `url_launcher: ^6.3.1` to `pubspec.yaml` dependencies, run `flutter pub get`.

---

## 3. Onboarding Flow (ONBOARD-01, ONBOARD-02)

### 3.1 Current Onboarding Page Count

**File:** `lib/features/onboarding/presentation/screens/onboarding_screen.dart`
**Page count:** `_pageCount = 5` (line 37)
**Pages:**
- Page 0: WelcomePage (welcome hero + language toggle)
- Page 1: ValuePreviewSlide (Track in 2 taps + TrackingDemo)
- Page 2: ValuePreviewSlide (Voice input + VoiceDemo)
- Page 3: ValuePreviewSlide (AI Financial Advisor + ChatDemo)
- Page 4: _StartingBalancePage (starting balance input)

**D-11 verification:** The "What's Your Main Account?" (`AccountTypePicker`) page was ALREADY REMOVED. It still exists as a widget class in `onboarding_pages.dart` (line 628-729) but is not used in `onboarding_screen.dart`. Page 4 = Starting Balance. The `_finish()` method auto-creates a default bank account. **No page removal needed.**

**Cleanup opportunity:** The `AccountTypePicker` class is dead code (defined but not used). Could be removed.

### 3.2 _finish() Method

**File:** `lib/features/onboarding/presentation/screens/onboarding_screen.dart`, lines 85-125
**Current flow:**
1. Sets loading
2. Creates system Cash wallet (`ensureSystemWalletExists`)
3. Creates default bank account with starting balance
4. Marks onboarding done (`prefs.markOnboardingDone()`)
5. Shows success overlay dialog (auto-dismisses after `AppDurations.splashHold`)
6. Navigates to dashboard (`context.go(AppRoutes.dashboard)`)

**Missing:** `ensureTrialStarted()` call (D-16/D-17) and trial snackbar (D-18).

### 3.3 Page Transitions & Polish (D-12)

**Skip button:** Lines 150-171 -- shows on pages 1-3, skips to starting balance page. Works correctly.
**Back behavior:** Lines 136-143 -- `PopScope` with `onPopInvokedWithResult`, goes to previous page. Works correctly.
**Page indicator:** Lines 228-240 -- `SmoothPageIndicator` with `WormEffect`. Works correctly.
**Parallax:** Lines 81, 159-165 -- `_offsetForPage()` for Transform.translate parallax. Works correctly.

**Assessment:** Transitions already work well. D-12 is mostly verification + minor style tweaks. No major changes needed.

### 3.4 Pre-existing L10n Bug (CRITICAL)

**BUG FOUND:** `onboarding_pages.dart` lines 569 and 603 reference `context.l10n.onboarding_demo_chat_user` and `context.l10n.onboarding_demo_chat_ai`, but these keys DO NOT EXIST in either `app_en.arb` or `app_ar.arb`. The generated `AppLocalizations` class does not have these getters.

**Additionally:** `onboarding_slide3_title` still says "SMS Auto-Detect" / "كشف SMS تلقائي" in the ARB files, but the onboarding page 3 now shows the ChatDemo widget (AI Financial Advisor). The title was never updated after the AI-first pivot.

**This means the onboarding currently has a compile error** (or runtime error if using late binding). These missing keys MUST be added as part of this phase's L10n work:
- `onboarding_demo_chat_user`: "How much did I spend on food this week?"
- `onboarding_demo_chat_ai`: "You spent EGP 450 on food this week -- 15% more than last week."
- Update `onboarding_slide3_title`: "SMS Auto-Detect" -> "Your AI Financial Advisor"
- Update `onboarding_slide3_body`: SMS description -> AI advisor description

---

## 4. Trial Activation (PAYWALL-04 wiring)

### 4.1 ensureTrialStarted() Method

**File:** `lib/core/services/subscription_service.dart`, lines 60-66
```dart
Future<void> ensureTrialStarted() async {
  if (_prefs.getString(_kTrialStartDate) != null) return;  // Already started
  await _prefs.setString(_kTrialStartDate, DateTime.now().toIso8601String());
}
```
- Idempotent: only sets the trial start date once.
- Uses SharedPreferences (fast, synchronous after first load).

### 4.2 Current Call Site in main.dart

**File:** `lib/main.dart`, line 87
```dart
unawaited(subService.ensureTrialStarted());
```
- Called on every app launch, immediately after IAP initialization.
- **Problem (D-16):** This means trial starts on first launch, even before onboarding completes. If user installs the app and doesn't onboard for 3 days, they lose 3 trial days.
- **Fix:** Remove line 87, call `ensureTrialStarted()` from `OnboardingScreen._finish()`.

### 4.3 Trial Display

**Provider:** `trialDaysRemainingProvider` in `subscription_provider.dart` (line 39-41)
**Used in:**
- `PaywallScreen` line 85: `ref.watch(trialDaysRemainingProvider)` -- shows trial banner if > 0
- `SubscriptionScreen` line 22-24: Shows trial info card

**Verification (D-19):** After moving `ensureTrialStarted()` to onboarding, the trial countdown should display correctly. Before onboarding, `trialDaysRemaining` returns `_trialDays` (7) because no start date is set, which means `hasProAccess = true` pre-onboarding. This is fine.

### 4.4 Snackbar After Onboarding (D-18)

**Pattern:** Use `SnackHelper.showSuccess(context, l10n.trial_started_message)` after the success overlay dismisses. The success overlay auto-pops after `AppDurations.splashHold`. The snackbar should fire after the `context.go(AppRoutes.dashboard)` -- but by then we're on the dashboard, so we need to use a different approach.

**Options:**
1. Show snackbar BEFORE navigating (after overlay pops, before `context.go`)
2. Use `appRouter.go()` from a ref-accessible place and show snackbar on the dashboard

**Best approach:** After `showDialog` returns (overlay dismissed), show snackbar, then navigate:
```dart
await showDialog(...); // success overlay
if (!mounted) return;
SnackHelper.showSuccess(context, context.l10n.trial_started_message);
context.go(AppRoutes.dashboard);
```
The snackbar will persist during navigation because `ScaffoldMessenger` is at the app level.

---

## 5. Financial Disclaimer (ONBOARD-03)

### 5.1 Onboarding Page 3 — Disclaimer Text

**File:** `lib/features/onboarding/presentation/widgets/onboarding_pages.dart`
**Widget:** `ValuePreviewSlide` (line 130-198)
**Structure:** `Column` with Spacer, demo widget (parallax), title, subtitle, Spacer.

**D-13 placement:** Add disclaimer text below the subtitle in the `ValuePreviewSlide` for page 3. However, `ValuePreviewSlide` is generic (used for all 3 slides). Options:
1. Add an optional `footer` widget parameter to `ValuePreviewSlide`
2. Create a custom slide for page 3 in `onboarding_screen.dart`
3. Add the disclaimer directly in `onboarding_screen.dart` page 3 definition

**Recommended:** Add an optional `footerWidget` parameter to `ValuePreviewSlide`. Pass the disclaimer text only for page 3.

### 5.2 ChatScreen — Disclaimer Banner

**File:** `lib/features/ai_chat/presentation/screens/chat_screen.dart`
**Build structure:** Lines 344-550
```
Scaffold
  appBar: AppAppBar
  body: Column
    - Offline banner (if !isOnline)
    - Expanded ListView (messages)
    - Input bar
```

**D-14 placement:** Add a persistent banner between the offline banner and the message list. Use `PreferencesService` flag `hasSeenAiDisclaimer`:
- First visit: Show dismissible banner with full disclaimer text
- After dismissal: Show subtle "AI-generated content" label (smaller text in app bar subtitle or persistent small banner)

**PreferencesService addition needed:**
```dart
static const _kHasSeenAiDisclaimer = 'has_seen_ai_disclaimer';
bool get hasSeenAiDisclaimer => _prefs.getBool(_kHasSeenAiDisclaimer) ?? false;
Future<void> markAiDisclaimerSeen() => _prefs.setBool(_kHasSeenAiDisclaimer, true);
```

### 5.3 Accessing PreferencesService in ChatScreen

`ChatScreen` is a `ConsumerStatefulWidget`. It accesses providers via `ref`. The preferences can be read via:
```dart
final prefs = await ref.read(preferencesFutureProvider.future);
```
Or for a one-shot synchronous check, could use a dedicated provider.

---

## 6. L10n Analysis

### 6.1 Existing Paywall/Subscription Keys (EN)

Already exist (16 keys):
- `pro_badge`, `pro_feature_title`, `pro_feature_body`, `pro_upgrade`
- `subscription_title`, `subscription_active`, `subscription_inactive`, `subscription_upgrade_prompt`
- `paywall_title`, `paywall_headline`, `paywall_subheadline`, `paywall_includes`
- `paywall_feature_budgets`, `paywall_feature_goals`, `paywall_feature_insights`, `paywall_feature_analytics`, `paywall_feature_backup`, `paywall_feature_export`, `paywall_feature_chat`
- `paywall_monthly`, `paywall_yearly`, `paywall_restore`
- `paywall_restored`, `paywall_no_purchases`, `paywall_store_unavailable`
- `paywall_trial_banner`, `paywall_pro_feature`, `paywall_unlock_cta`

All 16 keys also exist in AR.

### 6.2 New L10n Keys Needed

**Pricing & Trial:**
- `paywall_pricing_terms` -- "7-day free trial -- Cancel anytime"
- `trial_started_message` -- "Your 7-day Pro trial has started!"

**Settings Pro Status:**
- `settings_pro_status` -- "Masarify Pro"
- `settings_pro_trial_days` -- "Trial: {days} days left"
- `settings_pro_free` -- "Free Plan"

**Manage Subscription:**
- `subscription_manage` -- "Manage Subscription"
- `subscription_restore` -- "Restore Purchases" (reuse `paywall_restore`?)

**Financial Disclaimer:**
- `disclaimer_financial` -- "Masarify provides budgeting guidance only, not regulated financial, investment, or tax advice."
- `disclaimer_ai_content` -- "AI-generated content"
- `disclaimer_dismiss` -- "Got it" (for dismiss button)

**Budget/Goal Limit:**
- `budget_limit_reached` -- "Free plan allows 2 budgets. Upgrade to Pro for unlimited."
- `goal_limit_reached` -- "Free plan allows 1 savings goal. Upgrade to Pro for unlimited."

**Onboarding Fixes (pre-existing bug):**
- `onboarding_demo_chat_user` -- "How much did I spend on food this week?"
- `onboarding_demo_chat_ai` -- "You spent EGP 450 on food -- 15% more than last week."
- Update `onboarding_slide3_title` -- "Your AI Financial Advisor" (was: "SMS Auto-Detect")
- Update `onboarding_slide3_body` -- "Get smart spending insights, budget advice, and financial guidance -- powered by AI." (was: SMS description)

**Total:** ~14 new keys + 2 updated keys, all in both EN and AR.

### 6.3 Key Naming Convention

From existing keys:
- Prefix by screen/feature: `paywall_*`, `subscription_*`, `onboarding_*`, `settings_*`
- Lowercase snake_case
- Placeholders use `{name}` with `@key` metadata
- Multi-word labels: no articles (e.g., "Unlock Full Power" not "Unlock the Full Power")

---

## 7. Dependencies & Package Checks

### 7.1 url_launcher

**Status:** NOT in `pubspec.yaml`. Transitive dependencies exist in `pubspec.lock`.
**Action:** Add `url_launcher: ^6.3.1` to `pubspec.yaml` under `dependencies`.
**Impact:** Minimal -- it's a first-party Flutter package, already transitively resolved.

### 7.2 No Other New Dependencies

All other required functionality uses existing packages:
- `in_app_purchase` -- already in pubspec
- `shared_preferences` -- already in pubspec
- `flutter_riverpod` -- already in pubspec
- `go_router` -- already in pubspec

---

## 8. Risk Assessment

### High Risk
1. **Missing L10n keys (onboarding_demo_chat_*)** -- These cause compile/runtime errors. Must fix as part of this phase (or Phase 3 if it runs first). If the app is built before this fix, the ChatDemo widget on onboarding page 3 will crash.

### Medium Risk
2. **Silent restore on every resume** -- Could hit Google Play rate limits. Recommend throttling to once per hour using a timestamp in SharedPreferences.
3. **Trial start timing** -- Moving `ensureTrialStarted()` from main.dart to onboarding means the trial clock is NOT ticking for users who install but don't complete onboarding. This is the DESIRED behavior but verify that `hasProAccess` still returns `true` before onboarding (it does: `trialDaysRemaining` returns 7 when no start date is set).

### Low Risk
4. **url_launcher addition** -- Standard package, minimal size impact.
5. **Feature list reorder** -- Pure UI change, no logic impact.
6. **Disclaimer banner state** -- Uses well-established SharedPreferences pattern.

---

## 9. Existing Patterns to Follow

### Settings Row Pattern
```dart
_SettingsTile(
  icon: AppIcons.xxx,
  label: l10n.settings_xxx,
  subtitle: '...',
  onTap: () => context.push(AppRoutes.xxx),
)
```
Used throughout `settings_screen.dart`. The `_SettingsTile` widget handles glass card leading icon, chevron trailing, and onTap.

### Feature Gating Pattern
```dart
final hasPro = ref.read(hasProAccessProvider);
if (!hasPro) {
  context.push(AppRoutes.paywall);
  return;
}
```
Established in `pro_feature_guard.dart` lines 43, 69. The pattern uses `context.push` (stack, not replacement) so user can go back.

### Preference Flag Pattern
```dart
// In PreferencesService:
static const _kFlagName = 'flag_name';
bool get flagName => _prefs.getBool(_kFlagName) ?? false;
Future<void> setFlagName(bool v) => _prefs.setBool(_kFlagName, v);
```
Used extensively (20+ flags in preferences_service.dart).

### L10n Key Pattern
Keys in snake_case, prefixed by feature. Placeholders declared in `@key` metadata. Both `app_en.arb` and `app_ar.arb` must have every key.

---

## 10. Validation Architecture

### Plan 1: Free Tier Enforcement
- [ ] Budget gate: Create 3 budgets as free user -- 3rd should redirect to paywall
- [ ] Budget gate: Edit existing budget as free user at limit -- should succeed (edits not gated)
- [ ] Goal gate: Create 2 goals as free user -- 2nd should redirect to paywall
- [ ] Goal gate: Edit existing goal as free user at limit -- should succeed
- [ ] Lock badge: BudgetsScreen shows lock indicator when at limit and not Pro
- [ ] Lock badge: GoalsScreen shows lock indicator when at limit and not Pro
- [ ] AI chat: ProFeatureGuard blocks chat for expired-trial, non-Pro users
- [ ] AI chat: Chat accessible during trial (hasProAccess = true)
- [ ] Transaction logging: NEVER gated -- verify free users can always add transactions

### Plan 2: Paywall UI & Restore Flow
- [ ] Feature list order: AI first, budgets/goals after
- [ ] Pricing terms visible above purchase button
- [ ] "Manage subscription" button opens Play Store URL
- [ ] Restore button on PaywallScreen (already exists -- verify)
- [ ] Restore button on SubscriptionScreen (new)
- [ ] Pro status row in Settings shows correct badge (Pro / Trial X days / Free)
- [ ] Silent restore on app resume doesn't cause UI flicker
- [ ] Silent restore is throttled (not on every resume)

### Plan 3: Onboarding Polish
- [ ] Page count is 5 (Welcome, Track, Voice, AI, Balance)
- [ ] AccountTypePicker dead code removed
- [ ] Skip button works on pages 1-3
- [ ] Back button works on all pages
- [ ] Page indicator renders correctly
- [ ] Slide 3 title says "AI Financial Advisor" (not "SMS Auto-Detect")
- [ ] ChatDemo l10n keys exist and render
- [ ] Financial disclaimer visible on slide 3 below ChatDemo
- [ ] Transitions are smooth (no jank)

### Plan 4: Trial Activation Wiring
- [ ] `ensureTrialStarted()` removed from main.dart line 87
- [ ] `ensureTrialStarted()` called in `_finish()` after account creation
- [ ] "Your 7-day Pro trial has started!" snackbar shown after overlay
- [ ] Trial countdown displays correctly in SubscriptionScreen
- [ ] Trial countdown displays correctly in PaywallScreen trial banner
- [ ] Pre-onboarding: hasProAccess still returns true (trialDaysRemaining = 7)

### Cross-cutting
- [ ] All new l10n keys added to both `app_en.arb` and `app_ar.arb`
- [ ] `flutter gen-l10n` runs without errors
- [ ] `flutter analyze lib/` reports zero issues
- [ ] RTL layout verified for all new UI elements

---

## RESEARCH COMPLETE
