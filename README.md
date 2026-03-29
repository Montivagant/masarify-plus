# Masarify (مصاريفي)

Offline-first personal finance tracker for Android, targeting Egyptian young professionals.
Track income, expenses, transfers, budgets, and savings goals — with an AI Financial Advisor powered by Gemini.

**Stack:** Flutter/Dart | Riverpod 2.x | Drift (SQLite) | Material Design 3 | go_router

## Build

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze lib/
flutter test
flutter build appbundle --release          # Play Store
bash scripts/build-release.sh              # Sideload APKs
```

## Architecture

Clean Architecture (domain/data/presentation) with feature-first organization.
All monetary values stored as integer piastres (100 EGP = 10000).
100% offline — no internet required for core features.
