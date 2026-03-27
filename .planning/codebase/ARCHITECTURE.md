# Masarify Architecture

## Overview

Masarify follows **Clean Architecture** with **feature-first organization**. All layers are decoupled through repository interfaces, enabling testability and maintainability.

## Layer Structure

### 1. **Domain Layer** (`lib/domain/`)
Pure Dart — zero Flutter/Drift imports. Houses business logic and contracts.

- **`entities/`** — Data models representing core business objects
  - `wallet_entity.dart`, `transaction_entity.dart`, `budget_entity.dart`, etc.
  - All money stored as `int` (piastres, never `double`)
  - No serialization logic — keep immutable and simple

- **`repositories/`** — Abstract interfaces (e.g., `i_wallet_repository.dart`)
  - Define contracts via `abstract interface class`
  - Input: entities and primitives only
  - Output: entities and streams
  - Never reference Flutter, Drift, or external packages

- **`usecases/`** — Business logic operations (optional; currently minimal)

- **`adapters/`** — Domain-specific utilities (e.g., `transfer_adapter.dart`)
  - Convert between domains (e.g., Transfer → paired TransactionEntity)

### 2. **Data Layer** (`lib/data/`)
Implementation of repositories and database access. Bridge between domain and UI.

- **`database/app_database.dart`** — Drift-generated SQLite schema (v13)
  - 13 tables: Wallets, Categories, Transactions, Transfers, Budgets, SavingsGoals, etc.
  - Auto-generated via `dart run build_runner build --delete-conflicting-outputs`

- **`database/daos/`** — Drift Data Access Objects
  - Auto-generated from `@DriftAccessor` annotations
  - Return Drift entities (not domain entities)
  - Methods: `watchAll()`, `insertOne()`, `updateOne()`, `deleteWhere()`, etc.

- **`database/tables/`** — Drift table definitions
  - `wallets_table.dart`, `transactions_table.dart`, etc.
  - Define schema: columns, types, constraints

- **`repositories/`** — Implementations of domain interfaces
  - **Pattern:** `RepositoryImpl(dao, database, ...)`
  - Convert Drift entities → domain entities
  - Inject DAOs via constructor; watch streams in real-time
  - Example: `WalletRepositoryImpl(walletDao, database)`

- **`models/`** — Drift-generated model classes
  - Auto-generated from table definitions
  - Use `@freezed` + `@DriftEntity` for code generation

- **`services/`** — Specialized services
  - `backup_service_impl.dart` — Export/import JSON
  - `pdf_export_service.dart` — Generate transaction reports
  - No direct UI dependency; integrate via providers

- **`seed/`** — Database initialization
  - `category_seed.dart` — Default categories (34 items)
  - Runs once on first launch via `seedDefaultsIfEmpty()`

### 3. **Core Layer** (`lib/core/`)
Shared utilities, constants, and services. Never imports features or data layer.

- **`config/app_config.dart`** — Feature flags
  - `kMonetizationEnabled`, `kSmsEnabled`, `AiConfig.isEnabled`
  - Centralized for easy toggles

- **`constants/`** — Design tokens and navigation constants
  - `app_icons.dart` — Phosphor icon constants (`AppIcons.*`)
  - `app_sizes.dart` — Padding, margins, border radius (`AppSizes.*`)
  - `app_durations.dart` — Animation & transition durations
  - `app_navigation.dart` — Bottom nav tabs, routes
  - `app_routes.dart` — Go_router path names
  - `brand_registry.dart` — Egyptian brands with keywords
  - `voice_dictionary.dart` — SMS/voice parsing patterns

- **`services/`** — Platform and system services
  - **AI services** (`services/ai/`): `ai_chat_service.dart`, `gemini_audio_service.dart`, `recurring_pattern_detector.dart`
  - **Platform services**: `notification_service.dart`, `connectivity_service.dart`, `app_lock_service.dart`
  - **Parsers**: `sms_parser_service.dart`, `notification_transaction_parser.dart`
  - **Utilities**: `recurring_scheduler.dart`, `nudge_service.dart`, `subscription_service.dart`

- **`utils/`** — Pure Dart helpers
  - `money_formatter.dart` — Display piastres as EGP (INTEGER only)
  - `category_icon_mapper.dart` — Category → icon mapping
  - `voice_transaction_parser.dart` — Parse Gemini transcripts
  - `wallet_resolver.dart` — Smart account selection
  - `subscription_detector.dart` — Detect recurring transactions

- **`extensions/`** — Dart extension methods
  - Add convenience methods to built-in types

### 4. **Shared Layer** (`lib/shared/`)
Cross-feature reusable widgets, models, and providers. Never feature-specific.

- **`providers/`** — Global Riverpod providers
  - `database_provider.dart` — Single `AppDatabase` instance
  - `repository_providers.dart` — All repo providers (`walletRepositoryProvider`, etc.)
  - `theme_provider.dart` — Theme mode (light/dark), locale
  - `background_ai_provider.dart` — AI background services (categorization, recurring detection, predictions)
  - Feature providers: `transaction_provider.dart`, `wallet_provider.dart`, `chat_provider.dart`

- **`widgets/`** — Reusable UI components
  - `cards/` — `TransactionCard`, `BudgetProgressCard`
  - `buttons/` — Common button styles
  - `inputs/` — Form inputs (text fields, pickers)
  - `lists/` — `TransactionListSection` (multi-day grouping)
  - `sheets/` — Bottom sheets (wallet picker, category picker)
  - `navigation/` — `AppNavBar` (custom floating glassmorphic bar)
  - `feedback/` — Snackbars, dialogs, loaders
  - `guards/` — `RoutGuard` (auth redirect)

- **`models/`** — Shared DTO/view models
  - Not domain entities; UI-specific structures
  - Example: `ChatMessage` for UI display

### 5. **Features Layer** (`lib/features/`)
Feature-first: each feature is a vertical slice with its own presentation & state.

**Structure per feature:**
```
features/{feature_name}/
├── presentation/
│   ├── screens/          # Full-screen widgets (ConsumerWidget/ConsumerStatefulWidget)
│   ├── widgets/          # Feature-specific components (split by responsibility)
│   └── providers.dart    # Feature state (StreamProvider, FutureProvider, StateNotifierProvider)
├── [data/]               # Optional: feature-specific queries (rarely used; favor repos)
└── [domain/]             # Optional: feature-specific entities (rare)
```

**Key features:**
- **`dashboard/`** — Home screen with account carousel, zones, insight cards
- **`transactions/`** — Add/view transactions; filters (expense, income, transfer)
- **`wallets/`** — Account management, archiving, reordering, transfer flow
- **`recurring/`** — Subscriptions & Bills (DB: `RecurringRules` table)
- **`categories/`** — Category CRUD, search picker, icon/color assignment
- **`budgets/`** — Budget CRUD, progress cards, overspend alerts
- **`goals/`** — Savings goals, contributions, tracking
- **`ai_chat/`** — Chat interface; message bubbles; action cards (create transaction, transfer, budget)
- **`voice_input/`** — Audio recording, Gemini transcription, voice confirm screen
- **`sms_parser/`** — Review parsed SMS transactions, bulk import, enrichment
- **`onboarding/`** — 5-page setup (Account Type, Account Creation, AI Intro, Settings, Starting Balance)
- **`settings/`** — App settings, notifications, backups, theme/locale
- **`monetization/`** — Paywall, subscription management, IAP integration
- **`auth/`** — PIN setup & verification
- **`calendar/`**, **`reports/`**, **`hub/`**, **`quick_start/`** — Supporting features

### 6. **App Layer** (`lib/app/`)
Entry point configuration and routing.

- **`app.dart`** — `MasarifyApp` root widget
  - Configures `MaterialApp.router`
  - Manages theme (light/dark), locale (en/ar), L10n delegates
  - Auto-lock on resume if PIN enabled

- **`router/app_router.dart`** — Go_router configuration
  - 25+ routes defined
  - Transition builders: fade for navigation, slide-up for add/create screens
  - Root and shell navigators for tab persistence
  - Redirect guard for auth/lock screens

- **`theme/`** — Material Design 3 theming
  - `app_theme.dart` — Light & dark ThemeData builders
  - `app_colors.dart` — Color palette (Minty Fresh light, Gothic Noir dark)
  - `app_text_styles.dart` — Typography (Plus Jakarta Sans)
  - `app_theme_extension.dart` — Custom theme tokens (glass tiers, extended colors)

## Data Flow

### Reactive Stream Pattern
```
┌─────────────────────────────────────┐
│  Presentation (ConsumerWidget)      │
│  ref.watch(walletProvider)          │
└──────────────────┬──────────────────┘
                   │
┌─────────────────────────────────────┐
│  Riverpod Provider                  │
│  StreamProvider / FutureProvider    │
│  Repos via ref.watch(walletRepo)    │
└──────────────────┬──────────────────┘
                   │
┌─────────────────────────────────────┐
│  Repository Interface               │
│  IWalletRepository.watchAll()       │
│  Returns Stream<List<WalletEntity>> │
└──────────────────┬──────────────────┘
                   │
┌─────────────────────────────────────┐
│  Repository Implementation          │
│  WalletRepositoryImpl                │
│  Converts Drift → domain entities   │
└──────────────────┬──────────────────┘
                   │
┌─────────────────────────────────────┐
│  DAO (Data Access Object)           │
│  WalletDao.watchAll()               │
│  Returns Stream<List<WalletData>>   │
└──────────────────┬──────────────────┘
                   │
┌─────────────────────────────────────┐
│  Drift Database (SQLite)            │
│  AppDatabase                        │
└─────────────────────────────────────┘
```

## Navigation

**Router:** `go_router` only. Never `Navigator.push()`.

- **Tab routes:** Home, Transactions, Analytics, More (via `AppNavBar`)
- **Stack routes:** Modal dialogs, detail screens (via `context.push()`)
- **Redirect:** Guard checks auth/lock status; redirects to PIN entry
- **Cold start:** Splash → Onboarding (if first launch) → Home
- **Transitions:** Fade (default), Slide-up (add/create screens)

## Key Abstractions

### Repository Pattern
All domain contracts via interfaces in `domain/repositories/`:
- `IWalletRepository` → `WalletRepositoryImpl`
- `ITransactionRepository` → `TransactionRepositoryImpl`
- `ICategoryRepository` → `CategoryRepositoryImpl`
- Enables mocking in tests; decouples presentation from data layer

### Provider Cascade
1. **Database provider** — Singleton `AppDatabase`
2. **DAO providers** — Drift DAOs from database
3. **Repository providers** — Impl instances from DAOs
4. **Feature providers** — Streams/futures using repos

### Design System
- **Tokens:** `context.colors.*`, `AppIcons.*`, `AppSizes.*` (never hardcode)
- **Widgets:** `MasarifyDS` components in `shared/widgets/`
- **Theme:** Single source of truth in `app/theme/`
- **Glass:** 3-tier morphism via `GlassConfig` + `GlassTier` enum

## Build & Code Generation

**Triggers build_runner:**
1. Any schema/table change → `flutter pub get` + `dart run build_runner build`
2. Any `@freezed` or `@Drift` annotation → same
3. Any `.arb` L10n change → `flutter gen-l10n`

**Post-analysis check:** `flutter analyze lib/` (must be zero issues)

## Offline-First Design

- All data stored locally in Drift (SQLite)
- No Firebase or internet required for core features
- Background services (AI chat, SMS enrichment) marked as optional
- Connectivity detected via `connectivity_service.dart`; app shows offline banner if needed

## Summary

- **Clean layering:** domain (pure) → data (Drift) → presentation (Riverpod)
- **Feature-first:** Vertical slices with isolated state via providers
- **Reactive:** Streams propagate data changes; UI always in sync
- **Design tokens:** Centralized constants; no hardcoding
- **Money:** Always `int` piastres; never `double`
- **Offline-first:** SQLite + local services; no internet required
- **RTL-ready:** All screens validated in Arabic
