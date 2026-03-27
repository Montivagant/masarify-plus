---
phase: 03
slug: home-screen-overhaul
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 03 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) |
| **Config file** | None (standard Flutter test runner) |
| **Quick run command** | `flutter test test/unit/ --no-pub` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze lib/` (must be zero issues)
- **After every plan wave:** Run `flutter test` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green + manual RTL check
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Req ID | Requirement | Test Type | Automated Command | File Exists | Status |
|--------|-------------|-----------|-------------------|-------------|--------|
| HOME-01 | Balance header renders with total balance | widget | `flutter test test/widget/balance_header_test.dart` | ❌ W0 | ⬜ pending |
| HOME-02 | "All" chip visually distinct (filled primary) | widget | `flutter test test/widget/account_chip_test.dart` | ❌ W0 | ⬜ pending |
| HOME-03 | Filter state changes update transaction list | unit | `flutter test test/unit/home_filter_test.dart` | ❌ W0 | ⬜ pending |
| HOME-04 | Filter chips produce correct type filter | unit | `flutter test test/unit/home_filter_test.dart` | ❌ W0 | ⬜ pending |
| HOME-05 | Empty zones produce zero height | visual | Manual verification | manual-only | ⬜ pending |
| HOME-06 | Transaction list shows all types (lazy) | unit | `flutter test test/unit/home_filter_test.dart` | ❌ W0 | ⬜ pending |
| HOME-07 | Insight cards display correctly | visual | Manual verification | manual-only | ⬜ pending |
| TXN-01 | Slidable edit/delete callbacks fire | unit | `flutter test test/unit/transaction_actions_test.dart` | ❌ W0 | ⬜ pending |
| TXN-06 | Note field persists and displays | unit | Verify in existing tests | Partial | ⬜ pending |
| TXN-07 | VoiceConfirmScreen renders all fields | widget | `flutter test test/widget/voice_confirm_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/home_filter_test.dart` — stubs for HOME-03, HOME-04, HOME-06 (filter/search/sort provider logic)
- [ ] `test/widget/balance_header_test.dart` — stubs for HOME-01, HOME-02 (balance display, chip selection)
- [ ] `test/unit/transaction_actions_test.dart` — stubs for TXN-01 (delete/edit callbacks, transfer 2-step)
- [ ] `test/widget/voice_confirm_test.dart` — stubs for TXN-07 (voice confirm screen fields)
- [ ] Framework: Already installed (flutter_test) — no additional setup needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Zero whitespace zones | HOME-05 | Visual layout issue — no reliable automated pixel check | Run app in light+dark theme, screenshot home screen, verify no blank zones |
| Insight cards placement | HOME-07 | Contextual placement (scroll-away) is visual | Scroll down, verify insight cards scroll away and filter bar pins |
| Arabic RTL layout | TXN-07 | RTL text overflow requires visual inspection | Switch locale to Arabic, verify voice confirm screen has no overflow |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
