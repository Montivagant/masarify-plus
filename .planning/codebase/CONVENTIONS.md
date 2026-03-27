# Masarify Code Conventions

**Last Updated:** 2026-03-27
**Scope:** `lib/**/*.dart`, enforced on every edit

---

## 1. Money Handling

**Rule:** ALL monetary values are `int` (piastres). `100 EGP = 10,000 piastres`.

### Storage
```dart
// ❌ WRONG
double amount = 100.50;

// ✅ CORRECT
int amountPiastres = 10050;
```

### Display
ALWAYS use `MoneyFormatter` for user-facing output:
```dart
// From test/unit/money_formatter_test.dart
final result = MoneyFormatter.format(10000, locale: 'en-US');
// Output: "100.00 EGP"

final result = MoneyFormatter.format(10000, locale: 'ar-EG');
// Output: "100.00 ج.م"
```

See `lib/core/utils/money_formatter.dart` for methods: `format()`, `formatCompact()`, `formatAmount()`, `toDisplayDouble()`.

---

## 2. State Management (Riverpod 2.x)

### Screen Pattern
Every screen MUST be `ConsumerWidget` or `ConsumerStatefulWidget`:

```dart
// From lib/features/dashboard/presentation/screens/dashboard_screen.dart
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Ephemeral state only (form fields, scroll controller)
  final _scrollController = ScrollController();
  String _searchQuery = '';

  // NEVER use setState for non-ephemeral state
}
```

### Provider Usage
Provider chain: `StreamProvider` → Repository → DAO → Drift

```dart
// From lib/shared/providers/wallet_provider.dart
final walletsProvider = StreamProvider<List<WalletEntity>>(
  (ref) => ref.watch(walletRepositoryProvider).watchAll(),
);

final totalBalanceProvider = StreamProvider<int>(
  (ref) => ref.watch(walletRepositoryProvider).watchTotalBalance(),
);

final availableBalanceProvider = Provider<int>((ref) {
  final total = ref.watch(totalBalanceProvider).valueOrNull ?? 0;
  final inGoals = ref.watch(totalInGoalsProvider);
  return total - inGoals;
});
```

**Rules:**
- Use `ref.watch()` for reactive, persistent state
- Use `ref.read()` for one-shot actions (button taps)
- Provider names: `(singular|plural)Provider` or `(noun)Provider`
- **NEVER** `setState` except for `AnimationController` tick or ephemeral form state

---

## 3. Navigation (go_router)

**Rule:** NEVER use `Navigator.push()`, `Navigator.pop()`, `Navigator.of()`.

```dart
// ❌ WRONG
Navigator.push(context, MaterialPageRoute(builder: ...));

// ✅ CORRECT
context.go('/wallets');           // Replace current
context.push('/add-transaction');  // Push stack
context.pop();                     // Back
```

Router defined in `lib/app/router/app_router.dart` with fade/slide transitions.

---

## 4. Design Tokens (Mandatory)

NEVER hardcode values. Use centralized constants.

### Colors
```dart
// ❌ WRONG
Container(color: Color(0xFF3DA37A));
Container(color: Colors.red);

// ✅ CORRECT
Container(color: context.colors.primary);
Container(color: AppColors.success);
```

See `lib/app/theme/app_colors.dart`.

### Spacing
```dart
// ❌ WRONG
EdgeInsets.all(16);
SizedBox(height: 8);

// ✅ CORRECT
EdgeInsets.all(AppSizes.md);  // AppSizes.md = 16
SizedBox(height: AppSizes.sm);  // AppSizes.sm = 8
```

Spacing scale: `xs` (4), `sm` (8), `md` (16), `lg` (24), `xl` (32), `xxl` (48).
See `lib/core/constants/app_sizes.dart`.

### Icons
```dart
// ❌ WRONG
Icon(Icons.home);

// ✅ CORRECT
Icon(AppIcons.home);  // Phosphor Icons
Icon(AppIcons.homeOutlined);
```

See `lib/core/constants/app_icons.dart`. Uses Phosphor Icons exclusively.

### Text & Borders
```dart
// ❌ WRONG
TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
BorderRadius.circular(8);

// ✅ CORRECT
Theme.of(context).textTheme.titleMedium;
BorderRadius.circular(AppSizes.borderRadiusMd);
```

### Durations
```dart
// ❌ WRONG
Duration(milliseconds: 300);

// ✅ CORRECT
AppDurations.normal;  // 300ms
AppDurations.fast;    // 150ms
AppDurations.slow;    // 500ms
```

See `lib/core/constants/app_durations.dart`.

---

## 5. Import Ordering

**Rule:** Relative imports sort by depth: `../../` BEFORE `../`

```dart
// ✅ CORRECT
import '../../../../core/config/app_config.dart';      // 4 levels up
import '../../../../core/constants/app_sizes.dart';    // 4 levels up
import '../../../../shared/providers/wallet_provider.dart';
import '../widgets/account_carousel.dart';             // 2 levels up
import 'package:flutter/material.dart';                // Packages last

// ❌ WRONG — mixed depth ordering
import '../widgets/...';
import '../../../../core/...';
import 'package:flutter/...';
```

---

## 6. Localization (L10n)

**Rule:** ALL user-facing strings via `context.l10n.*`

```dart
// ❌ WRONG
Text('Add Transaction');

// ✅ CORRECT
Text(context.l10n.transactions_add);
```

### Adding New Strings
1. Edit BOTH `lib/l10n/app_en.arb` AND `lib/l10n/app_ar.arb`
2. Run `flutter gen-l10n`
3. Use via `context.l10n.keyName`

**Never hardcode user text.** Keys: snake_case, descriptive, max 3-4 words.

---

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

**Class names:** PascalCase, matching file name (with underscores → PascalCase).
```dart
// In file: add_transaction_screen.dart
class AddTransactionScreen extends ConsumerStatefulWidget { }
class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> { }
```

---

## 8. Error Handling

Pattern: Try-catch with mounted check (for async state changes):

```dart
// From lib/features/transactions/presentation/screens/add_transaction_screen.dart
try {
  await ref.read(repositoryProvider).save(transaction);
  if (!mounted) return;
  context.pop(true);
} catch (e) {
  if (!mounted) return;
  setState(() => _loading = false);
  SnackHelper.showError(context, context.l10n.common_error_generic);
}
```

**Rules:**
- Always check `if (!mounted)` before state changes post-await
- Use `SnackHelper.showError()` for user feedback (not `print()`)
- Log errors via service loggers, never console
- Fallback gracefully (e.g., use cached data if API fails)

---

## 9. Conditional Features & Feature Flags

```dart
// From lib/core/config/app_config.dart
abstract final class AiConfig {
  static const bool isEnabled = true;
}

abstract final class AppConfig {
  static const bool kSmsEnabled = false;  // SMS parsing hidden (AI-first pivot)
  static const bool kMonetizationEnabled = true;
}

// In code:
if (AppConfig.kSmsEnabled) {
  // SMS-only features
}
if (AiConfig.isEnabled) {
  // AI features
}
```

---

## 10. Glass System & Theming

Custom glass tier hierarchy via `GlassTier` enum:
```dart
// Background (sigma 20): sheets, dialogs
// Card (sigma 12): all cards, main UI
// Inset (sigma 8): icon badges, detail elements

GlassCard(
  tier: GlassTier.card,
  child: child,
)
```

Theme tokens: `context.appTheme.*` (from `AppThemeExtension`).
Never hardcode glass configs — use `GlassConfig` with device fallback.

---

## Summary

1. **Money:** Integer piastres. `MoneyFormatter` for display.
2. **State:** `ConsumerWidget`, `ref.watch()`, Riverpod StreamProvider chains.
3. **Navigation:** `context.go/push/pop()` only.
4. **Design:** `AppIcons.*`, `AppSizes.*`, `AppColors.*`, `context.colors.*` — never hardcode.
5. **Imports:** Depth-sorted, `../../` before `../`.
6. **L10n:** `context.l10n.*`, update .arb files bilingual.
7. **Naming:** PascalCase classes, snake_case files.
8. **Errors:** Try-catch with mounted check, `SnackHelper` for UX.
9. **Features:** Use `AppConfig` flags, test with guards.
10. **Glass:** `GlassTier` enum, `context.appTheme.*` tokens.

