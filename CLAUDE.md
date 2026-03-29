# Masarify-Plus — Claude Code Configuration

## Project
**Masarify (مصاريفي)** — Offline-first personal finance tracker for Android/iOS.
Flutter + Dart | Clean Architecture + Riverpod 2.x | Drift (SQLite) | Material Design 3.
See `MEMORY.md` at `C:\Users\omarw\.claude\projects\d--Masarify-Plus\memory\MEMORY.md` for project context.
See `docs/` for architecture, database, features, and setup documentation.

## MCP Tools (Windows workarounds)
- `dart` MCP: only `pub_dev_search` works. **Analyzer/formatter broken** — use `flutter analyze lib/` via Bash
- `dcm` MCP: **ALL broken** — use `bash scripts/analyze.sh dcm` instead
- `flutter-inspector`: OK (requires `flutter run --dds-port=8181 --disable-service-auth-codes`)
- `context7`: OK (live docs for any package)

## Slash Commands
| Command | Purpose |
|---------|---------|
| `/flutter-dev` | Flutter dev workflow — analyze, context7, inspector |
| `/think` | Structured reasoning for architecture/debugging |
| `/review` | Code review — analyzer + DCM + architecture audit |
| `/diagram` | Generate diagrams (excalidraw, mermaid, draw-uml) |
| `/ship` | Release preparation — analyze, test, build |
| `/audit` | Full 9-category surgical codebase audit |

## Hooks (automatic)
- **Post-edit:** `dart format` on every `.dart` file
- **Pre-edit:** Blocks writes to `*.g.dart`, `*.freezed.dart`, `pubspec.lock`, l10n generated files

## The 5 Critical Rules
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
bash scripts/analyze.sh                                    # Full analysis (analyzer + DCM)
flutter test
flutter build appbundle --release                          # Play Store (AAB)
bash scripts/build-release.sh                              # Sideload APKs (split by ABI)
```
