# Features

18 feature modules, 32 screens, 45+ routes. 4-tab navigation with center FAB.

## Navigation Structure

```
Bottom Nav (4 tabs + center FAB)
  Tab 1: Home (/)               — Dashboard with carousel, zones, insight cards, inline transactions
  Tab 2: Subscriptions (/recurring) — Subscriptions & Bills (4 sections: Overdue/Upcoming/Active/Paid)
  [FAB]                          — Center-docked. Tap → Expense. Long press → radial (Expense/Mic/Income)
  Tab 3: Analytics (/analytics)  — Reports with 3 sub-tabs (Overview, Categories, Trends)
  Tab 4: Planning (/more)        — Hub: Budgets, Goals, Wallets, Calendar, Export
  Settings: gear icon in AppBar  — Not a tab
```

## Feature Inventory

### 1. Dashboard (`features/dashboard/`)
| Screen | Route |
|--------|-------|
| `dashboard_screen.dart` | `/` |

Account carousel (PageView, viewportFraction 0.92). Page 0 = total balance, pages 1-N = per-account. Zones: QuickAddZone, BudgetHealth, InsightCards, RecentTransactions (SliverList). All zones filter by selected account via `selectedAccountIdProvider`.

### 2. Transactions (`features/transactions/`)
| Screen | Route |
|--------|-------|
| `add_transaction_screen.dart` | `/transactions/add`, `/transactions/:id/edit` |
| `transaction_detail_screen.dart` | `/transactions/:id` |

Add/edit expense, income. 4 filter chips (All, Expense, Income, Transfer). Category search picker. Smart defaults (frequency-based chip sorting, time-of-day suggestions). Wallet names on cards in All Accounts view. Daily net subtotals in date headers.

### 3. Wallets (`features/wallets/`)
| Screen | Route |
|--------|-------|
| `wallets_screen.dart` | `/wallets` |
| `add_wallet_screen.dart` | `/wallets/add`, `/wallets/:id/edit` |
| `wallet_detail_screen.dart` | `/wallets/:id` |
| `transfer_screen.dart` | `/transfer` |
| `transfer_detail_screen.dart` | `/transfers/:id` |

Account management. Archive/unarchive (2-step confirm). Drag-and-drop reorder (sortOrder). Cash wallet hidden from list. Default account protected. Starting balance support.

### 4. Categories (`features/categories/`)
| Screen | Route |
|--------|-------|
| `categories_screen.dart` | `/categories` |
| `add_category_screen.dart` | `/categories/add`, `/categories/:id/edit` |

34 defaults (28 expense + 6 income). Search picker. Icon/color assignment. Text-based suggestion.

### 5. Budgets (`features/budgets/`)
| Screen | Route |
|--------|-------|
| `budgets_screen.dart` | `/budgets` |
| `set_budget_screen.dart` | `/budgets/set`, `/budgets/:id/edit` |

Budget CRUD. Progress cards with animated fill (green/yellow/red). Overspend alerts. Spending excludes archived wallets.

### 6. Goals (`features/goals/`)
| Screen | Route |
|--------|-------|
| `goals_screen.dart` | `/goals` |
| `add_goal_screen.dart` | `/goals/add`, `/goals/:id/edit` |
| `goal_detail_screen.dart` | `/goals/:id` |

Savings goals with radial progress ring. Contribution tracking. Deadline with overdue badge. Target validation in edit mode.

### 7. Recurring (`features/recurring/`)
| Screen | Route |
|--------|-------|
| `recurring_screen.dart` | `/recurring` (tab) |
| `add_recurring_screen.dart` | `/recurring/add`, `/recurring/:id/edit` |

"Subscriptions & Bills" (user-facing name). 4 sections: Overdue, Upcoming Bills, Active Recurring, Paid. Frequencies: once/daily/weekly/monthly/yearly/custom. RecurringScheduler processes on app open.

### 8. AI Chat (`features/ai_chat/`)
| Screen | Route |
|--------|-------|
| `chat_screen.dart` | `/chat` |

Financial advisor chat via OpenRouter. Message bubbles with markdown rendering. Action cards (create transaction, transfer, budget). ChatActionExecutor for AI-driven mutations. Daily recap mode via notification tap.

### 9. Voice Input (`features/voice_input/`)
| Screen | Route |
|--------|-------|
| `voice_confirm_screen.dart` | `/voice/confirm` |

VoiceInputSheet (bottom sheet, no route) for recording. Gemini 2.5 Flash transcription + parsing. VoiceTransactionDraft → confirm screen. Supports: expense, income, cash_withdrawal, cash_deposit, transfer. Subscription detection suggestions.

### 10. SMS Parser (`features/sms_parser/`)
| Screen | Route |
|--------|-------|
| `parser_review_screen.dart` | `/parser/review` |

Currently hidden (`kSmsEnabled = false`). Code preserved for future Pro re-enablement. Regex-based local parsing + OpenRouter enrichment.

### 11. Reports (`features/reports/`)
| Screen | Route |
|--------|-------|
| `reports_screen.dart` | `/reports`, `/analytics` (tab) |

3 sub-tabs: Overview (income vs expense bar chart), Categories (horizontal bar + ranked list), Trends (line chart with period toggle).

### 12. Calendar (`features/calendar/`)
| Screen | Route |
|--------|-------|
| `calendar_screen.dart` | `/calendar` |

Cashflow calendar view using `table_calendar`.

### 13. Onboarding (`features/onboarding/`)
| Screen | Route |
|--------|-------|
| `onboarding_screen.dart` | `/onboarding` |
| `splash_screen.dart` | `/splash` |

5-page setup: Welcome, Account Creation, AI Intro (ChatDemo widget), Settings, Starting Balance. Bank account auto-created. Idempotent wallet creation.

### 14. Auth (`features/auth/`)
| Screen | Route |
|--------|-------|
| `pin_setup_screen.dart` | `/auth/pin-setup` |
| `pin_entry_screen.dart` | `/auth/pin-entry` |

PIN lock + biometric authentication. Route guard redirects to pin-entry if locked.

### 15. Settings (`features/settings/`)
| Screen | Route |
|--------|-------|
| `settings_screen.dart` | `/settings` |
| `backup_export_screen.dart` | `/settings/backup` |
| `notification_preferences_screen.dart` | `/settings/notifications` |

Language, currency, theme, first-day-of-week. Google Drive backup (AES-256 encrypted). CSV/PDF export. Daily spending recap toggle + time picker. Notification scheduling.

### 16. Monetization (`features/monetization/`)
| Screen | Route |
|--------|-------|
| `paywall_screen.dart` | `/paywall` |
| `subscription_screen.dart` | `/settings/subscription` |

Subscription-only (no ads). Free: unlimited txns, 2 budgets, 1 goal. Pro: 59-79 EGP/mo. `in_app_purchase` for Google Play Billing. Soft paywalls (show what's behind the gate). Error recovery with retry. 33-day grace period.

### 17. Hub (`features/hub/`)
| Screen | Route |
|--------|-------|
| `hub_screen.dart` | `/more` (tab) |

Planning hub: Budgets, Goals, Wallets, Calendar, Export. Entry point for non-tab features.

### 18. Quick Start (`features/quick_start/`)

Dashboard QuickAddZone component. Smart category defaults, frequency-based chip sorting.

## Feature Flags

| Flag | Value | Effect |
|------|-------|--------|
| `kSmsEnabled` | `false` | SMS parsing hidden (AI-first pivot) |
| `kMonetizationEnabled` | `true` | IAP active via Google Play Billing |
| `AiConfig.isEnabled` | `true` | AI voice + chat enabled |

## Deleted Features

| Feature | Reason | When |
|---------|--------|------|
| Smart Insights | Replaced by background AI heuristics | P4 |
| Net Worth | Scope reduction | P4 |
| Bills (separate) | Merged into RecurringRules table | P4 (DB v4) |
| Notification Parser | SMS-first pivot abandoned | P5 |
