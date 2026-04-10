# Development Setup

## Prerequisites

- Flutter SDK >= 3.22.0 (stable channel)
- Dart SDK >= 3.3.0
- Android SDK with API 24+ (min) and API 35 (target)
- Java 17 (for Gradle)

## Quick Start

```bash
# Clone and install
git clone <repo-url>
cd Masarify-Plus
flutter pub get

# Generate code (Drift DAOs, Riverpod providers, Freezed models)
dart run build_runner build --delete-conflicting-outputs

# Verify
flutter analyze lib/   # Must show zero issues
flutter test           # 11 test files, 202+ test cases

# Run
flutter run
```

## API Keys

The app uses two AI services. Keys are passed via `--dart-define` at build time:

```bash
flutter run \
  --dart-define=OPENROUTER_API_KEY=sk-or-v1-... \
  --dart-define=GOOGLE_AI_API_KEY=AIzaSy...
```

| Service | Purpose | Required? |
|---------|---------|-----------|
| OpenRouter | AI chat, SMS enrichment | Optional (chat feature) |
| Google AI (Gemini) | Voice audio transcription + parsing | Optional (voice feature) |

Core features (transactions, budgets, goals) work 100% offline without any API keys.

## Build Commands

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install dependencies |
| `dart run build_runner build --delete-conflicting-outputs` | Code generation (after schema/model/provider changes) |
| `flutter analyze lib/` | Static analysis (must be zero issues) |
| `bash scripts/analyze.sh` | Full analysis (analyzer + DCM if licensed) |
| `bash scripts/analyze.sh dcm` | DCM lint analysis only |
| `flutter test` | Run all tests |
| `flutter build appbundle --release` | Play Store AAB |
| `bash scripts/build-release.sh` | Sideload APKs (split by ABI) |

## Release Process

1. `flutter analyze lib/` — zero issues
2. `flutter test` — all pass
3. Build:
   - **Play Store:** `flutter build appbundle --release` → upload AAB to Google Play Console
   - **Sideload:** `bash scripts/build-release.sh` → distribute `app-arm64-v8a-release.apk` (~20MB) via Google Drive or GitHub Releases
4. **NEVER** send APKs via WhatsApp/Telegram — they corrupt the V2 signature

## Project Structure

```
lib/
  main.dart                    Entry point
  app/
    app.dart                   MasarifyApp root widget
    router/app_router.dart     go_router (45+ routes, 4-tab shell)
    theme/                     Material Design 3 theming (4 files)
  core/
    config/app_config.dart     Feature flags
    constants/                 Design tokens (8 files)
    services/                  Core services (16) + AI services (13)
    utils/                     Utilities (12 files)
    extensions/                Dart extensions (4 files)
  data/
    database/
      app_database.dart        Drift schema v14
      tables/                  14 table definitions
      daos/                    13 DAOs
    repositories/              9 repository implementations
    seed/                      Default category seed (34 categories)
  domain/
    entities/                  11 pure Dart entities
    repositories/              9 abstract interfaces
    adapters/                  TransferAdapter
  features/                    18 feature modules (32 screens)
  shared/
    providers/                 24 global Riverpod providers
    widgets/                   8 widget categories
    models/                    Shared DTOs/view models
  l10n/
    app_en.arb                 English localization
    app_ar.arb                 Arabic localization
test/
  unit/                        10 unit test files
  widget_test.dart             1 widget test
scripts/
  analyze.sh                   Analysis (analyzer + DCM)
  build-release.sh             Release APK builder
```

## Android Configuration

| Setting | Value |
|---------|-------|
| `applicationId` | `com.masarify.app` |
| `minSdk` | 24 (Android 7.0) |
| `targetSdk` | 35 |
| `versionName` | `1.0.0` (from pubspec.yaml) |
| `versionCode` | `1` (from pubspec.yaml) |
| `namespace` | `com.masarify.masarify` |
| `Kotlin/Java target` | VERSION_17 |
| Impeller | Disabled (BackdropFilter compatibility) |

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `drift` | ^2.32.0 | Type-safe SQLite ORM |
| `flutter_riverpod` | ^2.6.1 | State management |
| `go_router` | ^17.0.0 | Declarative navigation |
| `fl_chart` | ^1.0.0 | Charts and analytics |
| `phosphor_flutter` | ^2.1.0 | Icon set |
| `flutter_markdown` | ^0.7.4+3 | AI message rendering |
| `in_app_purchase` | ^3.2.0 | Google Play Billing |
| `google_sign_in` | ^6.2.1 | Google Drive OAuth |
| `record` | ^6.2.0 | Voice audio capture |
| `local_auth` | ^3.0.0 | Biometric authentication |
| `flutter_local_notifications` | ^17.2.3 | Local push notifications |
| `rxdart` | ^0.28.0 | Reactive stream operators |

Full dependency list in `pubspec.yaml`.

## Code Generation

After modifying files with `@DriftDatabase`, `@DriftAccessor`, `@riverpod`, `@freezed`, or `@JsonSerializable` annotations:

```bash
dart run build_runner build --delete-conflicting-outputs
```

**Never edit `*.g.dart` or `*.freezed.dart` files directly.**

## Localization

After editing `lib/l10n/app_en.arb` or `lib/l10n/app_ar.arb`:

```bash
flutter gen-l10n
```

Always add keys to BOTH files simultaneously.
