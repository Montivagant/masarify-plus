---
phase: 01-compliance-billing-foundation
plan: 01
subsystem: infra
tags: [android, targetSdk, edge-to-edge, manifest, google-fonts, compliance]

# Dependency graph
requires: []
provides:
  - targetSdk 35 in release build
  - Edge-to-edge opt-out for API 35 (safe for API 36+)
  - SCHEDULE_EXACT_ALARM removed from manifest
  - GoogleFonts runtime fetching disabled (offline-first)
affects: [02-verification-sweep, 07-store-submission]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "values-v35 resource qualifier for API 36+ crash prevention"

key-files:
  created:
    - android/app/src/main/res/values-v35/styles.xml
  modified:
    - android/app/build.gradle.kts
    - android/app/src/main/res/values/styles.xml
    - android/app/src/main/AndroidManifest.xml
    - lib/main.dart

key-decisions:
  - "Edge-to-edge opt-out via windowOptOutEdgeToEdgeEnforcement in base styles + values-v35 override omitting it for API 36+ safety"
  - "SCHEDULE_EXACT_ALARM directly deleted (no tools:node=remove) since no transitive dependency declares it"

requirements-completed: [STORE-01, CLEAN-03]

# Metrics
duration: 11 min
completed: 2026-03-27
---

# Phase 1 Plan 1: SDK & Manifest Compliance Summary

**targetSdk bumped to 35, edge-to-edge opted out for glassmorphic nav bar, SCHEDULE_EXACT_ALARM removed, GoogleFonts runtime fetching disabled**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-27T16:27:21Z
- **Completed:** 2026-03-27T16:38:25Z
- **Tasks:** 6
- **Files modified:** 5 (4 modified + 1 created)

## Accomplishments
- targetSdk bumped from 34 to 35 meeting Google Play August 2025 deadline
- Edge-to-edge enforcement opted out on API 35 to preserve glassmorphic nav bar rendering, with values-v35 override to prevent crash on API 36+
- SCHEDULE_EXACT_ALARM permission removed from AndroidManifest (app uses inexact alarms only)
- GoogleFonts.config.allowRuntimeFetching disabled before runApp() enforcing offline-first font loading
- Release build (flutter build appbundle --release) succeeds; merged manifest confirms no SCHEDULE_EXACT_ALARM and targetSdkVersion=35

## Task Commits

Each task was committed atomically:

1. **Task 1.1.1: Bump targetSdk from 34 to 35** - `150713d` (feat)
2. **Task 1.1.2: Add edge-to-edge opt-out to values/styles.xml** - `82027ed` (feat)
3. **Task 1.1.3: Create values-v35/styles.xml WITHOUT opt-out** - `bb20bb4` (feat)
4. **Task 1.1.4: Delete SCHEDULE_EXACT_ALARM from AndroidManifest.xml** - `a7ec017` (fix)
5. **Task 1.1.5: Disable GoogleFonts runtime fetching in main.dart** - `b3ac7ec` (feat)
6. **Task 1.1.6: Verify build succeeds** - (verification only, no commit needed)

## Files Created/Modified
- `android/app/build.gradle.kts` - targetSdk changed from 34 to 35
- `android/app/src/main/res/values/styles.xml` - windowOptOutEdgeToEdgeEnforcement=true on both themes
- `android/app/src/main/res/values-v35/styles.xml` (NEW) - API 36+ safe override omitting the opt-out attribute
- `android/app/src/main/AndroidManifest.xml` - SCHEDULE_EXACT_ALARM permission and section comment removed
- `lib/main.dart` - google_fonts import added, allowRuntimeFetching=false set after ensureInitialized()

## Decisions Made
- Edge-to-edge opt-out uses `windowOptOutEdgeToEdgeEnforcement` in base `values/styles.xml` with a `values-v35/` override that omits the attribute to prevent crashes on API 36+ where it was removed
- SCHEDULE_EXACT_ALARM was directly deleted (not `tools:node="remove"`) since no transitive dependency declares this permission

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Worktree missing gitignored files**
- **Found during:** Task 1.1.6 (verification/build)
- **Issue:** Worktree was missing `env.dart`, `google-services.json`, `key.properties`, and `masarify-release.jks` (all gitignored) which are required for analysis and release build
- **Fix:** Copied gitignored files from main repo to worktree to enable build verification
- **Files modified:** None committed (all files are gitignored)
- **Verification:** flutter analyze and flutter build appbundle --release both succeed
- **Committed in:** N/A (no committed file changes)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Worktree environment setup only. No scope creep.

## Issues Encountered
None beyond the worktree gitignored files (resolved as deviation above).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SDK compliance complete, ready for Plan 01-2 (Package & Settings Cleanup)
- Release build verified on targetSdk 35
- No blockers

---
*Phase: 01-compliance-billing-foundation*
*Completed: 2026-03-27*
