---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
current_phase: 03.1
status: executing
stopped_at: Phase 3.1 complete — all 3 plans done
last_updated: "2026-03-28T03:35:00.000Z"
progress:
  total_phases: 8
  completed_phases: 6
  total_plans: 20
  completed_plans: 20
---

# Masarify — Project State

**Current Phase:** 03.1
**Status:** Executing Phase 03.1
**Last Updated:** 2026-03-27

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)
**Core value:** Every transaction recorded effortlessly, offline, in Arabic or English — with an AI advisor that makes spending visible and actionable.
**Current focus:** Phase 03.1 — regression-fix-feature-audit

## Phase Progress

| Phase | Name | Status | Plans |
|-------|------|--------|-------|
| 1 | Compliance & Billing Foundation | ● Complete | 3/3 |
| 2 | Verification Sweep | ● Complete | 4/4 |
| 3 | Home Screen Overhaul | ◑ In progress | 2/3 |
| 3.1 | Regression Fix & Feature Audit | ● Complete | 3/3 |
| 4 | AI, Voice & Subscriptions Polish | ● Complete | 3/3 |
| 5 | Monetization & Onboarding | ○ Pending | 0/4 |
| 6 | Performance & Device Optimization | ○ Pending | 0/3 |
| 7 | Store Submission | ○ Pending | 0/3 |

## Quick Reference

| Symbol | Meaning |
|--------|---------|
| ○ | Pending — not started |
| ◑ | In progress |
| ● | Complete |
| ✗ | Blocked |

## Milestone

**Target:** Play Store Launch (Production)
**Submission target:** Internal Testing → Closed Testing → Production
**Buffer:** Allow 2-week review buffer after first AAB upload (Finance apps face manual review)

## Key Dependencies

- Phase 1 must complete before Phase 2 (SDK bump affects all UI rendering)
- Phase 2 must complete before Phases 3 and 4 (verified foundation before new features)
- Phases 3 and 4 run in parallel (no shared file dependencies)
- Phase 5 requires both Phase 3 and Phase 4 complete (monetization gates polished features)
- Phase 6 requires Phase 5 complete (profile stable UI, not moving targets)
- Phase 7 requires Phase 6 complete (screenshots from optimized app; performance targets met)

## Critical Path

Phase 1 → Phase 2 → Phase 3 → **Phase 3.1 (INSERTED)** → Phase 5 → Phase 6 → Phase 7
(Phase 4 runs parallel to Phase 3 and is off the critical path unless it takes longer)

## Accumulated Decisions

| Phase | Decision | Rationale |
|-------|----------|-----------|
| 01 | BL7 (in_app_purchase_android 0.4.0+8) compliant through Aug 2026 | No BL8 migration needed; avoids risk and RevenueCat dependency |
| 01 | Optional DAO injection for SubscriptionService | Gradual Drift integration; SharedPreferences remains fallback |
| 01 | Schema bumped v11 to v14 (incorporating uncommitted v12/v13) | Complete migration chain required for Drift code generation |
| 02 | Negative synthetic IDs for transfer entries | Avoids collision with real transaction IDs while keeping IDs deterministic |
| 02 | Transfer metadata encoded in tags field | Keeps TransactionEntity pure without adding new fields |
| 02 | Category-first display in TransactionCard | Bold categoryName primary, muted title secondary per P5 Phase 2B design |
| 02 | Schema bumped v13 to v14 to register SubscriptionRecords table | Phase 1 deliverable was incomplete; table created but not registered in @DriftDatabase |
| 02 | Added flutter_markdown for AI chat rendering | Was referenced in MEMORY.md but never committed; small well-maintained package |
| 02 | Inline keyword lists for subscription/cash detection | Avoids dependency on uncommitted SubscriptionDetector/WalletMatcher utilities |
| 02 | Created env.dart stub for dart-define variables | Resolves pre-existing analyzer errors; file is gitignored |
| 02 | showSuccessAndReturn/showInfoAndReturn for .closed patterns | Undo-then-record and deferred callbacks need ScaffoldFeatureController |
| 02 | Pre-built SnackBar for defunct context callbacks | onPressed fires after screen pop; context.appTheme unavailable |

- [Phase 03]: Used SliverToBoxAdapter for balance header instead of SliverAppBar to avoid dynamic expandedHeight and BackdropFilter issues
- [Phase 03]: Direct wallet-ID selection (StateProvider<int?>) replaces index-based carousel selection
- [Phase 03]: Flat _ListItem union type for interleaving date headers and transaction cards in SliverList
- [Phase 03]: Transfer deletion extracts original ID via syntheticId ~/ 2 from TransferAdapter convention
- [Phase 03]: SlidableAutoCloseBehavior wraps CustomScrollView for proper group close behavior
- [Phase 03.1]: Code-level Arabizi detector (isArabizi) supplements prompt-level Franco-Arab instruction
- [Phase 03.1]: Cash wallet included in AI FinancialContext walletList (was excluded by isSystemWallet filter)
- [Phase 03.1]: Voice confirm _applyDefaults already searches all wallets for Cash matching (verified, no fix needed)
- [Phase 03.1]: Brand icon pipeline verified: 60 brands, BrandRegistry.match() wired to TransactionCard via TransactionListSection

## Roadmap Evolution

- Phase 3.1 inserted after Phase 3: Regression Fix & Feature Audit (URGENT) — 18+ regressions discovered during user testing including removed features (Cash wallet, archive, account reorder), broken UI (RTL alignment, toast position, voice confirm layout), missing brand icons, AI language detection issues, and untouched CRUD screens.

## Known Issues

- No "set as default" UI for wallets (isDefaultAccount exists but no way to change via UI). Deferred.
- Phase 3 Home Screen Overhaul plan 3 still pending (2/3 complete).

## Session Continuity

**Last session:** 2026-03-28T03:35:00.000Z
**Stopped at:** Phase 3.1 complete — all 3 plans executed. Ready to proceed to Phase 5.
**Resume file:** .planning/phases/03.1-regression-fix-feature-audit/03.1-03-SUMMARY.md

---
*State initialized: 2026-03-27*
