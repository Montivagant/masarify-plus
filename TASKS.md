# TASKS.md — Masarify Development Task Checklist

**Format:** Mark tasks `[x]` when complete, `[/]` when in progress, `[ ]` when pending.
**Rule:** Complete phases in order. P0 tasks are BLOCKING — never advance with a P0 incomplete.
**Rule:** After every Drift schema change → run `dart run build_runner build --delete-conflicting-outputs`
**Rule:** After every task: verify dark mode + RTL layout + accessibility before marking `[x]`.
**Rule:** After every phase: complete the Verification Gate checklist before starting the next phase.
**Commit format:** `feat(module): short description` or `fix(module): what was fixed`

---

## PHASE 0 — Project Setup & Foundation

*Must be 100% complete before writing any feature UI.*

### P0.1 — Flutter Project

- [x] Create Flutter project: `flutter create masarify --org com.masarify --platforms android,ios`
- [x] Create ALL folder structure as defined in `AGENTS.md §4` (create placeholder files where needed)
- [x] Configure `analysis_options.yaml` with `flutter_lints` strict rules
- [x] Set `applicationId = "com.masarify.app"` in `android/app/build.gradle`
- [x] Set `minSdkVersion = 24`, `targetSdkVersion = 34` in `android/app/build.gradle`
- [x] Add ALL dependencies to `pubspec.yaml` as listed in `AGENTS.md §3`
- [x] Run `flutter pub get` — verify zero errors
- [x] Add ALL permissions to `android/app/src/main/AndroidManifest.xml` (see `AGENTS.md §8`)
- [x] Add `NotificationListenerService` declaration to `AndroidManifest.xml`
- [x] Create `assets/dictionaries/egyptian_arabic_finance.json` (empty object, populated later)
- [x] Create `assets/animations/` directory with placeholder text files
- [x] Register all asset directories in `pubspec.yaml` under `flutter: assets:`

### P0.2 — Database Setup

- [x] Create all Drift table files in `lib/data/database/tables/` (one file per table, see `AGENTS.md §5`)
- [x] Create `lib/data/database/app_database.dart` with `@DriftDatabase` referencing all tables
- [x] Create DAOs: `WalletDao`, `CategoryDao`, `TransactionDao`, `TransferDao`, `BudgetDao`, `GoalDao`, `GoalContributionDao`, `RecurringRuleDao`, `BillDao`, `SmsParserLogDao`
- [x] Write database `MigrationStrategy` v1 (initial schema, schemaVersion = 1)
- [x] Schema v2: add `aiEnrichmentJson` column to `SmsParserLogs` table
- [x] Run `build_runner` — verify all `.g.dart` files compile with zero errors
- [ ] ⚠️ **Unit test:** Create a wallet → verify it reads back correctly from a DB stream
- [ ] ⚠️ **Unit test:** MoneyFormatter — piastres → display string (EGP, USD, RTL)
- [ ] ⚠️ **Unit test:** `MoneyFormatter.parseToInt("150.75")` → 15075

### P0.3 — Core Theme & Design System

- [x] Create `lib/app/theme/app_colors.dart` — Minty Fresh `#3DA37A` primary (light) + Gothic Noir `#7B68AE` primary (dark) palette (see `AGENTS.md §7`)
- [x] Create `lib/app/theme/app_text_styles.dart` with full typography scale (see `AGENTS.md §7.2`)
- [x] Create `lib/app/theme/app_theme.dart` — light + dark `ThemeData` via `flex_color_scheme`
- [x] Configure Plus Jakarta Sans via `google_fonts` in both themes
- [x] Create `AppSizes` constants — full spacing, radius, icon, and layout constants (see `AGENTS.md §7.3`)
- [x] Apply theme in `MaterialApp` — verify both light and dark render correctly
- [x] **Verify:** Dark mode uses proper surface tint layering, not just inverted colors
- [x] Verify Lottie placeholder files registered in `pubspec.yaml` under `flutter: assets:`

### P0.4 — Localization

- [x] Create `lib/l10n/app_en.arb` — add keys for all known UI strings
- [x] Create `lib/l10n/app_ar.arb` — Arabic translation for every EN key
- [x] Configure `MaterialApp` with all 4 localization delegates + `GlobalMaterialLocalizations`
- [x] Add `supportedLocales: [Locale('en'), Locale('ar')]`
- [x] Run app in Arabic locale — verify RTL layout renders correctly on all base widgets
- [x] Create localization parity check script: verify EN and AR have identical key sets

### P0.5 — Navigation

- [x] Create `lib/core/constants/app_routes.dart` with ALL route name constants
- [x] Create `lib/app/router/app_router.dart` with all `go_router` routes (use placeholder screens)
- [x] Implement 4-tab bottom navigation bar (Home, Transactions, Analytics, More) per `AGENTS.md §23.4`
- [x] Implement PIN lock route guard (redirect to `/auth/pin-entry` if PIN is set and app is locked)
- [x] Verify all routes are reachable — no broken paths
- [x] **FAB goes DIRECTLY to AddTransactionScreen** (Expense preselected). No intermediate bottom sheet. FAB renders on Home and Transactions tabs only.

### P0.6 — Core Utilities

- [x] Create `lib/core/utils/money_formatter.dart` — full implementation (see `AGENTS.md §10`)
- [x] Create `lib/core/utils/date_utils.dart` — Egyptian locale date formatting
- [x] Create `lib/core/utils/permission_helper.dart` — wraps `permission_handler` with standard rationale dialog
- [x] Create `lib/core/services/notification_service.dart` — `flutter_local_notifications` wrapper
- [x] Create `lib/data/seed/category_seed.dart` — all 22 default categories

### P0.7 — Design Token System (AGENTS.md §23)

- [x] Create `lib/app/theme/app_theme_extension.dart` — `AppThemeExtension` with `ThemeExtension<T>` pattern
- [x] Register `AppThemeExtension.light` in light `ThemeData` and `.dark` in dark `ThemeData`
- [x] Create `lib/core/extensions/build_context_theme.dart` — `AppThemeX` extension with `.appTheme`, `.colors`, `.textStyles` shorthands
- [x] Create `lib/core/constants/app_icons.dart` — `AppIcons` class with all icon constants
- [x] Create `lib/core/constants/app_navigation.dart` — `AppNavDest` + `AppNavigation.destinations` list
- [x] **Enforce rule:** `grep -r "Color(0x" lib/` → must return zero results
- [x] **Enforce rule:** `grep -r "Icons\." lib/features/` → must return zero results

### P0.8 — MasarifyDS Core Components (Minimum for App Shell + Onboarding)

> **Only build what Phase 0 and the app shell actually need.** All other components are built IN the phase that first uses them (see Phase 2 component tasks below). This lets developers see a working app faster.

**Build FULL in Phase 0 (8 components):**
- [x] `buttons/app_button.dart` — Primary/Secondary/Danger/Ghost variants
- [x] `buttons/app_icon_button.dart` — min 48×48dp tap target
- [x] `buttons/app_fab.dart` — single FAB, on tap → navigates to AddTransactionScreen directly
- [x] `inputs/app_text_field.dart` — floating label, error state, RTL-safe, semantic label
- [x] `navigation/app_nav_bar.dart` — 4-tab bottom nav per §23.4
- [x] `navigation/app_app_bar.dart` — standard AppBar with back/menu
- [x] `feedback/shimmer_list.dart` — loading skeleton (needed everywhere)
- [x] `feedback/snack_helper.dart` — toast/snackbar (needed everywhere)

**Build as STUBS only (built fully when their phase arrives):**
- [x] `inputs/amount_input.dart` — FULL (`TextFormField` + `currency_text_input_formatter` with native keyboard, supports `compact: true` mode)
- [x] `inputs/app_date_picker.dart` — FULL (needed for Add Transaction)
- [x] `inputs/app_search_bar.dart` — FULL (needed for Transaction List)
- [x] `cards/*` — all card components FULL (built in Phase 2)
- [x] `lists/*` — FULL (built in Phase 2)
- [x] `dialogs/*` — FULL (built in Phase 2)
- [x] `feedback/lottie_widget.dart` — FULL (built in Phase 2)
- [ ] `pro/*` — STUBS (Phase 5)

- [x] **Rule:** Every P0 component must compile, render in light + dark + RTL, have semantic labels
- [ ] ⚠️ **Widget test:** AppButton renders all 4 variants correctly

### ✅ PHASE 0 — Foundation Verification Gate

- [x] All P0 components compile and render in light + dark + RTL
- [x] AppSizes spacing is consistent across all components
- [x] No hardcoded colors, icons, or spacing values in any file
- [x] `flutter analyze` — zero warnings (verified 2026-02-27)
- [x] App shell runs: bottom nav works, FAB navigates to placeholder AddTransaction screen

---

## PHASE 1 — Core Data Layer

*Build before any UI that needs real data.*

### 1.1 — Categories Data Layer

- [x] Implement `CategoryDao`: full CRUD + reorder + archive operations
- [x] Implement `CategoryRepository` (abstract interface + implementation)
- [x] Implement `categoryProvider` (Riverpod StreamProvider)
- [x] Implement `seedDefaultCategories()` — called on first launch if DB categories table is empty
- [ ] ⚠️ **Unit test:** CategoryRepository — CRUD round-trip

### 1.2 — Wallets Data Layer

- [x] Implement `WalletDao`: CRUD + balance update atomically inside Drift transaction
- [x] Implement `WalletRepository`
- [x] Implement `walletProvider` — reactive stream of all wallets
- [ ] ⚠️ **Unit test:** WalletRepository — CRUD + balance calculation

### 1.3 — Transactions Data Layer

- [x] Implement `TransactionDao`: CRUD + filters (by date, category, wallet, type) + pagination
- [x] Implement `TransferDao`: create/list transfers (never counted as income/expense)
- [x] Implement `TransactionRepository` and `TransferRepository`
- [x] Implement `transactionProvider` with month/wallet filtering
- [ ] ⚠️ **Unit test:** Add expense → wallet balance decreases by exact amount
- [ ] ⚠️ **Unit test:** Transfer creates balanced ledger (source decreases, target increases by same amount)
- [ ] ⚠️ **Unit test:** Transfer does NOT appear in income or expense analytics sums

### 1.4 — Goals & Budgets Data Layer

- [x] Implement `GoalDao` + `GoalContributionDao` (combined in GoalDao)
- [x] Implement `BudgetDao` (compute spent vs limit from Transactions stream per month/category)
- [x] Implement `GoalRepository` + `BudgetRepository`
- [x] Implement `goalProvider` + `budgetProvider`
- [ ] ⚠️ **Unit test:** Goal contribution updates `currentAmount` correctly
- [ ] ⚠️ **Unit test:** Budget progress computes correct percentage

### 1.5 — Recurring & Bills Data Layer

- [x] Implement `RecurringRuleDao` + `BillDao`
- [x] Implement `RecurringRuleRepository` + `BillRepository`
- [x] Implement `RecurringScheduler` service: on every app open, check rules with `nextDueDate <= today`
- [x] Auto-log flow: if `autoLog = true`, create Transaction + schedule next due date
- [ ] Remind flow: if `autoLog = false`, create local notification (Phase 3)
- [ ] ⚠️ **Unit test:** RecurringScheduler correctly identifies and processes due rules

### ✅ PHASE 1 — Data Layer Verification Gate

- [x] Domain entities: pure Dart, zero Flutter/Drift imports (9 entities)
- [x] Repository interfaces + implementations for all 8 domains
- [x] Riverpod providers wired: DB → DAOs → repositories → feature streams
- [x] RecurringScheduler wired into main.dart via ProviderContainer
- [x] `flutter analyze` — zero warnings (verified 2026-02-27)
- [ ] All DAOs: CRUD round-trip tests (deferred to P4 polish phase)
- [ ] MoneyFormatter: 10+ edge cases (deferred to P4 polish phase)

---

## PHASE 2 — Core Features (MVP — Minimum Shippable)

### 2.0 — Phase 2 Components (Build fully now)

> **Build each component fully when its feature first needs it.**

- [x] `inputs/amount_input.dart` — **FULL** (`TextFormField` + `currency_text_input_formatter` with native keyboard, supports `compact: true` mode)
- [x] `inputs/app_date_picker.dart` — **FULL** (needed for Add Transaction)
- [x] `inputs/app_search_bar.dart` — **FULL** (needed for Transaction List)
- [x] `cards/balance_card.dart` — **FULL** (hero balance, count-up animation, hide toggle, trend indicator)
- [x] `cards/transaction_card.dart` — **FULL** (swipeable, source badge, amount color, semantic labels)
- [x] `cards/budget_progress_card.dart` — **FULL** (animated fill, green/yellow/red states)
- [x] `cards/goal_progress_card.dart` — **FULL** (radial ring, keyword chips, completion badge)
- [x] `cards/stat_card.dart` — **FULL** (income/expense summary card for dashboard)
- [x] `lists/transaction_list_section.dart` — **FULL** (grouped by date, sticky headers)
- [x] `lists/empty_state.dart` — **FULL** (Lottie + title + subtitle + optional CTA, per §7.5)
- [x] `dialogs/app_bottom_sheet.dart` — **FULL** (for filter sheets, confirmation)
- [x] `dialogs/confirm_dialog.dart` — **FULL** (needed for delete actions)
- [x] `feedback/lottie_widget.dart` — **FULL** (reusable Lottie wrapper)
- [x] **Rule:** Every component must compile, render in light + dark + RTL, have semantic labels
- [ ] ⚠️ **Widget test:** Balance card renders correct amount, hides on toggle
- [ ] ⚠️ **Widget test:** Transaction card shows correct color (green/red/blue) by type
- [ ] ⚠️ **Widget test:** Empty state renders Lottie + text + button

### 2.1 — Splash + Onboarding

- [x] `SplashScreen`: Brand logo + subtle fade animation (1.5s) → auto-navigate
  - [x] If first launch → Onboarding
  - [x] If returning + PIN set → PIN Entry
  - [x] If returning + no PIN → Dashboard
- [x] `OnboardingScreen`: **2 pages** (NOT 3):
  - [x] **Page 1:** Welcome + tagline + hero illustration + "Get Started" button
  - [x] **Page 2 is ONE optional field only:** "What's your starting cash balance?" → single AmountInput (defaults to 0, currency auto EGP). "Start Tracking" button. Wallet name auto = "Cash", type auto = Cash. User can customize later in Settings → Wallets.
- [x] Skip behavior: If user skips Page 2 OR enters 0 → auto-create default "Cash" wallet, 0 balance, EGP
- [x] Save `onboarding_complete = true` → never show again
- [ ] ⚠️ **Widget test:** Onboarding renders, skip creates default wallet

### 2.2 — Wallets Module UI

- [x] `WalletsScreen`: clean list of wallet cards (not grid — list is more readable), live balance per wallet
- [x] `AddEditWalletScreen`: name, type dropdown, color picker, icon picker, initial balance
- [x] `WalletDetailScreen`: wallet info header + filterable transaction list for that wallet
- [x] **Transfer button on WalletDetailScreen** or WalletsScreen
- [x] `TransferScreen`: from-wallet, to-wallet, amount, note → Transfer record → update both balances
- [x] Delete wallet: only if no transactions exist, else show warning dialog
- [ ] ⚠️ **Widget test:** AddWallet form validation

### 2.3 — Categories Module UI

- [x] `CategoriesScreen`: sections for Income and Expense, icon grid with color accents
- [x] `AddEditCategoryScreen`: name-EN, name-AR, icon picker, color picker, type selector
- [x] Delete: protect default categories from deletion
- [ ] ⚠️ **Widget test:** Category creation validation

### 2.4 — Add Transaction (Manual) — THE CORE SCREEN

- [x] **FAB taps → opens `AddTransactionScreen` directly** with Expense preselected (the 80% case)
- [x] `AddTransactionScreen`:
  - [x] Type toggle at top: Expense / Income (NO Transfer here — Transfer is in Wallets)
  - [x] `AmountInput` with native keyboard via `currency_text_input_formatter`
  - [x] Amount display with MoneyFormatter in real-time
  - [x] **Category picker shows top 6 most-used categories as chips first.** Tap any chip = instant select. "All Categories" button expands full searchable grid below. First-time users see 6 default favorites.
  - [x] Wallet picker (chip row or dropdown)
  - [x] Date + time picker (defaults to now)
  - [x] Note field (optional, collapsed by default)
  - [x] Tags field (optional, collapsed by default, chip input)
  - [x] Validation: amount > 0, category required, wallet required
- [x] On save: update wallet balance atomically inside Drift transaction
- [x] After save: run `GoalKeywordMatcher.match(transaction)` → show SnackBar if match found
- [x] On save: trigger success haptic (`HapticFeedback.mediumImpact()`) + brief Lottie success
- [ ] ⚠️ **Unit test:** Add expense → wallet.balance decreases by exact amount in piastres
- [ ] ⚠️ **Widget test:** Full form validation and save flow

### 2.5 — Transaction List

- [x] `TransactionListScreen`: grouped by date with sticky date headers
- [x] Income rows: green amount. Expense rows: red amount.
- [x] Source badge: small icon if `source = 'voice'` or `'sms'` or `'notification'`
- [x] Search bar (top, collapsible): full-text across title + note
- [x] Filter bottom sheet: wallet, category, type, date range
- [x] `flutter_slidable`: swipe left → delete with 5s undo snackbar
- [x] Swipe right → opens edit screen
- [x] **Loading state:** Shimmer skeleton matching transaction list layout
- [x] **Empty state:** Lottie + "No transactions yet" + "Tap + to add" CTA
- [x] `TransactionDetailScreen`: all fields, receipt image viewer, location chip, raw transcript, edit button
- [ ] ⚠️ **Widget test:** List renders with data, empty state renders without

### 2.6 — Dashboard

- [x] `DashboardScreen`: implement layout from AGENTS.md §7.6:
  - [x] **Zone 1 — Hero Balance Card:** Net balance (32sp bold, count-up animation), Income ↑ / Expense ↓ summary line, trend indicator vs last month
  - [x] **Zone 2 — Quick Actions:** THREE buttons in Wrap: [+Expense] [+Income] [Transfer]. Each uses `FilledButton.tonalIcon` with semantic color. (Voice moved to FAB radial menu.)
  - [x] **Zone 3 — Recent Transactions:** Last 5 transactions grouped by date, "See All" → Transaction List
  - [x] **Zone 4 — Spending Overview (below fold):** Donut chart (top 5 categories + "Other"), tap category → filtered transaction list
  - [x] **Zone 5 — Budget Alerts (below fold, conditional):** Only shown if user has budgets set. Max 3 budget cards. "Manage Budgets →" link.
  - [x] **Zone 6 — Smart Insights (below fold):** Top 2 insight cards with CTA, dismiss, "See All →" link.
- [x] 32dp vertical gap between zones (use `AppSizes.xl`)
- [x] **FAB center-docked with expandable radial menu:** Tap → AddTransaction (expense). Long press → 3 bubbles: Expense (top-left), Mic (center-top), Income (top-right). Swipe to select. RTL-aware.
- [x] `DashboardProvider`: all data from reactive Drift streams
- [x] **Loading state:** Full shimmer skeleton matching dashboard layout
- [x] **Empty state (first use):** Welcome message + "Add your first transaction" CTA
- [ ] ⚠️ **Widget test:** Dashboard renders with mock data, zones have correct gaps

### 2.7 — Budgets

- [x] `BudgetsScreen`: current month's category budgets, animated progress bars, sorted by % used descending
- [x] `SetBudgetScreen`: category selector, amount input (AmountInput widget), rollover toggle
- [x] Progress bar: green (0–70%) → amber (70–90%) → red (90–100%+) — animated fill on screen enter (600ms)
- [ ] Local notification when budget reaches 80% and 100%
- [x] `BudgetProvider`: compute spent vs limit per category per month from Transactions stream
- [x] **Empty state:** "No budgets set yet" + "Set Your First Budget" CTA
- [ ] ⚠️ **Unit test:** Budget percent calculation edge cases (zero, overspent)

### 2.8 — Savings Goals

- [x] `GoalsScreen`: goal cards with animated progress rings
- [x] `AddEditGoalScreen`: name, target amount, deadline (optional), icon picker, color picker, keywords chip input
- [x] `GoalDetailScreen`: progress ring, contribution history, linked transactions, "Contribute" button, keywords section
- [x] `ContributeToGoalSheet`: amount input → creates `GoalContribution` + updates `currentAmount`
- [x] At 100%: trigger Lottie celebration + haptic success
- [x] Mark completed: `isCompleted = true`, shows completion summary
- [x] **Empty state:** "No goals yet" + "Set your first savings goal" CTA
- [ ] ⚠️ **Unit test:** `GoalKeywordMatcher.match()` with Arabic + English + diacritics stripped

### 2.9 — Settings (Core)

- [x] `SettingsScreen`: grouped section list (General, Security, Data, About)
- [x] Currency selector: searchable list → saves to shared_preferences → MoneyFormatter updates
- [x] Language selector: English / Arabic → triggers locale change immediately
- [x] Theme toggle: Light / Dark / System
- [x] First day of week: Saturday (default) / Sunday / Monday
- [x] First day of month: 1st through 28th (for budget cycle)
- [x] Clear all data: two-step confirmation with "Type DELETE" safety gate

### ✅ PHASE 2 — Design Review Gate

- [x] Screenshot EVERY screen in: light mode, dark mode, Arabic RTL
- [x] Verify 24dp section gaps on dashboard
- [x] Verify no screen has more than 3 *accent/semantic* colors in any section
- [x] Verify all empty states have Lottie + title + subtitle + CTA
- [x] Verify shimmer skeletons match actual content layout on every screen
- [x] Verify FAB position is correct in both LTR and RTL
- [x] All interactive elements ≥ 48dp tap target
- [x] Test on 360dp width device (small phone) — no overflow, no clipping
- [x] Test on 412dp width device (standard phone)
- [ ] **RECOMMENDED (non-blocking):** Show the app to 2-3 people. Watch them add a transaction and check a budget. Note confusion points. Fix critical issues if found.

---

## PHASE 3 — Smart Input + Reports + Recurring

### 3.1 — Recurring Transactions UI

- [x] `RecurringScreen`: list of rules with toggle switch, next due date chip
- [x] `AddEditRecurringScreen`: title, amount, type, category, wallet, frequency, start date, autoLog toggle
- [x] `RecurringScheduler` called in `main.dart` on every cold start
- [x] Auto-log: creates transaction + notification "Auto-logged: [title]"
- [x] Remind: scheduled notification with action "Log Now"
- [x] Edit and pause/cancel rules

### 3.2 — Bill Tracker UI

- [x] `BillsScreen`: upcoming bills sorted by due date, overdue in red at top
- [x] `AddEditBillScreen`: name, amount, wallet, category, due date
- [x] Mark as paid → creates linked expense transaction → moves to paid section
- [ ] Local notifications: 3 days before, 1 day before, on due date

### 3.3 — Voice Input ⚠️

- [x] **Voice is Dashboard Quick Action** — taps `VoiceInputSheet.show(context)`. First tap → permission rationale. After granted → voice bottom sheet.
- [x] Create `VoiceInputSheet` (bottom sheet) with `avatar_glow` pulsing mic:
  - [x] Tap-to-start / tap-to-stop interaction (NOT hold-to-record)
  - [x] Live transcript text updating as user speaks
  - [x] Loading indicator while parser processes
- [x] `VoiceInputService`: wraps `speech_to_text`, any device locale (Arabic gate removed in P4)
- [x] `VoiceTransactionParser`:
  - [x] `ArabicNumberParser`: spoken Egyptian numbers to integer piastres
  - [x] Expense / income keyword detection
  - [x] Time keyword → date offset mapping
  - [x] Category keyword → categoryId mapping
  - [x] Multi-transaction split on conjunction keywords
  - [x] Returns `List<ParsedTransactionDraft>`
- [x] `EgyptianDialectDictionary`: loads `assets/dictionaries/egyptian_arabic_finance.json`
- [x] `VoiceConfirmScreen`: editable card per parsed transaction
  - [x] Each card: title, amount (AmountInput compact mode), category picker, type toggle, date picker
  - [x] "Confirm All" → save all → run `GoalKeywordMatcher`
  - [x] Individual "Remove" per card
- [x] Request `RECORD_AUDIO` via `PermissionHelper` with rationale BEFORE first use
- [x] If denied: show inline message, never crash
- [x] AI voice parsing: multi-model fallback chain (Gemini Flash → Gemma 3 27B → Qwen3 4B)
- [x] ZDR (Zero Data Retention) enforced on all OpenRouter API requests
- [x] Settings: AI Model picker (Auto / individual model selection)
- [ ] ⚠️ **Unit tests (minimum 15 Egyptian Arabic sentences)**

### 3.4 — Location Tagging ⚠️

- [x] Collapsed "Location" section in `AddTransactionScreen`
- [x] Manual text input OR "Detect My Location" button
- [x] Permission rationale → `Geolocator` → reverse geocode → pre-fill
- [x] Location NEVER blocks saving
- [ ] ⚠️ **Test:** Location section works when permission denied

### 3.5 — Notification Parser ⚠️

- [x] `NotificationTransactionParser` with Egyptian bank regex patterns
- [x] `notification_listener_service` setup with allowlisted apps
- [x] `pendingTransactionsProvider`: list of pending parsed candidates
- [x] `SmsReviewScreen`: pending items with Approve / Skip / Edit
- [x] Persistent notification badge if pending items exist
- [x] Duplicate detection via SHA-256 hash
- [x] Settings: enable/disable toggle, app allowlist management
- [x] AI enrichment at ingestion (Qwen3 4B — category, merchant, note via OpenRouter)
- [x] Review screen shows AI-suggested category icon + merchant name
- [x] Approve uses AI-matched category (not hardcoded default)
- [ ] ⚠️ **Unit tests (10+ Egyptian financial message samples)**

### 3.6 — SMS Parser ⚠️ (ENABLED — Owner Approved)

- [x] `SmsTransactionParser` reusing notification parser regex
- [x] `SmsParserService` reading inbox via `another_telephony`
- [x] `const bool kSmsEnabled = true;` feature flag — ENABLED
- [x] Settings toggle for SMS parser (permission flow + scan on enable)
- [x] SMS scan wired into `main.dart` cold start
- [x] AI enrichment at ingestion (Qwen3 4B — category, merchant, note via OpenRouter)
- [ ] ⚠️ **IMPORTANT:** Submit SMS/Call Log permission declaration to Google Play before publishing

### 3.7 — Goal Keyword Matching

- [x] `GoalKeywordMatcher`: normalize + match transaction title against goal keywords
- [x] SnackBar with [Link] [Dismiss] on match
- [x] Called after EVERY transaction save (all sources)
- [ ] ⚠️ **Unit test:** Arabic diacritics stripped correctly

### 3.8 — Cashflow Calendar

- [x] `CalendarScreen` using `table_calendar`
- [x] Color-coded event dots: green = income day, red = expense day, both = split
- [x] Tap day → bottom sheet with that day's transactions
- [x] Today highlighted with brand primary ring

### 3.9 — Analytics & Reports

- [x] `ReportsScreen`: tabs (Overview / Categories / Trends / Comparison)
  - [x] Overview: income vs expense bar chart (last 6 months)
  - [x] Categories: **horizontal bar chart** (not donut — more readable) + ranked list
  - [x] Trends: line chart with 7d/30d/90d toggle
  - [x] Comparison: this month vs last month side-by-side bars with touch tooltips
- [x] Charts have `BarTouchData(enabled: true)` / `PieTouchData` with tooltips + period selectors
- [ ] Filter bar: wallet selector + date range picker
- [ ] Export button: PDF via `pdf` package → share via `share_plus`
- [ ] ⚠️ **Unit test:** Analytics edge cases (month boundary, zero data, transfers excluded)

### 3.10 — Net Worth

- [x] `NetWorthScreen`: net worth = non-credit wallets − credit card wallets
- [x] Large number with assets/liabilities breakdown
- [ ] Historical monthly snapshots line chart

### 3.11 — Smart Insights

- [x] `InsightsScreen`: scrollable insight cards with CTA buttons and onDismiss
- [x] Build `cards/insight_card.dart` — distinct icons per insight type, CTA button, dismiss
- [x] `InsightEngine` (pure Dart, no internet):
  - [x] Category overspend alert
  - [x] Budget forecast
  - [x] Top spending day
  - [x] Monthly savings comparison
- [x] **Dashboard Zone 6:** Top 2 insights as dismissible cards with "See All →" link to InsightsScreen

### ✅ PHASE 3 — Design Review Gate

- [x] Voice input flow: smooth animation, clear states, works when permission denied
- [x] Notification parser review screen: clear approve/skip affordances
- [x] Calendar: readable dots, smooth navigation
- [x] Charts: accessible colors, text fallbacks near every chart, max 6 segments on donut
- [x] Recurring/Bills screens: dark mode + RTL + empty states verified
- [x] All new screens: dark mode + RTL + empty state + loading state verified
- [x] Test on 360dp width device — charts don't overflow

---

## PHASE 4 — Security, Polish & Launch Prep

### 4.1 — Security

- [x] `PinSetupScreen`: 6-dot PIN entry + confirm → SHA-256 hash → `flutter_secure_storage`
- [x] `PinEntryScreen`: 6-dot keypad, shake on wrong PIN, biometric prompt option
- [x] `BiometricService` using `local_auth`, fallback to PIN
- [x] Auto-lock on `AppLifecycleState.paused`, configurable timeout
- [x] Hide balances: eye icon on dashboard → blur all amounts
- [x] Change PIN flow in Settings
- [ ] ⚠️ **Unit test:** PIN hash verification, wrong PIN rejection

### 4.2 — Backup & Export

- [x] `BackupService`: serialize all DB tables to JSON with schema version
- [x] `RestoreService`: validate schema, wipe DB, re-insert
- [x] CSV export with proper columns
- [x] PDF report: monthly summary
- [x] All exports via `share_plus`
- [x] `BackupRestoreScreen`: export JSON, CSV, PDF, restore, clear data
- [ ] ⚠️ **Integration test:** Full backup → clear → restore → verify data fidelity

### 4.3 — Android Home Screen Widget

- [ ] Small widget (2×1): "Today: [spent] | Balance: [total]"
- [ ] Medium widget (4×2): top 3 wallet balances
- [ ] Update widget data after every transaction save

### 4.4 — Microinteractions Polish

- [ ] Balance: count-up animation on value change (600ms easeOutCubic)
- [ ] Budget progress bars: animated fill on screen enter (600ms)
- [ ] Goal rings: animated arc fill (600ms easeInOut)
- [ ] Transaction save: brief Lottie checkmark
- [ ] Goal completed: Lottie confetti (play once, full-screen overlay)
- [ ] Delete swipe: red background with trash icon
- [ ] List items: staggered fade-in + slide-up (50ms stagger, 400ms per item)
- [ ] Empty states: Lottie specific to each feature
- [ ] Page transitions: shared axis or fade-through (300ms, configured in go_router)
- [ ] Haptic feedback: `HapticFeedback.mediumImpact()` on save, delete, tab switch

### 4.5 — Onboarding Polish

- [ ] Final Lottie animations (replace placeholders)
- [ ] Smooth page indicator animation
- [ ] Validate wallet is created before allowing home navigation

### 4.6 — Notification Settings

- [ ] `NotificationPreferencesScreen`: per-type toggles
  - [ ] Budget warnings (80%, 100%)
  - [ ] Bill reminders
  - [ ] Recurring transaction reminders
  - [ ] Goal milestone celebrations
  - [ ] Daily logging reminder (configurable time)
  - [ ] Quiet hours setting

### 4.7 — Crash Reporting Setup (Offline-Compatible — NO Firebase)

> Rule #1 says "No Firebase in v1." Crash reporting uses local logging + Play Console's built-in Android Vitals (no SDK needed).

- [x] Set up `FlutterError.onError` in `main.dart` → log to local crash log file
- [x] Set up `PlatformDispatcher.instance.onError` for async errors → same local log
- [x] Create `lib/core/services/crash_log_service.dart` → writes crash stack traces + device info to local file (`app_crash_log.txt` in app directory)
- [x] Cap local crash log at 500KB (rotate oldest entries)
- [x] Verify NO PII is logged (no balances, names, or transaction data)
- [x] Include crash log in backup JSON export (so user can share with developer if reporting a bug)
- [x] Rely on Play Console → Android Vitals for production crash monitoring (automatic, no SDK)
- [ ] Test: force a crash → verify local log captures the stack trace correctly

### 4.7b — Visual Refresh: Bug Fixes & Design Overhaul

- [x] Add `stylish_bottom_bar: ^1.1.1` and `phosphor_flutter: ^2.1.0` to pubspec.yaml
- [x] **Voice input fix:** Remove Arabic locale gate — mic works on any device language, AI parser handles multi-language
- [x] Remove `_showArabicInstallGuide()` and unused l10n keys (`voice_arabic_required_title`, `voice_arabic_required_body`, `voice_arabic_not_installed`)
- [x] **SMS/notification crash fix:** Wrap `_toggleNotificationParser()` and `_toggleSmsParser()` in try-catch with mounted checks and toggle reversion on failure
- [x] Add try-catch and diagnostic logging in `notification_listener_wrapper.dart:start()`
- [x] **Theme refresh:** Replace Indigo+Teal palette with Minty Fresh (light: `#3DA37A` primary) + Gothic Noir (dark: `#7B68AE` primary)
- [x] Update `app_colors.dart`, `app_theme.dart` with new FlexColorScheme configurations
- [x] **Icon migration:** Replace all Material Icons with Phosphor Icons (111 icons) in `app_icons.dart`
- [x] **Bottom bar replacement:** Replace `NavigationBar` with `StylishBottomBar` (liquid animation, FAB notch support)
- [x] Add `extendBody: true` on Scaffold for notch transparency
- [x] Change `AppScaffoldShell` to `ConsumerStatefulWidget` with `WidgetsBindingObserver`
- [x] **Lifecycle observer:** Re-check notification listener permission on `AppLifecycleState.resumed`
- [x] **Radial menu fix:** Increase bubble opacity from 0.15 to 0.85, add text label chips below each bubble
- [x] Add dark scrim overlay (black @ 0.3) behind expanded radial menu
- [x] White icon color on colored bubble background for contrast
- [x] Run `build_runner` + `flutter analyze` — zero issues

### 4.8 — Accessibility Pass

- [ ] Enable TalkBack on physical device → navigate every screen
- [ ] Verify all interactive elements have `Semantics` labels
- [ ] Verify all amounts are announced correctly by screen reader
- [ ] Test with system text size at 200% — no overflow, no clipping
- [ ] Test with system "Reduce Motion" enabled — animations respect the setting
- [ ] Run Flutter `Accessibility Inspector` on all screens

### 4.9 — Performance & Quality Pass

- [ ] `flutter analyze` — zero warnings, zero errors
- [ ] `flutter test` — all tests pass
- [ ] Profile: transaction list scroll at 60fps with 500+ transactions (standard device)
- [ ] Profile: transaction list scroll at 60fps with 500+ transactions (2GB RAM device)
- [ ] Stress test: 1000+ transactions, no UI jank
- [ ] Full RTL pass: every screen in Arabic locale
- [ ] Full dark mode pass: every screen
- [ ] Airplane mode test: 100% offline functionality verified
- [ ] **Device matrix:** Test on 5" (360dp), 6.1" (412dp), 6.7" (430dp) screen widths
- [ ] **API matrix:** Test on API 24, 28, 30, 34 emulators
- [ ] **APK size check:** Release APK < 25MB

### 4.10 — Play Store Release Prep

- [ ] Generate adaptive launcher icons via `flutter_launcher_icons`
- [ ] Configure splash screen via `flutter_native_splash`
- [ ] Confirm `applicationId = "com.masarify.app"`
- [ ] Confirm version `1.0.0+1`
- [ ] Configure ProGuard/R8 rules
- [ ] **Verify ProGuard:** Build release → install → full smoke test (ProGuard can strip needed classes)
- [ ] Verify `kSmsEnabled = true` — submit SMS permission declaration form to Google Play
- [ ] Verify `kMonetizationEnabled = false`
- [ ] Verify `AiConfig.isEnabled = true` — AI voice parsing via OpenRouter (fallback to rule-based when no key)
- [ ] Build: `flutter build appbundle --release`
- [ ] Install release APK on physical device — full smoke test
- [ ] Write Play Store listing: EN + AR descriptions
- [ ] Prepare 6 screenshots in EN + AR
- [ ] Write Data Safety section (declare notifications, location, microphone)
- [ ] Prepare privacy policy URL
- [ ] ⚠️ **Final:** Zero hardcoded colors, icons, or spacing in `lib/features/`

### ✅ PHASE 4 — Pre-Launch Design Review Gate

- [ ] Every screen screenshotted in: light + dark + RTL
- [ ] Every screen has proper loading, empty, and error states
- [ ] TalkBack navigation works on all screens
- [ ] Font scaling at 200% doesn't break layout
- [ ] **RECOMMENDED (non-blocking):** 3-5 person usability test on release build. Note confusion points. Fix critical issues.
- [ ] APK size < 25MB
- [ ] Cold start < 2s on physical device

---

## PHASE 5 — AI, Monetization & Advanced

*Implement AFTER a stable v1 is released. Do NOT implement during v1 development.*

### 5.1 — AI Integration Scaffold (AGENTS.md §21)

- [ ] Create AI config, interfaces, NullAiService, providers
- [ ] Integrate as optional enhancement to InsightEngine
- [ ] Create skeleton offline + Gemini services
- [ ] ⚠️ **Unit test:** NullAiService returns null/empty without throwing

### 5.2 — Monetization Infrastructure (AGENTS.md §22)

- [ ] EntitlementService abstraction + RevenueCat scaffold
- [ ] Paywall screen with 3 plans (prices from RevenueCat, not hardcoded)
- [ ] Pro feature gating via `hasProProvider`
- [ ] Test with Google Play test accounts
- [ ] Set `kMonetizationEnabled = true` only after full testing

### 5.3 — Remaining Component Implementations

- [ ] Build `PermissionRationale` dialog fully
- [ ] Build `ProFeatureDialog` fully
- [ ] Build `ProBadge` chip
- [ ] ⚠️ **Widget test:** Every component in light + dark + RTL

---

## Cross-Cutting Responsibilities (Ongoing)

- [ ] After EVERY Drift schema change: run `build_runner` + update migration
- [ ] After EVERY new screen: test in dark mode + Arabic RTL + verify spacing
- [ ] After EVERY new string: add to BOTH `app_en.arb` AND `app_ar.arb`
- [ ] After EVERY permission-gated feature: verify app works WITHOUT that permission
- [ ] After EVERY new widget: verify NO hardcoded colors, icons, or spacing
- [ ] After EVERY new widget: add `Semantics` labels for screen readers
- [ ] After EVERY new widget: verify 48dp minimum tap targets
- [ ] After EVERY new chart: add text fallback alongside visual
- [ ] Keep `TASKS.md` up to date — `[/]` in-progress, `[x]` done
- [ ] Run localization parity check periodically (EN keys == AR keys)

---

## Release Gating Checklist (All Must Pass Before Play Submission)

- [ ] Manual core tracking works fully offline (airplane mode verified)
- [ ] Transfers excluded from income/expense totals in all analytics
- [ ] Budgets/analytics calculations verified accurate
- [ ] Voice parser works with 10+ Egyptian phrases including slang
- [ ] Notification parser works for supported Egyptian apps
- [ ] SMS parser `kSmsEnabled = true` — Play Store SMS declaration submitted
- [ ] `kMonetizationEnabled = false` confirmed
- [ ] `AiConfig.isEnabled = true` — AI voice parsing works with API key, falls back without
- [ ] Permission-denied flows do not crash (all 4 permissions)
- [ ] Dark mode visual audit complete
- [ ] Arabic RTL visual audit complete
- [ ] TalkBack accessibility audit complete
- [ ] Font scaling 200% audit complete
- [ ] Backup/restore tested on physical device
- [ ] `flutter analyze` — zero issues
- [ ] `flutter test` — all pass
- [ ] Release APK < 25MB
- [ ] Cold start < 2s on physical device
- [ ] No fintech/bank-linking wording anywhere
- [ ] Play Store Data Safety matches actual permissions
- [ ] Privacy policy URL live
- [ ] Zero hardcoded colors/icons/spacing in `lib/features/`
- [ ] Local crash logging verified (force crash → check log file)
- [ ] Play Console Android Vitals enabled for the app
