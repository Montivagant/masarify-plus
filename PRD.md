# PRD.md — Masarify Product Requirements Document

**Personal Money Tracker · Offline-First · Flutter · Android (iOS Later)**
Version 1.3 | February 2026 (Visual Refresh)

---

## 1. Product Vision

Masarify (مَسارِفي) is an offline-first personal money tracking app designed primarily for Egyptian and MENA users. It helps people track every pound they earn and spend — without connecting to banks, without requiring internet, and without the complexity of full financial planning tools.

**Core Promise:** "سيطر على فلوسك — Track Every Pound. Own Your Money."

**What Masarify IS:**
- A personal expense and income tracker
- A budget and savings goal manager
- A smart input tool (voice, SMS/notification parsing)
- Offline-first, privacy-respecting, locally-stored

**What Masarify is NOT:**
- A banking app (no bank connections, no payment processing)
- A fintech app (no real money movement)
- A financial planning tool (no investment tracking, no tax calculations)
- A shared/family finance tool (single-user in v1)

---

## 2. Target Users & Personas

### Persona 1: Mariam — The Budget-Conscious Professional
- **Age:** 25-35 | **Location:** Cairo | **Income:** EGP 8,000-15,000/month
- **Pain:** Doesn't know where her salary goes each month. Tried spreadsheets but can't keep up.
- **Need:** Quick daily logging of expenses, monthly budget view, simple insights.
- **Behavior:** Opens the app 2-3x daily to log transactions. Prefers Arabic interface. Uses voice input while commuting.
- **Success metric:** Knows exactly how much she can still spend this month.

### Persona 2: Ahmed — The Savings-Focused Student
- **Age:** 18-24 | **Location:** Alexandria | **Income:** EGP 2,000-5,000/month (part-time + allowance)
- **Pain:** Wants to save for a laptop but keeps overspending without realizing.
- **Need:** Savings goals with visual progress, low-effort tracking.
- **Behavior:** Opens app 1x daily, mostly logs food and transport. Uses notification parser for Vodafone Cash.
- **Success metric:** Reaches his savings goal on time.

### Persona 3: Noura — The Small Business Freelancer
- **Age:** 28-40 | **Location:** Mansoura | **Income:** Variable (EGP 5,000-20,000/month)
- **Pain:** Income is irregular. Needs to track what comes in from different clients and manage cash flow.
- **Need:** Multiple wallets (cash + bank + mobile wallet), recurring transactions, bill tracker.
- **Behavior:** Opens app daily, logs client payments as income, tracks business expenses separately. Exports monthly CSV for accountant.
- **Success metric:** Clear picture of monthly profit and upcoming bills.

---

## 3. Competitive Analysis

| App | Strengths | Weaknesses | Masarify Differentiator |
|-----|-----------|------------|------------------------|
| **Money Lover** | Polished UI, multi-currency, cloud sync | No Arabic voice input, no Egyptian SMS parsing | Arabic-first, Egyptian dialect voice, SMS/notification parsing |
| **Wallet by BudgetBakers** | Bank sync, shared budgets | Requires internet for key features, no offline | 100% offline-first, no bank connections needed |
| **YNAB** | Zero-based budgeting philosophy, education | English-only, expensive ($14.99/mo), no Arabic | Arabic-first, free core, Egyptian-focused |
| **Masareef** | Arabic interface, simple | Very basic, no budgets/goals, outdated UI | Modern MD3 design, budgets, goals, smart input |
| **Cleo** | AI-powered insights, fun tone | English-only, requires bank linking | Offline AI insights, no bank linking, Arabic |

**Masarify's unique position:** The only offline-first, Arabic-first, Egyptian-dialect-aware money tracker with voice input and SMS parsing, built with modern design standards.

---

## 4. Success Metrics & KPIs

### Launch (First 90 Days)
| Metric | Target | Measurement |
|--------|--------|-------------|
| Play Store installs | 5,000 | Play Console |
| Day 7 retention | ≥ 30% | Analytics (post-v1) |
| Day 30 retention | ≥ 15% | Analytics (post-v1) |
| Average rating | ≥ 4.0 stars | Play Store |
| Crash-free rate | ≥ 99.5% | Play Console Android Vitals + local crash log |

### Engagement (Ongoing)
| Metric | Target | Measurement |
|--------|--------|-------------|
| Transactions per active user per week | ≥ 5 | Local analytics or surveys |
| Voice input adoption | ≥ 10% of transactions | In-app stats screen (local) |
| Budget feature adoption | ≥ 40% of active users set at least 1 budget | Local check |
| Goals feature adoption | ≥ 25% of active users create at least 1 goal | Local check |

> **Note:** Since the app is offline-first, engagement metrics in v1 are limited to crash reporting and Play Store data. Detailed analytics require opt-in analytics in a future version.

---

## 5. Feature Prioritization (MoSCoW)

### Must Have (Launch Blockers)
- Manual transaction tracking (expense, income)
- Wallet management (create, edit, delete, transfer between)
- Category management (22 defaults + custom)
- Monthly budgets with progress tracking
- Savings goals with contribution tracking
- Transaction list with search, filter, sort
- Dashboard with balance, monthly summary, budget health, recent transactions
- Settings: language, currency, theme, first-day-of-week
- Backup/restore (local JSON)
- PIN lock + biometric authentication
- Onboarding with first wallet creation
- Dark mode + RTL Arabic support

### Should Have (Important, but app ships without if needed)
- Voice input (Egyptian Arabic + English) — ✅ Implemented (P3)
- Notification parser (Egyptian banks/wallets)
- Recurring transactions + bill tracker — ✅ Implemented (P3)
- Cashflow calendar view — ✅ Implemented (P3)
- Analytics & reports (charts, category breakdown) — ✅ Implemented (P3)
- CSV/PDF export
- Smart insights engine — ✅ Implemented (P3)
- Home screen widget

### Could Have (Nice-to-Have, Post-Launch)
- Location tagging on transactions
- Net worth tracking
- Receipt photo attachment
- Goal keyword auto-matching
- Custom category icons beyond default set

### Won't Have (v1 Explicitly Excludes)
- Bank account connections
- Payment processing
- Cloud sync / multi-device
- Family/shared budgets
- Investment tracking
- In-app purchases / monetization (scaffolded but disabled)

### Now Implemented (Upgraded from Phase 5 to Phase 4)
- SMS parser enabled for Play Store (ENABLED — submit SMS permission declaration)
- AI voice parsing: multi-model fallback chain via OpenRouter (Gemini Flash → Gemma 3 27B → Qwen3 4B) with ZDR privacy enforcement
- AI-enhanced SMS/notification parsing: Qwen3 4B enriches parsed transactions with category, merchant name, and note
- Expandable radial FAB: long press to expand 3 bubbles (Expense, Mic, Income), swipe to select
- **Visual refresh (P4):** Minty Fresh (light) + Gothic Noir (dark) theme palettes, Phosphor Icons (replacing Material Icons), StylishBottomBar with liquid animation and FAB notch support
- Voice input: Arabic locale gate removed — works with any device language (AI parser handles English, Arabic, Arabizi, mixed input)
- SMS/notification toggle crash fixes: try-catch with mounted checks, toggle reversion on failure

---

## 6. Default Categories (22)

### Expense Categories (16)

| # | Name (EN) | Name (AR) | Icon | Color | Group |
|---|-----------|-----------|------|-------|-------|
| 1 | Food & Dining | أكل ومشروبات | restaurant | #FF6B6B | Needs |
| 2 | Transport | مواصلات | directions_car | #4ECDC4 | Needs |
| 3 | Housing & Rent | سكن وإيجار | home | #45B7D1 | Needs |
| 4 | Utilities | فواتير (كهرباء/مياه/غاز) | bolt | #96CEB4 | Needs |
| 5 | Phone & Internet | موبايل وإنترنت | phone_android | #6C5CE7 | Needs |
| 6 | Healthcare | صحة وأدوية | local_hospital | #E17055 | Needs |
| 7 | Groceries | بقالة وسوبرماركت | shopping_cart | #00B894 | Needs |
| 8 | Education | تعليم | school | #0984E3 | Needs |
| 9 | Shopping | تسوق | shopping_bag | #E84393 | Wants |
| 10 | Entertainment | ترفيه | movie | #FD79A8 | Wants |
| 11 | Clothing | ملابس | checkroom | #A29BFE | Wants |
| 12 | Personal Care | عناية شخصية | spa | #FFEAA7 | Wants |
| 13 | Gifts & Donations | هدايا وتبرعات | card_giftcard | #FAB1A0 | Wants |
| 14 | Travel | سفر | flight | #55A3F0 | Wants |
| 15 | Subscriptions | اشتراكات | subscriptions | #636E72 | Wants |
| 16 | Other Expense | مصروفات أخرى | more_horiz | #B2BEC3 | — |

### Income Categories (6)

| # | Name (EN) | Name (AR) | Icon | Color |
|---|-----------|-----------|------|-------|
| 17 | Salary | مرتب | payments | #00B894 |
| 18 | Freelance | عمل حر | work | #00CEC9 |
| 19 | Business | مشروع | store | #0984E3 |
| 20 | Gifts Received | هدايا مستلمة | redeem | #E17055 |
| 21 | Investment Returns | عوائد استثمار | trending_up | #6C5CE7 |
| 22 | Other Income | دخل آخر | more_horiz | #B2BEC3 |

---

## 7. Screen Inventory

### Navigation Structure

```
Bottom Nav (4 tabs) + Center FAB (Home + Transactions tabs)
├── Tab 1: Home (Dashboard)
│   └── Quick Actions: +Expense, +Income, Transfer
├── Tab 2: Transactions (List + Search/Filter)
├── Tab 3: Analytics (ReportsScreen with 4 sub-tabs)
│   ├── Overview (income vs expense bar chart, last 6 months)
│   ├── Categories (horizontal bar chart + ranked list)
│   ├── Trends (line chart with 7d/30d/90d toggle)
│   └── Comparison (this month vs last month side-by-side)
└── Tab 4: More (Hub)
    ├── Money: Wallets (with Transfer)
    ├── Planning: Budgets, Goals, Bills, Recurring
    ├── Reports: Calendar, Net Worth, Smart Insights
    ├── App: Settings, Backup & Export, About
    └── Settings
        ├── General (language, currency, theme, first-day)
        ├── Security (PIN, biometrics, auto-lock)
        ├── Notifications
        ├── Smart Input (voice, notification parser, SMS toggle)
        ├── Subscription (Phase 5)
        └── About
```

### Full Screen List

| # | Screen | Route | Phase |
|---|--------|-------|-------|
| 1 | Splash | `/splash` | 2 |
| 2 | Onboarding (2 pages) | `/onboarding` | 2 |
| 3 | Dashboard | `/` (home) | 2 |
| 4 | Transaction List | `/transactions` | 2 |
| 5 | Add/Edit Transaction | `/transactions/add`, `/transactions/:id/edit` | 2 |
| 6 | Transaction Detail | `/transactions/:id` | 2 |
| 7 | Wallets List | `/wallets` | 2 |
| 8 | Add/Edit Wallet | `/wallets/add`, `/wallets/:id/edit` | 2 |
| 9 | Wallet Detail | `/wallets/:id` | 2 |
| 10 | Transfer | `/transfer` | 2 |
| 11 | Categories | `/categories` | 2 |
| 12 | Add/Edit Category | `/categories/add`, `/categories/:id/edit` | 2 |
| 13 | Budgets List | `/budgets` | 2 |
| 14 | Set Budget | `/budgets/set` | 2 |
| 15 | Goals List | `/goals` | 2 |
| 16 | Add/Edit Goal | `/goals/add`, `/goals/:id/edit` | 2 |
| 17 | Goal Detail | `/goals/:id` | 2 |
| 18 | Settings | `/settings` | 2 |
| 19 | Recurring Rules | `/recurring` | 3 |
| 20 | Add/Edit Recurring | `/recurring/add`, `/recurring/:id/edit` | 3 |
| 21 | Bills | `/bills` | 3 |
| 22 | Add/Edit Bill | `/bills/add`, `/bills/:id/edit` | 3 |
| 23 | Voice Input Sheet | Bottom sheet (no route) | 3 |
| 24 | Voice Confirmation | `/voice/confirm` | 3 |
| 25 | SMS/Notification Review | `/parser/review` | 3 |
| 26 | Calendar | `/calendar` | 3 |
| 27 | Reports | `/reports` | 3 |
| 28 | Net Worth | `/net-worth` | 3 |
| 29 | Insights | `/insights` | 3 |
| 30 | PIN Setup | `/auth/pin-setup` | 4 |
| 31 | PIN Entry | `/auth/pin-entry` | 4 |
| 32 | Backup & Export | `/settings/backup` | 4 |
| 33 | Notification Preferences | `/settings/notifications` | 4 |
| 34 | Paywall | `/paywall` | 5 |
| 35 | Subscription | `/settings/subscription` | 5 |

---

## 8. User Journey Maps

### Journey 1: First-Time User Adds First Transaction
```
Install → Splash (1.5s) → Onboarding Page 1 (read tagline, "Get Started") →
Onboarding Page 2 ("Starting balance?" → enter 0 or skip) → "Start Tracking" →
Dashboard (empty state: "Welcome! Tap + to add your first expense") →
Tap FAB (+) → AddTransaction opens directly (Expense preselected) →
Enter 150 on keypad → Pick category (Food — shown in top row) → "Save" →
Success haptic + checkmark → Dashboard updated
```
**Total taps from dashboard to saved transaction: 4** (FAB → amount → category → save)

### Journey 2: Returning User Checks Budget Health
```
Open app → PIN Entry (or biometric) → Dashboard →
See Budget Health section: "Food 78%" bar in amber →
Tap "See All" → Budgets screen (full list) →
Tap "Food" budget → see detailed category transactions for this month
```
**Total taps: 3-4**

### Journey 3: Voice Input Flow
```
Dashboard → Tap Voice Quick Action → Permission rationale (first time only) →
Grant → VoiceInputSheet appears → Tap mic to start →
Say "صرفت مية جنيه على الأكل امبارح" → Tap mic to stop →
Parser processes → VoiceConfirmScreen: "Food, EGP 100, Yesterday" →
Tap "Confirm All" → Saved → Dashboard updated
```
**Total taps: 3-4 (after first-time permission)**

### Journey 4: Transfer Between Wallets
```
Dashboard → Tap Transfer Quick Action → TransferScreen →
Select from-wallet, to-wallet → Enter amount → Save
```
**Also available via:** More tab → Wallets → Transfer button
**Total taps: 4-5**

---

## 9. Privacy & Data Policy

### Data Storage
- ALL user data is stored locally on the device via SQLite (Drift)
- No data is transmitted to any server in v1
- Backup/restore creates local JSON files only — user controls export

### Data Collected
| Data Type | Stored | Transmitted | Purpose |
|-----------|--------|-------------|---------|
| Transaction amounts, titles, categories | Local only | Never | Core tracking |
| Wallet names and balances | Local only | Never | Core tracking |
| PIN hash (SHA-256) | Local (secure storage) | Never | App lock |
| Location coordinates (optional) | Local only | Never | Transaction tagging |
| Voice transcripts (optional) | Local only | OpenRouter API (ZDR enforced — zero data retention) | AI-powered voice parsing |
| SMS/notification text (optional) | Local only | OpenRouter API (ZDR enforced — zero data retention) | AI-powered transaction enrichment |
| Crash stack traces | Local file only | Never (user can share manually via bug report) | Crash debugging |

### Data NOT Collected (Ever)
- Bank account numbers or credentials
- Payment card numbers
- Government IDs
- Contact lists
- Browsing history
- Advertising identifiers

### User Rights
- User can export all data at any time (JSON backup)
- User can delete all data at any time (Clear All in Settings)
- Uninstalling the app deletes all local data
- No account creation required — the app works with zero personal info

---

## 10. Edge Cases Inventory

| Scenario | Expected Behavior |
|----------|-------------------|
| User has 0 wallets (skipped onboarding) | Auto-create default "Cash" wallet with 0 balance |
| All budgets exceeded | Budget section shows all in red, insight card warns |
| Goal deadline passed, not complete | Show "Overdue" badge, don't auto-delete |
| User denies microphone permission | Voice button shows inline message, no crash, all other features work |
| User denies notification access | Parser shows setup prompt in settings, no crash |
| User revokes permission mid-session | Graceful fallback, show re-enable prompt |
| Transaction with 0 amount | Validation rejects — "Amount must be greater than zero" |
| Wallet balance goes negative | Allowed (user might track credit/debt). Show negative in red |
| 1000+ transactions in list | Pagination or lazy loading, 60fps verified |
| Backup file from newer app version | Show "This backup requires a newer version" error, don't crash |
| Backup file corrupted/invalid JSON | Show friendly error, don't wipe existing data |
| Device in airplane mode | 100% functional, no error banners |
| System font size at 200% | Layout doesn't break, scrollable where needed |
| Screen width < 360dp | Single column, no overflow |
| Duplicate SMS/notification | Dedup via SHA-256 hash, skip silently |

---

## 11. Play Store Launch Strategy

### App Store Optimization (ASO)

**Category:** Finance → Budget

**Keywords (EN):** expense tracker, budget planner, money manager, Egyptian pounds, offline finance, voice expense, Arabic budget app

**Keywords (AR):** تتبع المصروفات, ميزانية, إدارة الفلوس, مصاريف, حساب المصروفات, توفير

**Short Description (EN):** Track every pound. Budget smarter. Save more. 100% offline.

**Short Description (AR):** سيطر على فلوسك. تتبع كل جنيه. ميزانية أذكى. 100% بدون إنترنت.

### Screenshot Strategy (6 screens)

1. Dashboard showing balance + monthly summary (hero shot)
2. Add transaction with amount input
3. Budget progress bars (showing real data)
4. Savings goal with progress ring at 65%
5. Voice input in action (pulsing mic, transcript visible)
6. Dark mode view of dashboard

Each screenshot: device frame, EN version + AR version, clean data (not lorem ipsum).

---

## 12. Post-Launch Roadmap

| Priority | Feature | Target | Depends On |
|----------|---------|--------|------------|
| P1 | Cloud backup (Google Drive) | v1.1 | User feedback confirming demand |
| P1 | Monetization (RevenueCat) | v1.2 | 1,000+ active users |
| P2 | AI-powered insights | v1.3 | Monetization live (Pro feature) |
| P2 | Custom themes / app icons | v1.3 | Monetization live (Pro feature) |
| P3 | Family/shared budgets | v2.0 | Major architecture work |
| P3 | iOS launch | v2.0 | Same codebase, App Store setup |
| P3 | Web companion (read-only) | v2.x | Future consideration |

---

*This PRD.md defines what Masarify is, who it's for, and what it does. For technical implementation, refer to `AGENTS.md`. For task sequence, refer to `TASKS.md`.*
