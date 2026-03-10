# Masarify (مصاريفي) — Product Requirements Document

**Version:** 1.0
**Date:** March 9, 2026
**Status:** Living document — product archive & reference

---

## 1. Product Overview

**Product Name:** Masarify (مصاريفي — "My Expenses")

**One-liner:** A personal finance app built for Egyptians who want to take control of their money without giving up their data.

**Vision:** Masarify exists because most budgeting apps are either too simple (just a ledger), too complex (enterprise-grade dashboards), or too invasive (cloud-mandatory, ad-supported). Masarify aims to be the sweet spot: smart enough to save users real time through AI voice input, SMS parsing, and predictive insights — while keeping 100% of their financial data on their own device.

### Target Audience

- Egyptian consumers (18–45) managing personal or household finances
- **Primary persona:** Salaried professionals tracking expenses across cash, bank accounts, and mobile wallets (Vodafone Cash, Fawry)
- **Secondary persona:** Freelancers or small business owners who need simple income/expense tracking without accounting software

### Core Differentiators

1. **Privacy-first** — all data stored locally on-device. No Firebase, no cloud accounts, no analytics. Works fully offline.
2. **Egypt-native** — Arabic RTL-first design, Egyptian bank SMS parsing, EGP as primary currency, mobile wallet support.
3. **AI that respects user control** — voice input, SMS parsing, and spending predictions all require user review before saving. No silent automation.
4. **Multi-input convenience** — manual entry, voice commands, bank SMS auto-detection, and notification interception — four ways to log transactions with minimal friction.

### Platform & Localization

- **Platform:** Android (Google Play) first. iOS planned second.
- **Languages:** Arabic (primary), English. Full RTL support.
- **Currencies:** EGP (primary), USD, EUR, SAR, AED, KWD.

---

## 2. Navigation & App Structure

### Bottom Navigation (4 tabs + center FAB)

| Tab | Label | Purpose |
|-----|-------|---------|
| 1 | Home | Dashboard with balances, insights, and quick actions |
| 2 | Transactions | Full transaction list with search, filter, and sort |
| 3 | Analytics | Spending reports, category breakdowns, and trends |
| 4 | More | Planning hub — Accounts, Budgets & Goals, Recurring & Bills, AI Chat |

### Floating Action Button (center-docked, visible on all tabs)

- **Tap:** Add Expense (the most common action)
- **Long press:** Radial menu with three options — Expense, Income, Voice Input

### Settings

Accessible via gear icon in the app bar — not a tab. Covers personalization, security, smart input toggles, data management, and notifications.

### Account Types

- Cash
- Bank Account
- Mobile Wallet (Vodafone Cash, Fawry, etc.)
- Credit Card
- Savings Account

### Transaction Types

- **Expense** — money spent
- **Income** — money earned
- **Transfer** — money moved between own accounts (with optional fee tracking)

---

## 3. Feature Areas

### 3.1 Home Dashboard

The dashboard is the first thing users see. It answers: "How much do I have, where is it going, and should I worry about anything?"

| Feature | Description |
|---------|-------------|
| Net Balance | Single headline number showing total across all accounts. Can be hidden for privacy. |
| Account Carousel | Swipeable cards — page 0 is total balance, pages 1–N are individual accounts. Selecting an account filters the rest of the dashboard. |
| Month Summary | This month's income, expenses, and net change with comparison to last month. |
| Spending Overview | Visual breakdown of top expense categories for the selected period. |
| Recent Transactions | Last few transactions with quick view. |
| AI Insight Cards | Up to 6 offline-generated insight cards (see AI section below). |
| Quick Add Zone | Shortcut buttons for the most frequent transaction types — smart defaults based on time of day and usage patterns. |
| Offline Banner | Appears when no internet — warns that voice input, SMS enrichment, and AI chat are unavailable. |

### 3.2 Transactions

The core ledger. Every financial event in the app lives here.

| Feature | Description |
|---------|-------------|
| Transaction List | Chronological list with date headers, title, amount, category icon, and account. |
| Search & Filter | Filter by keyword, type (expense/income/transfer), category, account, and date range. |
| Transaction Detail | Full view of any transaction — edit, delete, see source badge (Manual, Voice, SMS, Notification, Import). |
| Source Tracking | Every transaction records how it was created, giving users confidence in their data's origin. |

### 3.3 Analytics & Reports

Three tabs answering different questions about spending patterns.

| Tab | What It Answers |
|-----|-----------------|
| Overview | "How am I doing this month?" — income vs. expense, net, daily average, month-over-month comparison. |
| Categories | "Where is my money going?" — ranked category breakdown with bar/pie charts. |
| Trends | "Is my spending getting better or worse?" — income/expense trends over 7, 30, 90 days, 6 months, and 1 year. |

### 3.4 Accounts

Users manage their financial accounts (cash, bank, mobile wallet, credit card, savings).

| Feature | Description |
|---------|-------------|
| Account Management | Create, edit, delete accounts with name, type, starting balance, and icon. |
| Account Detail | View balance and transaction history for a single account. |
| Transfers | Move money between accounts with optional fee tracking (e.g., ATM withdrawal fee). |

### 3.5 Budgets

Monthly spending limits per category with progress tracking.

| Feature | Description |
|---------|-------------|
| Set Budget | Choose a category, set a monthly limit. |
| Progress Tracking | Visual progress bar — green/yellow/red based on percentage spent. |
| Rollover | Optional: unused budget rolls into next month (e.g., spend 800 of 1,000 → next month limit is 1,200). |
| Alerts | Notifications at 80% and 100% of budget spent. |
| AI Suggestions | App recommends budgets for unbudgeted categories where average monthly spend exceeds 500 EGP. |

### 3.6 Savings Goals

Target-based saving with progress tracking and milestones.

| Feature | Description |
|---------|-------------|
| Create Goal | Name, target amount, optional deadline, optional linked account. |
| Contributions | Add contributions manually or link transactions. |
| Progress | Visual bar with percentage, amount remaining, days remaining. |
| Milestones | Notifications at 25%, 50%, 75%, and 100% of target reached. |
| Status | Active, Completed, or Overdue (if deadline passed without reaching target). |

### 3.7 Recurring & Bills

Unified feature handling both repeating transactions and one-time bills.

| Feature | Description |
|---------|-------------|
| Create Rule | Set title, amount, category, account, frequency (once/daily/weekly/monthly/yearly/custom), start date, optional end date. |
| Four-Section View | Organized by status: Overdue Bills, Upcoming Bills, Active Recurring, Paid. |
| Mark as Paid | Marks one instance paid, creates a transaction record, and auto-advances to the next due date. |
| Pause/Resume | Temporarily disable a recurring rule without deleting it. |
| Reminders | Notifications before due dates. |

### 3.8 Settings

| Area | Capabilities |
|------|-------------|
| Personalization | Language (EN/AR/System), currency, theme (light/dark/system), first day of week, first day of month for budget cycles. |
| Security | 6-digit PIN, biometric login, auto-lock timeout (immediate/1 min/5 min). |
| Smart Input | Toggle voice input, SMS parser, notification parser. Choose AI model. |
| Data Management | JSON backup/restore, CSV export, PDF report export. |
| Categories | View, create, edit, delete custom expense/income categories. |
| Notifications | Control budget warnings, bill reminders, goal milestones, daily expense reminders, quiet hours. |

---

## 4. AI & Automation

Masarify uses AI to reduce friction in logging transactions and to surface spending insights — but never acts without user confirmation.

### 4.1 Voice Input (requires internet)

Users long-press the FAB and tap the mic icon. They speak naturally — "Spent 50 on coffee at Starbucks" or "Income 2000 salary" — and the app creates a transaction draft for review.

**Flow:** Record audio (WAV 16 kHz mono) → Send to Google Gemini 2.5 Flash (transcription + parsing in one API call) → Present draft with title, amount, category suggestion, and account → User reviews, edits if needed, confirms to save.

Nothing is saved without explicit confirmation.

### 4.2 SMS & Notification Parsing (offline core, optional online enrichment)

The app reads incoming bank SMS messages and notifications, matches them against known Egyptian bank patterns (on-device regex — no data leaves the phone), and presents parsed transactions for user review.

**Flow:** SMS/notification received → On-device pattern matching → Parsed transaction appears in review queue → User approves, edits, or skips.

**Optional AI Enrichment (requires internet):** Users can tap "Enrich" on a parsed transaction to have an AI model (via OpenRouter) detect the merchant name, suggest a category, and add notes. Enriched fields appear in the form for approval — never auto-saved.

### 4.3 Background Intelligence (fully offline)

Four services run on-device using only the user's local transaction history:

| Service | What It Does | How Users See It |
|---------|-------------|-----------------|
| Auto-Categorization Learning | Learns which category the user picks for similar transaction titles. Over time, new transactions pre-fill the most likely category. | Category field auto-suggested on new transactions. |
| Recurring Pattern Detection | Analyzes 90 days of transactions, groups by category + amount, detects weekly/monthly patterns with confidence scoring. | Dashboard insight card: "You spend X on Y every month — add as recurring?" |
| Spending Prediction | Predicts end-of-month spend per budgeted category using 60% current pace + 40% historical average. Flags categories on track to exceed budget. | Dashboard insight card: "Dining is on pace to hit 110% of budget by month-end." |
| Budget Suggestions | Identifies unbudgeted categories with average monthly spend above 500 EGP. Recommends the top 2. | Dashboard insight card: "You spend ~800/month on Transport — set a budget?" |

### 4.4 AI Chat Assistant (requires internet)

A conversational interface where users ask questions about their finances or take actions via natural language.

**Capabilities:**

- Query spending ("How much did I spend on food this month?")
- Get suggestions ("Should I set a budget for groceries?")
- Create transactions, budgets, or goals through conversation with a confirmation step before saving

Uses free models via OpenRouter (Gemma/Qwen). Shows offline warning when unavailable.

---

## 5. Key User Flows

### Flow 1: Adding a Transaction via Voice

1. User long-presses the FAB on any tab → radial menu appears
2. Taps the mic bubble → recording screen opens
3. Speaks: "Lunch 85 pounds at Zooba"
4. App sends audio to Gemini → receives parsed draft
5. Confirmation screen shows: Title "Lunch at Zooba", Amount 85 EGP, Category "Dining Out", Account "Cash"
6. User adjusts category or account if needed → taps Confirm
7. Transaction saved, user returned to previous screen

### Flow 2: Reviewing Parsed SMS Transactions

1. User receives bank SMS: "Purchase EGP 250.00 at Carrefour Maadi from a/c **1234"
2. App intercepts SMS, on-device regex extracts amount (250 EGP), type (expense), and raw merchant text
3. Parsed transaction appears in the review queue (Transactions tab → Parsed Transactions)
4. User opens the item → sees pre-filled amount and raw text
5. Optionally taps "Enrich" → AI fills in: Title "Carrefour Maadi", Category "Groceries"
6. User reviews, confirms → transaction saved to ledger
7. Or user skips → item stays in queue, no transaction created

### Flow 3: Setting a Budget and Getting Warned

1. User goes to More → Budgets → taps "Set Budget"
2. Selects category "Dining Out", enters limit 1,500 EGP/month, optionally enables rollover
3. Budget saved — progress bar appears showing 0% spent
4. Over the month, dining transactions accumulate
5. At 80% (1,200 EGP spent) → push notification: "Dining Out budget is at 80%"
6. Dashboard insight card also appears: "Dining is on pace to exceed budget by month-end"
7. At 100% → notification: "Dining Out budget exceeded"

### Flow 4: Creating a Savings Goal and Tracking Progress

1. User goes to More → Goals → taps "Add Goal"
2. Enters: "New iPhone", target 25,000 EGP, deadline 6 months from now
3. Goal card appears with progress bar at 0%, showing "25,000 EGP remaining, 180 days left"
4. User periodically adds contributions (manual amount or links a transaction)
5. At 25% (6,250 EGP) → milestone notification
6. Progress bar and remaining amount update in real time
7. If deadline approaches with insufficient progress → status changes to "Overdue"

### Flow 5: Discovering a Recurring Pattern via AI

1. User has been paying 200 EGP for a gym membership monthly for the last 3 months
2. Background Recurring Pattern Detector analyzes 90-day history, finds the pattern (same category, same amount, monthly interval, confidence above threshold)
3. Dashboard insight card appears: "You spend 200 EGP on Fitness every month — add as recurring?"
4. User taps the card → pre-filled Add Recurring screen with title, amount, category, monthly frequency
5. User confirms → recurring rule created, future instances tracked with reminders

---

## 6. Data & Privacy

Masarify's privacy stance is a core product differentiator, not just a policy checkbox.

- **100% offline-first.** Every feature except voice input, AI chat, and optional SMS enrichment works without internet. No account creation required. No cloud sync.
- **On-device storage.** All financial data lives in a local SQLite database on the user's phone. Nothing is sent to any server unless the user explicitly triggers an AI feature that requires it.
- **SMS parsing is local.** Bank SMS messages are parsed using on-device regex patterns. The raw SMS content never leaves the phone unless the user taps "Enrich" to request AI categorization.
- **User-controlled security.** Optional 6-digit PIN, biometric unlock, and configurable auto-lock timeout.
- **Backup is manual.** Users export/import JSON backups themselves. No silent cloud backup. PDF and CSV exports available for personal record-keeping.

---

## 7. Monetization

Monetization is planned but not yet defined. The current app is fully free with no feature gating. A Pro subscription tier is anticipated for a future phase, with the free tier remaining fully functional for core features. Details (pricing, pro-only features, payment provider) are to be determined.

---

## 8. Current Status

- **Phase:** P5 (Post-Launch AI & Monetization) — in progress
- **Completed:** Foundation, data layer, MVP UI, smart features, polish & launch prep, background AI intelligence
- **In progress:** AI chat assistant, remaining polish items (home widget, microinteractions, onboarding polish, performance, Play Store prep)
- **Database schema:** Version 6, 12 tables
- **Test suite:** 64 tests passing
- **Static analysis:** Zero issues
