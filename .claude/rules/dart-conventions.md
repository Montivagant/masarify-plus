---
description: Dart/Flutter coding conventions enforced on every file edit in this project
globs: "lib/**/*.dart"
---

# Masarify Dart Conventions

## Money
- All monetary values stored as `int` (piastres). `100 EGP = 10000`.
- Display via `MoneyFormatter` only. (Floating-point causes rounding errors in finance.)

## State Management
- Use `ConsumerWidget` or `ConsumerStatefulWidget` for screens. (Enables Riverpod dependency injection.)
- Provider chain: `StreamProvider`/`FutureProvider` → Repository → DAO → Drift.
- `ref.watch()` for reactive state, `ref.read()` for one-shot actions.
- Reserve `setState` for `AnimationController` ticks or ephemeral form fields only.

## Navigation
- Use `context.go()` for replacement, `context.push()` for stack, `context.pop()` for back. (GoRouter is the single navigation system.)

## Design Tokens (mandatory)
- Colors: `context.colors.*` or `AppColors.*`
- Spacing: `AppSizes.*`
- Text: `Theme.of(context).textTheme.*`
- Icons: `AppIcons.*` (Phosphor)
- Borders: `AppSizes.borderRadius*`
- Durations: `AppDurations.*`

(Hardcoded values break theming and visual consistency.)

## Imports
- `../../` paths sort before `../` paths.
- No Flutter/Drift imports in `domain/` layer. (Domain must be pure Dart.)

## L10n
- All user-facing strings via `context.l10n.*`.
- New keys added to both `app_en.arb` and `app_ar.arb`.
