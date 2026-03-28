# Phase 6: Performance & Device Optimization - Context

**Gathered:** 2026-03-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver sub-2-second cold start and smooth 60fps scrolling on Egypt's dominant mid-range Android devices (Samsung A14, Xiaomi Redmi 12). Optimize database queries, rendering pipeline, startup sequence, and build configuration. Requirements: PERF-01, PERF-02, PERF-03, PERF-04, PERF-05.

**BLOCKING PREREQUISITE:** 13 regressions from prior phases must be fixed before executing this phase. See `<deferred>` section. Performance profiling on broken UI is pointless — fix first, then optimize.

</domain>

<decisions>
## Implementation Decisions

### Glass Fallback Strategy (PERF-05)
- **D-01:** Add RAM-based threshold: `totalMem < 4GB` → blur OFF. Replace `BackdropFilter` with solid tinted backgrounds (theme color + opacity). Devices with ≥4GB get full glass effects. Current API < 28 check is insufficient — never triggers on target devices (Samsung A14/Redmi 12 run Android 12+).
- **D-02:** Nav bar (AppNavBar) also goes solid on fallback devices. Zero `BackdropFilter` passes = guaranteed 60fps. No exceptions for any widget.
- **D-03:** Confirm dialogs use dark scrim overlay (`Colors.black54`) on fallback devices instead of `BackdropFilter` blur.
- **D-04:** No manual "Reduce visual effects" toggle in Settings. Auto-detect only — RAM threshold handles it.
- **D-05:** On fallback devices, halve animation durations (300ms→150ms) and disable parallax/stagger effects. Keep fade/slide transitions. Respect `MediaQuery.disableAnimationsOf` (Reduce Motion accessibility).

### Pagination & Load-More UX (PERF-04)
- **D-06:** Invisible auto-load: fetch next 50 when user scrolls within 5 items of the end. No spinner, shimmer, or button. SQLite query < 5ms = imperceptible. Instagram/Twitter pattern.
- **D-07:** Filters re-query from DB. New SQL query with WHERE clause + LIMIT 50. Guarantees exactly 50 matching results per page. No in-memory filtering.
- **D-08:** Per-account views load ALL transactions (most users have <100 per account). Pagination only on "All Accounts" view where volume is high.
- **D-09:** Search results load all matches (not paginated). Search typically returns small sets.
- **D-10:** Stream-based updates for new transactions. DB insert triggers Drift stream → UI updates reactively. No optimistic insert — follows existing pattern.
- **D-11:** Paginate AI chat messages: load last 50, scroll-to-load-more for older.

### Cold Start Optimization (PERF-01)
- **D-12:** Native splash → home (no skeleton, no progressive reveal). Optimize what happens behind the splash so home screen with data is ready when splash lifts.
- **D-13:** Defer `NotificationService.initialize()` to post-frame via `WidgetsBinding.instance.addPostFrameCallback`. Saves ~50-100ms blocking time.
- **D-14:** Lazy-initialize `brand_registry.dart` map with `late final`. Only loaded when voice input or AI chat first accessed.
- **D-15:** Remove dead SMS scan code from `main.dart` (`_scanSmsInBackground` function + import). `kSmsEnabled = false` makes it unreachable. Service files preserved for future Pro re-enablement.
- **D-16:** Keep RecurringScheduler at current post-`runApp()` position. Already non-blocking.
- **D-17:** Profile-mode measurement only (`--trace-startup` on emulator). No persistent startup logging in release builds.

### Performance Thresholds
- **D-18:** Best-effort for cold start. Apply all planned optimizations, measure, accept the resulting number as baseline. No hard 2s requirement.
- **D-19:** Best-effort for 60fps scrolling. Apply optimizations (RepaintBoundary, no BackdropFilter in list items, ref.select). Accept profiler results after all optimizations.
- **D-20:** Emulator profiling only (4GB RAM, Helio G88 profile). No real device testing required.

### Provider Rebuild Audit
- **D-21:** Full audit across ALL screens, not just dashboard. Apply `ref.select()` narrowing wherever providers watch more data than they need.
- **D-22:** SQL-level filtering where possible. Create DAO methods like `watchByDateRange()`, `watchExpensesOnly()` instead of Dart-level filtering on full result sets.
- **D-23:** Debounce background AI providers (spending predictions, budget suggestions, recurring detection) by 500ms. Non-critical insight providers don't need instant updates.
- **D-24:** Debounce both `recentActivityProvider` and `activityByWalletProvider` `Rx.combineLatest2` streams by 100ms.

### Database & Stream Optimization (PERF-03)
- **D-25:** Add composite index `idx_transactions_wallet_date` on `(wallet_id, transaction_date DESC)`. Claude decides additional indexes based on EXPLAIN QUERY PLAN profiling.
- **D-26:** Schema bump v14→v15 for indexes. Claude decides whether to include table/column cleanup alongside indexes. No VACUUM.
- **D-27:** Enable WAL mode (`PRAGMA journal_mode=WAL`) if not already set. Concurrent reads during writes reduce lock contention.

### Rendering Performance (PERF-02)
- **D-28:** Full widget repaint audit using `debugRepaintRainbowEnabled`. Not limited to GlassCard + TransactionCard — audit all shared widgets for unnecessary repaints.
- **D-29:** Add `RepaintBoundary` to `GlassCard` build method. Verify `TransactionCard` in list views does NOT use `BackdropFilter`.
- **D-30:** Keep SliverAppBar collapse animation (smooth, not snap). Focus on making the header widget cheap to rebuild.

### APK Size Optimization
- **D-31:** Full asset audit: remove unused packages, font optimization, image compression, tree-shake unused Material icons, R8 default config (no full mode).
- **D-32:** Bundle Plus Jakarta Sans font + disable runtime fetch. On <4GB RAM devices, fall back to system font (Roboto) to save rendering cost. Font files stay in APK for ≥4GB devices.
- **D-33:** Keep SMS parsing code in build (compiled Dart, ~50KB, not worth stripping).

### Build Configuration
- **D-34:** Enable `--split-debug-info` and `--obfuscate` for release builds. Add to `build-release.sh`. Debug info saved to timestamped folder for crash symbolication.
- **D-35:** Investigate Phosphor Flutter icon tree-shaking feasibility. Claude decides based on how the package bundles icons.

### Performance Testing Strategy
- **D-36:** Manual profiling for cold start (`flutter run --profile` + DevTools). Automated scroll benchmark for 500-item transaction list via `integration_test`.
- **D-37:** Benchmark test seeds 500 synthetic transactions in setUp(). Self-contained, no fixture files.
- **D-38:** Benchmark runs via separate command only (`flutter test integration_test/`), not part of regular `flutter test` suite.

### AI/Network Optimization
- **D-39:** Optimize timeouts only, no response caching or preconnect. AI responses are unique.
- **D-40:** Reduce Gemini voice API timeout from 90s to 30s. Voice recordings are 5-15s of audio, Gemini processes in 3-8s.
- **D-41:** Add 5-second connection timeout to all HTTP clients. Fail fast when server is unreachable.

### Memory Management
- **D-42:** Trust pagination to keep memory in check. No explicit memory budget or monitoring.
- **D-43:** Provider disposal strategy at Claude's discretion based on profiling.
- **D-44:** Icon caching at Claude's discretion based on scroll profiling.

### Claude's Discretion
- Shadow/elevation treatment on glass-fallback devices (same vs slightly increased)
- Per-theme opacity for solid card backgrounds (same 85% or dark gets higher)
- Initial page size (fixed 50 vs screen-relative)
- Analytics tab optimization scope (dashboard focus vs include analytics)
- Index scope beyond the one ROADMAP composite index
- Schema cleanup alongside index migration
- Phosphor icon tree-shaking implementation

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Performance-Critical Files
- `lib/core/services/glass_config_service.dart` — Current blur detection (API < 28 only, needs RAM check)
- `lib/shared/widgets/cards/glass_card.dart` — GlassCard with BackdropFilter (add RepaintBoundary)
- `lib/shared/providers/activity_provider.dart` — recentActivityProvider + activityByWalletProvider (combineLatest2, needs pagination + debounce)
- `lib/shared/providers/transaction_provider.dart` — Transaction queries (needs paginated DAO methods)
- `lib/main.dart` — Startup sequence (defer NotificationService, remove SMS scan)
- `lib/core/constants/brand_registry.dart` — 410-line const map (needs lazy init)

### Dashboard (hot path)
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — Home screen (282 lines)
- `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart` — Needs ref.select()
- `lib/features/dashboard/presentation/widgets/month_summary_zone.dart` — Needs ref.select()

### Glass & Rendering
- `lib/shared/widgets/cards/balance_card.dart` — Uses GlassConfig
- `lib/shared/widgets/feedback/confirm_dialog.dart` — Uses BackdropFilter (needs scrim fallback)
- `lib/shared/widgets/navigation/app_nav_bar.dart` — Glassmorphic nav bar (needs fallback)
- `lib/app/theme/app_theme_extension.dart` — Glass tokens

### Database
- `lib/data/database/app_database.dart` — Schema v14, migration chain, index definitions
- `lib/data/database/daos/` — All DAOs (audit watchAll patterns, add paginated methods)

### AI/Network
- `lib/core/services/ai/gemini_audio_service.dart` — Voice API timeout (90s → 30s)
- `lib/core/services/ai/openrouter_service.dart` — Chat API timeout
- `lib/core/services/ai/ai_chat_service.dart` — Chat service

### Build
- `scripts/build-release.sh` — Add --split-debug-info --obfuscate flags
- `lib/core/services/notification_service.dart` — Defer initialize to post-frame

### Background AI Providers
- `lib/shared/providers/background_ai_provider.dart` — 6 providers (needs 500ms debounce)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GlassConfig` — Already has `blurEnabled` bool and `shouldBlur(context)` method. Extend with RAM detection.
- `DeviceInfoPlugin` — Already imported in glass_config_service.dart. Android info includes `systemFeatures` but RAM requires `totalMem` from device_info_plus.
- `Rx.combineLatest2` — Used in both activity providers. Add `.debounceTime(Duration(milliseconds: 100))` pipe.
- `flutter_native_splash` — Already configured. Splash covers startup time.
- `integration_test` — Flutter's built-in integration testing framework. Available for scroll benchmarks.

### Established Patterns
- Zone-based dashboard: each widget independently reactive via Riverpod. `ref.select()` narrowing fits naturally.
- Provider cascade: `StreamProvider` → Repository → DAO → Drift stream. Pagination needs DAO-level changes.
- `GlassCard` uses `GlassTier` enum for blur sigma. Fallback path needs to bypass `BackdropFilter` entirely when `!GlassConfig.blurEnabled`.
- `AppDurations` centralized animation durations. Fallback devices can read a reduced set.

### Integration Points
- `GlassConfig.initialize()` in `main.dart` — Add RAM detection here
- `GlassCard.build()` — Conditional: blur enabled → BackdropFilter, disabled → solid container
- `AppNavBar.build()` — Same conditional
- `ConfirmDialog` — Same conditional for scrim
- Activity providers — Add `.debounceTime()` to combineLatest2 streams
- Transaction DAO — Add `watchPaginated(limit, offset)` method
- `app_database.dart` `onUpgrade` — Add v14→v15 CREATE INDEX migration
- `build-release.sh` — Add --split-debug-info and --obfuscate flags

</code_context>

<specifics>
## Specific Ideas

- Target devices are Samsung A14 (Exynos 850, 3-4GB) and Xiaomi Redmi 12 (Helio G88, 4GB) — Egypt's dominant mid-range
- Invisible auto-load pagination (Instagram/Twitter pattern) — no visible loading indicators
- Fonts: bundle Plus Jakarta Sans but fall back to Roboto on <4GB RAM
- User explicitly chose "best-effort" for both cold start and 60fps targets — no hard requirements
- Voice API timeout reduced from 90s → 30s (typical processing is 3-8s)
- Scroll benchmark must seed 500 transactions in test setUp, run separately from unit tests

</specifics>

<deferred>
## Deferred Ideas

### BLOCKING: Prior Phase Regressions (Must Fix Before Phase 6 Execution)

These 11 issues were discovered during user testing and must be resolved before performance work begins. Use `/gsd:quick` or `/gsd:insert-phase` to create a regression fix pass.

1. **Cash wallet removed** — System "Cash" / "Cash in Hand" wallet was removed during home screen revamp (Phase 3). NOT requested. Critical for differentiating physical cash from bank/card accounts. Also broke AI cash detection.
2. **Account reorder feature missing** — Drag-and-drop reorder modal (Phase 2B/3 feature) lost during home screen overhaul.
3. **Quick archive feature missing** — Quick archive from reorder modal lost during overhaul.
4. **Archive feature entirely removed** — Archive/unarchive wallet functionality removed entirely.
5. **Balance and card tags LTR instead of center** — RTL alignment regression on home screen.
6. **Set as default feature for accounts missing** — Default account designation UI broken or missing.
7. **AI can't detect Cash wallet** — Downstream breakage from Cash wallet removal affects AI/voice categorization.
8. **Voice Confirm Screen needs "accept all at once"** — Multi-draft review needs batch accept. User requirement: less steps, more accessibility, ease of use, clean/sleek/modern UI.
9. **"Additional details" in transaction form** — Needs rethinking as a toggle approach.
10. **"Subscriptions & Bills" reverted to "Recurring"** — Label regression. Should be "Subscriptions & Bills" everywhere user-facing.
11. **Subscriptions & Bills screen, Transaction Details screen, Add New X screens/bottom sheets** — No UI improvements applied from planned changes. CRUD screens untouched.
12. **Toast notifications appearing mid-screen** — SnackBars should appear at bottom, not centered on screen. Regression.
13. **AI replies in English to Arabizi input** — When user types in Arabizi (Arabic written in Latin script, e.g., "ana sraft 200 gneih"), AI should reply in Arabic since the user's intent is Arabic communication. AI should detect language intent, not just script. Also: AI should reply in the same language the user types in (English input → English reply, Arabic/Arabizi input → Arabic reply), regardless of app locale.

### Not In Scope (Future Phases)
- None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-performance-device-optimization*
*Context gathered: 2026-03-28*
