# Masarify — Technology Stack

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

```dart
// Drift table declaration example (wallets_table.dart)
@DataClassName('WalletEntity')
class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get balance => integer()();  // piastres (100 EGP = 10000)
  TextColumn get currencyCode => text().withDefault(const Constant('EGP'))();
  IntColumn get sortOrder => integer().nullable()();  // v13: reordering
  BoolColumn get isSystemWallet => boolean().withDefault(const Constant(false))();
  BoolColumn get isDefaultAccount => boolean().withDefault(const Constant(false))();
}
```

## UI & Design System

### Material Design 3 + Theming
- **Theme:** `lib/app/theme/app_theme.dart` — light (Mint #3DA37A) and dark (Purple #7B68AE)
- **Design Tokens:** Centralized in `lib/core/constants/`
  - `app_icons.dart` — Phosphor Icons centralized
  - `app_sizes.dart` — spacing, borders, shadows
  - `app_colors.dart` — semantic tokens (error, success, etc.)
  - `app_durations.dart` — transitions, animations
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
  - `scheduleDaily()` — daily spending recap at user-set time
  - Tap callback → deep link to ChatScreen in recap mode
  - Notification ID collision avoidance (recap=99999, recurring=ruleId+100000)

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
  1. `google/gemini-2.0-flash-001` (paid, reliable)
  2. `google/gemma-3-27b-it:free` (fast free alternative)
  3. `qwen/qwen3-4b:free` (last resort)
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

```dart
// Voice → Gemini → Transaction example
final drafts = await GeminiAudioService().parseAudio(
  audioBytes: wavBytes,
  mimeType: 'audio/wav',
  categories: userCategories,
  goals: userGoals,
  walletNames: ['CIB', 'Vodafone Cash'],
);
```

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

```bash
# Dependencies
flutter pub get

# Code generation (AFTER schema/provider/model changes)
dart run build_runner build --delete-conflicting-outputs

# Analysis
flutter analyze lib/         # Must be zero issues
bash scripts/analyze.sh      # Full analysis + DCM lint

# Testing
flutter test

# Release builds
flutter build appbundle --release          # Play Store (AAB)
bash scripts/build-release.sh              # Split-per-ABI APKs (sideload)
```

## Feature Flags

```dart
// lib/core/config/app_config.dart
static const bool kSmsEnabled = false;           // Hidden (AI-first pivot)
static const bool kMonetizationEnabled = true;   // P5 active
```

## Key Architecture Constraints

1. **Money:** Always `int` (piastres). 100 EGP = 10000. Never `double`.
2. **Domain Layer:** Pure Dart only — zero Flutter/Drift imports.
3. **Offline-First:** No internet required for core features (transactions, budgets, goals).
4. **RTL:** Every screen validated in Arabic.
5. **No Navigation.push()** — go_router only.
6. **Design tokens mandatory** — `context.colors.*`, `AppIcons.*`, `AppSizes.*`.
