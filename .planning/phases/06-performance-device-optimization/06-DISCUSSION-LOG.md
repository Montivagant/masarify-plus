# Phase 6: Performance & Device Optimization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-03-28
**Phase:** 06-performance-device-optimization
**Areas discussed:** Glass fallback strategy, Pagination & load-more UX, Cold start experience, Performance thresholds, Provider rebuild audit, APK size optimization, Database migration strategy, Memory budget, Animation performance, Build configuration, Performance testing strategy, AI/Network optimization

---

## Glass Fallback Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| RAM-based threshold | <4GB → blur OFF (solid tinted backgrounds) | ✓ |
| GPU benchmark at startup | Quick render test (~50ms) first launch | |
| Keep API < 28 only | Trust Android 9+ devices can handle blur | |

**User's choice:** RAM-based threshold
**Notes:** Catches Samsung A14/Redmi 12 correctly. Simple, reliable.

### Nav bar fallback
| Option | Description | Selected |
|--------|-------------|----------|
| Nav bar also goes solid | Zero BackdropFilter passes everywhere | ✓ |
| Nav bar keeps blur | Keep as one glass element | |
| You decide | Claude's discretion | |

**User's choice:** Nav bar also goes solid

### 4GB cutoff
| Option | Description | Selected |
|--------|-------------|----------|
| 4GB gets blur | <4GB = no blur, ≥4GB = blur | ✓ |
| Raise to <6GB | More aggressive, only flagships get glass | |

**User's choice:** 4GB gets blur (standard threshold)

### Manual toggle
| Option | Description | Selected |
|--------|-------------|----------|
| Yes, add toggle | Settings > Reduce visual effects | |
| No, auto-detect only | RAM threshold handles it | ✓ |
| You decide | Claude's discretion | |

**User's choice:** No manual toggle

### Fallback shadow depth
| Option | Description | Selected |
|--------|-------------|----------|
| Keep same shadows | Minimal change from glass version | |
| Slightly increase shadows | Compensate for lost depth | |
| You decide | Claude profiles both | ✓ |

**User's choice:** Claude's discretion

### Dialog blur
| Option | Description | Selected |
|--------|-------------|----------|
| Dark scrim on fallback | Standard Material dimming overlay | ✓ |
| Keep dialog blur always | Transient, won't cause sustained jank | |
| You decide | Claude profiles | |

**User's choice:** Dark scrim on fallback

### Theme parity
| Option | Description | Selected |
|--------|-------------|----------|
| Same treatment both themes | 85% opacity both | |
| Dark gets higher opacity | 90% dark, 85% light | |
| You decide | Claude tests both | ✓ |

**User's choice:** Claude's discretion

---

## Pagination & Load-More UX

### Load-more behavior
| Option | Description | Selected |
|--------|-------------|----------|
| Invisible auto-load | Auto-fetch next 50 at scroll end | ✓ |
| Shimmer skeleton | 3-4 placeholder cards while loading | |
| "Load more" button | Explicit button at bottom | |

**User's choice:** Invisible auto-load

### Page size
| Option | Description | Selected |
|--------|-------------|----------|
| Fixed 50 | Simple, predictable | |
| Screen-relative | Based on device height | |
| You decide | Claude profiles | ✓ |

**User's choice:** Claude's discretion

### Filter + pagination
| Option | Description | Selected |
|--------|-------------|----------|
| Re-query from DB | New SQL with WHERE + LIMIT 50 | ✓ |
| Filter in-memory | Instant but may show fewer results | |
| You decide | Claude picks | |

**User's choice:** Re-query from DB

### Per-account views
| Option | Description | Selected |
|--------|-------------|----------|
| Same pagination everywhere | Consistent behavior | |
| Per-account loads all | <100 per account, paginate only All | ✓ |
| You decide | Claude profiles | |

**User's choice:** Per-account loads all

### New transaction update
| Option | Description | Selected |
|--------|-------------|----------|
| Stream-based | Drift stream → reactive update | ✓ |
| Optimistic insert | Add before DB confirms | |

**User's choice:** Stream-based (existing pattern)

### Analytics optimization scope
| Option | Description | Selected |
|--------|-------------|----------|
| Home screen only | ROADMAP scope | |
| Include Analytics too | Optimize both | |
| You decide | Profile and expand if needed | ✓ |

**User's choice:** Claude's discretion

### Search pagination
| Option | Description | Selected |
|--------|-------------|----------|
| Search loads all matches | Small result sets | ✓ |
| Search also paginates | Consistent but unnecessary | |
| You decide | Claude picks | |

**User's choice:** Search loads all matches

---

## Cold Start Experience

### Startup UX
| Option | Description | Selected |
|--------|-------------|----------|
| Native splash → home | No intermediate loading state | ✓ |
| Splash → skeleton → home | Shimmer cards for 200-300ms | |
| Progressive reveal | Elements appear as data arrives | |

**User's choice:** Native splash → home

### Services to defer
| Option | Description | Selected |
|--------|-------------|----------|
| NotificationService.initialize() | ~50-100ms savings | ✓ |
| GlassConfig.initialize() | ~30ms savings, risk of flash | |
| CrashLogService.initialize() | ~10ms, protective | |
| Category seeding check | ~5ms, tiny | |

**User's choice:** NotificationService only

### Brand registry lazy init
| Option | Description | Selected |
|--------|-------------|----------|
| Lazy-init with late final | Only loaded on first access | ✓ |
| Keep eager | Small savings, not worth it | |

**User's choice:** Lazy-init

### SMS scan removal
| Option | Description | Selected |
|--------|-------------|----------|
| Remove from main.dart | Dead code, kSmsEnabled=false | ✓ |
| Keep guarded | If-guard prevents execution | |

**User's choice:** Remove from main.dart

### RecurringScheduler position
| Option | Description | Selected |
|--------|-------------|----------|
| Keep post-runApp (current) | Already non-blocking | ✓ |
| Defer to first idle | Marginal improvement | |

**User's choice:** Keep current

### Startup logging
| Option | Description | Selected |
|--------|-------------|----------|
| Profile-mode only | No runtime overhead | ✓ |
| Log to SharedPreferences | Real-world monitoring | |
| You decide | Claude picks | |

**User's choice:** Profile-mode only

---

## Performance Thresholds

### Cold start ceiling
| Option | Description | Selected |
|--------|-------------|----------|
| Hard 2s | Non-negotiable | |
| 3s acceptable, 2s aspirational | Accept up to 3s | |
| Best-effort | Apply optimizations, accept result | ✓ |

**User's choice:** Best-effort

### Jank tolerance
| Option | Description | Selected |
|--------|-------------|----------|
| Zero jank (strict) | No red frames | |
| Near-zero (≤3 jank frames) | 99.4% smooth | |
| Best-effort | Accept after optimizations | ✓ |

**User's choice:** Best-effort

### Test device
| Option | Description | Selected |
|--------|-------------|----------|
| Emulator profiling only | Practical, repeatable | ✓ |
| Real device available | ADB profiling | |

**User's choice:** Emulator only

### Index scope
| Option | Description | Selected |
|--------|-------------|----------|
| Minimal — one composite index | ROADMAP spec | |
| Aggressive — audit all queries | EXPLAIN QUERY PLAN | |
| You decide | Profile and add as needed | ✓ |

**User's choice:** Claude's discretion

### Widget repaint audit
| Option | Description | Selected |
|--------|-------------|----------|
| GlassCard + TransactionCard only | ROADMAP scope | |
| Full widget audit | debugRepaintRainbowEnabled | ✓ |
| You decide | Start with two, expand if needed | |

**User's choice:** Full widget audit

### Debounce scope
| Option | Description | Selected |
|--------|-------------|----------|
| Both providers | recentActivity + activityByWallet | ✓ |
| recentActivityProvider only | Minimal change | |
| You decide | Profile both | |

**User's choice:** Both providers

---

## Provider Rebuild Audit

### Scope
| Option | Description | Selected |
|--------|-------------|----------|
| Dashboard widgets only | Hot path focus | |
| All screens | Comprehensive | ✓ |
| You decide | Profile and expand | |

**User's choice:** All screens

### DAO-level vs Dart-level
| Option | Description | Selected |
|--------|-------------|----------|
| SQL-level where possible | New DAO methods | ✓ |
| Dart-level filtering fine | Small volume after pagination | |
| You decide | Evaluate per query | |

**User's choice:** SQL-level where possible

### Background AI provider debounce
| Option | Description | Selected |
|--------|-------------|----------|
| Debounce 500ms | Non-critical insight providers | ✓ |
| Timer-based (every 30s) | Very efficient, stale data risk | |
| You decide | Per provider | |

**User's choice:** Debounce 500ms

---

## APK Size Optimization

### Aggressiveness
| Option | Description | Selected |
|--------|-------------|----------|
| Remove unused packages | Low effort, ~1-3MB savings | |
| Full asset audit | Packages + fonts + images + tree-shaking | ✓ |
| Skip | Size is fine | |

**User's choice:** Full asset audit

### Font strategy
| Option | Description | Selected |
|--------|-------------|----------|
| Bundle + disable runtime fetch | Verify font bundled in assets | |
| System font fallback on low-end | Roboto on <4GB, custom on ≥4GB | |

**User's choice:** Both! Bundle font + system fallback on <4GB

### SMS assets
| Option | Description | Selected |
|--------|-------------|----------|
| Keep in build | Compiled Dart, ~50KB | ✓ |
| Strip via conditional import | Complex, future build flavor | |
| You decide | Evaluate size impact | |

**User's choice:** Keep in build

### R8 mode
| Option | Description | Selected |
|--------|-------------|----------|
| Keep Flutter defaults | Safe, no reflection risk | ✓ |
| Enable R8 full mode | Aggressive, risks IAP breakage | |
| You decide | Evaluate compatibility | |

**User's choice:** Flutter defaults

---

## Database Migration Strategy

### Migration scope
| Option | Description | Selected |
|--------|-------------|----------|
| Indexes only | Low risk, fast migration | |
| Indexes + cleanup | Drop unused columns too | |
| You decide | Evaluate what's safe | ✓ |

**User's choice:** Claude's discretion

### VACUUM
| Option | Description | Selected |
|--------|-------------|----------|
| Yes — VACUUM on upgrade | Reclaim space | |
| No — skip VACUUM | Avoids DB lock | ✓ |

**User's choice:** No VACUUM

### WAL mode
| Option | Description | Selected |
|--------|-------------|----------|
| Enable WAL if not set | Concurrent reads/writes | ✓ |
| Skip — default journal | Write contention is rare | |
| You decide | Check current mode | |

**User's choice:** Enable WAL

---

## Memory Budget

### Strategy
| Option | Description | Selected |
|--------|-------------|----------|
| Trust pagination | Architecture constrains memory | ✓ |
| Add memory monitoring | Debug overlay in profile builds | |
| Set hard budget | <100MB peak RSS | |

**User's choice:** Trust pagination

### Provider disposal
| Option | Description | Selected |
|--------|-------------|----------|
| Keep providers alive | Global providers stay, autoDispose handles rest | |
| Aggressive disposal | Dispose on navigate away | |
| You decide | Profile and dispose where safe | ✓ |

**User's choice:** Claude's discretion

### Icon caching
| Option | Description | Selected |
|--------|-------------|----------|
| Icons are fine as-is | Vectors, zero memory overhead | |
| Add icon cache | Cache brand icon renders | |
| You decide | Profile during scroll | ✓ |

**User's choice:** Claude's discretion

### Chat message pagination
| Option | Description | Selected |
|--------|-------------|----------|
| Load all chat messages | <100 messages typical | |
| Paginate chat messages | Last 50, scroll for older | ✓ |

**User's choice:** Paginate chat messages

---

## Animation Performance

### Low-end device animations
| Option | Description | Selected |
|--------|-------------|----------|
| Reduce duration, keep animations | Half durations, disable parallax/stagger | ✓ |
| Disable all animations | Instant transitions | |
| Same animations everywhere | Don't differentiate | |
| You decide | Profile and optimize per tier | |

**User's choice:** Reduce duration, keep animations

### SliverAppBar collapse
| Option | Description | Selected |
|--------|-------------|----------|
| Keep collapse animation | Flutter framework handles it | ✓ |
| Snap instead of smooth | Instant open/closed | |
| You decide | Profile and simplify if jank | |

**User's choice:** Keep collapse animation

---

## Build Configuration

### Debug info + obfuscation
| Option | Description | Selected |
|--------|-------------|----------|
| Enable both | --split-debug-info --obfuscate | ✓ |
| split-debug-info only | Easier crash debugging | |
| Neither | Full debug info in release | |

**User's choice:** Enable both

### Script update
| Option | Description | Selected |
|--------|-------------|----------|
| Add to build-release.sh | Automated for every build | ✓ |
| Manual flags only | Developer chooses | |

**User's choice:** Add to script

### Phosphor icon tree-shaking
| Option | Description | Selected |
|--------|-------------|----------|
| Enable tree-shaking | Verify working for Phosphor | |
| Skip | May not apply to SVG icons | |
| You decide | Investigate and implement if possible | ✓ |

**User's choice:** Claude's discretion

---

## Performance Testing Strategy

### Verification approach
| Option | Description | Selected |
|--------|-------------|----------|
| Manual profiling | DevTools per optimization | |
| Add integration benchmarks | Automated scroll tests | |
| Manual + benchmark for scroll | Cold start manual, scroll automated | ✓ |

**User's choice:** Manual + benchmark for scroll

### Test data
| Option | Description | Selected |
|--------|-------------|----------|
| Seed in test | 500 synthetic transactions in setUp | ✓ |
| Pre-built fixture | Ship test.db file | |
| You decide | Most maintainable | |

**User's choice:** Seed in test

### Benchmark in CI
| Option | Description | Selected |
|--------|-------------|----------|
| Separate command only | Not part of flutter test | ✓ |
| Part of CI suite | Every PR runs benchmark | |

**User's choice:** Separate command only

---

## AI/Network Optimization

### Optimization scope
| Option | Description | Selected |
|--------|-------------|----------|
| Optimize timeouts only | Tighten HTTP timeouts | ✓ |
| Add response caching | Cache AI responses | |
| Skip AI optimization | Already async/non-blocking | |
| You decide | Evaluate and optimize | |

**User's choice:** Optimize timeouts only

### Voice API timeout
| Option | Description | Selected |
|--------|-------------|----------|
| 30 seconds | 4x buffer for slow networks | ✓ |
| 45 seconds | More conservative | |
| You decide | Profile response times | |

**User's choice:** 30 seconds

### Connection timeout
| Option | Description | Selected |
|--------|-------------|----------|
| 5-second connection timeout | Fail fast on no internet | ✓ |
| 3-second connection timeout | More aggressive | |
| You decide | Based on network latency | |

**User's choice:** 5-second connection timeout

---

## Claude's Discretion

- Shadow/elevation on glass-fallback devices
- Per-theme opacity for fallback card backgrounds
- Initial page size (50 vs screen-relative)
- Analytics optimization scope
- Index scope beyond one composite index
- Schema cleanup alongside index migration
- Phosphor icon tree-shaking
- Provider disposal strategy
- Icon caching need

## Deferred Ideas

### BLOCKING: 11 Prior Phase Regressions
See CONTEXT.md `<deferred>` section for full list. Key items:
- Cash wallet removed (not requested)
- Account reorder, quick archive, archive feature removed
- RTL alignment regressions
- "Recurring" label reverted (should be "Subscriptions & Bills")
- Voice Confirm Screen needs batch accept
- Transaction form / CRUD screens untouched
- Toast notifications appearing mid-screen

---

*Discussion log for: 06-performance-device-optimization*
*Date: 2026-03-28*
