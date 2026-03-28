# Phase 8: Category System Overhaul - Context

**Gathered:** 2026-03-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Complete revamp of the category system across the entire app: visual styling (glassmorphism), most-used tracking, bulk migration on deletion, default categories reduction, AI integration updates, and cross-app picker unification. This phase modifies how categories look, behave, and are managed — but does NOT add new capabilities like category hierarchy, tagging, or sub-categories.

</domain>

<decisions>
## Implementation Decisions

### Visual Style
- **D-01:** Category icons use glass circles — colored glass circle (BackdropFilter with GlassConfig device fallback) with white Phosphor icon inside. Consistent with the app's 3-tier glass system.
- **D-02:** Shared category picker as DraggableScrollableSheet with "Most Used" section (top 5), then "All Categories" grouped by type. Search bar at top. Glass card background. Replaces all 3 inline picker implementations.
- **D-03:** Category management screen is a hybrid list+grid with glassmorphic cards, showing icon+name+usage count. Swipe actions for archive/delete. Sections: Expense / Income. Supports drag-drop reordering.

### Deletion & Migration
- **D-04:** Empty category: 1-step confirmation -> hard delete.
- **D-05:** Category with connected data: 3-step flow: (a) impact preview showing counts of affected transactions/budgets/subscriptions/learning patterns, (b) prompt to archive instead OR continue deleting, (c) if continuing: FORCE migration picker -- user MUST select a replacement category -> all data migrates -> hard delete.
- **D-06:** Standalone "Merge into..." action available on any category (not just deletion). Opens picker, shows impact count, migrates all connected data (transactions, budgets, recurring rules, learning patterns).
- **D-07:** Migration UPDATE logic: `UPDATE transactions SET category_id = target WHERE category_id = source`, same for budgets (merge amounts), recurring_rules, category_mappings (transfer learned patterns with combined hitCount).

### Default Categories
- **D-08:** Reduce defaults from 34 to ~20 essentials. Research phase determines exact set. Removed defaults must NOT break AI matching. **voice_dictionary.dart keywords are intentionally KEPT** -- do NOT prune them. Rationale: keywords map to `iconName` strings (not categoryId integers), so delete/recreate/merge cycles on categories never cause dictionary conflicts. Learned patterns in `category_mappings` DB table take priority over static dictionary entries anyway.
- **D-09:** Default categories are fully deletable using the same 3-step flow as user categories. Remove the `isDefault` protection from delete UI.
- **D-10:** No visual difference between defaults and user-created categories. Remove the "Default" chip badge from categories_screen.
- **D-11:** Default categories are fully customizable (name, icon, color all editable). Seed uses DoNothing -- user edits persist across re-seeding.

### Most-Used Tracking
- **D-12:** Add `usageCount` integer column to categories table (schema v15 migration, default 0). Increment on every transaction save from ALL entry paths (manual, voice, AI chat).
- **D-13:** Usage count visible everywhere -- picker "Most Used" section, management screen badge, dashboard filter chips, transaction form smart defaults.
- **D-14:** Usage follows category ID: rename keeps count, merge combines counts (`target.usageCount += source.usageCount`), hard delete loses count.

### Category Ordering
- **D-15:** Default sort: usage-first (usageCount DESC), then alphabetical. Manual drag-drop reorder available on management screen. `displayOrder` column persists custom order; when set, overrides usage-based sort.

### Grouping
- **D-16:** Keep categories flat -- no parent/child hierarchy.
- **D-17:** Remove `groupType` field entirely (needs/wants/savings). Drop column in v15 migration. Remove from entity, DAO, seed, add_category_screen UI, categories_screen subtitle.

### AI Integration
- **D-18:** AI prompts use live DB category list only (no hardcoded fallback). When defaults are reduced, prompts auto-update via `financialContextProvider`.
- **D-19:** If AI suggests a deleted category, show graceful error with available list and let AI re-suggest. No auto-fallback to "Other".
- **D-20:** On merge: UPDATE category_mappings SET category_id = target WHERE category_id = source (preserves learned patterns with combined hitCount). On hard delete: CASCADE delete mappings.

### Analytics & History
- **D-21:** History follows merge -- UPDATE changes category_id on all historical transactions. Reports show merged totals under target category.
- **D-22:** Pie chart styling at Claude's discretion during planning.

### REGRESSION PREVENTION (MANDATORY for ALL plans)
- **D-23:** NEVER rewrite any file from scratch. All modifications are INCREMENTAL -- edit existing code, don't replace it. Extract to NEW files when creating shared widgets.
- **D-24:** Every plan MUST include the Feature Preservation Checklist (below) in every task's `<acceptance_criteria>`.
- **D-25:** Plan 5 (cross-app picker integration) modifies ONE file at a time with verification between each.
- **D-26:** `add_transaction_screen.dart` is the HIGHEST RISK file (16 features). Extract `_CategoryPickerSheet` to shared widget, swap call site -- NEVER touch the mixin, save logic, wallet/location/goal code.

### Claude's Discretion
- Exact set of ~20 essential default categories (with research input)
- Glass circle implementation details (sigma, opacity, fallback)
- Drag-drop reorder UX on management screen
- Pie chart visual treatment
- Smart defaults algorithm refinement

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Category Core
- `lib/data/database/tables/categories_table.dart` -- Schema (10 columns, groupType to be removed)
- `lib/data/database/daos/category_dao.dart` -- All CRUD + archive queries (73 lines)
- `lib/domain/entities/category_entity.dart` -- Entity used in 33 files (groupType to be removed)
- `lib/domain/repositories/i_category_repository.dart` -- Interface contract (31 lines)
- `lib/data/repositories/category_repository_impl.dart` -- Archive cascade (5 operations, lines 84-118)
- `lib/data/seed/category_seed.dart` -- 34 defaults to reduce to ~20
- `lib/shared/providers/category_provider.dart` -- StreamProvider + derived providers (29 lines)

### Display & Resolution
- `lib/core/utils/category_icon_mapper.dart` -- 83 icon mappings (dual-key system: never remove entries, only add)
- `lib/core/utils/category_resolver.dart` -- categoryId -> display data (29 lines)
- `lib/shared/widgets/cards/transaction_card.dart` -- Category display in lists (294 lines)

### HIGH-RISK Integration Points (most features flowing through)
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` -- 16 features, DO NOT REWRITE
- `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` -- 12 features, DO NOT REWRITE
- `lib/core/services/ai/chat_action_executor.dart` -- 9 action types, category fuzzy matching

### AI Integration
- `lib/core/services/ai/ai_chat_service.dart` -- System prompt with category list
- `lib/core/services/ai/gemini_audio_service.dart` -- Voice prompt with category JSON
- `lib/core/services/ai/categorization_learning_service.dart` -- Title->category learning
- `lib/core/constants/voice_dictionary.dart` -- 83 keyword->iconName mappings (KEPT intentionally per D-08; keywords map to iconNames not categoryIds)

### Pickers to Replace
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` lines 1608-1763 -- `_CategoryPickerSheet`
- `lib/features/budgets/presentation/screens/set_budget_screen.dart` lines 69-119 -- inline picker
- `lib/features/recurring/presentation/screens/add_recurring_screen.dart` lines 163-200 -- inline picker

### Category Management
- `lib/features/categories/presentation/screens/categories_screen.dart` -- List + delete UI (236 lines)
- `lib/features/categories/presentation/screens/add_category_screen.dart` -- CRUD form (369 lines)

### Dashboard
- `lib/features/dashboard/presentation/widgets/filter_bar.dart` -- Top-used category chips (222 lines)

### Audit Plan (regression analysis)
- `.claude/plans/dreamy-sleeping-sloth.md` -- Full 5-round audit with 50+ item feature checklist

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GlassCard` widget -- existing glassmorphic card with 3-tier system (Background/Card/Inset)
- `GlassConfig.deviceFallback` -- auto-disables blur on low-end devices
- `CategoryIconMapper` -- centralized icon resolution with 83 entries
- `CategoryResolver` -- pre-resolves categoryId -> display data for lists
- `CategorizationLearningService` -- already wired into manual+voice+AI paths
- `category_frequency_service` -- SharedPreferences-based tracking (to be superseded by DB usageCount)
- `AccountManageSheet` -- existing drag-drop reorder pattern (ReorderableListView) to replicate for categories
- `WalletsScreen` -- existing swipe-to-archive/unarchive pattern with Slidable

### Established Patterns
- Drift schema migrations: v14 -> v15 with `onUpgrade` handler
- `DoNothing()` conflict strategy for seed data (preserves user edits)
- `StreamProvider` -> Repository -> DAO -> Drift reactive stream pattern
- `DraggableScrollableSheet` for bottom sheet pickers
- `SlidableAutoCloseBehavior` + `Slidable` for swipe actions

### Integration Points
- `financialContextProvider` builds AI category list from live DB
- `categoriesProvider` is watched by 15+ files
- `transactionRepositoryProvider` save methods must increment `usageCount`
- Backup service must include new columns (usageCount) in export/import

</code_context>

<specifics>
## Specific Ideas

- Management screen should be a mix of list and grid -- glassmorphic cards with icon+name+usage count, swipeable, with drag-drop reorder
- "Merge into..." is a first-class action, not buried in delete flow -- accessible from category long-press or swipe menu
- Usage count badges should be visible everywhere to help users see which categories they actually use
- The 3-step delete flow prioritizes education: step 1 shows impact, step 2 suggests archive as safer option, step 3 forces migration choice

## Feature Preservation Checklist (MANDATORY for every executor)

Every executor agent MUST verify ALL of these still work after their modifications:

### Transaction Entry
- [ ] Manual expense/income creation works
- [ ] Cash withdrawal/deposit creates Transfer
- [ ] Edit transaction loads correctly
- [ ] Title -> category auto-suggestion fires
- [ ] Smart default: last-used category pre-selected
- [ ] Category chips show frequency-sorted categories
- [ ] "More" opens full search picker with working search
- [ ] Wallet picker respects selectedAccountIdProvider
- [ ] Category learning recorded on save (recordMapping)
- [ ] Bottom sheet variant (AddTransactionSheet) works

### Voice Input
- [ ] Category auto-match by iconName resolves
- [ ] Category keyword fallback matching works
- [ ] "Other" category fallback assigned when no match
- [ ] Voice "cash" routes to system Cash wallet
- [ ] Subscription detection suggestion appears
- [ ] Category picker per draft works

### AI Chat
- [ ] System prompt includes current category list
- [ ] AI creates transactions with correct category
- [ ] AI creates budgets with correct category
- [ ] AI creates recurring rules with correct category
- [ ] Category not found shows available categories
- [ ] Subscription suggestion after transaction creation

### Category Management
- [ ] Categories screen shows expense/income sections
- [ ] Add category: name validation, type selector, color picker, icon picker
- [ ] Edit category loads existing values
- [ ] Archive cascades: deactivate recurring, purge learning, delete budgets, reassign transactions

### Cross-Cutting
- [ ] Brand icons still show on transactions
- [ ] Transfer route labels "CIB -> NBE" display correctly
- [ ] Cash wallet visible in home chips
- [ ] Archive/unarchive 2-step on wallets still works
- [ ] Offline: all category operations work without internet
- [ ] RTL: all category screens validate in Arabic
- [ ] Design tokens: no hardcoded colors, spacing, icons
- [ ] Money format: all amounts in integer piastres

</specifics>

<deferred>
## Deferred Ideas

- Category hierarchy (parent/child) -- separate phase if needed
- Tag-based grouping -- alternative to hierarchy, evaluate later
- Category-based spending limits (per-category budget auto-creation) -- monetization feature
- Category analytics dashboard (dedicated screen with trends) -- Phase after analytics overhaul

</deferred>

---

*Phase: 08-category-system-overhaul*
*Context gathered: 2026-03-28*
