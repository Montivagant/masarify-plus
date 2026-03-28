# Masarify-Plus — Claude Code Configuration

## Project
**Masarify (مصاريفي)** — Offline-first personal finance tracker for Android/iOS.
Flutter + Dart | Clean Architecture + Riverpod 2.x | Drift (SQLite) | Material Design 3.
See `MEMORY.md` at `C:\Users\omarw\.claude\projects\d--Masarify-Plus\memory\MEMORY.md` for full project context.

## MCP Tool Roster

### Flutter Development
| Tool | Use For | Windows Status |
|------|---------|----------------|
| `dart` (official) | Package search (`pub_dev_search`) works. **Analyzer/formatter/fix tools BROKEN** — use `flutter analyze lib/` via Bash instead | Partial |
| `dcm` | **ALL tools BROKEN on Windows** — use `bash scripts/analyze.sh dcm` instead | Broken |
| `flutter-inspector` | Live app inspection: screenshots, errors, view details. Requires `flutter run --dds-port=8181 --disable-service-auth-codes` | OK |
| `context7` | Real-time library docs for any package (Riverpod, Drift, go_router, fl_chart, etc.) | OK |

### Reasoning
| Tool | Use For |
|------|---------|
| `sequential-thinking` | Multi-step structured reasoning — architecture decisions, complex debugging, refactoring plans |

### Visualization
| Tool | Use For |
|------|---------|
| `excalidraw` | Architecture diagrams, wireframes, ERDs |
| `mcp-mermaid` / `claude-mermaid` | Sequence diagrams, flowcharts, state machines |
| `draw-uml` | UML class/package diagrams |
| `antv-chart` / `quickchart` | Data charts, analytics visualizations |

### Documentation
| Tool | Use For |
|------|---------|
| `md-to-pdf` | Export markdown to PDF |
| `mcp-pandoc` | Convert between document formats |

### External Services
| Tool | Use For |
|------|---------|
| `firebase` | Firebase project management |
| `Atlassian` | Jira/Confluence |
| `Notion` | Workspace docs/tasks |
| `Gmail` | Email |

## Slash Commands (Workflow Modes)
| Command | Purpose |
|---------|---------|
| `/flutter-dev` | Flutter development — `flutter analyze` (Bash), `scripts/analyze.sh`, context7, live inspector |
| `/think` | Structured reasoning for architecture decisions and complex problems |
| `/review` | Code review — `scripts/analyze.sh`, `flutter analyze` (Bash), architecture audit |
| `/diagram` | Generate architecture diagrams, flows, ERDs |
| `/ship` | Release preparation checklist and build pipeline |
| `/audit` | Full 9-category surgical codebase audit |

## Auto-Workflow Selection

Automatically select the right workflow based on prompt context — no slash command needed:

| If the prompt... | Activate workflow | Key tools |
|-----------------|-------------------|-----------|
| Asks to write, modify, fix, or add Dart/Flutter code | **flutter-dev** | `flutter analyze` (Bash), `scripts/analyze.sh`, `context7` |
| Asks "should we...", "how should...", or involves a design/architecture decision | **think** | `sequential-thinking` |
| Says "review", "check", "audit", or "what's wrong with" | **review** | `scripts/analyze.sh`, `flutter analyze` (Bash), Grep |
| Says "build", "release", "deploy", "ship", or "publish" | **ship** | `flutter analyze` (Bash), build commands |
| Asks to "draw", "diagram", "visualize", "map out", or "show me" a structure | **diagram** | `excalidraw`, `mermaid`, `draw-uml` |
| Asks about a package API, widget usage, or "how does X work" | **docs lookup** | `context7` for live docs |
| Involves debugging a running app, screenshots, or runtime errors | **inspect** | `flutter-inspector` (requires running app) |

When multiple workflows apply (e.g., "fix this bug and review the result"), chain them: code first with **flutter-dev**, then verify with **review**.

## GSD (Get Shit Done) — Spec-Driven Development

GSD is installed locally (`.claude/get-shit-done/`). It provides phase-based, spec-driven development with fresh-context subagents.

### When to use GSD vs existing workflows
| Scenario | Use |
|----------|-----|
| Multi-step feature with 3+ files | `/gsd:plan-phase` → `/gsd:execute-phase` |
| Quick bug fix or small change | `/gsd:fast` or `/flutter-dev` directly |
| Ad-hoc task with state tracking | `/gsd:quick` |
| New milestone/project phase | `/gsd:new-milestone` |
| Existing workflow (analyze, review) | `/flutter-dev`, `/review`, `/audit` as before |

### Key GSD commands
- `/gsd:new-project` — Initialize project (creates PROJECT.md, REQUIREMENTS.md, ROADMAP.md)
- `/gsd:plan-phase <N>` — Research + create atomic plans for phase N
- `/gsd:execute-phase <N>` — Execute plans in parallel waves with fresh contexts
- `/gsd:verify-work` — User acceptance testing
- `/gsd:next` — Auto-advance to next workflow step
- `/gsd:quick` — Ad-hoc task with GSD guarantees (atomic commits, state tracking)
- `/gsd:fast` — Trivial inline task, no subagents

### GSD state files (in `.planning/`)
PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.md — automatically managed. Do not manually edit.

## Automated Hooks (run automatically — no action needed)

These hooks fire deterministically without Claude needing to "remember":
- **Post-edit:** `dart format` runs on every `.dart` file after Edit/Write
- **Post-coding:** `flutter analyze lib/` runs on Stop (warns but does not block)
- **Pre-compact:** Critical project context re-injected before context compaction
- **Context monitor:** GSD warns agent when context window is running low (35%/25% thresholds)
- **Prompt guard:** GSD scans `.planning/` writes for injection patterns
- **Notifications:** Windows toast when Claude needs your input

## The 5 Critical Rules (Never Violate)
1. **Money = INTEGER piastres.** `100 EGP = 10000`. Never double. `MoneyFormatter` for display.
2. **100% offline-first.** No Firebase/internet for core features.
3. **RTL-first.** Every screen validated in Arabic RTL.
4. **Design tokens are LAW.** `context.colors`, `AppIcons.*`, `AppSizes.*`, `context.appTheme.*` — NEVER hardcode.
5. **MasarifyDS components always.** Never build layout primitives inline in screen files.

## Architecture Rules
- `domain/` = pure Dart only (zero Flutter/Drift imports)
- Provider flow: `StreamProvider`/`FutureProvider` → Repository → DAO → Drift stream
- NEVER `setState` in screens (except AnimationController and ephemeral form state)
- NEVER `Navigator.push()` — use `context.go()` / `context.push()`
- Every screen: `ConsumerWidget` or `ConsumerStatefulWidget`
- Import ordering: `../../` before `../`

## Build Commands
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs  # After ANY schema/model/provider change
flutter analyze lib/                                       # Must be zero issues
bash scripts/analyze.sh                                    # Full analysis (analyzer + DCM if licensed)
flutter test
flutter build appbundle --release                          # Play Store (AAB)
bash scripts/build-release.sh                              # Sideload APKs (split by ABI)
```

## Known Issues (Windows)

### dart/dcm MCP tools broken on Windows
**Bug:** Claude Code registers project roots as `file://D:\path` (2 slashes, backslashes) instead of `file:///D:/path` (3 slashes, forward slashes per RFC 8089). All MCP tools requiring the `roots` parameter fail.

**Impact:** `dart` MCP (analyzer, formatter, fix, test) and `dcm` MCP (analyze, unused code, metrics) — ALL root-dependent tools are unusable.

**Workaround:** Use CLI commands via Bash instead:
- `flutter analyze lib/` — replaces `dart` MCP analyzer
- `bash scripts/analyze.sh` — full analysis (analyzer + DCM)
- `bash scripts/analyze.sh dcm` — DCM lint analysis only
- `bash scripts/analyze.sh dcm-unused` — DCM unused code check
- `dart` MCP `pub_dev_search` still works (no filesystem access needed)

**Upstream:** https://github.com/anthropics/claude-code/issues — file URI format on Windows

## Quick MCP Setup (for fresh install)
```bash
# Core Flutter tooling (project-scoped)
claude mcp add dart -s local -- dart mcp-server
claude mcp add dcm -s local -- dcm start-mcp-server --client=claude-code
claude mcp add flutter-inspector -s local -- bash "$HOME/Developer/mcp_flutter/flutter-inspector-start.sh" --no-resources --images

# Reasoning (global)
# sequential-thinking and context7 are installed as plugins — no manual setup needed

# Run Flutter app for live inspection
flutter run --host-vmservice-port=8182 --dds-port=8181 --disable-service-auth-codes
```

<!-- GSD:project-start source:PROJECT.md -->
## Project

**Masarify (مصاريفي)**

An offline-first personal finance tracker for Android (Play Store first, iOS second) targeting Egyptian young professionals. Users track income, expenses, transfers, budgets, and savings goals — with an AI Financial Advisor powered by Gemini that handles voice input, spending recaps, and intelligent categorization. Built with Flutter/Dart, Clean Architecture, Riverpod 2.x, and Drift (SQLite).

**Core Value:** **Every transaction recorded effortlessly, offline, in Arabic or English — with an AI advisor that makes spending visible and actionable.** If everything else fails, recording transactions via voice and seeing where money goes must work.

### Constraints

- **Tech Stack**: Flutter/Dart, Riverpod, Drift, go_router — already established, no changes
- **Offline-First**: Core features must work without internet. AI features gracefully degrade
- **Money Format**: Integer piastres always (100 EGP = 10000). MoneyFormatter for display
- **RTL-First**: Every screen must work in Arabic RTL. No hardcoded directional values
- **Design Tokens**: AppIcons, AppSizes, AppColors, context.colors — never hardcode
- **Min SDK**: API 24 (Android 7.0) — covers 99% of Egyptian market
- **Impeller Disabled**: BackdropFilter (glassmorphism) causes grey overlay with Impeller on Android
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Language & Runtime
- **Dart:** `>=3.3.0 <4.0.0`
- **Flutter:** `>=3.22.0`
- **Minimum Android SDK:** API 24 (supports 99% of market)
- **Build System:** Flutter Gradle + Dart build_runner
## Core Framework & State Management
### Flutter & Navigation
- **UI Framework:** Flutter with Material Design 3
- **Navigation:** `go_router: ^14.3.0` — declarative routing, no Navigator.push()
- **Animations:** `flutter_animate: ^4.5.0`
### State Management
- **Riverpod:** `flutter_riverpod: ^2.6.1`
- **Code Generation:** `riverpod_generator: ^2.6.1`
- **Pattern:** Feature-scoped providers → StreamProvider/FutureProvider → Repository → DAO → Drift
- **Key Providers:** `lib/shared/providers/` — database_provider, repository_providers, theme_provider, activity_provider
## Database
### Drift ORM + SQLite
- **Drift:** `^2.20.0` (immutable, strongly-typed query API)
- **Drift Flutter:** `^0.2.1`
- **SQLite:** `sqlite3_flutter_libs: ^0.5.0`
- **Schema Version:** 13 (wallets gained `sortOrder` for drag-and-drop reordering)
### Database Location
- **File:** `lib/data/database/app_database.dart`
- **13 Tables:** Wallets, Categories, Transactions, Transfers, Budgets, SavingsGoals, GoalContributions, RecurringRules, SmsParserLogs, ExchangeRates, CategoryMappings, ChatMessages, ParsedEventGroups
- **DAOs:** All in `lib/data/database/daos/` — typed, single-responsibility
- **Migrations:** v1→v13 tracked in `onUpgrade` with data transformations (e.g., Bills→RecurringRules merge at v4)
## UI & Design System
### Material Design 3 + Theming
- **Theme:** `lib/app/theme/app_theme.dart` — light (Mint #3DA37A) and dark (Purple #7B68AE)
- **Design Tokens:** Centralized in `lib/core/constants/`
- **Fonts:** Plus Jakarta Sans (Google Fonts)
- **Glass Morphism:** 3-tier hierarchy (Background σ20, Card σ12, Inset σ8) via `GlassConfig`
### UI Libraries
| Library | Version | Use Case |
|---------|---------|----------|
| `fl_chart` | ^0.69.0 | Monthly income/expense trends |
| `flutter_markdown` | ^0.7.4+3 | AI assistant message formatting |
| `shimmer` | ^3.0.0 | Skeleton loaders |
| `smooth_page_indicator` | ^1.2.0 | Onboarding carousel indicator |
| `flutter_slidable` | ^3.1.1 | Transaction swipe actions |
| `phosphor_flutter` | ^2.1.0 | Icon set (open-source) |
| `table_calendar` | ^3.1.2 | Date picker for budgets |
## Localization
### Dart Intl + ARB Format
- **intl:** `^0.20.0`
- **Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_ar.arb` (200+ keys)
- **Code-generated:** `lib/l10n/app_localizations.dart` → `flutter gen-l10n`
- **RTL:** Full Arabic support, all screens validated in RTL mode
## Security & Local Storage
### Authentication
- **Biometric:** `local_auth: ^2.3.0` (fingerprint, face unlock)
- **Secure Storage:** `flutter_secure_storage: ^9.2.2` (AES-256 per platform)
- **Encryption:** `encrypt: ^5.0.3` (AES-256-SIC for Drive backups)
- **Hashing:** `crypto: ^3.0.5`
### Preferences
- **SharedPreferences:** `^2.3.2` (theme, locale, notification settings)
- **Custom Service:** `PreferencesService` wraps SharedPreferences with typed getters
## Export & Sharing
| Library | Version | Format |
|---------|---------|--------|
| `pdf` | ^3.11.1 | PDF reports |
| `csv` | ^6.0.0 | CSV transaction exports |
| `file_picker` | ^8.1.2 | File selection (import backup) |
| `share_plus` | ^10.0.0 | iOS/Android share sheet |
## Notifications & Scheduling
### Local Notifications
- **flutter_local_notifications:** `^17.2.3` (Android channels + iOS UNUserNotificationCenter)
- **timezone:** `^0.9.4` (daily recap scheduling)
- **Service:** `NotificationService` in `lib/core/services/notification_service.dart`
## Device & Platform
- **package_info_plus:** `^8.1.0` (app version, build number)
- **device_info_plus:** `^11.0.0` (device hardware info for analytics)
- **permission_handler:** `^11.3.1` (SMS, microphone, location)
- **geolocator:** `^13.0.1` (location services)
- **geocoding:** `^3.0.0` (reverse geocoding)
## Audio & Voice
- **record:** `^6.2.0` (WAV audio capture, 16kHz mono, local only)
- **Integration:** Voice input → Gemini API → transaction parsing
- **Flow:** `VoiceInputSheet` records → GeminiAudioService sends to API → VoiceTransactionDraft returned
## HTTP & Networking
- **http:** `^1.2.2` (basic REST client)
- **connectivity_plus:** `^7.0.0` (online/offline detection)
- **Pattern:** Custom `OpenRouterService` and `GeminiAudioService` wrap http.Client
## AI & LLM Integration
### OpenRouter (Chat Completions)
- **Base URL:** `https://openrouter.ai/api/v1`
- **Service:** `lib/core/services/ai/openrouter_service.dart`
- **Models (Fallback Chain):**
- **Usage:** Financial advice chat, SMS enrichment, budget suggestions
- **Authentication:** Bearer token via `--dart-define=OPENROUTER_API_KEY=...`
### Google AI / Gemini Direct REST
- **Base URL:** `https://generativelanguage.googleapis.com/v1beta`
- **Service:** `lib/core/services/ai/gemini_audio_service.dart`
- **Model:** `gemini-2.5-flash` (audio transcription + JSON parsing)
- **Input:** WAV audio (base64 encoded) + system prompt
- **Output:** Structured `VoiceTransactionDraft` (JSON parsed)
- **Timeout:** 90s (accommodates large audio files ~2.5MB)
- **Authentication:** API key via `--dart-define=GOOGLE_AI_API_KEY=...`
## Monetization & IAP
- **in_app_purchase:** `^3.2.0` (Google Play Billing, iOS StoreKit)
- **Service:** `SubscriptionService` in `lib/core/services/subscription_service.dart`
- **Model:** Subscription-only (no ads)
- **Free Tier:** Unlimited txns, 2 budgets, 1 goal
- **Pro Tier:** 59-79 EGP/month (starting balance, SMS parsing future, brand icons)
- **Trial:** 7 days free
## Google Drive Backup
- **google_sign_in:** `^6.2.1` (OAuth 2.0)
- **googleapis:** `^14.0.0` (Drive API v3)
- **extension_google_sign_in_as_googleapis_auth:** `^2.0.12` (Dart auth bridge)
- **Service:** `GoogleDriveBackupService` in `lib/core/services/google_drive_backup_service.dart`
- **Scope:** `appDataFolder` (isolated, user-granted)
- **Encryption:** AES-256-SIC (key in secure storage)
## SMS & Local Parsing
- **another_telephony:** `^0.4.1` (Android SMS inbox access)
- **Feature Status:** Hidden in P5 (kSmsEnabled = false), code preserved for Pro re-enablement
- **Parsing:** Regex-based (no AI), local only
- **Enrichment:** Deferred to user action on review screen (OpenRouter fallback chain)
## Reactive Extensions
- **rxdart:** `^0.28.0` (advanced Rx operators: combineLatest, distinct, debounce)
- **Usage:** Activity providers merge transaction + transfer streams
## Build Tools (Dev Dependencies)
| Tool | Version | Purpose |
|------|---------|---------|
| `build_runner` | ^2.4.12 | Code generation (Drift, Riverpod, Freezed) |
| `drift_dev` | ^2.20.0 | Drift DAOs + migrations |
| `riverpod_generator` | ^2.6.1 | Riverpod code-gen |
| `freezed` | ^2.5.7 | Immutable model generation |
| `json_serializable` | ^6.8.0 | JSON serialization (fallback) |
| `flutter_lints` | ^4.0.0 | Analysis + style lint rules |
| `flutter_launcher_icons` | ^0.14.1 | Icon generation |
| `flutter_native_splash` | ^2.4.1 | Splash screen (Android + iOS) |
## Build Commands
# Dependencies
# Code generation (AFTER schema/provider/model changes)
# Analysis
# Testing
# Release builds
## Feature Flags
## Key Architecture Constraints
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## 1. Money Handling
### Storage
### Display
## 2. State Management (Riverpod 2.x)
### Screen Pattern
### Provider Usage
- Use `ref.watch()` for reactive, persistent state
- Use `ref.read()` for one-shot actions (button taps)
- Provider names: `(singular|plural)Provider` or `(noun)Provider`
- **NEVER** `setState` except for `AnimationController` tick or ephemeral form state
## 3. Navigation (go_router)
## 4. Design Tokens (Mandatory)
### Colors
### Spacing
### Icons
### Text & Borders
### Durations
## 5. Import Ordering
## 6. Localization (L10n)
### Adding New Strings
## 7. File & Class Naming
| Artifact | Pattern | Example |
|----------|---------|---------|
| **Screen** | `<feature>_screen.dart` | `dashboard_screen.dart`, `add_transaction_screen.dart` |
| **Widget** | `<name>_widget.dart` or `<name>.dart` | `account_carousel.dart`, `glass_card.dart` |
| **Provider** | `<domain>_provider.dart` | `wallet_provider.dart`, `transaction_provider.dart` |
| **Repository** | `<entity>_repository_impl.dart` | `wallet_repository_impl.dart` |
| **DAO** | `<entity>_dao.dart` | `wallet_dao.dart` |
| **Service** | `<purpose>_service.dart` or `<purpose>_service_impl.dart` | `ai_chat_service.dart`, `backup_service_impl.dart` |
| **Test** | `<unit>_test.dart` | `money_formatter_test.dart`, `budget_entity_test.dart` |
## 8. Error Handling
- Always check `if (!mounted)` before state changes post-await
- Use `SnackHelper.showError()` for user feedback (not `print()`)
- Log errors via service loggers, never console
- Fallback gracefully (e.g., use cached data if API fails)
## 9. Conditional Features & Feature Flags
## 10. Glass System & Theming
## Summary
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Overview
## Layer Structure
### 1. **Domain Layer** (`lib/domain/`)
- **`entities/`** — Data models representing core business objects
- **`repositories/`** — Abstract interfaces (e.g., `i_wallet_repository.dart`)
- **`usecases/`** — Business logic operations (optional; currently minimal)
- **`adapters/`** — Domain-specific utilities (e.g., `transfer_adapter.dart`)
### 2. **Data Layer** (`lib/data/`)
- **`database/app_database.dart`** — Drift-generated SQLite schema (v13)
- **`database/daos/`** — Drift Data Access Objects
- **`database/tables/`** — Drift table definitions
- **`repositories/`** — Implementations of domain interfaces
- **`models/`** — Drift-generated model classes
- **`services/`** — Specialized services
- **`seed/`** — Database initialization
### 3. **Core Layer** (`lib/core/`)
- **`config/app_config.dart`** — Feature flags
- **`constants/`** — Design tokens and navigation constants
- **`services/`** — Platform and system services
- **`utils/`** — Pure Dart helpers
- **`extensions/`** — Dart extension methods
### 4. **Shared Layer** (`lib/shared/`)
- **`providers/`** — Global Riverpod providers
- **`widgets/`** — Reusable UI components
- **`models/`** — Shared DTO/view models
### 5. **Features Layer** (`lib/features/`)
```
```
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
- **`app.dart`** — `MasarifyApp` root widget
- **`router/app_router.dart`** — Go_router configuration
- **`theme/`** — Material Design 3 theming
## Data Flow
### Reactive Stream Pattern
```
```
## Navigation
- **Tab routes:** Home, Transactions, Analytics, More (via `AppNavBar`)
- **Stack routes:** Modal dialogs, detail screens (via `context.push()`)
- **Redirect:** Guard checks auth/lock status; redirects to PIN entry
- **Cold start:** Splash → Onboarding (if first launch) → Home
- **Transitions:** Fade (default), Slide-up (add/create screens)
## Key Abstractions
### Repository Pattern
- `IWalletRepository` → `WalletRepositoryImpl`
- `ITransactionRepository` → `TransactionRepositoryImpl`
- `ICategoryRepository` → `CategoryRepositoryImpl`
- Enables mocking in tests; decouples presentation from data layer
### Provider Cascade
### Design System
- **Tokens:** `context.colors.*`, `AppIcons.*`, `AppSizes.*` (never hardcode)
- **Widgets:** `MasarifyDS` components in `shared/widgets/`
- **Theme:** Single source of truth in `app/theme/`
- **Glass:** 3-tier morphism via `GlassConfig` + `GlassTier` enum
## Build & Code Generation
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
<!-- GSD:architecture-end -->

<!-- GSD:profile-end -->
