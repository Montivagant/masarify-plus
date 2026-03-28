# Phase 8: Category System Overhaul - Research

**Researched:** 2026-03-28
**Domain:** Flutter/Dart — Drift schema migration, glassmorphic UI, cross-app widget extraction, AI integration
**Confidence:** HIGH

## Summary

This phase is a comprehensive overhaul of the category system touching 33+ files across 6 architectural layers: schema (Drift), domain entity, data repositories, AI services, providers, and presentation screens. The core challenge is NOT technical complexity but **regression risk** — the user has documented 18+ regressions from a previous "overhaul" phase (Phase 3) and explicitly mandates incremental modification over wholesale rewrites.

The phase involves: (1) Drift v14-to-v15 migration adding `usageCount`, removing `groupType`; (2) extracting `_CategoryPickerSheet` from `add_transaction_screen.dart` into a shared widget; (3) replacing 3 inline picker implementations one file at a time; (4) building a 3-step deletion/migration flow; (5) reducing default categories from 34 to ~20; (6) glassmorphic visual treatment for category icons; (7) updating AI prompt integration to handle deleted/merged categories gracefully.

**Primary recommendation:** Structure this phase as 7-8 sequential plans with strict feature preservation checklists verified between each. The highest-risk operation is extracting the picker from `add_transaction_screen.dart` (1763 lines, 16 features) — this MUST be a pure extraction (copy to new file, replace call site) with zero changes to surrounding code.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Category icons use glass circles -- colored glass circle (BackdropFilter with GlassConfig device fallback) with white Phosphor icon inside. Consistent with the app's 3-tier glass system.
- **D-02:** Shared category picker as DraggableScrollableSheet with "Most Used" section (top 5), then "All Categories" grouped by type. Search bar at top. Glass card background. Replaces all 3 inline picker implementations.
- **D-03:** Category management screen is a hybrid list+grid with glassmorphic cards, showing icon+name+usage count. Swipe actions for archive/delete. Sections: Expense / Income. Supports drag-drop reordering.
- **D-04:** Empty category: 1-step confirmation -> hard delete.
- **D-05:** Category with connected data: 3-step flow: (a) impact preview showing counts of affected transactions/budgets/subscriptions/learning patterns, (b) prompt to archive instead OR continue deleting, (c) if continuing: FORCE migration picker -- user MUST select a replacement category -> all data migrates -> hard delete.
- **D-06:** Standalone "Merge into..." action available on any category (not just deletion). Opens picker, shows impact count, migrates all connected data (transactions, budgets, recurring rules, learning patterns).
- **D-07:** Migration UPDATE logic: `UPDATE transactions SET category_id = target WHERE category_id = source`, same for budgets (merge amounts), recurring_rules, category_mappings (transfer learned patterns with combined hitCount).
- **D-08:** Reduce defaults from 34 to ~20 essentials. Research phase determines exact set. Removed defaults must NOT break AI matching -- `voice_dictionary.dart` keyword mappings must be pruned for removed categories.
- **D-09:** Default categories are fully deletable using the same 3-step flow as user categories. Remove the `isDefault` protection from delete UI.
- **D-10:** No visual difference between defaults and user-created categories. Remove the "Default" chip badge from categories_screen.
- **D-11:** Default categories are fully customizable (name, icon, color all editable). Seed uses DoNothing -- user edits persist across re-seeding.
- **D-12:** Add `usageCount` integer column to categories table (schema v15 migration, default 0). Increment on every transaction save from ALL entry paths (manual, voice, AI chat).
- **D-13:** Usage count visible everywhere -- picker "Most Used" section, management screen badge, dashboard filter chips, transaction form smart defaults.
- **D-14:** Usage follows category ID: rename keeps count, merge combines counts (`target.usageCount += source.usageCount`), hard delete loses count.
- **D-15:** Default sort: usage-first (usageCount DESC), then alphabetical. Manual drag-drop reorder available on management screen. `displayOrder` column persists custom order; when set, overrides usage-based sort.
- **D-16:** Keep categories flat -- no parent/child hierarchy.
- **D-17:** Remove `groupType` field entirely (needs/wants/savings). Drop column in v15 migration. Remove from entity, DAO, seed, add_category_screen UI, categories_screen subtitle.
- **D-18:** AI prompts use live DB category list only (no hardcoded fallback). When defaults are reduced, prompts auto-update via `financialContextProvider`.
- **D-19:** If AI suggests a deleted category, show graceful error with available list and let AI re-suggest. No auto-fallback to "Other".
- **D-20:** On merge: UPDATE category_mappings SET category_id = target WHERE category_id = source (preserves learned patterns with combined hitCount). On hard delete: CASCADE delete mappings.
- **D-21:** History follows merge -- UPDATE changes category_id on all historical transactions. Reports show merged totals under target category.
- **D-22:** Pie chart styling at Claude's discretion during planning.
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

### Deferred Ideas (OUT OF SCOPE)
- Category hierarchy (parent/child) -- separate phase if needed
- Tag-based grouping -- alternative to hierarchy, evaluate later
- Category-based spending limits (per-category budget auto-creation) -- monetization feature
- Category analytics dashboard (dedicated screen with trends) -- Phase after analytics overhaul
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| D-01 | Glass circle category icons | GlassCard widget exists with 3-tier system; GlassConfig.deviceFallback handles low-end devices; Inset tier (sigma 8) is the right tier for icon badges |
| D-02 | Shared picker with Most Used + grouped All | Current `_CategoryPickerSheet` in add_transaction_screen.dart (lines 1608-1763) is the extraction target; DraggableScrollableSheet pattern already established |
| D-03 | Hybrid list+grid management screen | AccountManageSheet provides ReorderableListView drag-drop pattern; WalletsScreen provides Slidable swipe pattern; CategoriesScreen (236 lines) is the modification target |
| D-04 | Empty category 1-step delete | Requires new DAO method to count connected data (transactions, budgets, recurring_rules, category_mappings) |
| D-05 | 3-step delete with migration | Repository archive() already does transaction reassignment + cascade; needs generalization to hard-delete + merge flow |
| D-06 | Standalone merge action | New repository method: `mergeCategories(sourceId, targetId)` wrapping D-07 SQL |
| D-07 | Migration UPDATE SQL | Drift transaction wrapping 5 UPDATE statements + usageCount merge |
| D-08 | Reduce defaults to ~20 | category_seed.dart has 34 entries; research below recommends 20 categories |
| D-09 | Defaults fully deletable | CategoriesScreen._confirmDelete() currently blocks with isDefault check (line 117-125); remove guard |
| D-10 | Remove Default chip badge | CategoriesScreen._CategoryTile line 216-228 shows Chip vs delete button branching on isDefault |
| D-11 | Defaults fully customizable | AddCategoryScreen._save() already handles edit; DoNothing seed strategy already in place |
| D-12 | usageCount DB column | Schema v15 migration; CategoryFrequencyService (SharedPreferences) is the superseded system |
| D-13 | Usage visible everywhere | FilterBar._topCategories() currently reads SharedPreferences via categoryFrequencyServiceProvider; needs migration to DB provider |
| D-14 | Usage follows category ID | Merge path must combine usageCount; CategoryRepositoryImpl.archive() template for transaction logic |
| D-15 | Usage-first sort with manual override | DAO watchAll() currently orders by displayOrder ASC; needs compound sort |
| D-16 | Flat categories (no hierarchy) | Confirmed — no changes needed, already flat |
| D-17 | Remove groupType | 9 files reference groupType; migration must DROP COLUMN (SQLite 3.35+ required, API 24 has 3.19 — need ALTER TABLE workaround) |
| D-18 | AI uses live DB list | financialContextProvider already builds categoryList from live DB; confirmed no hardcoded fallback |
| D-19 | Graceful AI category-not-found | ChatActionExecutor line 171 records mapping; category matching logic needs error path enhancement |
| D-20 | Merge preserves learning patterns | CategoryMappings has CASCADE on category_id FK; merge needs explicit UPDATE before delete |
| D-21 | History follows merge | D-07 SQL handles this via UPDATE transactions |
| D-22 | Pie chart styling | Claude's discretion |
| D-23 | No file rewrites | Enforced via plan structure |
| D-24 | Feature preservation checklists | CONTEXT.md provides 30+ item checklist; every plan must include |
| D-25 | One file at a time for picker swap | Plan structure enforces sequential modification |
| D-26 | add_transaction_screen.dart highest risk | Pure extraction: copy _CategoryPickerSheet (lines 1608-1763) to shared widget, swap import+call |
</phase_requirements>

## Standard Stack

### Core (Already in Project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `drift` | ^2.20.0 | Schema migration v14->v15, new DAO methods | Already the ORM; all migration patterns established |
| `flutter_riverpod` | ^2.6.1 | Category providers, usage tracking providers | Already state management solution |
| `flutter_slidable` | ^3.1.1 | Swipe-to-archive/delete on category tiles | Already used in transaction cards |
| `flutter_animate` | ^4.5.0 | Stagger animations on category list | Already used in categories_screen |
| `phosphor_flutter` | ^2.1.0 | Category icons via AppIcons | Already the icon library |

### Supporting (Already in Project)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `rxdart` | ^0.28.0 | Combine category + usage streams if needed | Only if reactive merge is required |

### No New Dependencies Needed
This phase requires zero new packages. All patterns exist in the codebase:
- GlassCard + GlassTier.inset for glass circle icons
- DraggableScrollableSheet for picker
- ReorderableListView for drag-drop (AccountManageSheet pattern)
- Slidable for swipe actions (WalletsScreen pattern)

## Architecture Patterns

### Recommended File Structure for New/Modified Files

```
lib/
  shared/
    widgets/
      pickers/
        category_picker_sheet.dart      # NEW: extracted from add_transaction_screen
      category/
        glass_category_icon.dart         # NEW: glass circle icon widget
  features/
    categories/
      presentation/
        screens/
          categories_screen.dart         # MODIFIED: hybrid list+grid, swipe, drag-drop
          add_category_screen.dart       # MODIFIED: remove groupType UI
        widgets/
          category_delete_flow.dart      # NEW: 3-step delete dialog/flow
          category_merge_sheet.dart      # NEW: merge picker with impact preview
  data/
    database/
      tables/categories_table.dart       # MODIFIED: add usageCount, remove groupType
      daos/category_dao.dart             # MODIFIED: add merge, delete, usage methods
    repositories/
      category_repository_impl.dart      # MODIFIED: merge, hard-delete, usage increment
    seed/category_seed.dart              # MODIFIED: reduce to ~20 categories
  domain/
    entities/category_entity.dart        # MODIFIED: add usageCount, remove groupType
    repositories/i_category_repository.dart # MODIFIED: add merge, hardDelete, incrementUsage
  core/
    constants/voice_dictionary.dart      # MODIFIED: prune removed category keywords
```

### Pattern 1: Pure Widget Extraction (D-26)
**What:** Extract private widget class from a large file into a shared widget, replace call site with import.
**When to use:** When `add_transaction_screen.dart` picker needs to become shared.
**Critical rule:** The extraction MUST be a pure copy-paste. The source file gets only these changes: (1) remove the private class definition, (2) add import for the new file, (3) update the call site to use the public class name. NOTHING ELSE changes in the source file.

```dart
// BEFORE (in add_transaction_screen.dart):
class _CategoryPickerSheet extends StatefulWidget { ... }

// AFTER:
// 1. New file: lib/shared/widgets/pickers/category_picker_sheet.dart
//    Contains the EXACT same code, renamed to public:
class CategoryPickerSheet extends StatefulWidget { ... }

// 2. add_transaction_screen.dart:
//    - Delete lines 1608-1763
//    - Add: import '../../../../shared/widgets/pickers/category_picker_sheet.dart';
//    - All showModalBottomSheet calls unchanged, just reference CategoryPickerSheet
```

### Pattern 2: Drift Schema Migration (v14 -> v15)
**What:** Add `usageCount` column, drop `groupType` column.
**Critical issue with groupType removal:** SQLite < 3.35.0 does NOT support `ALTER TABLE DROP COLUMN`. Android API 24 ships SQLite 3.19.4. The app targets API 24.

**Solution:** Do NOT use ALTER TABLE DROP COLUMN. Instead:
1. Leave the physical column in the database (SQLite ignores unmapped columns)
2. Remove `groupType` from the Drift table definition (Drift stops generating code for it)
3. Remove from entity, DAO, repository, seed, and all presentation code
4. Existing data in the column becomes harmless orphan data

This is the SAME approach used for `autoLog` column removal in v4 migration (see app_database.dart line 103-105 comment).

```dart
// In app_database.dart onUpgrade:
if (from < 15) {
  // Add usageCount with default 0
  await m.addColumn(categories, categories.usageCount);

  // NOTE: groupType column is NOT dropped via ALTER TABLE because
  // Android API 24 ships SQLite 3.19 which doesn't support DROP COLUMN.
  // Column is simply removed from Drift table definition — Drift ignores
  // unmapped physical columns. Existing data is harmless.

  // Backfill usageCount from transaction counts
  await customStatement('''
    UPDATE categories SET usage_count = (
      SELECT COUNT(*) FROM transactions WHERE category_id = categories.id
    )
  ''');
}
```

### Pattern 3: Repository Transaction for Merge (D-07)
**What:** Atomic merge of all category references within a Drift transaction.
**When to use:** Both merge action (D-06) and delete-with-migration step 3 (D-05).

```dart
Future<void> mergeCategories(int sourceId, int targetId) async {
  return _db.transaction(() async {
    // 1. Migrate transactions
    await _db.customStatement(
      'UPDATE transactions SET category_id = ? WHERE category_id = ?',
      [targetId, sourceId],
    );
    // 2. Migrate budgets (merge amounts for same month)
    // First, update non-conflicting budgets
    await _db.customStatement(
      'UPDATE budgets SET category_id = ? WHERE category_id = ? '
      'AND NOT EXISTS (SELECT 1 FROM budgets b2 WHERE b2.category_id = ? AND b2.year = budgets.year AND b2.month = budgets.month)',
      [targetId, sourceId, targetId],
    );
    // Delete conflicting (target already has budget for that month)
    await _db.customStatement(
      'DELETE FROM budgets WHERE category_id = ?',
      [sourceId],
    );
    // 3. Migrate recurring rules
    await _db.customStatement(
      'UPDATE recurring_rules SET category_id = ? WHERE category_id = ?',
      [targetId, sourceId],
    );
    // 4. Migrate learning patterns (combine hit counts)
    await _db.customStatement(
      'UPDATE category_mappings SET category_id = ? WHERE category_id = ? '
      'AND NOT EXISTS (SELECT 1 FROM category_mappings cm2 WHERE cm2.category_id = ? AND cm2.title_pattern = category_mappings.title_pattern)',
      [targetId, sourceId, targetId],
    );
    // For duplicate patterns: sum hitCount into target, delete source
    // (handled in 2 steps to avoid constraint violations)
    await _db.customStatement(
      'DELETE FROM category_mappings WHERE category_id = ?',
      [sourceId],
    );
    // 5. Combine usageCount
    await _db.customStatement(
      'UPDATE categories SET usage_count = usage_count + '
      '(SELECT usage_count FROM categories WHERE id = ?) WHERE id = ?',
      [sourceId, targetId],
    );
    // 6. Hard delete source category
    await _db.customStatement(
      'DELETE FROM categories WHERE id = ?',
      [sourceId],
    );
  });
}
```

### Pattern 4: Usage Count Increment (D-12)
**What:** Increment `usageCount` in the categories table on every transaction save.
**When to use:** All three save paths: manual, voice, AI chat.

```dart
// In CategoryDao — new method:
Future<void> incrementUsageCount(int categoryId) async {
  await customStatement(
    'UPDATE categories SET usage_count = usage_count + 1 WHERE id = ?',
    [categoryId],
  );
}

// Called from:
// 1. add_transaction_screen.dart _save() — after transaction insert
// 2. voice_confirm_screen.dart _confirmAll() — after each draft save
// 3. chat_action_executor.dart _executeTransaction() — after transaction insert
```

### Anti-Patterns to Avoid
- **Rewriting entire files:** Per D-23, NEVER replace a file. Always edit incrementally.
- **Testing via grep:** Per historical lesson, "code exists" is not "feature works". Use the Feature Preservation Checklist.
- **Touching unrelated code:** Per D-26, when modifying add_transaction_screen.dart, NEVER touch the mixin, save logic, wallet/location/goal code — only the picker section.
- **Batch file modifications:** Per D-25, modify one file at a time with verification between each for picker integration.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Glass circle icon | Custom BackdropFilter code | `GlassCard` with `GlassTier.inset` wrapping an `Icon` | GlassConfig.deviceFallback already handles low-end devices; consistent with 3-tier system |
| Drag-drop reorder | Custom gesture detector | `ReorderableListView` (Flutter built-in) | AccountManageSheet already uses this pattern successfully |
| Swipe actions | Custom Dismissible | `Slidable` from flutter_slidable | Already used throughout the app; consistent UX |
| Bottom sheet picker | Custom overlay | `DraggableScrollableSheet` in `showModalBottomSheet` | Existing pattern in 3 pickers + used across app |
| Category frequency sorting | Custom comparator with SharedPreferences | DB-level `usageCount` column with ORDER BY | SharedPreferences approach is fragile, not atomic, missing from 2/3 save paths |
| Schema column removal | ALTER TABLE DROP COLUMN | Remove from Drift definition only (leave physical column) | API 24 SQLite 3.19 doesn't support DROP COLUMN |

**Key insight:** Every UI pattern needed in this phase already exists somewhere in the codebase. The work is composition and extraction, not invention.

## Common Pitfalls

### Pitfall 1: SQLite DROP COLUMN on Old Android
**What goes wrong:** Using `ALTER TABLE categories DROP COLUMN group_type` crashes on devices with SQLite < 3.35.0 (Android API < 30).
**Why it happens:** The app targets API 24 which ships SQLite 3.19.4, which lacks DROP COLUMN support.
**How to avoid:** Remove `groupType` from Drift table definition ONLY. The physical column remains in SQLite but is ignored by Drift. This is the same proven pattern used for `autoLog` removal in v4 migration.
**Warning signs:** Migration crash on older devices, "near DROP: syntax error" in logs.

### Pitfall 2: CategoryMappings Foreign Key CASCADE
**What goes wrong:** Hard-deleting a category triggers CASCADE DELETE on `category_mappings`, losing learned patterns before the merge step can preserve them.
**Why it happens:** `category_mappings_table.dart` line 9: `onDelete: KeyAction.cascade`.
**How to avoid:** In the merge flow, UPDATE category_mappings BEFORE deleting the source category. The cascade only fires on DELETE, so updating the FK first preserves data.
**Warning signs:** After merging categories, previously learned title-to-category mappings stop suggesting the target category.

### Pitfall 3: Backup Service GroupType References
**What goes wrong:** Removing `groupType` from the entity/table breaks backup export and restore.
**Why it happens:** `backup_service_impl.dart` lines 471 and 639 explicitly read/write `groupType` in the JSON backup format.
**How to avoid:** Keep `groupType` in the backup JSON as a nullable field. Write `null` on export. Accept and ignore on import. This maintains backward compatibility with older backups.
**Warning signs:** Backup restore crashes or loses category data after the migration.

### Pitfall 4: Frequency Service Duplication
**What goes wrong:** After adding DB `usageCount`, the SharedPreferences-based `CategoryFrequencyService` and the DB column get out of sync.
**Why it happens:** Two sources of truth for the same data.
**How to avoid:** Phase the migration: (1) Add DB column and backfill from transaction counts. (2) Add increment calls to all 3 save paths. (3) Update all consumers (filter_bar, smart_defaults_provider) to read from categoriesProvider instead of categoryFrequencyServiceProvider. (4) Remove CategoryFrequencyService entirely in the final plan.
**Warning signs:** Dashboard filter chips show different "top categories" than the picker's "Most Used" section.

### Pitfall 5: Regression in add_transaction_screen.dart
**What goes wrong:** Modifying the 1763-line file breaks any of its 16 features: manual save, cash transfer, edit mode, category suggestion, smart defaults, wallet picker, etc.
**Why it happens:** Fresh-context subagents lack full knowledge of the file and make "harmless" changes that break adjacent features.
**How to avoid:** Per D-26, the ONLY modification allowed is extracting `_CategoryPickerSheet` (lines 1608-1763) to a new file and replacing the call site. The rest of the file is untouchable. Verification: run the full Feature Preservation Checklist from CONTEXT.md after modification.
**Warning signs:** Any line outside 1608-1763 is modified; any import other than the new picker import is added/removed.

### Pitfall 6: Seed Data vs Existing Users
**What goes wrong:** Reducing defaults from 34 to 20 deletes categories that existing users actively use, orphaning their transactions.
**Why it happens:** Confusing "seed defaults" with "active categories". The seed only runs on FIRST LAUNCH (empty table). Existing users already have the 34 categories in their DB.
**How to avoid:** The seed reduction (D-08) ONLY affects new installations. For existing users, the reduced set is cosmetic information — no migration needed. Existing users who want to clean up can use the new delete/merge flow.
**Warning signs:** Existing user's categories disappearing after app update.

### Pitfall 7: Voice Dictionary Pruning Breaks AI
**What goes wrong:** Removing keyword entries from `voice_dictionary.dart` causes voice transactions to fail category matching.
**Why it happens:** The Gemini audio service sends the full categories list from the DB. But `VoiceDictionary.categoryKeywords` is used for FALLBACK matching when Gemini returns an unrecognized iconName.
**How to avoid:** Keep ALL keyword entries in the dictionary. Pruning only applies to entries whose `iconName` targets a category that was removed from the SEED. Since existing users still have those categories (Pitfall 6), the keywords should stay. Only add new keywords for new categories; never remove.
**Warning signs:** Voice says "كافيه" but no category is matched, falling back to "Other".

## Default Categories Recommendation (Claude's Discretion)

Based on analysis of the current 34 defaults, Egyptian market relevance, and universal finance tracking needs:

### Recommended 20 Essential Categories

**Expense (15):**
1. Food & Dining (restaurant) -- universal daily expense
2. Transport (directions_car) -- daily for Egyptian commuters (Uber, Metro, etc.)
3. Housing & Rent (home) -- primary fixed expense
4. Utilities (bolt) -- electricity/water/gas
5. Phone & Internet (phone_android) -- essential in Egypt (Vodafone, Orange, Etisalat, WE)
6. Healthcare (local_hospital) -- medical + pharmacy
7. Groceries (shopping_cart) -- distinct from dining out
8. Shopping (shopping_bag) -- general retail
9. Entertainment (movie) -- leisure spending
10. Subscriptions (subscriptions) -- streaming, gym, etc.
11. Installments (credit_score) -- very common in Egyptian market (Buy Now Pay Later: Shahry, Sympl, ValU)
12. Cafe & Coffee (coffee) -- significant daily expense category in Egypt
13. Gifts & Donations (card_giftcard) -- includes charitable giving
14. Education (school) -- courses, books, tuition
15. Other Expense (more_horiz) -- catch-all

**Income (5):**
16. Salary (payments) -- primary income
17. Freelance (work) -- gig economy
18. Business (store) -- self-employment
19. Gifts Received (redeem) -- monetary gifts
20. Other Income (more_horiz) -- catch-all

### Removed from Defaults (14 categories)
These are removed from the SEED only. Existing users retain them:
- Clothing (checkroom) -- rare enough to create on demand
- Personal Care (spa) -- infrequent
- Travel (flight) -- seasonal
- Insurance (shield) -- niche
- Fuel & Parking (local_gas_station) -- subset of Transport
- Maintenance (build) -- infrequent
- Kids & Family (child_care) -- demographic-specific
- Pets (pets) -- niche
- Home Supplies (weekend) -- can use Groceries or Shopping
- Charity & Zakat (volunteer_activism) -- merged into Gifts & Donations conceptually
- ATM & Bank Fees (account_balance) -- rarely tracked
- Delivery & Shipping (local_shipping) -- subset of Shopping
- Savings Transfer (savings) -- use Transfer feature instead
- Investment Returns (trending_up) -- niche income, use Other Income

### Voice Dictionary Impact
The `VoiceDictionary.categoryKeywords` map entries targeting removed categories will NOT be pruned (Pitfall 7). They remain functional for existing users who still have those categories. The Gemini audio service receives the live category list from DB, so new users without these categories simply won't match those keywords (graceful degradation to "Other").

## Code Examples

### Impact Count Query (for D-05 step a)

```dart
// New method in CategoryDao:
Future<({int transactions, int budgets, int recurringRules, int mappings})>
    countConnectedData(int categoryId) async {
  final txCount = await customSelect(
    'SELECT COUNT(*) AS cnt FROM transactions WHERE category_id = ?',
    variables: [Variable.withInt(categoryId)],
    readsFrom: {},
  ).getSingle();
  final budgetCount = await customSelect(
    'SELECT COUNT(*) AS cnt FROM budgets WHERE category_id = ?',
    variables: [Variable.withInt(categoryId)],
    readsFrom: {},
  ).getSingle();
  final recurringCount = await customSelect(
    'SELECT COUNT(*) AS cnt FROM recurring_rules WHERE category_id = ?',
    variables: [Variable.withInt(categoryId)],
    readsFrom: {},
  ).getSingle();
  final mappingCount = await customSelect(
    'SELECT COUNT(*) AS cnt FROM category_mappings WHERE category_id = ?',
    variables: [Variable.withInt(categoryId)],
    readsFrom: {},
  ).getSingle();
  return (
    transactions: txCount.read<int>('cnt'),
    budgets: budgetCount.read<int>('cnt'),
    recurringRules: recurringCount.read<int>('cnt'),
    mappings: mappingCount.read<int>('cnt'),
  );
}
```

### Glass Category Icon Widget (D-01)

```dart
// lib/shared/widgets/category/glass_category_icon.dart
class GlassCategoryIcon extends StatelessWidget {
  const GlassCategoryIcon({
    super.key,
    required this.iconName,
    required this.colorHex,
    this.size = AppSizes.categoryChipSize,
  });

  final String iconName;
  final String colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(colorHex);
    final icon = CategoryIconMapper.fromName(iconName);

    return GlassCard(
      tier: GlassTier.inset,
      padding: EdgeInsets.zero,
      showBorder: true,
      tintColor: color.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(size / 2),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}
```

### Usage Count Provider (replaces CategoryFrequencyService)

```dart
// Derived provider from categoriesProvider — no new DB stream needed
final topUsedCategoriesProvider = Provider<List<CategoryEntity>>((ref) {
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  if (categories.isEmpty) return [];

  final sorted = [...categories]
    ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
  return sorted.where((c) => c.usageCount > 0).take(5).toList();
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SharedPreferences frequency tracking | DB `usageCount` column | This phase | Single source of truth, atomic increments, available in all save paths |
| needs/wants/savings groupType | Flat list, usage-sorted | This phase | Simpler mental model, data-driven ordering |
| isDefault protection on delete | All categories deletable with migration | This phase | Users have full control |
| 3 separate inline pickers | 1 shared CategoryPickerSheet | This phase | Consistent UX, single maintenance point |

**Deprecated/outdated after this phase:**
- `CategoryFrequencyService` — superseded by DB usageCount
- `categoryFrequencyServiceProvider` — superseded by categoriesProvider + usageCount
- `groupType` field — removed from entity and UI
- `isDefault` guard in delete flow — removed

## Open Questions

1. **Budget merge conflict handling (D-07)**
   - What we know: When merging categories, both source and target may have budgets for the same month. D-07 says "merge amounts" for budgets.
   - What's unclear: Should merged budget limits be summed? That could create an unreasonably high budget. Or should we keep the target's budget and drop the source's?
   - Recommendation: Keep the HIGHER limit amount between the two, delete the duplicate. This is safer than summing and less lossy than arbitrary choice. Document in plan.

2. **Backfill usageCount accuracy**
   - What we know: The migration backfills from transaction COUNT. But CategoryFrequencyService in SharedPreferences may have different counts (it tracks each save event, not just existing transactions — deleted transactions still count).
   - What's unclear: Should we use transaction COUNT (accurate to current data) or SharedPreferences data (includes historical saves)?
   - Recommendation: Use transaction COUNT. It reflects actual current state. SharedPreferences data is not reliably available on all devices and is incomplete (only tracks manual saves, not voice/AI chat).

3. **Category color for glass circles**
   - What we know: D-01 says colored glass circle with white icon. The tint color comes from `colorHex`.
   - What's unclear: What opacity/sigma works best for the inset glass tier with colored tint?
   - Recommendation: Use GlassTier.inset (sigma 8) with `tintColor: color.withValues(alpha: 0.35)`. The existing GlassCard handles device fallback. Fine-tune during implementation.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | none (default Flutter test setup) |
| Quick run command | `flutter test test/unit/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| D-07 | Merge SQL correctly migrates all connected data | unit | `flutter test test/unit/category_merge_test.dart -x` | No - Wave 0 |
| D-12 | usageCount increments on save | unit | `flutter test test/unit/category_usage_test.dart -x` | No - Wave 0 |
| D-14 | Merge combines usageCount correctly | unit | `flutter test test/unit/category_merge_test.dart -x` | No - Wave 0 |
| D-17 | Entity works without groupType | unit | `flutter test test/unit/category_entity_test.dart -x` | No - Wave 0 |
| D-08 | Seed produces ~20 categories | unit | `flutter test test/unit/category_seed_test.dart -x` | No - Wave 0 |
| D-01 | Glass icon renders (widget test) | widget | `flutter test test/widget/glass_category_icon_test.dart -x` | No - Wave 0 |
| D-02 | Picker shows Most Used section | widget | Manual verification | N/A |
| D-03 | Management screen shows usage count | widget | Manual verification | N/A |
| D-05 | 3-step delete flow completes | integration | Manual verification | N/A |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/`
- **Per wave merge:** `flutter test && flutter analyze lib/`
- **Phase gate:** Full suite green + Feature Preservation Checklist verified manually before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/category_entity_test.dart` -- covers D-17 (entity without groupType)
- [ ] `test/unit/category_merge_test.dart` -- covers D-07, D-14 (merge logic)
- [ ] `test/unit/category_usage_test.dart` -- covers D-12 (usage increment)
- [ ] `test/unit/category_seed_test.dart` -- covers D-08 (seed count)

## GroupType Removal Impact Analysis (D-17)

Full audit of all 9 files referencing `groupType`:

| File | Lines | What to Change | Risk |
|------|-------|----------------|------|
| `categories_table.dart` | L10 | Remove column definition | LOW (Drift ignores physical column) |
| `category_entity.dart` | L12, L27, L49-50, L62 | Remove field, update copyWith | LOW (pure Dart, no side effects) |
| `i_category_repository.dart` | L21 | Remove parameter from create() | LOW |
| `category_repository_impl.dart` | L55, L71, L77 | Remove from CategoriesCompanion | LOW |
| `category_seed.dart` | All entries | Remove group parameter | LOW |
| `add_category_screen.dart` | L33, L63, L88, L128, L139, L207, L213-239 | Remove _groupType state, group chips UI, save logic | MEDIUM (UI changes) |
| `categories_screen.dart` | L191-197, L213-214 | Remove _groupLabel helper, subtitle | LOW |
| `backup_service_impl.dart` | L471, L639 | Keep in JSON as nullable for backward compat | MEDIUM (compat) |
| `app_database.g.dart` | Generated | Regenerated by build_runner | AUTO |

## File Modification Risk Matrix

| File | Lines | Features | Modification Type | Risk |
|------|-------|----------|-------------------|------|
| `add_transaction_screen.dart` | 1763 | 16 | Extract lines 1608-1763 ONLY | CRITICAL |
| `voice_confirm_screen.dart` | 1423 | 12 | Add usageCount increment in save path | HIGH |
| `chat_action_executor.dart` | ~300 | 9 | Add usageCount increment in execute | HIGH |
| `categories_screen.dart` | 236 | 5 | Overhaul to hybrid list+grid+swipe+drag | HIGH |
| `add_category_screen.dart` | 369 | 4 | Remove groupType UI | MEDIUM |
| `category_repository_impl.dart` | 142 | 3 | Add merge + hard delete methods | MEDIUM |
| `category_dao.dart` | 73 | 2 | Add new query methods | LOW |
| `category_entity.dart` | 77 | 0 | Add usageCount, remove groupType | LOW |
| `category_seed.dart` | 343 | 0 | Reduce to 20 entries | LOW |
| `filter_bar.dart` | 222 | 1 | Switch from SharedPreferences to DB | MEDIUM |
| `smart_defaults_provider.dart` | ~15 | 1 | Switch provider source | LOW |
| `backup_service_impl.dart` | ~700 | 1 | Keep groupType as nullable | LOW |

## Suggested Plan Wave Structure

Based on risk analysis and dependency ordering:

| Wave | Plan | Dependencies | Files Modified | Risk |
|------|------|--------------|----------------|------|
| 0 | Schema + Entity + DAO | None | 5 data-layer files | LOW |
| 1 | Repository methods + Seed reduction | Wave 0 | 3 repository/seed files | MEDIUM |
| 2 | Shared picker extraction | Wave 0 (entity changes) | 2 NEW files + 1 deletion from source | CRITICAL |
| 3 | Categories management screen overhaul | Waves 0-1 | 2 screen files | HIGH |
| 4 | Cross-app picker integration (D-25: one at a time) | Wave 2 | 3 files, sequential | HIGH |
| 5 | Usage increment in all save paths | Wave 0 | 3 files (high-risk) | HIGH |
| 6 | AI integration + voice dictionary update | Waves 0-1 | 4 AI service files | MEDIUM |
| 7 | Cleanup: remove old frequency service + l10n | All previous | 4 files | LOW |

## Project Constraints (from CLAUDE.md)

The following CLAUDE.md directives MUST be honored by all plans:

1. **Money = INTEGER piastres.** Budget merge amounts must be integer.
2. **100% offline-first.** All category operations work without internet.
3. **RTL-first.** New picker, management screen, delete flow all validated in Arabic RTL.
4. **Design tokens are LAW.** Glass circles use `AppSizes.*`, `context.colors.*`, `AppIcons.*`. Never hardcode.
5. **MasarifyDS components always.** Use `GlassCard`, `AppButton`, `AppTextField`, etc. Never inline.
6. **`domain/` = pure Dart only.** CategoryEntity must have zero Flutter/Drift imports.
7. **Provider flow:** StreamProvider -> Repository -> DAO -> Drift. New providers follow this.
8. **No `setState` in screens** except AnimationController/ephemeral form. Picker state in widget is fine (it's ephemeral).
9. **No `Navigator.push()`** -- use `context.go()` / `context.push()`.
10. **Import ordering:** `../../` before `../`.
11. **Build runner after schema changes:** `dart run build_runner build --delete-conflicting-outputs`.
12. **`flutter analyze lib/`** must show zero issues after every plan.

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis of 25+ files across all layers
- `categories_table.dart` -- current schema (10 columns)
- `category_dao.dart` -- current CRUD (73 lines)
- `category_entity.dart` -- current entity (77 lines)
- `category_repository_impl.dart` -- current archive cascade (142 lines)
- `category_seed.dart` -- all 34 defaults
- `add_transaction_screen.dart` lines 1608-1763 -- picker extraction target
- `app_database.dart` -- migration chain v1-v14 with proven patterns
- `account_manage_sheet.dart` -- ReorderableListView drag-drop pattern

### Secondary (MEDIUM confidence)
- `voice_dictionary.dart` -- 83 keyword mappings analyzed for pruning impact
- `backup_service_impl.dart` -- groupType reference analysis
- `filter_bar.dart` -- frequency service consumer analysis
- CONTEXT.md 26 decisions -- user-locked requirements

### Tertiary (LOW confidence)
- SQLite 3.19 DROP COLUMN limitation on API 24 -- verified against SQLite changelog (3.35.0 added DROP COLUMN, released 2021-03-12; Android API 24 ships 3.19.4)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries already in project, no new deps
- Architecture: HIGH -- all patterns already exist in codebase (glass, drag-drop, swipe, picker)
- Pitfalls: HIGH -- based on direct code analysis of migration history, FK constraints, and file risk assessment
- Default categories: MEDIUM -- based on Egyptian market analysis and common finance app patterns
- SQLite version: HIGH -- verified against official SQLite release notes

**Research date:** 2026-03-28
**Valid until:** 2026-04-28 (stable; no external dependencies changing)
