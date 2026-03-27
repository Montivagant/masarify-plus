---
phase: 04
slug: ai-voice-subscriptions-polish
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 04 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (built-in) |
| **Config file** | None (Flutter default) |
| **Quick run command** | `flutter test test/unit/ --no-pub` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter analyze lib/` (must show zero new issues)
- **After every plan wave:** Run `flutter test` (full suite)
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Req ID | Requirement | Test Type | Automated Command | File Exists | Status |
|--------|-------------|-----------|-------------------|-------------|--------|
| AI-01 | ChatActionMessages l10n keys resolve | unit | `flutter test test/unit/chat_action_messages_l10n_test.dart` | ❌ W0 | ⬜ pending |
| AI-02 | FinancialContext.currentDate populated | unit | `flutter test test/unit/financial_context_test.dart` | ❌ W0 | ⬜ pending |
| AI-06 | Transfer keywords in EN and AR prompts | unit | `flutter test test/unit/transfer_keywords_test.dart` | ❌ W0 | ⬜ pending |
| VOICE-03 | BrandRegistry matches new Egyptian brands | unit | `flutter test test/unit/brand_registry_test.dart` | ❌ W0 | ⬜ pending |
| SUB-03 | BillReminderService schedules correctly | unit | `flutter test test/unit/bill_reminder_service_test.dart` | ❌ W0 | ⬜ pending |
| SUB-04 | DetectedPattern insight card routes | visual | Manual verification | N/A | ⬜ pending |
| AI-05/SUB-05 | Subscription card renders in chat | visual | Manual verification | N/A | ⬜ pending |
| CAT-05 | Category suggestion from title input | unit | Existing detector tests | Partial | ⬜ pending |
| SUB-02 | Due date picker present and labeled | visual | Manual verification | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/unit/brand_registry_test.dart` — covers VOICE-03 (new brands match correctly)
- [ ] `test/unit/bill_reminder_service_test.dart` — covers SUB-03 (scheduling logic, past-date guard)
- [ ] Framework: Already installed (flutter_test) — no additional setup needed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DetectedPattern insight card routes | SUB-04 | Navigation + UI rendering | Tap insight card → verify AddRecurringScreen opens with pre-filled data |
| Subscription card in chat | AI-05/SUB-05 | Interactive widget rendering | Say "paid Netflix 200" in chat → verify interactive "Add to Subscriptions?" card appears |
| Due date picker labeled | SUB-02 | UX labeling verification | Create new subscription → verify date picker shows appropriate label for all frequencies |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
