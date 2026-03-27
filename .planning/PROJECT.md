# Masarify (مصاريفي)

## What This Is

An offline-first personal finance tracker for Android (Play Store first, iOS second) targeting Egyptian young professionals. Users track income, expenses, transfers, budgets, and savings goals — with an AI Financial Advisor powered by Gemini that handles voice input, spending recaps, and intelligent categorization. Built with Flutter/Dart, Clean Architecture, Riverpod 2.x, and Drift (SQLite).

## Core Value

**Every transaction recorded effortlessly, offline, in Arabic or English — with an AI advisor that makes spending visible and actionable.** If everything else fails, recording transactions via voice and seeing where money goes must work.

## Requirements

### Validated

<!-- Shipped and confirmed working. Phases P0-P4 + P5 Phases 1-4. -->

- ✓ **TXN-01**: Record income/expense/transfer transactions with category, amount, date, notes — existing
- ✓ **TXN-02**: Voice input via Gemini 2.5 Flash (audio transcription + JSON parsing) — existing
- ✓ **TXN-03**: Smart category defaults, frequency-based chip sorting, time-of-day suggestions — P5 Phase 1
- ✓ **WAL-01**: Multiple accounts (wallets) with starting balance, archiving, drag-and-drop reorder — existing
- ✓ **WAL-02**: Inter-account transfers with full visibility in all transaction lists — existing
- ✓ **BUD-01**: Budget creation per category with progress tracking — existing
- ✓ **GOAL-01**: Savings goals with contribution tracking — existing
- ✓ **REC-01**: Subscriptions & Bills with overdue/upcoming tracking — existing
- ✓ **AI-01**: AI chat advisor (OpenRouter, Gemma/Qwen free models) — existing
- ✓ **AI-02**: Background AI services: auto-categorization learning, recurring detection, spending predictions, budget suggestions — P5 Phase 2A
- ✓ **AI-03**: Proactive daily spending recap notification — P5 Phase 4
- ✓ **AI-04**: Subscription detection suggestions on voice input — P5 Phase 3
- ✓ **DASH-01**: Home dashboard with account carousel, quick actions, insight cards, transaction list — existing
- ✓ **NAV-01**: 4-tab navigation (Home/Transactions/Analytics/More) with floating glassmorphic nav bar — existing
- ✓ **FAB-01**: Center-docked FAB with long-press radial menu (Expense/Mic/Income) — existing
- ✓ **L10N-01**: Full Arabic + English localization, RTL-first — existing
- ✓ **THEME-01**: Light (Minty Fresh) + Dark (Gothic Noir) themes with MD3 design tokens — existing
- ✓ **BACKUP-01**: Google Drive backup with AES-256 encryption — existing
- ✓ **ONBOARD-01**: 5-page onboarding with AI advisor intro — P5 Phase 4
- ✓ **DATA-01**: 34 default categories, brand icon registry (30+ Egyptian brands) — P5 Phase 2B

### Active

<!-- Current milestone: Play Store Launch -->

- [ ] **PERF-01**: App startup time under 2 seconds on mid-range Android devices
- [ ] **PERF-02**: Smooth 60fps scrolling on transaction lists (500+ items)
- [ ] **PERF-03**: Database query optimization for heavy users (1000+ transactions)
- [ ] **PAYWALL-01**: Free tier enforcement (2 budgets, 1 savings goal)
- [ ] **PAYWALL-02**: Pro subscription purchase flow via Google Play Billing
- [ ] **PAYWALL-03**: Paywall UI (upgrade prompts, feature gating, subscription management)
- [ ] **PAYWALL-04**: 7-day free trial for Pro features
- [ ] **ONBOARD-02**: Final onboarding polish (smooth transitions, skip/back, progress indicator)
- [ ] **STORE-01**: Play Store listing (title, description, screenshots, feature graphic)
- [ ] **STORE-02**: Privacy policy and terms of service
- [ ] **STORE-03**: App signing, release build, store submission
- [ ] **STORE-04**: Content rating questionnaire and target audience declaration

### Out of Scope

<!-- Explicit boundaries for this milestone. -->

- **Home Screen Widget** (4.3) — Complex Android-only feature, low ROI for initial launch. Revisit v1.1
- **Lottie Microinteractions** (4.4) — Polish feature, not launch-blocking. Revisit v1.1
- **iOS App Store** — Android first, iOS after Play Store validation
- **SMS Parsing** — Feature-flagged off (kSmsEnabled=false). Legal/compliance risk. Revisit for Pro tier
- **Streak/Gamification** — User explicitly rejected this approach
- **Firebase/Cloud Sync** — Offline-first is core value. Cloud sync is future feature
- **Ads** — Subscription-only monetization, no ads ever

## Context

- **Target Market:** Egyptian young professionals (25-35), English-preferred UI, Arabic for family users
- **Monetization:** Subscription-only. Free: unlimited txns/categories/wallets, 2 budgets, 1 goal. Pro: 59-79 EGP/mo (7-day trial)
- **AI-First Brand:** Positioned as "AI Financial Advisor", not "expense tracker". SMS parsing hidden, voice + AI chat are the hero features
- **Current State:** P5 Phase 4 complete. 218 tests passing. Zero analyzer issues. DB schema v13. ~80 Dart files modified since last commit
- **Platform:** RevenueCat considered but `in_app_purchase` already in pubspec.yaml — use Google Play Billing directly
- **Distribution:** Play Store (AAB) primary. Sideload APK via Google Drive for beta testing. Never send APK via WhatsApp/Telegram (corrupts V2 signature)

## Constraints

- **Tech Stack**: Flutter/Dart, Riverpod, Drift, go_router — already established, no changes
- **Offline-First**: Core features must work without internet. AI features gracefully degrade
- **Money Format**: Integer piastres always (100 EGP = 10000). MoneyFormatter for display
- **RTL-First**: Every screen must work in Arabic RTL. No hardcoded directional values
- **Design Tokens**: AppIcons, AppSizes, AppColors, context.colors — never hardcode
- **Min SDK**: API 24 (Android 7.0) — covers 99% of Egyptian market
- **Impeller Disabled**: BackdropFilter (glassmorphism) causes grey overlay with Impeller on Android

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| AI-first pivot (hide SMS) | iOS incompatible, Play Store risk, brand identity | ✓ Good |
| Subscription-only (no ads) | Better UX, sustainable revenue, premium positioning | — Pending |
| Performance before paywall | Users must feel value before being asked to pay | — Pending |
| Onboarding before Store Prep | Screenshots come from onboarding flow (dependency) | — Pending |
| Defer Home Widget to v1.1 | Complex, Android-only, low ROI for initial launch | — Pending |
| Google Play Billing direct | in_app_purchase already in pubspec, simpler than RevenueCat | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd:transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd:complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-03-27 after initialization*
