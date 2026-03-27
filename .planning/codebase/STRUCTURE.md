# Masarify Directory Structure & Conventions

## Directory Tree

```
lib/
├── main.dart                                # App entry point (crash logging, DB seed, notifications)
├── app/
│   ├── app.dart                             # MasarifyApp root widget (theme, l10n, router config)
│   ├── router/
│   │   └── app_router.dart                  # Go_router configuration (25+ routes)
│   └── theme/
│       ├── app_theme.dart                   # Light & dark ThemeData
│       ├── app_colors.dart                  # Color palette (Mint/Purple)
│       ├── app_text_styles.dart             # Typography
│       └── app_theme_extension.dart         # Custom glass/token themes
├── core/
│   ├── config/
│   │   └── app_config.dart                  # Feature flags (SMS, monetization, AI)
│   ├── constants/
│   │   ├── app_icons.dart                   # AppIcons.* (Phosphor)
│   │   ├── app_sizes.dart                   # AppSizes.* (padding, radius, spacing)
│   │   ├── app_durations.dart               # AppDurations.* (animations)
│   │   ├── app_navigation.dart              # Nav bar tabs, bottom padding
│   │   ├── app_routes.dart                  # Go_router path names
│   │   ├── brand_registry.dart              # Egyptian brands with keywords
│   │   └── voice_dictionary.dart            # SMS/voice patterns
│   ├── extensions/
│   │   └── *.dart                           # Extension methods on Dart types
│   ├── services/
│   │   ├── ai/                              # AI services
│   │   │   ├── ai_chat_service.dart         # Chat logic (OpenRouter)
│   │   │   ├── gemini_audio_service.dart    # Transcription (Gemini REST)
│   │   │   ├── recurring_pattern_detector.dart
│   │   │   ├── categorization_learning_service.dart
│   │   │   └── chat_action_executor.dart    # Execute AI-suggested actions
│   │   ├── app_lock_service.dart            # PIN lock state
│   │   ├── auth_service.dart                # Auth logic
│   │   ├── connectivity_service.dart        # Network detection
│   │   ├── glass_config_service.dart        # Glassmorphism blur settings
│   │   ├── notification_service.dart        # Notifications + daily recap scheduling
│   │   ├── preferences_service.dart         # Shared prefs wrapper
│   │   ├── recurring_scheduler.dart         # Recurring transaction cron
│   │   ├── sms_parser_service.dart          # SMS regex parsing
│   │   ├── subscription_service.dart        # IAP, trial, paywall
│   │   └── *.dart                           # Other platform/utility services
│   └── utils/
│       ├── money_formatter.dart             # Format piastres → EGP (int only)
│       ├── category_icon_mapper.dart        # Category → Phosphor icon
│       ├── voice_transaction_parser.dart    # Parse Gemini transcript
│       ├── wallet_resolver.dart             # Smart account selection
│       └── *.dart                           # Other utilities
├── data/
│   ├── database/
│   │   ├── app_database.dart                # Drift database (v13)
│   │   ├── daos/
│   │   │   ├── wallet_dao.dart              # WalletDao (Drift auto-gen)
│   │   │   ├── transaction_dao.dart
│   │   │   ├── category_dao.dart
│   │   │   ├── budget_dao.dart
│   │   │   ├── goal_dao.dart
│   │   │   ├── recurring_rule_dao.dart
│   │   │   ├── transfer_dao.dart
│   │   │   ├── sms_parser_log_dao.dart
│   │   │   ├── chat_message_dao.dart
│   │   │   └── *.dart                       # Other DAOs
│   │   └── tables/
│   │       ├── wallets_table.dart           # Drift table definition
│   │       ├── transactions_table.dart
│   │       ├── categories_table.dart
│   │       └── *.dart                       # Other tables
│   ├── repositories/
│   │   ├── wallet_repository_impl.dart      # Implements IWalletRepository
│   │   ├── transaction_repository_impl.dart
│   │   ├── category_repository_impl.dart
│   │   ├── budget_repository_impl.dart
│   │   ├── goal_repository_impl.dart
│   │   ├── recurring_rule_repository_impl.dart
│   │   ├── transfer_repository_impl.dart
│   │   ├── sms_parser_log_repository_impl.dart
│   │   ├── chat_message_repository_impl.dart
│   │   └── *.dart                           # Other implementations
│   ├── models/
│   │   └── *.dart                           # Drift-generated model classes
│   ├── services/
│   │   ├── backup_service_impl.dart         # Export/import JSON
│   │   ├── pdf_export_service.dart          # Generate reports
│   │   └── *.dart                           # Other data services
│   └── seed/
│       └── category_seed.dart               # Default categories (34 items)
├── domain/
│   ├── entities/
│   │   ├── wallet_entity.dart               # Pure Dart; int money
│   │   ├── transaction_entity.dart
│   │   ├── category_entity.dart
│   │   ├── budget_entity.dart
│   │   ├── goal_entity.dart
│   │   ├── recurring_rule_entity.dart
│   │   ├── transfer_entity.dart
│   │   ├── sms_parser_log_entity.dart
│   │   ├── chat_message_entity.dart
│   │   └── *.dart                           # Other entities
│   ├── repositories/
│   │   ├── i_wallet_repository.dart         # Abstract interface
│   │   ├── i_transaction_repository.dart
│   │   ├── i_category_repository.dart
│   │   ├── i_budget_repository.dart
│   │   ├── i_goal_repository.dart
│   │   ├── i_recurring_rule_repository.dart
│   │   ├── i_transfer_repository.dart
│   │   ├── i_sms_parser_log_repository.dart
│   │   ├── i_chat_message_repository.dart
│   │   └── *.dart                           # Other interfaces
│   ├── usecases/
│   │   └── *.dart                           # Business logic operations (optional)
│   └── adapters/
│       ├── transfer_adapter.dart            # Convert Transfer → pair of Transactions
│       └── *.dart                           # Other domain-specific utilities
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── dashboard_screen.dart    # Home screen (ConsumerWidget)
│   │       ├── widgets/
│   │       │   ├── account_carousel.dart
│   │       │   ├── insight_cards_zone.dart
│   │       │   ├── month_summary_zone.dart
│   │       │   ├── quick_add_zone.dart
│   │       │   └── *.dart                   # Feature-specific components
│   │       └── providers.dart               # Feature state (optional)
│   ├── transactions/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── add_transaction_screen.dart
│   │       │   └── transaction_detail_screen.dart
│   │       ├── widgets/
│   │       │   └── *.dart
│   │       └── providers.dart
│   ├── wallets/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── wallets_screen.dart
│   │       │   ├── add_wallet_screen.dart
│   │       │   ├── wallet_detail_screen.dart
│   │       │   └── transfer_screen.dart
│   │       ├── widgets/
│   │       │   └── *.dart
│   │       └── providers.dart
│   ├── recurring/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── recurring_screen.dart    # Subscriptions & Bills
│   │       │   └── add_recurring_screen.dart
│   │       └── widgets/
│   ├── categories/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── categories_screen.dart
│   │       │   └── add_category_screen.dart
│   │       └── widgets/
│   ├── budgets/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── budgets_screen.dart
│   │       │   └── set_budget_screen.dart
│   │       └── widgets/
│   ├── goals/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── goals_screen.dart
│   │       │   ├── add_goal_screen.dart
│   │       │   └── goal_detail_screen.dart
│   │       └── widgets/
│   ├── ai_chat/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── chat_screen.dart
│   │       └── widgets/
│   │           ├── message_bubble.dart
│   │           ├── action_card.dart
│   │           └── *.dart
│   ├── voice_input/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── voice_confirm_screen.dart
│   │       └── widgets/
│   ├── sms_parser/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── parser_review_screen.dart
│   │       └── widgets/
│   ├── onboarding/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── splash_screen.dart
│   │       │   └── onboarding_screen.dart
│   │       ├── widgets/
│   │       │   └── onboarding_pages.dart
│   │       └── providers.dart
│   ├── settings/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── settings_screen.dart
│   │       │   ├── notification_preferences_screen.dart
│   │       │   └── backup_export_screen.dart
│   │       └── widgets/
│   ├── monetization/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── paywall_screen.dart
│   │       │   └── subscription_screen.dart
│   │       └── widgets/
│   ├── auth/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── pin_setup_screen.dart
│   │       │   └── pin_entry_screen.dart
│   │       └── widgets/
│   ├── calendar/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── calendar_screen.dart
│   │       └── widgets/
│   ├── reports/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── reports_screen.dart
│   │       └── widgets/
│   ├── hub/
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── hub_screen.dart
│   │       └── widgets/
│   └── quick_start/
│       └── presentation/
│           ├── screens/
│           │   └── quick_start_screen.dart
│           └── widgets/
├── shared/
│   ├── providers/
│   │   ├── database_provider.dart           # Single AppDatabase instance
│   │   ├── repository_providers.dart        # All repo instances
│   │   ├── theme_provider.dart              # Theme mode, locale
│   │   ├── transaction_provider.dart        # Transaction queries
│   │   ├── wallet_provider.dart             # Wallet queries
│   │   ├── chat_provider.dart               # Chat state
│   │   ├── activity_provider.dart           # Activity feeds
│   │   ├── background_ai_provider.dart      # Background AI services
│   │   └── *.dart                           # Other shared providers
│   ├── widgets/
│   │   ├── cards/
│   │   │   ├── transaction_card.dart        # ReusableTransaction UI
│   │   │   ├── budget_progress_card.dart
│   │   │   └── *.dart
│   │   ├── buttons/
│   │   │   └── *.dart                       # Reusable button styles
│   │   ├── inputs/
│   │   │   ├── amount_input.dart
│   │   │   ├── category_picker.dart
│   │   │   └── *.dart
│   │   ├── lists/
│   │   │   ├── transaction_list_section.dart # Multi-day grouping
│   │   │   └── *.dart
│   │   ├── sheets/
│   │   │   ├── wallet_picker_sheet.dart
│   │   │   ├── category_picker_sheet.dart
│   │   │   └── *.dart
│   │   ├── navigation/
│   │   │   └── app_nav_bar.dart             # Custom floating tab bar
│   │   ├── feedback/
│   │   │   ├── loading_indicator.dart
│   │   │   └── *.dart
│   │   ├── guards/
│   │   │   └── route_guard.dart             # Auth redirect
│   │   └── [other]/
│   │       └── *.dart
│   └── models/
│       └── *.dart                           # Shared DTOs (not domain entities)
└── l10n/
    ├── app_en.arb                           # English strings (edit this)
    ├── app_ar.arb                           # Arabic strings (edit this)
    ├── app_localizations.dart               # Generated (dart gen-l10n)
    ├── app_localizations_en.dart            # Generated
    └── app_localizations_ar.dart            # Generated
```

## Adding a New Feature

### Step 1: Create Directory Structure
```bash
mkdir -p lib/features/my_feature/presentation/{screens,widgets}
```

### Step 2: Create Screen
File: `lib/features/my_feature/presentation/screens/my_feature_screen.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyFeatureScreen extends ConsumerWidget {
  const MyFeatureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Feature')),
      body: const Center(child: Text('Hello')),
    );
  }
}
```

### Step 3: Create Providers (if needed)
File: `lib/features/my_feature/presentation/providers.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/repository_providers.dart';

final myDataProvider = StreamProvider<List<MyData>>((ref) {
  final repo = ref.watch(myRepositoryProvider);
  return repo.watchAll();
});
```

### Step 4: Add Route
File: `lib/app/router/app_router.dart` (add to route list):
```dart
GoRoute(
  path: AppRoutes.myFeature,
  pageBuilder: (context, state) =>
      _fadePage(child: const MyFeatureScreen(), state: state),
),
```

### Step 5: Update Constants
File: `lib/core/constants/app_routes.dart`:
```dart
static const String myFeature = '/my-feature';
```

## Naming Conventions

### Files
- Screen files: `{feature}_screen.dart` → class `{Feature}Screen`
- Widget files: `{component_name}.dart` → class `{ComponentName}`
- Provider files: `{feature}_provider.dart` or `{name}_providers.dart`
- Repository impl: `{entity}_repository_impl.dart`
- DAO: `{entity}_dao.dart`
- Entity: `{entity}_entity.dart`
- Table: `{entities}_table.dart`

### Classes
- **Screens:** `PascalCase` + `Screen` suffix (e.g., `DashboardScreen`)
- **Widgets:** `PascalCase` (e.g., `AccountCarousel`)
- **Repositories:** `PascalCase` + `RepositoryImpl` suffix
- **Entities:** `PascalCase` + `Entity` suffix
- **Providers:** `camelCase` + `Provider` suffix
- **Services:** `PascalCase` + `Service` suffix
- **DAOs:** `PascalCase` + `Dao` suffix

### Imports
- Relative imports: `../../core/` BEFORE `../` (ASCII sort: `.` < `d`)
- Never import `lib/` prefix; always relative paths
- Domain imports pure Dart only

## Key File Locations

| Purpose | Path |
|---------|------|
| App entry | `lib/main.dart` |
| Router | `lib/app/router/app_router.dart` |
| Theme (light/dark) | `lib/app/theme/app_theme.dart` |
| Color palette | `lib/app/theme/app_colors.dart` |
| Icon constants | `lib/core/constants/app_icons.dart` |
| Size/spacing tokens | `lib/core/constants/app_sizes.dart` |
| Route paths | `lib/core/constants/app_routes.dart` |
| Money formatting | `lib/core/utils/money_formatter.dart` |
| Database schema | `lib/data/database/app_database.dart` |
| Localization (EN) | `lib/l10n/app_en.arb` |
| Localization (AR) | `lib/l10n/app_ar.arb` |
| Repository interfaces | `lib/domain/repositories/` |
| Repository implementations | `lib/data/repositories/` |
| DAO definitions | `lib/data/database/daos/` |
| Reusable widgets | `lib/shared/widgets/` |
| Global providers | `lib/shared/providers/` |

## Code Generation & Build

**After schema/model/provider changes, run:**
```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n  # After L10n edits
flutter analyze lib/  # Verify (must be zero issues)
```

**Auto-generated files (never edit):**
- `*.g.dart` — Drift/Freezed artifacts
- `*.freezed.dart` — Freezed model classes
- `app_localizations*.dart` — L10n generated files
- `pubspec.lock` — Dependency lock

## Feature Module Best Practices

1. **No cross-feature imports** — Use shared/ or core/
2. **All screens are ConsumerWidget** — Never raw StatefulWidget
3. **One feature per screen** — Split complex screens into sub-widgets
4. **Providers in feature folder** — Isolated state management
5. **Entity imports only in domain/** — No Flutter/Drift in domain/
6. **Design tokens always** — `context.colors.*`, never `Color(0x...)`
7. **Money as int** — Never double; use `MoneyFormatter` for display
8. **Go_router only** — Never `Navigator.push()`; use `context.go()` / `context.push()`
