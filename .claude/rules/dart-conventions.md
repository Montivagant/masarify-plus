---
description: Dart/Flutter coding conventions enforced on every file edit in this project
globs: "lib/**/*.dart"
---

# Masarify Dart Conventions

## Money
- ALL monetary values stored as `int` (piastres). `100 EGP = 10000`.
- Display via `MoneyFormatter` only. Never `double` for money.

## State Management
- Use `ConsumerWidget` or `ConsumerStatefulWidget`. Never raw `StatefulWidget` for screens.
- Provider chain: `StreamProvider`/`FutureProvider` → Repository → DAO → Drift.
- `ref.watch()` for reactive state, `ref.read()` for one-shot actions.
- Never `setState` except for `AnimationController` tick or ephemeral form state.

## Navigation
- `context.go()` for replacement, `context.push()` for stack, `context.pop()` for back.
- Never `Navigator.push()`, `Navigator.pop()`, or `Navigator.of()`.

## Design Tokens (mandatory)
- Colors: `context.colors.*` or `AppColors.*` — never `Color(0x...)` or `Colors.red`
- Spacing: `AppSizes.*` — never raw `EdgeInsets` numbers
- Text: `Theme.of(context).textTheme.*` — never raw `TextStyle(fontSize: ...)`
- Icons: `AppIcons.*` (Phosphor) — never `Icons.home`
- Borders: `AppSizes.borderRadius*` — never raw `BorderRadius.circular(8)`
- Durations: `AppDurations.*` — never raw `Duration(milliseconds: 300)`

## Imports
- `../../` paths sort BEFORE `../` paths
- No unused imports
- No Flutter/Drift imports in `domain/` layer

## L10n
- All user-facing strings via `context.l10n.*`
- New keys added to BOTH `app_en.arb` AND `app_ar.arb`
