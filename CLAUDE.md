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

## Automated Hooks (run automatically — no action needed)

These hooks fire deterministically without Claude needing to "remember":
- **Post-edit:** `dart format` runs on every `.dart` file after Edit/Write
- **Post-coding:** `flutter analyze lib/` runs when Claude finishes a coding task (Stop hook)
- **Post-compact:** Critical project context re-injected after context compaction
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
