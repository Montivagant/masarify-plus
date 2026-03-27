# Architecture Research: Subscriptions, Performance, and Onboarding

_Research date: 2026-03-27 | App: Masarify (مصاريفي) | Stack: Flutter + Riverpod + Drift_

---

## 1. Subscription Architecture

### Current State

The subscription infrastructure is already fully scaffolded:

- `lib/core/services/subscription_service.dart` — IAP listener, trial logic, purchase handler
- `lib/shared/providers/subscription_provider.dart` — `hasProAccessProvider`, `trialDaysRemainingProvider`, `subscriptionServiceProvider`
- `lib/features/monetization/presentation/screens/paywall_screen.dart` — purchase UI
- `lib/features/monetization/presentation/screens/subscription_screen.dart` — status UI
- `lib/core/config/app_config.dart` — `kMonetizationEnabled = true`
- `in_app_purchase: ^3.2.0` already in `pubspec.yaml`

The core architecture is sound. The gaps are around feature gating and offline entitlement resilience.

### Where the Subscription Service Lives

The service belongs in `lib/core/services/` (already there). This is correct placement because:

- It is a platform service (wraps `in_app_purchase`), not a domain concept
- It has no business logic — it only tracks entitlement state
- It must be accessible across features without creating circular imports

The `SubscriptionService` is intentionally **not** a repository — subscription state is not persisted via Drift. It uses `SharedPreferences` for local caching, which is appropriate: entitlement is a lightweight key-value fact, not a structured data record.

### Riverpod Provider Integration

```
lib/shared/providers/subscription_provider.dart
│
├── subscriptionServiceProvider   (Provider<SubscriptionService>)
│   └── initialized in main.dart via unawaited(subService.initialize())
│
├── hasProAccessProvider          (Provider<bool>)
│   └── reads service.hasProAccess
│   └── subscribes to service.proStatusStream → invalidateSelf() on purchase
│
└── trialDaysRemainingProvider    (Provider<int>)
    └── reads service.trialDaysRemaining
```

This is correct. `hasProAccessProvider` uses `ref.invalidateSelf()` triggered by the `proStatusStream`, so the entire UI tree rebuilds immediately on purchase completion without requiring an app restart.

### Feature Gating Pattern

The recommended pattern is a thin wrapper at the use point — no global "gate widget":

```
// CHECK at data layer (enforcement):
//   In repository or provider, clamp free-tier limits:
final budgetsProvider = StreamProvider<List<BudgetEntity>>((ref) {
  final hasPro = ref.watch(hasProAccessProvider);
  final repo = ref.watch(budgetRepositoryProvider);
  if (hasPro) return repo.watchAll();
  return repo.watchAll().map((list) => list.take(2).toList()); // free: 2 budgets
});

// CHECK at UI layer (affordance):
//   In the "Add Budget" button handler:
final hasPro = ref.read(hasProAccessProvider);
final count = ref.read(budgetsProvider).valueOrNull?.length ?? 0;
if (!hasPro && count >= 2) {
  context.push(AppRoutes.paywall); // redirect to paywall
  return;
}
```

**Do not** gate with a wrapper widget (e.g., `ProGate(child: ...)`) — it creates hidden coupling and makes it hard to reason about what is gated where. Instead:

1. **Enforcement in providers**: clamp collection sizes, return null for gated data
2. **Affordance in UI**: check `hasProAccessProvider` before navigating to create screens
3. **Visual hint**: show a lock badge on gated items (tap opens paywall, does not crash)

**Free tier limits to enforce:**
- Budgets: max 2 (gate in `budgetsProvider` + `SetBudgetScreen`)
- Savings Goals: max 1 (gate in `goalsProvider` + `AddGoalScreen`)
- AI Chat: unlimited (AI is the hero feature — do not gate)
- Voice Input: unlimited (core value — do not gate)
- Backup/Export: Pro only (gate in `BackupScreen` and export actions)
- Advanced Analytics: Pro only (gate at Analytics tab entry or specific charts)

### Offline-First Subscription Status

Current approach: `SharedPreferences` stores `_kProActive` (bool) and `_kTrialStartDate` (ISO string).

**Gaps to address:**

1. **Subscription expiry is not cached.** If a user cancels, the app does not know until `restorePurchases()` is called. This is acceptable for v1 (trust the cached bool on launch, re-verify on foreground resume).

2. **Trial cannot be reset by clearing prefs.** The 14-day trial is purely client-side. This is intentional for v1 — server-side enforcement is a post-launch hardening step.

3. **Recommended foreground-resume verification:**

```
// In app.dart AppLifecycleListener:
case AppLifecycleState.resumed:
  final service = container.read(subscriptionServiceProvider);
  unawaited(service.restorePurchases()); // re-checks Google Play silently
```

**Entitlement cache decision tree:**

```
On app open:
  hasProAccess?
    ├─ isPro (SharedPrefs _kProActive = true)  → grant Pro UI
    ├─ isInTrial (trial days remaining > 0)    → grant Pro UI
    └─ neither                                 → free tier

On foreground resume (every time):
  restorePurchases() → silently updates _kProActive → invalidates hasProAccessProvider
```

### Component Diagram

```
┌──────────────────────────────────────────────────────────────┐
│  Features (budgets, goals, backup, analytics)                │
│  ref.watch(hasProAccessProvider) at gate points              │
└──────────────────┬───────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────────┐
│  Riverpod Providers (subscription_provider.dart)             │
│  hasProAccessProvider → bool                                 │
│  trialDaysRemainingProvider → int                            │
│  subscriptionServiceProvider → SubscriptionService          │
└──────────────────┬───────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────────┐
│  SubscriptionService (core/services)                         │
│  isPro: bool        (SharedPreferences _kProActive)          │
│  isInTrial: bool    (trial date diff)                        │
│  hasProAccess: bool (isPro || isInTrial)                     │
│  proStatusStream: Stream<bool>   (broadcasts on purchase)    │
│  initialize() → IAP listener + restorePurchases()           │
│  purchase(product) → _iap.buyNonConsumable()                │
│  restorePurchases() → _iap.restorePurchases()               │
└──────────────────┬───────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────────┐
│  in_app_purchase (Google Play Billing)                       │
│  InAppPurchase.instance                                      │
│  purchaseStream: Stream<List<PurchaseDetails>>              │
└──────────────────────────────────────────────────────────────┘
                   │
┌──────────────────▼───────────────────────────────────────────┐
│  SharedPreferences (persistence)                             │
│  _kProActive = bool                                         │
│  _kTrialStartDate = ISO8601 string                          │
└──────────────────────────────────────────────────────────────┘
```

### Build Order for Subscription Work

1. Verify `SubscriptionService` initializes cleanly (already done in `main.dart`)
2. Add `AppLifecycleState.resumed` re-verification hook in `app.dart`
3. Implement budget limit enforcement in `budgetsProvider` (clamp to 2 for free)
4. Implement goal limit enforcement in `goalsProvider` (clamp to 1 for free)
5. Add paywall redirect in `SetBudgetScreen` and `AddGoalScreen` at the add button
6. Add lock badges on gated items in `BudgetsScreen` and `GoalsScreen`
7. Gate backup/export actions in `SettingsScreen` and `BackupScreen`
8. Gate advanced analytics charts in `AnalyticsScreen`

---

## 2. Performance Architecture

### Current Performance Baseline

The app already has solid performance foundations:
- All indexes defined in `_createIndexes()` in `app_database.dart`
- `unawaited()` for all background init in `main.dart` (RecurringScheduler, SMS scan, IAP)
- Shimmer loading states in heavy screens
- `flutter_animate` for declarative animations (no manual `AnimationController`)
- `CustomScrollView` with slivers on DashboardScreen
- `StreamProvider.family` for per-wallet and per-month transaction filtering

### Lazy Loading for Heavy Screens

Flutter's `go_router` lazily constructs routes on navigation — screens are not built until first visited. This is already leveraged by the feature-first architecture. No additional lazy loading mechanism is needed for screen-level initialization.

**Within screens**, use `AutoDispose` providers for data that should not live beyond the screen:

```dart
// CORRECT: data discarded when screen pops
final transactionByIdProvider =
    FutureProvider.autoDispose.family<TransactionEntity?, int>((ref, id) { ... });

// AVOID for detail screens: non-autoDispose keeps data in memory indefinitely
```

**For the Analytics screen** (potentially heavy chart rendering):
- Compute aggregates in a `FutureProvider.autoDispose` (not a `StreamProvider`) — analytics do not need real-time reactivity
- Cache the result for the session; only recompute when the provider is invalidated
- Use `isolate.run()` for aggregation over large datasets (>500 transactions)

```dart
// Analytics aggregation off main thread
final analyticsProvider = FutureProvider.autoDispose<AnalyticsData>((ref) async {
  final txs = await ref.watch(rawRecentTransactionsProvider.future);
  return compute(_buildAnalytics, txs); // runs in isolate
});
```

### Drift Query Optimization

**Existing indexes (already in place):**

| Index | Table | Columns | Use |
|-------|-------|---------|-----|
| `idx_transactions_date` | transactions | transaction_date DESC | watchAll(), dashboard list |
| `idx_transactions_wallet` | transactions | wallet_id | watchByWallet() |
| `idx_transactions_category` | transactions | category_id | analytics |
| `idx_transfers_date` | transfers | transfer_date DESC | activity merge |
| `idx_budgets_year_month` | budgets | year, month | monthly budget queries |
| `idx_recurring_rules_due` | recurring_rules | next_due_date WHERE is_active=1 | scheduler, upcoming bills |

**Missing composite index for dashboard (add this):**

The dashboard loads "transactions by wallet + month" frequently. A composite index would eliminate the need to scan by date then filter by wallet:

```sql
CREATE INDEX IF NOT EXISTS idx_transactions_wallet_date
ON transactions(wallet_id, transaction_date DESC);
```

**Pagination for large datasets:**

The current `watchAll()` returns all transactions with no limit. For users with 500+ transactions, this causes both memory pressure and slow initial render. Add paginated variants:

```dart
// In TransactionDao — paginated cursor-based query
Stream<List<Transaction>> watchPage({
  required int limit,
  required int offset,
  int? walletId,
}) {
  final query = (select(transactions)
    ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
    ..limit(limit, offset: offset));
  if (walletId != null) query.where((t) => t.walletId.equals(walletId));
  return query.watch();
}
```

For the dashboard, loading the most recent 50 items initially and fetching more on scroll is sufficient for 60fps performance.

**Batch operations for seed and import:**

Use `transaction()` for multi-row inserts (already used in migrations):

```dart
await db.transaction(() async {
  for (final row in rows) {
    await dao.insertOne(row);
  }
});
```

**Stream efficiency — avoid `Rx.combineLatest` over large streams:**

`recentActivityProvider` (in `activity_provider.dart`) uses `Rx.combineLatest3` to merge transactions, transfers, and wallets. Every mutation to any of the three tables causes a full re-merge and re-sort. For heavy users this can be slow.

Optimization: debounce the stream to avoid thrashing during bulk import:

```dart
return Rx.combineLatest3(txStream, transferStream, walletStream, merge)
    .debounceTime(const Duration(milliseconds: 100));
```

### Widget Rebuild Optimization

**`const` constructors:**

All pure display widgets (icons, labels, static cards) should use `const`. This is already enforced by `flutter_lints`. Audit `GlassCard`, `TransactionCard`, and `BudgetProgressCard` to ensure const-eligible children are marked `const`.

**`ref.select()` for fine-grained subscriptions:**

Instead of watching the entire wallet list to get a single property:

```dart
// AVOID: rebuilds on any wallet change
final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
final defaultWallet = wallets.firstWhere((w) => w.isDefaultAccount);

// PREFER: rebuilds only when the default account id changes
final defaultId = ref.watch(
  walletsProvider.select((async) =>
    async.valueOrNull?.firstWhere((w) => w.isDefaultAccount)?.id
  )
);
```

Use `select()` liberally in insight cards, month summary, and the account carousel where partial wallet data is needed.

**`Provider.family` for per-entity streams:**

Already used correctly (`transactionsByWalletProvider`, `walletByIdProvider`). Ensure `autoDispose` is applied to any family provider used only on detail screens.

**`ValueListenableBuilder` for scroll-driven UI:**

`DashboardScreen` already uses `ValueNotifier<double> _scrollOffset` + `ValueListenableBuilder` to drive the sticky search bar opacity. This is the correct pattern — it bypasses Riverpod entirely for scroll-driven updates, preventing `setState` rebuild cascade.

**`RepaintBoundary` for glass cards:**

The glassmorphic `GlassCard` uses `BackdropFilter` (Impeller disabled on Android to avoid grey overlay). `BackdropFilter` forces a compositing layer. Ensure each glass card is already inside a `RepaintBoundary` — if not, add it to `GlassCard`'s build method to isolate repaint costs.

```dart
// In GlassCard:
return RepaintBoundary(
  child: ClipRRect(
    child: BackdropFilter(...),
  ),
);
```

### Image and Asset Caching

The app has no network images (brand icons are either local SVGs or name-based resolution). No image cache configuration is needed for v1.

For future brand icon network fetch (noted in MEMORY.md as a Pro feature):
- Use `cached_network_image` package
- Cache to `path_provider` application support directory
- Set `maxNrOfCacheObjects: 200` (one per brand)

### Startup Optimization

**Current startup sequence (main.dart):**

```
1. WidgetsFlutterBinding.ensureInitialized()    [blocking]
2. CrashLogService.initialize()                  [blocking, fast]
3. SharedPreferences.getInstance()               [blocking, fast]
4. GlassConfig.initialize()                      [blocking, fast — device check]
5. NotificationService.initialize()              [blocking, medium]
6. ProviderContainer creation                    [blocking, instantaneous]
7. categoryRepository.seedDefaultsIfEmpty()      [blocking, DB read check]
8. runApp()                                      [UI visible]
9. subService.initialize()                       [unawaited — background]
10. RecurringScheduler.run()                     [unawaited — background]
11. NotificationService.scheduleDaily()          [unawaited — background]
```

Steps 1-8 are on the critical path to first frame. Target: under 400ms combined.

**Optimization opportunities:**

- Step 5 (`NotificationService.initialize()`) can be moved to post-`runApp()` with `unawaited` if the notification tap handler is wired before the first `scheduleDaily()` call. This saves ~50-100ms on cold start.

- Step 7 (`seedDefaultsIfEmpty()`) issues a COUNT query. This is fast but adds a DB open round-trip. Acceptable; keep as-is.

- `GlassConfig.initialize()` reads `FlutterView` render capabilities — fast, keep blocking.

- Consider `flutter_native_splash` (already in dev deps) to hold the splash screen while the async init runs, giving a smooth perceived startup.

**Deferred provider initialization:**

Services that are never used during onboarding (AI chat, recurring scheduler, analytics) should not be initialized before `runApp()`. They are currently deferred with `unawaited()` — this is correct.

**Database open is lazy** via `drift_flutter` — the SQLite connection opens on first query, not on `AppDatabase()` construction. The `ProviderContainer` creates `AppDatabase` immediately but no query fires until the first provider is watched. This is already optimal.

### Performance Component Diagram

```
Startup Critical Path (target <400ms total):
  BindingsInit → CrashLog → SharedPrefs → GlassConfig → NotifInit → ProviderContainer → SeedCheck → runApp()

Post-Launch (background, non-blocking):
  IAPInit → RecurringScheduler → NotifSchedule

Data Layer Performance:
  Transactions table
    ├── idx_transactions_date          (dashboard, all-transactions view)
    ├── idx_transactions_wallet        (per-account view)
    ├── idx_transactions_category      (analytics, category breakdown)
    └── [ADD] idx_transactions_wallet_date  (dashboard per-account with month filter)

Widget Rebuild Containment:
  ScrollOffset changes → ValueNotifier → ValueListenableBuilder (no Riverpod involved)
  Wallet list changes → ref.select() → only affected widget rebuilds
  Purchase event → proStatusStream → ref.invalidateSelf() → hasProAccessProvider
  DB mutation → Drift stream → StreamProvider → only watching providers rebuild
```

---

## 3. Onboarding Architecture

### Current State

`OnboardingScreen` (`lib/features/onboarding/`) is a `ConsumerStatefulWidget` with a `PageController`, 5 pages, `smooth_page_indicator`, parallax page offsets, and a `PopScope` that intercepts back navigation to move between pages rather than exit.

The flow is already well-structured. The gaps are: progress persistence across app restarts during onboarding, and analytics event hooks for funnel analysis.

### Page Controller Pattern

Current implementation is correct. The `PageController` lives in the `State` class (`ConsumerStatefulWidget`), not in a provider — this is intentional since onboarding state is ephemeral UI state, not domain state.

**Back navigation:** `PopScope(canPop: false)` + `previousPage()` call is the correct Flutter pattern. It works with Android physical back button and gesture navigation.

**Skip navigation:** `_skipToStartingBalance()` animates directly to the last page. This is correct — never jump backwards from skip, always jump to the terminal setup page.

**Parallax:** `_offsetForPage(int pageIndex) => _currentPage - pageIndex` fed into `Transform.translate` is a clean, no-overhead parallax implementation. No `AnimationController` needed.

### Progress Persistence (Resume if Interrupted)

Currently, if the user is interrupted mid-onboarding (force-quit, call, low battery), they restart from page 0.

**Recommended implementation — persist last-seen page index:**

```dart
// In PreferencesService (lib/core/services/preferences_service.dart)
static const _kOnboardingPage = 'onboarding_last_page';

int get lastOnboardingPage => _prefs.getInt(_kOnboardingPage) ?? 0;
Future<void> saveOnboardingPage(int page) =>
    _prefs.setInt(_kOnboardingPage, page);
```

In `_OnboardingScreenState.initState()`:

```dart
@override
void initState() {
  super.initState();
  _pageController.addListener(_onPageScroll);
  // Resume from last-seen page
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final prefs = await ref.read(preferencesFutureProvider.future);
    final savedPage = prefs.lastOnboardingPage;
    if (savedPage > 0 && savedPage < _pageCount - 1) {
      _pageController.jumpToPage(savedPage);
    }
  });
}
```

In `_onPageScroll()`, save progress (debounced):

```dart
void _onPageScroll() {
  final page = _pageController.page;
  if (page != null) {
    final rounded = page.round();
    if (rounded != _currentIndex) {
      setState(() {
        _currentPage = page;
        _currentIndex = rounded;
      });
      // Debounce the prefs write — don't write on every scroll frame
      _savePageDebounce?.cancel();
      _savePageDebounce = Timer(const Duration(milliseconds: 300), () async {
        final prefs = await ref.read(preferencesFutureProvider.future);
        await prefs.saveOnboardingPage(rounded);
      });
    }
  }
}
```

Clean up the saved page on `_finish()` (or let `markOnboardingDone()` implicitly invalidate it).

### Skip/Back Navigation Rules

| Current page | Back button | Skip button |
|---|---|---|
| Page 0 (Welcome) | No-op (PopScope blocks) | Not shown |
| Pages 1-3 (Value slides) | Go to previous page | Jump to page 4 (Starting Balance) |
| Page 4 (Starting Balance) | Go to page 3 | Not shown (two CTA buttons: Set / Skip) |

This matches the current implementation exactly. No changes needed to navigation logic.

### Analytics Events for Funnel Tracking

The app has no analytics package (no Firebase, no Mixpanel — offline-first constraint). For the Play Store launch milestone, basic funnel tracking via `shared_preferences` counters is sufficient. Full analytics can be added post-launch if/when a privacy-respecting analytics solution is chosen.

**Minimum viable funnel tracking (local only):**

```dart
// In PreferencesService:
Future<void> trackOnboardingStep(int step) async {
  final key = 'onboarding_reached_step_$step';
  await _prefs.setBool(key, true);
}

// Emit from _onPageScroll when a new page is first reached:
void _onPageScroll() {
  ...
  if (rounded > _highWaterMark) {
    _highWaterMark = rounded;
    unawaited(prefs.trackOnboardingStep(rounded));
  }
}
```

This data is readable in crash reports (SharedPreferences values are included when using `CrashLogService`) and gives post-hoc funnel visibility.

**If network analytics are added later** (e.g., PostHog with local-first mode), instrument these events:

| Event | Properties |
|---|---|
| `onboarding_started` | locale, is_fresh_install |
| `onboarding_step_viewed` | step_index, step_name |
| `onboarding_skipped` | from_step, to_step |
| `onboarding_completed` | starting_balance_set: bool, time_to_complete_seconds |
| `onboarding_interrupted` | last_step_reached |

### Onboarding Architecture Diagram

```
OnboardingScreen (ConsumerStatefulWidget)
│
├── State: _pageController (PageController)
├── State: _currentIndex (int)
├── State: _currentPage (double — for parallax)
├── State: _startingBalancePiastres (int)
├── State: _loading (bool)
│
├── PopScope (canPop: false)
│   └── onPopInvoked → previousPage()
│
├── Skip button (shown on pages 1-3 only)
│   └── _skipToStartingBalance() → animateToPage(4)
│
├── PageView [5 pages]
│   ├── Page 0: WelcomePage (language toggle, hero, Next button)
│   ├── Page 1: ValuePreviewSlide — Track in 2 taps
│   ├── Page 2: ValuePreviewSlide — Voice input
│   ├── Page 3: ValuePreviewSlide — AI Financial Advisor
│   └── Page 4: _StartingBalancePage (AmountInput, Set/Skip buttons)
│
├── SmoothPageIndicator (read-only, driven by PageController)
│
└── _finish()
    ├── walletRepo.ensureSystemWalletExists()  [async]
    ├── walletRepo.create(bank, startingBalance)  [async]
    ├── prefs.markOnboardingDone()  [async]
    ├── showDialog(_SuccessOverlay)  [2s auto-dismiss]
    └── context.go(AppRoutes.dashboard)

PreferencesService additions (for persistence):
  lastOnboardingPage: int   (key: 'onboarding_last_page')
  saveOnboardingPage(int)
  trackOnboardingStep(int)  (keys: 'onboarding_reached_step_N')
```

---

## 4. Cross-Cutting Build Order

Dependencies between the three areas determine the implementation sequence:

```
Phase A — Foundation (no UI dependencies):
  A1. hasProAccessProvider gate points in budgetsProvider + goalsProvider
  A2. App lifecycle resumed hook → restorePurchases()
  A3. Onboarding page persistence in PreferencesService

Phase B — Feature gating UI (depends on A1):
  B1. Budget limit enforcement in SetBudgetScreen (paywall redirect)
  B2. Goal limit enforcement in AddGoalScreen (paywall redirect)
  B3. Lock badges on gated items in BudgetsScreen + GoalsScreen
  B4. Backup/export gate in SettingsScreen

Phase C — Performance (independent, any order):
  C1. Add idx_transactions_wallet_date composite index
  C2. Pagination in TransactionDao (watchPage with limit/offset)
  C3. Debounce on recentActivityProvider stream
  C4. ref.select() audit across InsightCardsZone + MonthSummaryZone
  C5. RepaintBoundary audit on GlassCard

Phase D — Onboarding polish (depends on A3):
  D1. Wire page persistence in _OnboardingScreenState.initState()
  D2. Add debounced save in _onPageScroll()
  D3. Add local funnel tracking (trackOnboardingStep)
  D4. Test back navigation + skip on physical device (RTL)

Phase E — Startup (after C + D stable):
  E1. Move NotificationService.initialize() to post-runApp() if safe
  E2. Verify cold start time on mid-range Android (target <2s to first frame)
```

**Critical path for Play Store launch:** A1 → B1 → B2 → B3 → C1 → C2 → D1 → D4

---

## 5. Key Decisions and Tradeoffs

| Decision | Recommended | Rationale |
|---|---|---|
| Feature gating location | Provider layer + UI call site | Enforcement in provider prevents bypass; UI check enables affordance (lock badges, paywall redirect) |
| Subscription cache strategy | SharedPrefs + resume revalidation | v1 simplicity; server-side enforcement is post-launch hardening |
| Trial enforcement | Client-side only (SharedPrefs) | Acceptable for 14-day trial at v1; negligible abuse risk |
| Analytics during onboarding | Local SharedPrefs counters | No analytics package in app; respects offline-first constraint |
| Transaction pagination | Limit 50 on dashboard, full on Transactions tab | Dashboard needs speed; Transactions tab needs completeness with virtual scroll |
| Composite DB index | wallet_id + transaction_date | Most common query pattern: "show account X's transactions sorted by date" |
| RepaintBoundary on GlassCard | Yes | BackdropFilter always forces compositing layer; explicit boundary prevents parent repaints from cascading |

---

_All file paths are relative to `lib/` unless prefixed with `D:\Masarify-Plus\`._
