# AGENTS.md — Masarify

# ⚠️ READ THIS ENTIRE FILE BEFORE WRITING A SINGLE LINE OF CODE ⚠️

**Personal Money Tracker · Offline-First · Flutter · Android (iOS Later)**
Version 1.2 | February 2026

---

## 1. Project Identity

| Field              | Value                                                            |
|--------------------|------------------------------------------------------------------|
| **App Name**       | Masarify (مصاريفي)                                               |
| **Tagline**        | سيطر على فلوسك — Track Every Pound. Own Your Money.             |
| **App Type**       | Offline-first personal money tracking & management app           |
| **Package Name**   | `com.masarify.app`                                               |
| **Platform**       | Android (Google Play) FIRST → iOS SECOND (same codebase)        |
| **Framework**      | Flutter (Dart) — latest stable channel                           |
| **Min Android SDK**| API 24 (Android 7.0)                                            |
| **Architecture**   | Clean Architecture — Feature-first folder structure              |
| **State Mgmt**     | Riverpod 2.x (`flutter_riverpod` + `riverpod_annotation`)        |
| **Local DB**       | Drift + `drift_flutter` (type-safe, reactive SQLite ORM)         |
| **Navigation**     | `go_router` — all routes are declared, no `Navigator.push()`     |
| **Design**         | Material Design 3 — Minty Fresh (light) + Gothic Noir (dark) themes, Phosphor Icons, StylishBottomBar with FAB notch |

---

## 2. Non-Negotiable Rules (Agent Must Follow at All Times)

1. **100% Offline-First.** All data stored locally via Drift (SQLite). No internet required for any core feature. No Firebase, Supabase, or any external data dependency in v1. Backup/restore uses local JSON files only.

2. **NOT a Fintech App.** No bank connections. No payment processing. No real money movement. No storing bank credentials, card numbers, or payment tokens — EVER.

3. **RTL-First.** Arabic (ar-EG) is a primary language. Every widget and screen MUST be validated in RTL mode. Use `Directionality.of(context)` where needed. Test every screen with Arabic locale.

4. **Monetary Precision — Integer Only.** ALL amounts are stored as `INTEGER` (piastres). NEVER use `double` or `float` for money storage. Rule: `100.50 EGP → stored as 10050`. Divide by 100.0 for display only. Use `MoneyFormatter` class exclusively.

5. **No Hardcoded Strings.** Every user-facing string goes through `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb`. Both files must stay in sync — add to EN, immediately add to AR.

6. **Permissions = Explanation First.** Before requesting `RECORD_AUDIO`, `READ_SMS`, `ACCESS_FINE_LOCATION`, or notification listener access, show an in-app rationale dialog explaining the benefit and offering "Maybe Later". All three permission-gated features (Voice, Location, SMS/Notifications) are OPTIONAL — the app must work 100% without any of them.

7. **Smart Features Require User Review.** Voice-parsed and SMS/notification-parsed transactions MUST pass through a review screen before being committed to the database. NEVER auto-save without explicit user confirmation.

8. **Transfers Are Not Income/Expense.** Wallet-to-wallet transfers must NEVER inflate income or expense analytics. They are tracked separately in the `Transfers` table.

9. **Migrations Must Be Versioned.** Every Drift schema change requires a proper migration in `AppDatabase.migration`. Never break the migration chain. Always run `build_runner` after any schema change.

10. **Definition of Done for Every Task:** Feature works end-to-end, errors/empty states handled, basic tests added, code formatted & linted, no debug leftovers.

11. **UI Must Breathe.** Never cram more than 3–4 content zones on a single screen viewport. Use scroll and progressive disclosure. Generous whitespace between sections (min 24dp between zones). See §7.5 for layout rules.

---

## 3. Tech Stack & Package Manifest

### Core Dependencies

```yaml
name: masarify
description: Offline-first personal money tracking app for Egyptian and MENA users.
version: 1.0.0+1

environment:
  sdk: '>=3.3.0 <4.0.0'
  flutter: '>=3.22.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # ── Database ─────────────────────────────────────────────────────────────────
  drift: ^2.20.0
  drift_flutter: ^0.2.1
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.4
  path: ^1.9.0

  # ── State Management ─────────────────────────────────────────────────────────
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1

  # ── Immutable Models ─────────────────────────────────────────────────────────
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0

  # ── Navigation ───────────────────────────────────────────────────────────────
  go_router: ^14.3.0

  # ── UI & Animations ──────────────────────────────────────────────────────────
  flutter_animate: ^4.5.0
  lottie: ^3.1.2
  shimmer: ^3.0.0
  flex_color_scheme: ^8.4.0
  google_fonts: ^6.2.1
  smooth_page_indicator: ^1.2.0
  flutter_slidable: ^3.1.1
  modal_bottom_sheet: ^3.0.0
  avatar_glow: ^3.0.1                  # Pulsing glow effect for VoiceInputSheet mic
  animations: ^2.1.1
  phosphor_flutter: ^2.1.0               # Phosphor icon family (replaces Material Icons)
  # NOTE: Haptic feedback uses Flutter's built-in HapticFeedback from services.dart
  # No external package needed. See §14 for usage.

  # ── Reactive Streams ──────────────────────────────────────────────────────────
  rxdart: ^0.28.0                        # Rx.combineLatest2 for budget repo reactive streams

  # ── Charts ───────────────────────────────────────────────────────────────────
  fl_chart: ^0.69.0

  # ── Localization & Formatting ─────────────────────────────────────────────────
  intl: ^0.20.0

  # ── Notifications ────────────────────────────────────────────────────────────
  flutter_local_notifications: ^17.2.3
  timezone: ^0.9.4

  # ── Calendar ─────────────────────────────────────────────────────────────────
  table_calendar: ^3.1.2

  # ── Image (receipt photos) ───────────────────────────────────────────────────
  image_picker: ^1.1.2

  # ── Security ─────────────────────────────────────────────────────────────────
  local_auth: ^2.3.0
  flutter_secure_storage: ^9.2.2

  # ── Export ───────────────────────────────────────────────────────────────────
  pdf: ^3.11.1
  share_plus: ^10.0.0
  csv: ^6.0.0
  file_picker: ^8.1.2

  # ── Utilities ────────────────────────────────────────────────────────────────
  uuid: ^4.4.2
  equatable: ^2.0.5
  collection: ^1.18.0
  shared_preferences: ^2.3.2
  connectivity_plus: ^6.1.0
  package_info_plus: ^8.1.0
  url_launcher: ^6.3.1

  # ── Home Screen Widget ───────────────────────────────────────────────────────
  home_widget: ^0.5.0

  # ── Permissions ──────────────────────────────────────────────────────────────
  permission_handler: ^11.3.1

  # ── Voice Input ──────────────────────────────────────────────────────────────
  speech_to_text: ^7.3.0          # Uses device's native STT (ar-EG locale)
  # NOTE: audio_waveforms removed — zero imports existed, dead dependency

  # ── Location ─────────────────────────────────────────────────────────────────
  geolocator: ^13.0.1
  geocoding: ^3.0.0

  # ── SMS & Notification Parser ─────────────────────────────────────────────────
  # NOTE: Direct SMS reading (READ_SMS) is enabled (owner-approved).
  # Submit SMS permission declaration to Google Play before publishing.
  # ⚠️ WARNING: `another_telephony` has low pub.dev popularity. If it becomes unmaintained,
  # consider `telephony` package or a custom platform channel as fallback.
  another_telephony: ^1.2.0                       # Android SMS inbox (feature-flagged)
  notification_listener_service: ^0.8.0           # Android NotificationListenerService

dev_dependencies:
  flutter_test:
    sdk: flutter
  drift_dev: ^2.20.0
  riverpod_generator: ^2.6.1
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  build_runner: ^2.4.12
  flutter_lints: ^4.0.0
  flutter_launcher_icons: ^0.14.1
  flutter_native_splash: ^2.4.1
```

---

## 4. Project Folder Structure

```
masarify/
├── AGENTS.md                              ← This file (SINGLE SOURCE OF TRUTH)
├── PRD.md                                 ← Product Requirements Document
├── TASKS.md                               ← Development task checklist
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart                          ← Entry point: ProviderScope + app init
│   ├── app/
│   │   ├── app.dart                       ← MaterialApp.router + theme + locale setup
│   │   ├── router/
│   │   │   └── app_router.dart            ← All go_router route definitions
│   │   └── theme/
│   │       ├── app_theme.dart             ← ThemeData (light + dark) via flex_color_scheme
│   │       ├── app_theme_extension.dart   ← AppThemeExtension custom semantic tokens (§19.2)
│   │       ├── app_colors.dart            ← Color tokens (brand palette)
│   │       └── app_text_styles.dart       ← Typography scale (Plus Jakarta Sans)
│   ├── core/
│   │   ├── config/
│   │   │   └── ai_config.dart             ← AiConfig: OpenRouter integration (isEnabled=true)
│   │   ├── constants/
│   │   │   ├── app_routes.dart            ← All route name string constants
│   │   │   ├── app_sizes.dart             ← Spacing / padding scale + icon sizes
│   │   │   ├── app_icons.dart             ← AppIcons — ALL icon constants (§19.3)
│   │   │   ├── app_navigation.dart        ← AppNavDest + AppNavigation.destinations (§19.4)
│   │   │   ├── egyptian_sms_patterns.dart ← Regex patterns for Egyptian bank/wallet SMS
│   │   │   └── voice_dictionary.dart      ← Egyptian Arabic lexicon (amounts, triggers)
│   │   ├── extensions/                    ← DateTime, num, String, BuildContext extensions
│   │   ├── utils/
│   │   │   ├── money_formatter.dart       ← MoneyFormatter — MANDATORY for all amounts
│   │   │   ├── date_utils.dart            ← Egyptian locale date formatting
│   │   │   ├── permission_helper.dart     ← permission_handler + rationale dialog wrapper
│   │   │   ├── voice_transaction_parser.dart ← Voice NLP pipeline
│   │   │   ├── goal_keyword_matcher.dart  ← Post-save goal keyword matching
│   │   │   └── error_handler.dart         ← Centralized error handler (§16)
│   │   ├── services/
│   │   │   ├── notification_service.dart  ← flutter_local_notifications wrapper
│   │   │   ├── recurring_scheduler.dart   ← Checks due recurring rules on app open
│   │   │   ├── backup_service.dart        ← Serialize/restore all DB tables as JSON
│   │   │   ├── entitlement_service.dart   ← EntitlementService abstraction (§22.3)
│   │   │   └── ai/
│   │   │       ├── ai_service_interface.dart  ← IAiService abstract class (§21.2)
│   │   │       ├── null_ai_service.dart       ← No-op default (safe fallback)
│   │   │       ├── openrouter_service.dart     ← OpenRouter HTTP client (ACTIVE)
│   │   │       ├── ai_voice_parser.dart        ← LLM voice transcript parser (ACTIVE)
│   │   │       ├── offline_ai_service.dart    ← On-device impl (tflite, future)
│   │   │       └── gemini_ai_service.dart     ← Gemini cloud impl (legacy stub)
│   │   └── widgets/                       ← (deprecated — use lib/shared/widgets/)
│   ├── data/
│   │   ├── database/
│   │   │   ├── app_database.dart          ← Drift AppDatabase class + migrations
│   │   │   ├── app_database.g.dart        ← Generated (do not edit)
│   │   │   └── tables/                    ← One file per Drift table
│   │   │       ├── wallets_table.dart
│   │   │       ├── categories_table.dart
│   │   │       ├── transactions_table.dart
│   │   │       ├── transfers_table.dart
│   │   │       ├── budgets_table.dart
│   │   │       ├── savings_goals_table.dart
│   │   │       ├── goal_contributions_table.dart
│   │   │       ├── recurring_rules_table.dart
│   │   │       ├── bills_table.dart
│   │   │       ├── sms_parser_logs_table.dart
│   │   │       └── exchange_rates_table.dart
│   │   ├── daos/                          ← One DAO per table
│   │   ├── repositories/                  ← Implementations of domain interfaces
│   │   ├── models/                        ← Freezed data models (fromJson/toJson)
│   │   └── seed/                          ← First-launch seed data (categories, wallet)
│   ├── domain/
│   │   ├── entities/                      ← Pure Dart entities (no Flutter/Drift imports)
│   │   ├── repositories/                  ← Abstract repository interfaces
│   │   └── usecases/                      ← Single-responsibility use cases
│   ├── features/
│   │   ├── onboarding/
│   │   ├── auth/                          ← PIN setup, PIN entry, biometric
│   │   ├── dashboard/
│   │   ├── transactions/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── transaction_list_screen.dart
│   │   │       │   ├── add_transaction_screen.dart
│   │   │       │   └── transaction_detail_screen.dart
│   │   │       └── widgets/
│   │   ├── voice_input/                   ← Voice capture, parser, review flow
│   │   │   ├── data/
│   │   │   │   └── parsers/
│   │   │   │       ├── arabic_number_parser.dart
│   │   │   │       ├── egyptian_dialect_dictionary.dart
│   │   │   │       ├── transaction_extractor.dart
│   │   │   │       └── category_classifier.dart
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── voice_confirmation_screen.dart
│   │   │       └── widgets/
│   │   │           └── voice_input_button.dart
│   │   ├── sms_parser/                    ← SMS + notification parsing feature
│   │   │   ├── data/
│   │   │   │   └── parsers/
│   │   │   │       ├── sms_transaction_parser.dart
│   │   │   │       ├── notification_transaction_parser.dart
│   │   │   │       └── egyptian_bank_patterns.dart
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── sms_review_screen.dart
│   │   ├── monetization/                  ← IAP/subscriptions — Phase 5 (kMonetizationEnabled=false)
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           ├── paywall_screen.dart        ← Subscription plan selection
│   │   │           └── subscription_screen.dart   ← Current plan + restore
│   │   ├── wallets/
│   │   ├── categories/
│   │   ├── budgets/
│   │   ├── goals/
│   │   ├── recurring/
│   │   ├── bills/
│   │   ├── reports/                       ← Analytics & charts
│   │   ├── calendar/                      ← Cashflow calendar
│   │   ├── insights/                      ← Smart insights engine
│   │   ├── net_worth/
│   │   ├── hub/                           ← "More" tab — hub screen linking to Goals, Budgets, Bills, etc.
│   │   ├── export/                        ← Backup, CSV, PDF, restore
│   │   └── settings/
│   ├── l10n/
│   │   ├── app_en.arb                     ← English strings (source of truth)
│   │   └── app_ar.arb                     ← Arabic translations (always in sync)
│   └── shared/
│       ├── widgets/                       ← MasarifyDS component library (§20.2)
│       │   ├── buttons/                   ← app_button, app_icon_button, app_fab
│       │   ├── inputs/                    ← app_text_field, amount_input, app_date_picker, app_search_bar
│       │   ├── cards/                     ← balance_card, transaction_card, budget/goal/insight/stat cards
│       │   ├── lists/                     ← transaction_list_section, empty_state
│       │   ├── dialogs/                   ← app_bottom_sheet, confirm_dialog, permission_rationale, pro_feature_dialog
│       │   ├── navigation/                ← app_nav_bar, app_app_bar
│       │   ├── feedback/                  ← shimmer_list, lottie_widget, snack_helper
│       │   └── pro/                       ← pro_badge
│       ├── models/                        ← Shared Freezed models
│       └── providers/                     ← Shared Riverpod providers (ai_provider, entitlement_provider)
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
└── assets/
    ├── animations/                        ← Lottie JSON files (sourced from LottieFiles.com, max 50KB each)
    │   ├── success.json
    │   ├── error.json
    │   ├── celebration.json
    │   ├── empty_transactions.json
    │   ├── empty_goals.json
    │   └── onboarding_*.json
    ├── icons/                             ← App icon source
    ├── images/                            ← Onboarding illustrations
    └── dictionaries/
        └── egyptian_arabic_finance.json   ← Egyptian dialect NLP dictionary
```

---

## 5. Database Schema (Drift Tables)

All tables are defined in `lib/data/database/app_database.dart` and individual table files.

```dart
// ── Wallets ───────────────────────────────────────────────────────────────────
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type => text()();         // 'cash' | 'bank' | 'mobile_wallet' | 'credit_card' | 'savings'
  IntColumn get balance => integer().withDefault(const Constant(0))(); // piastres (NEVER double)
  TextColumn get currencyCode => text().withLength(min: 3, max: 3).withDefault(const Constant('EGP'))();
  TextColumn get iconName => text().withDefault(const Constant('wallet'))();
  TextColumn get colorHex => text().withDefault(const Constant('#1A6B5E'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Categories ────────────────────────────────────────────────────────────────
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get nameAr => text()();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  TextColumn get type => text()();         // 'income' | 'expense' | 'both'
  TextColumn get groupType => text().nullable()(); // 'needs' | 'wants' | 'savings'
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
}

// ── Transactions ──────────────────────────────────────────────────────────────
// NOTE: Wallet-to-wallet transfers use the Transfers table below instead.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amount => integer()();     // always positive, in piastres
  TextColumn get type => text()();         // 'income' | 'expense'
  TextColumn get currencyCode => text().withLength(min: 3, max: 3).withDefault(const Constant('EGP'))();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get receiptImagePath => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))(); // comma-separated

  // Location (optional)
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get locationName => text().nullable()();

  // Source tracking — MANDATORY for non-manual entries
  TextColumn get source => text().withDefault(const Constant('manual'))();
  // Values: 'manual' | 'voice' | 'sms' | 'notification' | 'import'
  TextColumn get rawSourceText => text().nullable()(); // original SMS body or voice transcript

  // Recurring link
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  IntColumn get recurringRuleId => integer().nullable()();

  // Goal link
  IntColumn get goalId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Transfers (wallet-to-wallet — NEVER income/expense) ───────────────────────
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromWalletId => integer().references(Wallets, #id)();
  IntColumn get toWalletId => integer().references(Wallets, #id)();
  IntColumn get amount => integer()();     // piastres
  IntColumn get fee => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transferDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Budgets ───────────────────────────────────────────────────────────────────
class Budgets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get month => integer()();      // 1–12
  IntColumn get year => integer()();
  IntColumn get limitAmount => integer()(); // piastres
  BoolColumn get rollover => boolean().withDefault(const Constant(false))();
  IntColumn get rolloverAmount => integer().withDefault(const Constant(0))();
}

// ── Savings Goals ─────────────────────────────────────────────────────────────
class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  IntColumn get targetAmount => integer()(); // piastres
  IntColumn get currentAmount => integer().withDefault(const Constant(0))();
  TextColumn get currencyCode => text().withLength(min: 3, max: 3).withDefault(const Constant('EGP'))();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  // JSON array of keyword strings: ["Noon","laptop","سفر","تذكرة"]
  TextColumn get keywords => text().withDefault(const Constant('[]'))();
  IntColumn get walletId => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Goal Contributions (separate tracking from main transactions) ──────────────
class GoalContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(SavingsGoals, #id)();
  IntColumn get amount => integer()();     // piastres
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
}

// ── Recurring Rules ───────────────────────────────────────────────────────────
class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amount => integer()();     // piastres
  TextColumn get type => text()();         // 'income' | 'expense'
  TextColumn get title => text()();
  TextColumn get frequency => text()();    // 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'yearly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get autoLog => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastProcessedDate => dateTime().nullable()();
}

// ── Bills ─────────────────────────────────────────────────────────────────────
// NOTE: Bills are one-off upcoming payments. For repeating payments, use RecurringRules.
// If a bill repeats monthly (e.g. electricity), create a RecurringRule instead.
class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get amount => integer()();     // piastres
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  IntColumn get linkedTransactionId => integer().nullable()();
}

// ── SMS Parser Log (prevent duplicate processing) ─────────────────────────────
class SmsParserLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderAddress => text()();
  TextColumn get bodyHash => text().unique()(); // SHA-256 of SMS body — dedup key
  TextColumn get body => text()();
  TextColumn get parsedStatus => text()(); // 'approved' | 'skipped' | 'failed'
  IntColumn get transactionId => integer().nullable()();
  TextColumn get source => text()();       // 'sms' | 'notification'
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get processedAt => dateTime().withDefault(currentDateAndTime)();
}

// ── Exchange Rates (cached, optional) ─────────────────────────────────────────
class ExchangeRates extends Table {
  TextColumn get baseCurrency => text().withLength(min: 3, max: 3)();
  TextColumn get targetCurrency => text().withLength(min: 3, max: 3)();
  RealColumn get rate => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {baseCurrency, targetCurrency};
}
```

---

## 6. Build & Run Commands

```bash
# Install dependencies
flutter pub get

# ALWAYS run after any Drift table change, @freezed model, or @riverpod provider
dart run build_runner build --delete-conflicting-outputs

# Run on connected Android device (debug)
flutter run

# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code (must be zero warnings before any commit)
flutter analyze

# Format all Dart files
dart format lib/ test/

# Build release APK
flutter build apk --release

# Build release App Bundle (preferred for Play Store)
flutter build appbundle --release
```

⚠️ **Always run `build_runner` after:**

- Any Drift table or column change
- Any new `@freezed` data model
- Any new `@riverpod` provider annotation

---

## 7. Design System

### 7.1 Color Palette (`lib/app/theme/app_colors.dart`)

**Visual refresh (P4):** Replaced Indigo+Teal with two new palettes — Minty Fresh (light) and Gothic Noir (dark).

```dart
abstract final class AppColors {
  // ── Minty Fresh — Light Mode ─────────────────────────────────────────────
  static const Color primary      = Color(0xFF3DA37A);  // Mint Green
  static const Color primaryLight = Color(0xFFE0F7EF);  // Very Light Mint
  static const Color accent       = Color(0xFF558B71);  // Sage Green
  static const Color incomeGreen  = Color(0xFF2D7A4F);  // Forest Green
  static const Color expenseRed   = Color(0xFFD94452);  // Coral Red
  static const Color transferBlue = Color(0xFF2E7DD1);  // Ocean Blue
  static const Color warning      = Color(0xFFB8860B);  // Warm Amber
  static const Color surface      = Color(0xFFF5FBF8);  // Mint White
  static const Color onSurface    = Color(0xFF1A2E27);  // Deep Green-Black
  static const Color surfaceCard  = Color(0xFFFFFFFF);  // Pure White

  // ── Gothic Noir — Dark Mode ──────────────────────────────────────────────
  static const Color backgroundDark  = Color(0xFF0E0E0E);  // True Noir
  static const Color surfaceDark     = Color(0xFF1A1A1A);  // Dark Charcoal
  static const Color primaryDark     = Color(0xFF7B68AE);  // Muted Purple
  static const Color onSurfaceDark   = Color(0xFFC4C4C4);  // Silver Gray
  static const Color surfaceCardDark = Color(0xFF252020);  // Dark Brown
  static const Color incomeGreenDark = Color(0xFFE19B8B);  // Rose Gold (income in dark)
  static const Color expenseRedDark  = Color(0xFFD91B24);  // Gothic Red
  static const Color transferBlueDark = Color(0xFF6B7FA3); // Muted Blue
  static const Color warningDark     = Color(0xFFD4A574);  // Warm Tan

  // Comparison / Previous Period
  static const Color lastMonthGray      = Color(0xFF94A3B8);  // Slate 400
  static const Color lastMonthGrayLight = Color(0xFFCBD5E1);  // Slate 300

  // Semantic
  static const Color success     = Color(0xFF1B7A4A);  // Deep Emerald
  static const Color successDark = Color(0xFF7DAE8B);  // Sage Green
  static const Color disabled      = Color(0xFFB0C4B8);  // Muted Sage (light)
  static const Color disabledDark  = Color(0xFF4A4A4A);  // Charcoal Gray (dark)
  static const Color error       = expenseRed;
}
```

### 7.2 Typography

- **Font**: Plus Jakarta Sans (via `google_fonts`)
- Both light and dark themes implemented via `flex_color_scheme`
- Test dark mode on EVERY screen before marking a task done

### Typography Scale

```
displayLarge    32sp  Bold    — Wallet balance (dashboard hero number)
headlineLarge   26sp  Bold    — Screen titles
headlineMedium  22sp  SemiBold— Section headers
titleLarge      18sp  Medium  — List primary text, card titles
bodyLarge       16sp  Regular — Amounts, body copy
bodyMedium      14sp  Regular — Secondary info, dates
labelLarge      14sp  Medium  — Buttons, tabs, chips
labelSmall      11sp  Regular — Timestamps, tertiary labels
```

### 7.3 Spacing Scale (multiples of 4dp)

```
xs:  4dp  — icon-to-text gaps
sm:  8dp  — inline element spacing
md:  16dp — padding inside cards/sections
lg:  24dp — spacing between related sections
xl:  32dp — spacing between major zones on screen
xxl: 48dp — top/bottom page padding, hero area breathing room
```

### 7.4 Border Radius & Elevation

```
borderRadiusSm:   8dp  — chips, small elements
borderRadiusMd:  16dp  — cards, inputs
borderRadiusLg:  24dp  — bottom sheets, large modals
borderRadiusFull: 100dp — circular elements (avatars, FAB)

elevationNone:    0     — flat elements
elevationLow:     1     — subtle cards (use for transaction cards)
elevationMedium:  2     — balance card, prominent cards
elevationHigh:    4     — FAB, bottom sheet
```

### 7.5 UI Layout Rules (MANDATORY — Avoids Cramming)

> Inspired by best practices from Revolut, Monzo, Monarch, YNAB, and top-rated Behance finance app concepts. The guiding principle: **let content breathe**.

**Rule 1 — Max 4 Content Zones per Viewport.** A "zone" is a distinct visual group (e.g., balance card, summary row, transaction list, chart). If a screen has more than 4 zones, the extras MUST be below the fold and accessed via scroll.

**Rule 2 — Section Spacing.** Between major zones: minimum `AppSizes.xl` (32dp). Between items within a zone: `AppSizes.sm` (8dp) to `AppSizes.md` (16dp).

**Rule 3 — Hero Content First.** Every screen has ONE hero element that dominates the top 30% of the viewport. Dashboard hero = balance card. Goals hero = progress ring. Reports hero = main chart.

**Rule 4 — Progressive Disclosure.** Don't show all data at once. Use "See All →" links, expandable sections, and navigation to detail screens instead of cramming everything inline.

**Rule 5 — Card Padding.** All cards have minimum `AppSizes.md` (16dp) internal padding on all sides. Never let content touch card edges.

**Rule 6 — Horizontal Scroll Sparingly.** Max ONE horizontal scroll section per screen. More than one creates confusion.

**Rule 7 — Empty Space Is Intentional.** Screen edges have `AppSizes.md` (16dp) horizontal padding. Top of scroll content has `AppSizes.lg` (24dp) padding. Bottom of scroll content has `AppSizes.xxl` (48dp) padding to clear the bottom nav.

**Rule 8 — Text Truncation.** All text in cards uses `maxLines` + `TextOverflow.ellipsis`. Transaction titles: maxLines 1. Notes: maxLines 2. Never let text wrap indefinitely inside a card.

### 7.6 Dashboard Layout Specification

The dashboard is the most important screen. It MUST NOT feel cluttered.

```
┌─────────────────────────────────────┐
│  AppBar: "Masarify" + settings gear │  ← 56dp
├─────────────────────────────────────┤
│                                     │
│  ┌─ ZONE 1: Hero Balance Card ───┐ │  ← ~120dp
│  │  Net Balance (count-up anim)   │ │
│  │  Income ↑ | Expense ↓ summary  │ │
│  │  Trend indicator vs last month │ │
│  └────────────────────────────────┘ │
│          32dp spacing               │
│  ┌─ ZONE 2: Quick Actions ───────┐ │  ← ~72dp
│  │  [+Expense] [+Income]         │ │  ← FOUR buttons
│  │  [Transfer] [🎤 Voice]        │ │  ← Wrap layout
│  │  Each: FilledButton.tonalIcon  │ │
│  │  with semantic color           │ │
│  └────────────────────────────────┘ │
│          32dp spacing               │
│  ┌─ ZONE 3: Recent Transactions ─┐ │  ← ~280dp
│  │  "Recent"         "See All →" │ │
│  │  ┌─ Transaction Row ────────┐ │ │
│  │  │ Icon | Title | Amount    │ │ │
│  │  └──────────────────────────┘ │ │
│  │  (show last 5, tap → detail) │ │
│  └────────────────────────────────┘ │
│          32dp spacing               │
│  ── below fold (scroll to see) ──── │
│                                     │
│  ┌─ ZONE 4: Spending Overview ───┐ │
│  │  Donut chart (top 5 cats)     │ │
│  │  Tap category → filtered list │ │
│  └────────────────────────────────┘ │
│          32dp spacing               │
│  ┌─ ZONE 5: Budget Alerts ──────┐ │
│  │  Only shown if budgets set    │ │
│  │  Max 3 budget cards           │ │
│  │  "Manage Budgets →"           │ │
│  └────────────────────────────────┘ │
│          32dp spacing               │
│  ┌─ ZONE 6: Smart Insights ─────┐ │
│  │  Top 2 insight cards          │ │
│  │  Each: distinct icon, CTA,    │ │
│  │  onDismiss                     │ │
│  │  "See All →" → InsightsScreen │ │
│  └────────────────────────────────┘ │
│          48dp bottom padding        │
└─────────────────────────────────────┘
```

**Key changes from original spec:**

- **Removed**: 7-day sparkline (moved to Reports screen)
- **Removed**: Budget mini-card horizontal scroll (replaced with max 3 alert cards, only if budgets exist)
- **Removed**: Upcoming bills indicator from dashboard (lives in Hub/More tab)
- **Changed**: Quick Actions row has FOUR buttons in Wrap layout: +Expense, +Income, Transfer, and Voice. Each uses `FilledButton.tonalIcon` with semantic color. +Expense/+Income open `AddTransactionScreen` with type preselected. Transfer navigates to TransferScreen. Voice taps `VoiceInputSheet.show(context)`.
- **Changed**: Balance card is larger, more prominent, with income/expense integrated into it and a trend indicator comparing to last month (`lastMonthExpensePiastres`)
- **Added**: Zone 6 — Smart Insights showing top 2 insight cards with CTA buttons, dismiss, and "See All →" link to InsightsScreen

### 7.7 Chart Design Guidelines

```dart
// fl_chart configuration standards
// 1. Colors: ALWAYS use context.appTheme tokens, never hardcode
//    - "Last month" / previous period bars: context.appTheme.previousPeriodColor
//    - Light variant for expense previous: context.appTheme.previousPeriodColorAlt
// 2. Labels: max 6 labels on axis to prevent crowding
// 3. Touch: all charts MUST have touch enabled:
//    - BarTouchData(enabled: true) with tooltips
//    - PieTouchData with section highlighting
//    - Period selectors (7d/30d/90d) on Trends tab
// 4. Empty: show EmptyState widget if no data, never an empty chart frame
// 5. Sizing: charts are ALWAYS inside a SizedBox with fixed height (200–280dp)
// 6. Animation: entry animation 800ms ease-in-out, updates 300ms
// 7. Donut: max 5 slices + "Other" grouping. Center shows total.
// 8. Line: max 2 lines (income + expense). Single line for trends.
// 9. Bar: max 12 bars visible. Horizontal scroll if more months.
```

---

## 8. Android Permissions (AndroidManifest.xml)

Add inside `<manifest>` tag:

```xml
<!-- Voice Input -->
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<!-- SMS Parser (feature-flagged — validate Play policy before enabling in store build) -->
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>

<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

<!-- Biometrics -->
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
```

Add inside `<application>` tag (for notification listener):

```xml
<service
  android:name="notification.listener.service.NotificationListener"
  android:label="Masarify Transaction Alerts"
  android:permission="android.permission.BIND_NOTIFICATION_LISTENER_SERVICE"
  android:exported="true">
  <intent-filter>
    <action android:name="android.service.notification.NotificationListenerService"/>
  </intent-filter>
</service>
```

**⚠️ SMS Policy Note:** Direct SMS reading via `READ_SMS` is enabled (owner-approved). Before Play Store submission, submit a [SMS/Call Log permission declaration](https://support.google.com/googleplay/android-developer/answer/9047303) — financial tracking is an approved use case. The notification listener approach is the fallback if the declaration is not approved.

---

## 9. Architecture & Coding Conventions

### Architecture Rules

- **No Flutter imports in `domain/`** — pure Dart only.
- **No Drift imports in `domain/`** — repositories use domain entities, not Drift models.
- **Providers call use cases** — never call repositories directly from providers.
- **Use cases are single-responsibility** — one class, one `execute()` or `call()` method.
- **DAOs return domain entities** — convert Drift model → domain entity inside DAO or repository.
- **NEVER put business logic in widgets** — use Riverpod providers.

### Dart Style

- Dart 3 patterns: sealed classes, records, pattern matching where appropriate.
- `@riverpod` annotation for all providers. `AsyncNotifier` for async, `Notifier` for sync.
- Immutable data everywhere in domain and presentation layers. Use `copyWith`.
- File names: `snake_case.dart`. Classes: `PascalCase`. Variables/methods: `camelCase`.
- Max line length: 120 characters.
- Use `const` constructors wherever possible.
- Keep widgets small — extract if exceeding ~100 lines.
- Use `AsyncValue.when()` pattern for loading/error/data states.
- **Never use `setState` in screens** — exceptions: `AnimationController` in `StatefulWidget`, and ephemeral form state (category selection, loading toggles, local amount/toggle fields) where converting to Riverpod would add boilerplate with no UX benefit.
- **Never use `Navigator.push()`** — use `context.go()` or `context.push()` from `go_router`.

### Widget Rules

- Every screen is a `ConsumerWidget` or `ConsumerStatefulWidget`.
- Use `ref.watch()` for reactive data, `ref.read()` for callbacks.
- All route names are constants in `lib/core/constants/app_routes.dart`.
- All interactive elements need `Semantics` labels.
- Minimum touch target: **48×48 logical pixels**.
- Bottom sheets: `showModalBottomSheet` with `isScrollControlled: true`.

### State Management (Riverpod)

- Use `@riverpod` annotation for all code-generated providers.
- `AsyncNotifierProvider` for data from database (reactive streams).
- `NotifierProvider` for UI-only state (selected tab, filter state, etc.).
- Keep providers in `domain/providers/` or `shared/providers/` per feature.

### Data Models (Freezed)

- All domain data models use `@freezed` annotation.
- Include `fromJson`/`toJson` factories for serialization.
- Use `@Default()` for optional fields with defaults.

---

## 10. Money Formatting (Mandatory — Never Skip)

```dart
// ALWAYS use MoneyFormatter. NEVER use raw doubles for display.
// File: lib/core/utils/money_formatter.dart

class MoneyFormatter {
  // Convert piastres integer → formatted currency string
  static String format(int piastres, {String currency = 'EGP', String locale = 'ar-EG'}) {
    final amount = piastres / 100.0;
    return NumberFormat.currency(
      locale: locale,
      symbol: _symbol(currency),
      decimalDigits: 2,
    ).format(amount);
  }

  // Compact format for large numbers: "12.5K" or "1.2M"
  static String formatCompact(int piastres, {String currency = 'EGP', String locale = 'ar-EG'}) {
    final amount = piastres / 100.0;
    return NumberFormat.compactCurrency(
      locale: locale,
      symbol: _symbol(currency),
    ).format(amount);
  }

  static String _symbol(String currency) {
    switch (currency) {
      case 'EGP': return 'ج.م';
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'SAR': return 'ر.س';
      case 'AED': return 'د.إ';
      case 'KWD': return 'د.ك';
      default: return currency;
    }
  }

  // Parse user input to integer piastres: "150.75" → 15075
  static int parseToInt(String input) {
    final cleaned = input.replaceAll(',', '').replaceAll('٬', '');
    final value = double.tryParse(cleaned) ?? 0.0;
    return (value * 100).round();
  }
}
```

---

## 11. Voice Input Architecture

Three-stage pipeline in `lib/features/voice_input/data/parsers/`.

### Stage 1 — Capture

- Package: `speech_to_text` with device default locale (no Arabic locale gate — works with any language)
- **Entry point:** FAB radial menu (mic bubble) → `VoiceInputSheet.show(context)` bottom sheet
- **Interaction:** Tap-to-start/tap-to-stop (NOT hold-to-record). Mic button uses `avatar_glow` pulsing effect while recording.
- Show live transcript in bottom sheet as user speaks
- Graceful fallback if device STT is unavailable

### Stage 2 — Parse (`VoiceTransactionParser`)

Located in `lib/core/utils/voice_transaction_parser.dart`:

```dart
// Egyptian Arabic amount dictionary (partial — implement all)
const Map<String, int> arabicAmountWords = {
  'مية': 100, 'مئة': 100, 'مئتين': 200, 'ميتين': 200,
  'ألف': 1000, 'الف': 1000, 'الفين': 2000, 'ألفين': 2000,
  'تلاتة آلاف': 3000, 'تلت آلاف': 3000,
  'مليون': 1000000,
  'نص': 50,    // "نص جنيه" = 50 piastres
  'ربع': 25,   // "ربع جنيه" = 25 piastres
};

// Expense trigger keywords (Egyptian Arabic + English)
const List<String> expenseTriggers = [
  'صرفت', 'دفعت', 'اشتريت', 'شريت', 'كليت', 'ركبت',
  'عملت', 'اديت', 'دفعتلهم', 'بعتلهم', 'جبت',
  'spent', 'paid', 'bought', 'ordered',
];

// Income trigger keywords
const List<String> incomeTriggers = [
  'اتودت', 'استلمت', 'اتقبضت', 'بعت', 'اخدت', 'قبضت',
  'اتحولتلي', 'ودوني', 'received', 'got paid', 'salary',
];

// Time keyword → day offset mapping
const Map<String, int> timeKeywords = {
  'امبارح': -1, 'أمس': -1,
  'أول امبارح': -2, 'اول امبارح': -2,
  'النهارده': 0, 'اليوم': 0, 'دلوقتي': 0,
  'من يومين': -2, 'من تلات تيام': -3,
  'من اسبوع': -7,
};

// Category keyword → category mapping (partial)
const Map<String, String> categoryKeywords = {
  // Food
  'أكل': 'food', 'اكل': 'food', 'فطار': 'food', 'غدا': 'food',
  'عشا': 'food', 'كافيه': 'food', 'قهوه': 'food', 'مطعم': 'food',
  'ماكدونالدز': 'food', 'ماك': 'food', 'كنتاكي': 'food',
  'بيتزا': 'food', 'دليفري': 'food', 'طلبات': 'food',
  'talabat': 'food', 'elmenus': 'food',
  // Transport
  'عربيه': 'transport', 'أوبر': 'transport', 'اوبر': 'transport',
  'كريم': 'transport', 'باص': 'transport', 'مترو': 'transport',
  'تاكسي': 'transport', 'بنزين': 'transport',
  'uber': 'transport', 'careem': 'transport', 'swvl': 'transport',
  // Shopping
  'نون': 'shopping', 'امازون': 'shopping', 'جوميا': 'shopping',
  'مول': 'shopping', 'كارفور': 'shopping', 'سبينيس': 'shopping',
  'noon': 'shopping', 'amazon': 'shopping',
  // Health
  'دكتور': 'health', 'دواء': 'health', 'صيدليه': 'health',
  'مستشفى': 'health', 'pharmacy': 'health',
  // Bills
  'فاتوره': 'bills', 'كهرباء': 'bills', 'ميه': 'bills',
  'غاز': 'bills', 'انترنت': 'bills',
  // Housing
  'ايجار': 'housing', 'إيجار': 'housing', 'rent': 'housing',
};

// Multi-transaction split conjunctions
const List<String> splitKeywords = [
  'وكمان', 'وبعدين', 'وبرضو', 'كمان', 'وبعد كده',
  'بعدين', 'and also', 'then',
];
```

### Stage 3 — Review

- Show each parsed transaction as an editable card
- User edits: title, amount, category, type, date before confirming
- "Confirm All" saves all at once
- "Remove" removes a single card from batch
- NEVER auto-save — always require explicit user confirmation

---

## 12. SMS & Notification Parser Architecture

### Supported Egyptian Financial Senders

```dart
const List<String> egyptianFinancialSenders = [
  // Banks
  'CIB', 'NBE', 'BANQUEMISR', 'MISR', 'QNB', 'AAIB',
  'ALEXBANK', 'ADIB', 'AHLI', 'HSBC', 'FAISAL',
  // Mobile Money
  'VODAFONE', 'VODAFONECASH', 'VCASH', 'ORANGE',
  'ETISALAT', 'ECASH', 'WE',
  // Fintech & Payments
  'INSTAPAY', 'FAWRY', 'VALU', 'SOUHOOLA', 'CONTACT',
  // E-commerce
  'AMAZON', 'NOON', 'JUMIA', 'TALABAT',
];

// Amount extraction regex
// r'(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?)\s*(?:EGP|LE|جنيه|ج\.م)'

// Credit/Income patterns:
// Arabic: "تم إيداع", "تم ايداع", "تم استلام", "رصيد جديد"
// English: "credited", "received", "deposited", "added to"

// Debit/Expense patterns:
// Arabic: "تم خصم", "تم السداد", "تم الشراء", "جارى خصم"
// English: "debited", "deducted", "purchase", "payment of"
```

### User Flow

1. Settings → SMS & Notifications → "Enable" button
2. Show rationale dialog (purpose, privacy promise)
3. Request notification listener access (preferred) or READ_SMS (feature-flagged)
4. On grant: scan for financial messages, filter by known senders
5. Deduplicate via `SmsParserLogs` (bodyHash SHA-256 — never re-process same message)
6. Show banner: "X transactions found — tap to review"
7. `SmsReviewScreen`: approve / edit / skip each item
8. On approve: save transaction with `source = 'sms'` or `source = 'notification'`, log to `SmsParserLogs`

---

## 13. Goal Keyword Matching

Located in `lib/core/utils/goal_keyword_matcher.dart`:

```dart
// Called after EVERY transaction save (manual, voice, SMS, notification)
// Algorithm:
// 1. Load all active goals with non-empty keywords
// 2. Normalize text: lowercase, strip Arabic diacritics
//    using RegExp(r'[\u064B-\u065F]')
// 3. Check transaction.title + category.name against each goal's keywords
// 4. If match found → show SnackBar (5s timeout):
//    "This looks like it relates to your '[Goal Name]'. Link it?"
//    [Link] [Dismiss]
// 5. On Link: set transaction.goalId = goal.id via TransactionDao
// 6. Update goal.currentAmount if transaction contributes to savings
```

---

## 14. Micro-Interactions Guide

### Animation Budget Rules (MANDATORY)

> Too many simultaneous animations feel chaotic and hurt performance. Follow these constraints:

1. **Max 2 concurrent animations** on any single screen at any time.
2. **Total animation duration budget per screen load**: 1200ms max.
3. **Stagger delays**: 60–100ms between items (not more).
4. **No animation on scroll** — animated elements only on first appearance or state change.
5. **Lottie file size**: max 50KB per file. Source from LottieFiles.com (free tier) or create custom.
6. **Disable animations** if user has "Reduce motion" enabled in system accessibility settings:

   ```dart
   final reduceMotion = MediaQuery.of(context).disableAnimations;
   ```

### Lottie Animations

All Lottie JSON files in `assets/animations/`. Pre-load during app init.

```dart
// Success animation after saving transaction
LottieBuilder.asset(
  'assets/animations/success.json',
  controller: _controller,
  onLoaded: (composition) {
    _controller.duration = composition.duration;
    _controller.forward();
  },
  repeat: false,
  width: 120, height: 120,
)
```

### Haptic Feedback Pattern

```dart
// Use Flutter's built-in HapticFeedback — NO external package needed
import 'package:flutter/services.dart';

HapticFeedback.heavyImpact();    // On save success
HapticFeedback.vibrate();         // On validation error
HapticFeedback.mediumImpact();    // On delete
HapticFeedback.lightImpact();     // On FAB tap, button press
HapticFeedback.selectionClick();  // On tab switch, chip select
```

### Required Micro-Interactions

- **Quick Actions**: subtle scale (0.95→1.0) on tap, 150ms
- **Balance**: count-up animation on value change (800ms, ease-out)
- **Budget progress bars**: animated width fill on screen enter (500ms)
- **Goal rings**: animated arc fill on screen enter (800ms, ease-in-out)
- **Transaction save**: Lottie success checkmark (green circle + check, ~1s, auto-dismiss)
- **Goal completed**: Lottie celebration (confetti, ~2s, full-screen overlay)
- **Empty states**: Static Lottie illustration (loop: false) — no distracting looping
- **Loading**: shimmer skeleton on all list screens before first data
- **Delete swipe**: red background with trash icon revealed during drag
- **Page transitions**: slide + fade (300ms)

---

## 15. Localization Rules

- `lib/l10n/app_en.arb` and `lib/l10n/app_ar.arb` MUST always stay in sync.
- Every new EN string immediately gets an AR translation — no exceptions.
- Arabic numbers: use `intl` with `ar-EG` locale — never manually replace digit characters.
- Currency in Arabic: `NumberFormat.currency(locale: 'ar-EG', symbol: 'ج.م')`
- Test RTL by setting device/emulator language to Arabic.

---

## 16. Error Handling Patterns

### Centralized Error Handler

```dart
// File: lib/core/utils/error_handler.dart

sealed class AppError {
  const AppError(this.message, {this.code});
  final String message;
  final String? code;
}

class DatabaseError extends AppError { const DatabaseError(super.message); }
class ValidationError extends AppError { const ValidationError(super.message); }
class PermissionError extends AppError { const PermissionError(super.message); }
class ParsingError extends AppError { const ParsingError(super.message); }
class FileError extends AppError { const FileError(super.message); }
```

### Error Display Rules

1. **Validation errors**: Show inline below the field (red text, `bodySmall`). Never use dialogs for validation.
2. **Save/DB errors**: Show error SnackBar via `SnackHelper.showError(context, message)`. Include "Retry" action.
3. **Permission errors**: Show inline message with "Grant Permission" CTA button. Never crash.
4. **Parser errors (voice/SMS)**: Show "Could not parse" state with "Enter Manually" fallback button.
5. **Network errors**: Never show network errors in v1 (app is offline-first). Only relevant for future cloud features.
6. **Empty results**: Show `EmptyState` widget (Lottie + title + subtitle + optional CTA). See §16.1.

### 16.1 Empty State Specifications

Every screen with a list MUST have a designed empty state:

| Screen | Illustration | Title | Subtitle | CTA |
|---|---|---|---|---|
| Transactions | `empty_transactions.json` | "No transactions yet" | "Tap + to add your first one" | "Add Transaction" |
| Goals | `empty_goals.json` | "No savings goals" | "Set a goal and start saving" | "Create Goal" |
| Budgets | (use neutral Lottie) | "No budgets set" | "Set monthly limits to control spending" | "Set Budget" |
| Wallets | (won't happen — always ≥1) | — | — | — |
| Reports | (use neutral Lottie) | "Not enough data" | "Add some transactions to see insights" | — |
| Calendar | (use neutral Lottie) | "No activity this month" | — | — |
| Bills | (use neutral Lottie) | "No upcoming bills" | "Track your bills to never miss a payment" | "Add Bill" |

---

## 17. Security Rules

1. PIN stored as SHA-256 hash only — NEVER store plaintext PIN or any plaintext password.
2. Hash stored in `flutter_secure_storage` — NEVER in `shared_preferences`.
3. Biometric via `local_auth` — PIN must always be available as fallback.
4. Transaction data does NOT need encryption at rest (it's not bank credentials).
5. No analytics or crash-reporting SDKs that send user financial data.
6. SMS content processed on-device only — never transmitted externally.
7. Voice audio not stored or transmitted — transcription is on-device STT only.
8. Location data is optional and stored locally only.

---

## 18. Accessibility Requirements

> Beyond WCAG AA compliance — these are specific implementation rules.

1. **Contrast ratios**: All text meets 4.5:1 minimum contrast (AA). Large text (18sp+): 3:1 minimum.
2. **Touch targets**: All interactive elements ≥ 48×48dp. Use `SizedBox` or `Material(type: MaterialType.transparency)` to expand small icons.
3. **Semantic labels**: Every icon-only button has a `Semantics(label: ...)` wrapper.
4. **Screen reader order**: Logical reading order matches visual order. Test with TalkBack.
5. **Color is never the only indicator**: Income/expense use color + icon (↑/↓) + text label. Budget states use color + text percentage.
6. **Reduce motion**: Respect `MediaQuery.disableAnimations`. Replace animations with instant state changes.
7. **Font scaling**: Test at 1.0x, 1.3x, and 2.0x font scale. Use `maxLines` + `ellipsis` to prevent overflow.
8. **Focus order**: Tab/D-pad navigation works logically on all screens.

---

## 19. Pagination & Lazy Loading

### Transaction List

```dart
// Use Drift's .watch() with limit/offset for reactive pagination
// Load 50 items per page. Load next page when user scrolls to last 10 items.
// Use a ScrollController + listener pattern:

class TransactionListNotifier extends AsyncNotifier<List<Transaction>> {
  int _page = 0;
  static const _pageSize = 50;
  bool _hasMore = true;

  Future<void> loadNextPage() async {
    if (!_hasMore) return;
    final items = await ref.read(transactionRepoProvider)
        .getTransactions(limit: _pageSize, offset: _page * _pageSize);
    if (items.length < _pageSize) _hasMore = false;
    _page++;
    state = AsyncData([...state.value ?? [], ...items]);
  }
}
```

### Performance Targets

- Transaction list: 60fps scroll with 5,000+ items
- Initial load: first 50 items in < 100ms
- Next page load: < 50ms (SQLite with index)
- Ensure Drift table has index on `transactionDate DESC` for fast queries

---

## 20. AI Agent Working Rules

1. **Read `PRD.md` and `TASKS.md` before implementing any feature.**
2. **Check existing code before creating new files — avoid duplication.**
3. **Follow existing patterns in the codebase for consistency.**
4. **Never remove existing tests unless explicitly instructed.**
5. **Never make architectural changes that affect multiple modules without documenting why.**
6. **One feature per logical unit — keep changes focused.**
7. **Use only the specified packages — no alternative packages without justification.**
8. **Offline-first always — every feature must work without internet.**
9. **No sensitive data — never store bank credentials, card numbers, or payment tokens.**
10. **When parsing dialect/voice/SMS, always reference dictionaries in `assets/dictionaries/`.**
11. **Test edge cases — especially voice parsing (mixed Arabic-English, slang numbers, multiple transactions).**
12. **Commit format: `feat(module): short description` or `fix(module): description`.**
13. **Design tokens are law (§21) — NEVER hardcode a color, icon, spacing value, or font. Use `context.colors`, `context.appTheme`, `AppIcons.*`, `AppSizes.*` exclusively.**
14. **Use MasarifyDS components (§22) — NEVER build layout primitives in a screen file. Import from `lib/shared/widgets/`.**
15. **AI is enabled via OpenRouter (`AiConfig.isEnabled = true`). New AI features should use the same `openrouter_service.dart` client.**
16. **Never add `purchases_flutter` or enable billing unless `kMonetizationEnabled = true` is being explicitly activated.**
17. **Respect the UI layout rules (§7.5) — max 4 zones per viewport, generous spacing, progressive disclosure.**

---

## 21. Frequently Asked Questions for Agent

**Q: Should I implement user login / accounts?**
A: NO. Offline, local-only app. No server, no JWT, no Firebase Auth. Only security is local PIN/biometric.

**Q: Which database?**
A: Drift (SQLite ORM). Do NOT use Hive, Isar, or Firebase. Drift provides type-safe SQL, reactive streams, and proper relational joins.

**Q: How should I handle state?**
A: Riverpod 2.x with `@riverpod` annotation. `AsyncNotifierProvider` for DB data. `NotifierProvider` for UI-only state.

**Q: Navigation library?**
A: `go_router`. All routes defined in `lib/app/router/app_router.dart`. Named routes via constants in `lib/core/constants/app_routes.dart`.

**Q: Currency formatting?**
A: Use `MoneyFormatter.format(piastres)`. Get locale and currency from `shared_preferences`. Never do number formatting inline.

**Q: How do recurring transactions work?**
A: On app launch, `RecurringScheduler` checks if any rules have `nextDueDate <= today`. Either auto-creates transactions or shows a reminder notification (based on `autoLog` flag). Schedule a `flutter_local_notifications` notification for the next due date.

**Q: What about transfers?**
A: Wallet-to-wallet transfers use the `Transfers` table. They MUST NOT appear as income or expense in analytics. Show them in the transaction history with a "Transfer" type badge.

**Q: SMS vs Notification parsing?**
A: Both are enabled. Notification listener is always-on when toggled. SMS inbox scanning runs on cold start and when toggled on in Settings. Submit SMS permission declaration to Google Play before publishing — financial tracking is an approved use case.

**Q: Bills vs Recurring — when to use which?**
A: **Recurring** = repeating transactions (salary, subscription, rent). They auto-create or remind on schedule. **Bills** = one-off upcoming payments with a due date. If something repeats monthly, use Recurring. If it's a single payment due on a specific date, use Bills.

**Q: How do I use a color in a widget?**
A: `context.colors.primary` for Material ColorScheme colors. `context.appTheme.incomeColor` for custom semantic tokens. NEVER `Color(0xFF...)` directly in a widget. See §23.

**Q: How do I use an icon in a widget?**
A: `AppIcons.home`, `AppIcons.expense`, etc. — NEVER `Icons.home` directly. The `AppIcons` class in `lib/core/constants/app_icons.dart` is the single source for all icon references. See §23.3.

**Q: Why 4 nav tabs instead of 5?**
A: Industry best practice (Revolut, Monzo, YNAB). Settings doesn't warrant a permanent tab — it's accessed via a gear icon in the app bar. The 4 tabs are: Home, Transactions, Budget & Goals, More. Tab 3 has two sub-tabs (Budgets + Goals) since these are checked frequently. The "More" hub holds Wallets, Reports, Calendar, Bills, Recurring, Insights, Net Worth, and Settings.

**Q: I need to add an AI feature. What do I do?**
A: Voice input now uses AI via OpenRouter with rule-based fallback. `AiConfig.isEnabled = true`. The API key is injected at build time via `--dart-define=OPENROUTER_API_KEY=...`. For new AI features: (1) Add methods to the relevant service. (2) Use `ref.read(aiVoiceParserProvider)` or create a new provider. (3) Always provide a graceful fallback when offline or no API key. See §25.

**Q: I need to add a Pro-only feature. What do I do?**
A: (1) Check `ref.watch(hasProProvider)`. (2) If false AND `kMonetizationEnabled = true`, show `ProFeatureDialog` with a paywall route CTA. (3) If `kMonetizationEnabled = false` (default), `hasPro` returns `true` for everyone — no gating. See §26.

**Q: For haptic feedback, which package?**
A: Use Flutter's built-in `HapticFeedback` from `flutter/services.dart`. No external package needed. See §14.

---

## 22. Transaction Entry UX (Amount-First Flow)

> Inspired by YNAB and top Behance concepts. The key insight: users think "amount first, then details."

### Entry Points

- **Dashboard Quick Actions**: Tap "+ Expense" or "+ Income" → opens `AddTransactionScreen` with type preselected
- **FAB (center-docked, all tabs)**: Tap → AddTransaction (Expense preset). Long press → expandable radial menu with 3 bubbles: Expense (top-left), Mic/Voice (center-top), Income (top-right). Swipe to select, RTL-aware.
- **Wallets screen**: "Transfer" button → opens `TransferScreen` (Transfer is NOT in the FAB — it's a wallet-level action)

### Flow (optimized for speed — target < 10 seconds)

```
Step 1: Tap FAB or Quick Action button
        → Opens AddTransactionScreen directly (full screen, NOT bottom sheet)
        → Type toggle at top: [Expense] [Income] — Expense preselected

Step 2: Amount keypad is immediately focused (hero position, top 40% of screen)
        → Type amount → real-time MoneyFormatter display
        → "Next" or scroll down to continue

Step 3: Category picker — FREQUENT FIRST
        → Top row: 6 chips showing user's most-used categories
        → Tap any chip = instant select (no extra screen)
        → "All Categories" button → expands full searchable grid below
        → First-time users see 6 default favorites (Food, Transport, Shopping, Bills, Health, Entertainment)

Step 4: Optional fields collapsed by default:
        → Wallet (pre-selected to default wallet)
        → Date (pre-set to today)
        → Note
        → Location
        → Tags

Step 5: "Save" button (always visible, sticky at bottom)
        → Success haptic + brief checkmark animation
        → Returns to previous screen
```

**Key principles:**

- Amount and category are the only two required interactions
- Everything else has smart defaults (today, default wallet)
- FAB → 1 tap to start entering amount. Long press → radial menu (Expense, Mic, Income)
- Frequent categories first eliminates scrolling for the 80% case

---

## 23. Flexible Design Token System (Change Colors / Icons / Nav Without Errors)

> Goal: You can change ANY brand color, icon set, font, spacing, or navigation layout by editing ONE file. No widget hardcodes anything visual directly.

### 23.1 The Rule — Tokens Are Law

**NEVER hardcode a color, spacing value, icon name, border radius, or font in a widget directly.**

```dart
// ❌ WRONG — this breaks when brand evolves
Container(color: Color(0xFF4F46E5))
Icon(Icons.home, size: 24)
SizedBox(height: 16)

// ✅ CORRECT — change token once, everything updates
Container(color: context.colors.primary)
Icon(AppIcons.home, size: AppSizes.iconMd)
SizedBox(height: AppSizes.md)
```

### 23.2 ThemeExtension — Custom Semantic Tokens

Add a `ThemeExtension` to carry custom tokens the standard `ColorScheme` doesn't have.

```dart
// File: lib/app/theme/app_theme_extension.dart

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color incomeColor;
  final Color expenseColor;
  final Color transferColor;
  final Color warningColor;
  final Color successColor;
  final Color previousPeriodColor;     // For "last month" bars/dots in comparison charts
  final Color previousPeriodColorAlt;  // Lighter variant for expense comparison bars
  final Color cardSurface;
  final double cardBorderRadius;
  final double listItemRadius;
  final double cardElevation;

  const AppThemeExtension({
    required this.incomeColor,
    required this.expenseColor,
    required this.transferColor,
    required this.warningColor,
    required this.successColor,
    required this.previousPeriodColor,
    required this.previousPeriodColorAlt,
    required this.cardSurface,
    required this.cardBorderRadius,
    required this.listItemRadius,
    required this.cardElevation,
  });

  static const light = AppThemeExtension(
    incomeColor: AppColors.incomeGreen,   // #2D7A4F — Forest Green
    expenseColor: AppColors.expenseRed,
    transferColor: AppColors.transferBlue,
    warningColor: AppColors.warning,       // #B8860B — Warm Amber
    successColor: AppColors.success,
    previousPeriodColor: AppColors.lastMonthGray,       // Slate 400
    previousPeriodColorAlt: AppColors.lastMonthGrayLight, // Slate 300
    cardSurface: Color(0xFFFFFFFF),
    cardBorderRadius: 16.0,
    listItemRadius: 12.0,
    cardElevation: 1.0,
  );

  static const dark = AppThemeExtension(
    incomeColor: AppColors.incomeGreenDark,    // #E19B8B — Rose Gold
    expenseColor: Color(0xFFD91B24),           // Gothic Red
    transferColor: AppColors.transferBlueDark,  // #6B7FA3 — Muted Blue
    warningColor: AppColors.warningDark,        // #D4A574 — Warm Tan
    successColor: AppColors.successDark,        // #7DAE8B — Sage Green
    previousPeriodColor: Color(0xFF64748B),    // Slate 500
    previousPeriodColorAlt: Color(0xFF475569), // Slate 600
    cardSurface: AppColors.surfaceCardDark,    // #252020 — Dark Brown
    cardBorderRadius: 16.0,
    listItemRadius: 12.0,
    cardElevation: 0.0,  // dark mode uses border instead of elevation
  );

  @override
  AppThemeExtension copyWith({ /* all fields */ }) => AppThemeExtension(/* ... */);

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      transferColor: Color.lerp(transferColor, other.transferColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      previousPeriodColor: Color.lerp(previousPeriodColor, other.previousPeriodColor, t)!,
      previousPeriodColorAlt: Color.lerp(previousPeriodColorAlt, other.previousPeriodColorAlt, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorderRadius: lerpDouble(cardBorderRadius, other.cardBorderRadius, t)!,
      listItemRadius: lerpDouble(listItemRadius, other.listItemRadius, t)!,
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t)!,
    );
  }
}

// ── Extension shorthand on BuildContext ───────────────────────────────────────
extension AppThemeX on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
}
```

### 23.3 Icon System — `AppIcons` (Phosphor Icons)

> **P4 visual refresh:** Migrated from Material Icons to Phosphor Icons (`phosphor_flutter: ^2.1.0`).
> Uses `PhosphorIconsFill.*` for active/filled, `PhosphorIconsRegular.*` for outlined, `PhosphorIconsBold.*` for emphasis.
> All 111 icon constants are centralized here — widgets use `AppIcons.*` only.

```dart
// File: lib/core/constants/app_icons.dart
import 'package:phosphor_flutter/phosphor_flutter.dart';

abstract final class AppIcons {
  // Navigation
  static const IconData home             = PhosphorIconsFill.house;
  static const IconData homeOutlined     = PhosphorIconsRegular.house;
  static const IconData transactions     = PhosphorIconsFill.receipt;
  static const IconData transactionsOutlined = PhosphorIconsRegular.receipt;
  static const IconData analytics        = PhosphorIconsFill.chartBar;
  static const IconData analyticsOutlined = PhosphorIconsRegular.chartBar;
  static const IconData more             = PhosphorIconsFill.squaresFour;
  static const IconData moreOutlined     = PhosphorIconsRegular.squaresFour;
  static const IconData settings         = PhosphorIconsFill.gear;

  // Actions
  static const IconData add              = PhosphorIconsBold.plus;
  static const IconData edit             = PhosphorIconsRegular.pencilSimple;
  static const IconData delete           = PhosphorIconsRegular.trash;
  static const IconData search           = PhosphorIconsRegular.magnifyingGlass;
  static const IconData filter           = PhosphorIconsRegular.funnelSimple;
  static const IconData share            = PhosphorIconsRegular.shareFat;
  static const IconData mic              = PhosphorIconsFill.microphone;
  static const IconData camera           = PhosphorIconsRegular.camera;
  static const IconData location         = PhosphorIconsFill.mapPin;

  // Transaction types
  static const IconData expense          = PhosphorIconsBold.arrowDown;
  static const IconData income           = PhosphorIconsBold.arrowUp;
  static const IconData transfer         = PhosphorIconsBold.arrowsLeftRight;

  // Finance (subset — full list in app_icons.dart)
  static const IconData wallet           = PhosphorIconsFill.wallet;
  static const IconData budget           = PhosphorIconsFill.chartBar;
  static const IconData bill             = PhosphorIconsFill.receipt;
  static const IconData recurring        = PhosphorIconsRegular.repeat;
  static const IconData category         = PhosphorIconsFill.gridFour;
  static const IconData calendar         = PhosphorIconsRegular.calendarBlank;
  static const IconData notification     = PhosphorIconsFill.bell;
  static const IconData backup           = PhosphorIconsFill.cloudArrowUp;
  static const IconData security         = PhosphorIconsFill.shield;
  static const IconData eye              = PhosphorIconsRegular.eye;
  static const IconData eyeOff           = PhosphorIconsRegular.eyeSlash;
  static const IconData star             = PhosphorIconsFill.star;
  static const IconData crown            = PhosphorIconsFill.crown;
  static const IconData goals            = PhosphorIconsFill.target;
  static const IconData insights         = PhosphorIconsFill.lightbulb;
  static const IconData netWorth         = PhosphorIconsFill.bank;
}
```

### 23.4 Navigation Configuration — `AppNavigation` (4 Tabs + StylishBottomBar)

> **P4 visual refresh:** Bottom nav uses `StylishBottomBar` with liquid animation, FAB notch support (`hasNotch: true`, `fabLocation: StylishBarFabLocation.center`), and `extendBody: true` on the Scaffold for notch transparency.

```dart
// File: lib/core/constants/app_navigation.dart
// 4 tabs only. Settings accessed via gear icon in AppBar.
// Center FAB on all tabs → tap: AddTransactionScreen. Long press: radial menu (Expense/Mic/Income).

class AppNavDest {
  final String Function(Locale) label;  // l10n-aware label function
  final IconData icon;                  // Outlined (inactive)
  final IconData activeIcon;            // Filled (active)
  final String route;
  const AppNavDest({required this.label, required this.icon, required this.activeIcon, required this.route});
}

class AppNavigation {
  static const List<AppNavDest> destinations = [
    AppNavDest(label: ..., icon: AppIcons.homeOutlined,         activeIcon: AppIcons.home,         route: AppRoutes.dashboard),
    AppNavDest(label: ..., icon: AppIcons.transactionsOutlined, activeIcon: AppIcons.transactions, route: AppRoutes.transactions),
    AppNavDest(label: ..., icon: AppIcons.analyticsOutlined,    activeIcon: AppIcons.analytics,    route: AppRoutes.analytics),
    AppNavDest(label: ..., icon: AppIcons.moreOutlined,         activeIcon: AppIcons.more,         route: AppRoutes.hub),
  ];
}

// AppNavBar uses StylishBottomBar:
StylishBottomBar(
  option: AnimatedBarOptions(
    barAnimation: BarAnimation.liquid,
    iconStyle: IconStyle.animated,
    opacity: 0.3,
  ),
  items: [for (final dest in dests) BottomBarItem(
    icon: Icon(dest.icon),
    selectedIcon: Icon(dest.activeIcon),
    title: Text(dest.label(locale)),
    selectedColor: cs.primary,
  )],
  fabLocation: StylishBarFabLocation.center,
  hasNotch: true,
  currentIndex: currentIndex,
  onTap: onTap,
)
```

> **Tab 3 is Analytics** (NOT Budget & Goals). Budget & Goals are accessed via More → Planning section.

### 23.5 "More" Hub Screen Layout

The 4th tab opens a clean hub screen with categorized navigation tiles:

```
┌─────────────────────────────────────┐
│  AppBar: "More"                     │
├─────────────────────────────────────┤
│                                     │
│  ── Money ──────────────────────── │
│  [Wallets]                          │
│                                     │
│  ── Planning ───────────────────── │
│  [Budgets]  [Goals]                 │
│  [Bills]  [Recurring]               │
│                                     │
│  ── Reports ───────────────────── │
│  [Calendar]  [Net Worth]            │
│  [Smart Insights]                   │
│                                     │
│  ── App ────────────────────────── │
│  [Settings]  [Backup & Export]     │
│  [About]  [Help & FAQ]            │
│                                     │
└─────────────────────────────────────┘
```

Each tile: icon + label, 2-column grid with `AppSizes.md` gap, tap → navigate.

---

## 24. Pre-Built UI Component Library (MasarifyDS)

> Goal: Every screen is assembled from components. The agent NEVER builds layout from scratch in a screen file. This prevents text overlapping, messy UI, and inconsistency.

### 24.1 Philosophy

- **All screen files import components — they never define layout primitives inline.**
- Components handle padding, overflow, RTL, dark mode, and accessibility internally.
- To change a button style app-wide → change `AppButton`, not 30 call sites.

### 24.2 Component Catalogue (files in `lib/shared/widgets/`)

```
lib/shared/widgets/
├── buttons/
│   ├── app_button.dart              ← Primary, Secondary, Danger, Ghost variants
│   ├── app_icon_button.dart         ← Icon-only button with proper 48×48 tap target
│   └── app_fab.dart                 ← (Legacy) Simple FAB
├── inputs/
│   ├── app_text_field.dart          ← Labeled, error, hint, RTL-safe
│   ├── amount_input.dart            ← Native keyboard input with compact mode — MANDATORY for all money inputs
│   ├── app_date_picker.dart         ← Date + time picker with locale-aware format
│   └── app_search_bar.dart          ← Search with close button and debounce
├── cards/
│   ├── balance_card.dart            ← Wallet/total balance display (count-up anim)
│   ├── transaction_card.dart        ← One transaction list tile (icon, title, amount, date)
│   ├── budget_progress_card.dart    ← Budget category card with animated progress bar
│   ├── goal_progress_card.dart      ← Savings goal card with progress ring
│   ├── insight_card.dart            ← Smart insight card (dismissible)
│   └── stat_card.dart               ← Income/Expense summary pair
├── lists/
│   ├── transaction_list_section.dart ← A date-grouped section of transactions
│   └── empty_state.dart              ← Lottie + title + subtitle + optional CTA
├── dialogs/
│   ├── app_bottom_sheet.dart        ← Standard draggable bottom sheet template
│   ├── confirm_dialog.dart          ← Destructive action confirmation (two-step)
│   ├── permission_rationale.dart    ← Pre-permission explanation dialog
│   └── pro_feature_dialog.dart      ← Paywall/upgrade nudge dialog
├── navigation/
│   ├── app_nav_bar.dart             ← StylishBottomBar with FAB notch + AppScaffoldShell
│   ├── expandable_fab.dart          ← Radial FAB with 3 bubbles (Expense/Mic/Income)
│   └── app_app_bar.dart             ← Standardised AppBar (title, back, actions)
├── feedback/
│   ├── shimmer_list.dart            ← Skeleton shimmer for any list width
│   ├── lottie_widget.dart           ← Preloaded Lottie player helper
│   └── snack_helper.dart            ← showSuccess / showError / showInfo helpers
└── pro/
    └── pro_badge.dart               ← Small "PRO" badge chip for premium features
```

### 24.3 Component Rules (Agent Must Follow)

1. **All text inside components uses `overflow: TextOverflow.ellipsis`** or `maxLines`.
2. **All cards have fixed/min height** — never let content collapse to 0 height.
3. **All icon + text rows use `Flexible` or `Expanded`** correctly.
4. **RTL is automatic** — use `EdgeInsetsDirectional` instead of LTRB.
5. **Dark mode is automatic** — all colors via `context.colors` or `context.appTheme`.
6. **Minimum tap targets** — all interactive components ≥ 48×48dp.
7. **Card internal padding** — always `AppSizes.md` (16dp) minimum.

### 24.4 Amount Input Rule

**ALL monetary amount inputs use `AmountInput` component — no exceptions.**

`AmountInput` uses a `TextFormField` with `currency_text_input_formatter` and the native keyboard (NOT a calculator-style keypad). Supports `compact: true` mode for inline card use (e.g., VoiceConfirmScreen editable cards).

```dart
// ✅ CORRECT — uses AmountInput with native keyboard
AmountInput(
  onAmountChanged: (int piastres) => ref.read(formProvider.notifier).setAmount(piastres),
  initialPiastres: currentAmount,
  currencySymbol: 'ج.م',
)

// ✅ ALSO CORRECT — compact mode for inline card use
AmountInput(
  onAmountChanged: (int piastres) => setState(() => _amount = piastres),
  initialPiastres: currentAmount,
  compact: true,
)

// ❌ WRONG — raw TextField without AmountInput wrapper
TextField(keyboardType: TextInputType.number, ...)
```

---

## 25. AI Integration Layer (Feature-Flagged, Privacy-First)

> AI features are ACTIVE via OpenRouter with ZDR (Zero Data Retention) enforced on all requests. The API key is injected at build time via `--dart-define=OPENROUTER_API_KEY=...`. When no key is provided, the app gracefully falls back to rule-based parsing. All AI features remain gated by `AiConfig`.

### 25.1 Feature Flag & Config

```dart
// File: lib/core/config/ai_config.dart
abstract final class AiConfig {
  static const bool isEnabled = true;
  static const String openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
  static const String defaultModel = modelGeminiFlash;

  // Model IDs
  static const String modelGeminiFlash = 'google/gemini-2.0-flash-001';
  static const String modelGemma27b = 'google/gemma-3-27b-it:free';
  static const String modelQwen3_4b = 'qwen/qwen3-4b:free';

  // Priority-ordered fallback chain for Auto mode
  static const List<String> fallbackChain = [modelGeminiFlash, modelGemma27b, modelQwen3_4b];

  static const int apiTimeoutSeconds = 15;
  static const int maxResponseTokens = 1024;
  static bool get hasApiKey => openRouterApiKey.isNotEmpty;
}
```

### 25.2 AI Voice Parsing Flow (Multi-Model Fallback)

```
User speaks → speech_to_text (on-device STT, live transcript)
    ↓ user taps Done
[Has API key?]
  NO → VoiceTransactionParser.parseAll() (rule-based fallback)
  YES → [Model preference == "auto"?]
    YES → models = [Gemini Flash, Gemma 27B, Qwen3 4B]
    NO  → models = [selected model]
    ↓
  for model in models:
    try OpenRouter chatCompletion(model) → parse JSON → return drafts
    on error → log, try next model
  all failed → rule-based fallback
    ↓
VoiceConfirmScreen (user review — never auto-save)
```

### 25.3 AI SMS/Notification Enrichment

```
Notification/SMS received → regex parse (amount, type)
    ↓
[Has API key?]
  YES → AiTransactionParser.enrich(sender, body, amount, type, categories)
      → Qwen3 4B (free, fastest) → JSON {category_icon, merchant, note, confidence}
      → Store in aiEnrichmentJson column
  NO  → aiEnrichmentJson = null (regex data only)
    ↓
SmsParserLogs (pending, with optional AI enrichment)
    ↓
ParserReviewScreen (shows AI-suggested category + merchant if available)
    ↓ user taps Approve
Transaction created with AI-matched category (or default if no AI data)
```

**Key files:**
- `lib/core/services/ai/openrouter_service.dart` — HTTP client with ZDR enforcement
- `lib/core/services/ai/ai_voice_parser.dart` — Voice parsing with multi-model fallback chain
- `lib/core/services/ai/ai_transaction_parser.dart` — SMS/notification AI enrichment
- `lib/shared/providers/ai_provider.dart` — Riverpod providers for AI services

### 25.4 Current AI Packages

```yaml
http: ^1.2.2  # OpenRouter API calls
```

### 25.5 AI Features Status

| Feature | Implementation | Status |
|---|---|---|
| Voice parser (multi-model fallback) | OpenRouter (Gemini Flash → Gemma 27B → Qwen3 4B) | **ACTIVE** |
| SMS/notification enrichment | OpenRouter (Qwen3 4B, free) | **ACTIVE** |
| Settings model picker | Auto / individual model selection | **ACTIVE** |
| ZDR privacy enforcement | `provider.zdr: true` on all API requests | **ACTIVE** |
| Smart category prediction | On-device ML Kit text classifier | Planned |
| Monthly spending insights | LLM summarization | Planned |

---

## 26. Monetization & Subscription Infrastructure

> The app is architecturally ready for subscriptions/IAP. All premium features are gated by `EntitlementService.hasPro`. Implementing actual billing requires only wiring up RevenueCat.

### 26.1 Use `purchases_flutter` (RevenueCat)

```yaml
# Add when monetization feature is being implemented — NOT before
purchases_flutter: ^8.0.0
in_app_purchase: ^3.2.0
```

### 26.2 Entitlement System

```dart
abstract class EntitlementService {
  bool get hasPro;
  String get planName;
  Future<void> restorePurchases();
}

const bool kMonetizationEnabled = false;

class FreeEntitlementService implements EntitlementService {
  @override bool get hasPro => true;
  @override String get planName => 'free';
  @override Future<void> restorePurchases() async {}
}
```

### 26.3 Features Earmarked for Pro Tier

| Feature | Free | Pro |
|---|---|---|
| Manual transaction tracking | ✅ Unlimited | — |
| Voice input | ✅ | — |
| SMS/Notification parser | ✅ | — |
| Wallets | Up to 3 | ✅ Unlimited |
| Budgets | Up to 3 categories | ✅ Unlimited |
| Savings goals | Up to 3 | ✅ Unlimited |
| CSV/PDF export | ✅ Basic CSV | ✅ PDF + advanced |
| AI-powered insights | ❌ | ✅ |
| Google Drive backup | ❌ | ✅ |
| Home screen widgets | ❌ | ✅ |
| Custom themes | ❌ | ✅ |

> ⚠️ These limits are illustrative only. When `kMonetizationEnabled = false`, all features are fully accessible.

---

*This AGENTS.md is the single source of truth for any AI coding agent working on Masarify. Read it completely before writing any code. For product context, refer to `PRD.md`. For task sequence, refer to `TASKS.md`.*
