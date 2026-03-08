# Phase 2A: Background AI Intelligence — Design

## Context

Masarify's AI is currently reactive (voice parsing, SMS enrichment). Phase 2A adds proactive, offline-first AI intelligence that runs on local data without internet. Four components: auto-categorization learning, recurring pattern detection, spending predictions, and budget suggestions. All feed the existing dashboard insight card system.

## Decisions

- **Storage:** New `category_mappings` DB table (v5 migration) for auto-categorization
- **Learning trigger:** On every manual transaction save
- **Architecture:** Pure Dart services, no isolates (data is small)
- **No LLM:** All heuristic-based, 100% offline

---

## Component 1: Auto-Categorization Learning

**Purpose:** Learn user's {title → category} mappings from manual saves. Suggest categories for future SMS/notification transactions.

**DB table `category_mappings` (v5):**

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | Auto-increment |
| title_pattern | TEXT NOT NULL | Normalized (lowercase, trimmed) |
| category_id | INTEGER NOT NULL | FK → categories |
| hit_count | INTEGER DEFAULT 1 | Reinforcement counter |
| last_used_at | INTEGER NOT NULL | Unix timestamp |

UNIQUE constraint on `(title_pattern, category_id)`.

**Service: `CategorizationLearningService`**
- `recordMapping(title, categoryId)` — normalize title, upsert (increment or insert)
- `suggestCategory(title)` → `int?` — find best match, return categoryId with highest hit_count
- Normalization: `title.toLowerCase().trim().replaceAll(RegExp(r'\d+'), '')` — strip numbers to generalize ("Uber 45" → "uber")

**Integration:** Called from `add_transaction_screen.dart` `_save()` after successful create. SMS parser checks `suggestCategory()` before falling back to AI enrichment.

---

## Component 2: Recurring Pattern Detection

**Purpose:** Detect repeated transactions that look like recurring expenses (monthly bills, weekly habits). Surface as insight cards.

**No new DB table** — computed on-the-fly from transaction streams.

**Service: `RecurringPatternDetector`**
- Input: `List<TransactionEntity>` (last 90 days)
- Algorithm:
  1. Group by `(categoryId, amount)` — ignore title variations
  2. For each group with ≥ 3 entries, compute intervals between dates
  3. Check if intervals are roughly consistent: monthly (28-31 days ± 3) or weekly (7 days ± 1)
  4. Filter out transactions already linked to a RecurringRule (`isRecurring == true`)
- Output: `List<DetectedPattern>`
  - `categoryId`, `amount`, `title` (most common), `frequency` ('weekly'/'monthly'), `confidence` (0.0-1.0), `nextExpectedDate`

**Confidence scoring:**
- 3 occurrences with consistent interval → 0.7
- 4+ occurrences → 0.85
- 5+ occurrences → 0.95
- Reduce by 0.1 if interval variance > 2 days

**Provider:** `detectedPatternsProvider` — watches `recentTransactionsProvider` + `recurringRulesProvider` (to exclude known recurring). Filters confidence ≥ 0.7.

---

## Component 3: Spending Predictions

**Purpose:** Predict end-of-month spending per category. Alert when predicted spending exceeds budget.

**Service: `SpendingPredictor`**
- Input: current month transactions, last 2-3 months for average, budgets
- Algorithm:
  1. For each budgeted category, calculate current spending pace: `currentSpent / dayOfMonth * daysInMonth`
  2. Blend with historical average: `predicted = 0.6 * paceProjection + 0.4 * historicalAvg`
  3. If predicted > budget limit by 10%+, flag as over-budget prediction
- Output: `List<SpendingPrediction>`
  - `categoryId`, `categoryName`, `predictedAmount`, `budgetLimit`, `overByAmount`

**Provider:** `spendingPredictionsProvider` — watches `budgetsByMonthProvider`, `transactionsByMonthProvider` (current + last 2 months).

---

## Component 4: Budget Suggestions

**Purpose:** Suggest budgets for high-spending categories that have no budget set.

**Service: `BudgetSuggestionService`**
- Input: existing budgets, last 3 months transactions, categories
- Algorithm:
  1. Compute 3-month average spending per expense category
  2. Filter: categories with no existing budget AND average ≥ 50,000 piastres (500 EGP)
  3. Suggested amount = round average up to nearest 10,000 piastres (100 EGP)
  4. Sort by spending desc, take top 2
- Output: `List<BudgetSuggestion>`
  - `categoryId`, `categoryName`, `suggestedAmount`, `monthlyAvg`

**Provider:** `budgetSuggestionsProvider` — watches `budgetsByMonthProvider`, `transactionsByMonthProvider` (last 3 months).

---

## Integration: Enhanced Insight Cards

**File:** `ai_insights_zone.dart` — `_computeInsights()` gains 3 new insight types:

| Insight | Icon | Color | Action |
|---------|------|-------|--------|
| Recurring detected | `AppIcons.recurring` | primary | Navigate to AddRecurring (pre-filled) |
| Over-budget prediction | `AppIcons.trendingUp` | expense | Navigate to budgets |
| Budget suggestion | `AppIcons.budget` | primary | Navigate to SetBudget (pre-filled) |

Auto-categorization does NOT show on dashboard — it integrates into SMS parser flow.

**Card ordering priority:**
1. Budget at risk (existing)
2. Over-budget prediction (new)
3. Recurring detected (new)
4. Budget suggestion (new)
5. Spending trend (existing)
6. Top category (existing)

---

## New Files

| File | Type |
|------|------|
| `lib/data/database/tables/category_mappings_table.dart` | Drift table |
| `lib/data/database/daos/category_mapping_dao.dart` | Drift DAO |
| `lib/core/services/ai/categorization_learning_service.dart` | Service |
| `lib/core/services/ai/recurring_pattern_detector.dart` | Service |
| `lib/core/services/ai/spending_predictor.dart` | Service |
| `lib/core/services/ai/budget_suggestion_service.dart` | Service |
| `lib/shared/providers/background_ai_provider.dart` | Providers |

## Modified Files

| File | Change |
|------|--------|
| `lib/data/database/app_database.dart` | v5 migration, add category_mappings table + DAO |
| `lib/features/dashboard/presentation/widgets/ai_insights_zone.dart` | Add 3 new insight types |
| `lib/features/transactions/presentation/screens/add_transaction_screen.dart` | Call `recordMapping()` on save |
| `lib/l10n/app_en.arb` / `app_ar.arb` | New insight card strings |
| `lib/l10n/app_localizations*.dart` | Generated |

## L10n Keys

| Key | EN | AR |
|-----|----|----|
| `insight_recurring_detected` | `"Monthly: {title} — add as recurring?"` | `"شهري: {title} — أضف كمتكرر؟"` |
| `insight_over_budget_prediction` | `"{category} may exceed budget by {amount}"` | `"{category} قد يتجاوز الميزانية بـ {amount}"` |
| `insight_budget_suggestion` | `"Set a {amount} budget for {category}?"` | `"حدد ميزانية {amount} لـ {category}؟"` |

## Verification

1. `dart run build_runner build --delete-conflicting-outputs` (after DB table + DAO)
2. `flutter analyze lib/` — zero issues
3. `flutter test` — all pass
4. Manual testing:
   - Save 3+ transactions with same title → mapping recorded in DB
   - Add 3+ monthly-interval transactions in same category → recurring insight appears
   - Spending pace > budget → prediction insight appears
   - High-spend category with no budget → suggestion insight appears
   - Test AR/RTL
   - Test offline (all components work without internet)
