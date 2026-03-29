# Architecture

Masarify uses Clean Architecture with feature-first organization, Riverpod for state management, and Drift for persistence.

## Layer Structure

```
lib/
  app/           App shell: MaterialApp, router, theme
  core/          Platform services, utilities, constants, extensions
  data/          Drift database, DAOs, repository implementations, seed data
  domain/        Pure Dart entities + repository interfaces (zero Flutter imports)
  features/      18 feature modules, each with screens + widgets + providers
  shared/        Global providers (24), reusable widgets, shared models
```

### Domain Layer (`lib/domain/`)

Pure Dart only — no Flutter, no Drift. Defines business objects and repository contracts.

**11 Entities:**
`budget_entity`, `category_entity`, `chat_message_entity`, `goal_contribution_entity`, `recurring_rule_entity`, `savings_goal_entity`, `sms_parser_log_entity`, `transaction_entity`, `transfer_entity`, `wallet_entity`, `wallet_type`

**9 Repository Interfaces:**
`i_budget_repository`, `i_category_repository`, `i_chat_message_repository`, `i_goal_repository`, `i_recurring_rule_repository`, `i_sms_parser_log_repository`, `i_transaction_repository`, `i_transfer_repository`, `i_wallet_repository`

### Data Layer (`lib/data/`)

Drift database (SQLite), DAOs, and repository implementations.

- `database/app_database.dart` — Schema v14, 14 tables, 13 DAOs
- `database/tables/` — 14 Drift table definitions
- `database/daos/` — 13 type-safe DAOs (one per table, except GoalContributions shares with GoalDao)
- `repositories/` — 9 implementations matching domain interfaces
- `seed/category_seed.dart` — 34 default categories (28 expense + 6 income)

### Core Layer (`lib/core/`)

Platform services and shared utilities.

| Directory | Contents |
|-----------|----------|
| `config/` | Feature flags (`kSmsEnabled`, `kMonetizationEnabled`) |
| `constants/` | `AppSizes`, `AppIcons`, `AppDurations`, `AppRoutes`, `AppNavigation`, `brand_registry`, `egyptian_sms_patterns`, `voice_dictionary` |
| `services/` | 16 core services + `ai/` subdir with 13 AI services |
| `utils/` | 12 utilities (`MoneyFormatter`, `ArabicNumberParser`, `WalletMatcher`, etc.) |
| `extensions/` | 4 extensions (`BuildContext`, `DateTime`, `FrequencyLabel`, `MonthName`) |

### Shared Layer (`lib/shared/`)

Global providers and reusable UI components.

**24 Providers** in `lib/shared/providers/`:
`activity`, `ai`, `analytics`, `background_ai`, `budget`, `calendar`, `category`, `chat`, `connectivity`, `database`, `goal`, `google_drive`, `hide_balances`, `home_filter`, `pending_transactions`, `preferences`, `recurring_rule`, `repository_providers`, `selected_account`, `smart_defaults`, `subscription`, `theme`, `transaction`, `wallet`

**8 Widget Categories** in `lib/shared/widgets/`:
`buttons/`, `cards/`, `feedback/`, `guards/`, `inputs/`, `lists/`, `navigation/`, `sheets/`

### App Layer (`lib/app/`)

Application shell and configuration.

- `app.dart` — `MasarifyApp` root widget (ProviderScope + MaterialApp.router)
- `router/app_router.dart` — go_router with 45+ routes, 4-tab StatefulShellRoute
- `theme/` — `app_theme.dart`, `app_colors.dart`, `app_text_styles.dart`, `app_theme_extension.dart`

## Data Flow

```
UI (ConsumerWidget)
  ↓ ref.watch()
Provider (StreamProvider / FutureProvider)
  ↓
Repository Implementation
  ↓
DAO (Drift @DriftAccessor)
  ↓
Drift Database (SQLite)
  ↓ (stream)
DAO → Repository → Provider → UI rebuild
```

All data flows are reactive. Drift emits streams on table changes, which propagate through DAOs → repositories → Riverpod providers → UI rebuilds automatically.

## Provider Cascade

```
database_provider (AppDatabase singleton)
  ↓
repository_providers (9 repositories, each taking DB ref)
  ↓
feature providers (wallet_provider, transaction_provider, etc.)
  ↓
screens (ref.watch for reactive, ref.read for actions)
```

## Key Patterns

### Money Handling
All monetary values stored as `int` piastres (100 EGP = 10000). Display via `MoneyFormatter` only. Never `double`.

### Transfer Visibility
`TransferAdapter` converts `Transfer` records into `TransactionEntity` pairs with negative IDs. Activity providers merge transaction + transfer streams via `Rx.combineLatest`, so transfers appear in all transaction lists.

### Account Archiving
Wallets have an `isArchived` flag. Archived wallets are invisible everywhere (balance totals, transaction lists, analytics, AI context). Cash wallet is hidden from the Accounts screen. Default account is not deletable.

### Glass Morphism
3-tier system: Background (sigma 20, sheets/dialogs), Card (sigma 12, all cards), Inset (sigma 8, icon badges). Controlled by `GlassTier` enum + `GlassConfig`. Impeller is disabled on Android to avoid BackdropFilter grey overlay.

### AI Services
- **Voice:** Gemini 2.5 Flash (Google AI Studio REST) — audio → transcription + JSON parsing
- **Chat:** OpenRouter (Gemma/Qwen free) — financial advice, SMS enrichment
- **Background:** 4 offline heuristics (auto-categorization, recurring detection, spending prediction, budget suggestions)

## Startup Sequence (`main.dart`)

1. `CrashLogService.initialize()` — error capture before anything else
2. `SharedPreferences.getInstance()` — pre-load for providers
3. `GlassConfig.initialize()` — glass tier detection
4. `NotificationService.initialize()` — push notification channels
5. `ProviderContainer` creation with prefs override
6. `seedDefaultCategories()` — 34 defaults if table empty
7. Mount `MasarifyApp` widget
8. `ensureSystemWalletExists()` — guarantee Cash wallet exists
9. `NotificationService.onNotificationTap` callback setup
10. `SubscriptionService.initialize()` — IAP listener
11. `RecurringScheduler.run()` — process overdue recurring rules
12. `SmsParserService.scanInbox()` — background SMS scan (Android, if enabled)
13. `NotificationService.getLaunchPayload()` — cold-start notification handling
