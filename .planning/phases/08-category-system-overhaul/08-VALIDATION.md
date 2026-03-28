---
phase: 8
slug: category-system-overhaul
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-28
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) |
| **Config file** | none (default Flutter test setup) |
| **Quick run command** | `flutter test test/unit/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit/`
- **After every plan wave:** Run `flutter test && flutter analyze lib/`
- **Before `/gsd:verify-work`:** Full suite must be green + Feature Preservation Checklist verified manually
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 08-01-01 | 01 | 0 | D-17 | unit | `flutter test test/unit/category_entity_test.dart` | ❌ W0 | ⬜ pending |
| 08-01-02 | 01 | 0 | D-12 | unit | `flutter test test/unit/category_usage_test.dart` | ❌ W0 | ⬜ pending |
| 08-01-03 | 01 | 0 | D-07 | unit | `flutter test test/unit/category_merge_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-01 | 02 | 1 | D-08 | unit | `flutter test test/unit/category_seed_test.dart` | ❌ W0 | ⬜ pending |
| 08-02-02 | 02 | 1 | D-14 | unit | `flutter test test/unit/category_merge_test.dart` | ❌ W0 | ⬜ pending |
| 08-03-01 | 03 | 2 | D-01 | widget | `flutter test test/widget/glass_category_icon_test.dart` | ❌ W0 | ⬜ pending |
| 08-03-02 | 03 | 2 | D-02 | widget | Manual verification | N/A | ⬜ pending |
| 08-04-01 | 04 | 3 | D-03 | widget | Manual verification | N/A | ⬜ pending |
| 08-04-02 | 04 | 3 | D-05 | integration | Manual verification | N/A | ⬜ pending |
| 08-05-01 | 05 | 4 | D-25 | integration | Manual verification + Feature Preservation Checklist | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/category_entity_test.dart` — covers D-17 (entity without groupType)
- [ ] `test/unit/category_merge_test.dart` — covers D-07, D-14 (merge logic, usageCount combine)
- [ ] `test/unit/category_usage_test.dart` — covers D-12 (usage increment)
- [ ] `test/unit/category_seed_test.dart` — covers D-08 (seed count ~20)

*Existing test infrastructure covers framework setup. Only test files need creation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Glass icon renders correctly | D-01 | Visual correctness requires human eye | Open any category picker, verify glass circles with white icons |
| Picker shows Most Used section | D-02 | Layout/ordering visual | Open picker, verify top 5 most-used appear first |
| Management screen hybrid layout | D-03 | Visual layout verification | Open categories screen, verify grid+list+swipe+drag |
| 3-step delete flow | D-05 | Multi-step dialog UX | Delete category with transactions, verify impact→archive→migrate flow |
| Cross-app picker consistency | D-25 | 3 different screens must match | Test picker in add_transaction, set_budget, add_recurring screens |
| RTL layout validation | D-23 | Visual RTL correctness | Switch to Arabic, verify all category screens render correctly |
| Feature Preservation Checklist | D-24 | 40+ items across 4 feature areas | Run full checklist from CONTEXT.md after each plan completion |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
