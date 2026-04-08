# Phase 2: UI Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 4 UI revamps from Stitch mockups: Hero section, Voice review list, Subscriptions & Bills (with auto-pay), and Unified Transaction Detail (with OpenStreetMap).

**Architecture:** 4 independent tasks. Item 7 (Subscriptions) includes a schema migration (v18→v19) and new auto-pay logic. Item 8 (Transaction Detail) adds `flutter_map` dependency. Items 1 and 3 are UI-only.

**Tech Stack:** Flutter, Riverpod, Drift (SQLite), GlassCard, flutter_slidable, flutter_map + latlong2 (new), Phosphor Icons

---

## Task 1: Hero Section Redesign (Item 1)

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/balance_header.dart`
- Modify: `lib/features/dashboard/presentation/widgets/month_summary_inline.dart`

The hero section needs refined editorial spacing. The Cash wallet banner is already standalone in the code. Changes focus on spacing, Net label prominence, and visual hierarchy.

- [ ] **Step 1: Read balance_header.dart and identify current layout structure**

Read the file to understand the current widget tree: balance display → month summary → cash banner → account selector → wallet cards row.

- [ ] **Step 2: Refine balance section spacing**

In `balance_header.dart`, adjust the hero container padding and spacing:
- Top padding: `AppSizes.xl` (32) instead of `lg` (24) for editorial breathing room
- Balance text: ensure `displayLarge` style (32sp bold)
- Gap between balance and month summary: `AppSizes.md` (16)

- [ ] **Step 3: Make Net label prominent in month_summary_inline.dart**

In `month_summary_inline.dart`, ensure the Net row displays prominently:
- Net amount in `titleSmall` (14sp semibold) with semantic color (green for positive, red for negative)
- Add "Net" label prefix using `context.l10n`
- Even spacing above and below: `AppSizes.sm` (8) both sides

- [ ] **Step 4: Refine Cash wallet banner styling**

In `balance_header.dart`, update the cash wallet banner:
- Use `GlassCard(tier: inset)` with green-tinted background: `tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight3)`
- Ensure it sits between the income/expense pills and the account selector
- Add `AppSizes.md` (16) vertical margin above and below

- [ ] **Step 5: Run analyzer and commit**

```bash
flutter analyze lib/features/dashboard/
git add lib/features/dashboard/presentation/widgets/balance_header.dart lib/features/dashboard/presentation/widgets/month_summary_inline.dart
git commit -m "feat: refine hero section spacing and Cash wallet prominence"
```

---

## Task 2: Voice Review List View Redesign (Item 3)

**Files:**
- Modify: `lib/features/voice_input/presentation/widgets/draft_list_item.dart`

Redesign to match swipe-card visual weight — substantial glassmorphic cards stacked vertically.

- [ ] **Step 1: Read draft_list_item.dart and the swipe_card.dart for reference**

Read both files to understand the swipe card's layout structure (icon, category, amount, transcript, chips, suggestion).

- [ ] **Step 2: Add new parameters for additional data**

Add to DraftListItem constructor:
```dart
this.rawTranscript,
this.transactionDate,
```
And fields:
```dart
final String? rawTranscript;
final DateTime? transactionDate;
```

- [ ] **Step 3: Redesign the card layout to match swipe card weight**

Replace the current compact row layout in `build()` with a richer card:

```dart
final cardBody = Opacity(
  opacity: isIncluded ? 1.0 : AppSizes.opacityLight5,
  child: GlassCard(
    margin: const EdgeInsets.symmetric(
      horizontal: AppSizes.screenHPadding,
      vertical: AppSizes.sm,
    ),
    showShadow: true,
    padding: const EdgeInsets.all(AppSizes.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: Icon + Category + Amount ──
        Row(
          children: [
            Container(
              width: AppSizes.iconContainerMd,
              height: AppSizes.iconContainerMd,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: AppSizes.opacityLight),
                shape: BoxShape.circle,
              ),
              child: Icon(categoryIcon, size: AppSizes.iconSm, color: categoryColor),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                categoryName ?? '\u2014',
                style: textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formattedAmount,
              style: textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: typeColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.sm),

        // ── Row 2: Title + transcript ──
        if (title.isNotEmpty)
          Text(title, style: textStyles.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        if (rawTranscript != null && rawTranscript!.isNotEmpty) ...[
          const SizedBox(height: AppSizes.xs),
          Text(
            rawTranscript!,
            style: textStyles.bodySmall?.copyWith(
              color: colors.outline,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: AppSizes.sm),

        // ── Row 3: Detail chips ──
        Wrap(
          spacing: AppSizes.xs,
          runSpacing: AppSizes.xs,
          children: [
            if (walletName != null)
              _detailPill(context, walletName!, colors.surfaceContainerHigh),
            if (transactionDate != null)
              _detailPill(context, DateFormat('MMM d').format(transactionDate!), colors.surfaceContainerHigh),
            _detailPill(context, _typeLabel(context), typeColor.withValues(alpha: AppSizes.opacityLight2)),
          ],
        ),

        // ── Suggestion chip ──
        if (suggestionChip != null) suggestionChip,

        const SizedBox(height: AppSizes.sm),

        // ── Row 4: Include toggle + Edit ──
        Row(
          children: [
            SizedBox(
              height: AppSizes.minTapTarget,
              child: Row(
                children: [
                  Checkbox(value: isIncluded, onChanged: (_) => onToggle()),
                  const SizedBox(width: AppSizes.xs),
                  Text(context.l10n.voice_confirm_include, style: textStyles.labelMedium),
                ],
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(AppIcons.edit, size: AppSizes.iconXs),
              label: Text(context.l10n.common_edit),
            ),
          ],
        ),
      ],
    ),
  ),
);
```

- [ ] **Step 4: Add helper methods**

Add `_detailPill` and `_typeLabel` methods:
```dart
Widget _detailPill(BuildContext context, String text, Color bg) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xxs),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
    ),
    child: Text(text, style: context.textStyles.labelSmall),
  );
}

String _typeLabel(BuildContext context) => switch (type) {
  'income' || 'cash_deposit' => context.l10n.transaction_type_income,
  'transfer' => context.l10n.transaction_type_transfer,
  _ => context.l10n.transaction_type_expense,
};
```

- [ ] **Step 5: Update voice_confirm_screen.dart to pass new params**

In `voice_confirm_screen.dart`, find both DraftListItem call sites and add:
```dart
rawTranscript: draft.rawText,
transactionDate: draft.transactionDate,
```

- [ ] **Step 6: Add `intl` import for DateFormat**

Add to draft_list_item.dart:
```dart
import 'package:intl/intl.dart';
```

- [ ] **Step 7: Run analyzer and commit**

```bash
flutter analyze lib/features/voice_input/
git add lib/features/voice_input/
git commit -m "feat: redesign voice review list to match swipe card visual weight"
```

---

## Task 3: Subscriptions & Bills Revamp (Item 7)

**Files:**
- Modify: `lib/data/database/tables/recurring_rules_table.dart` — add `autoMarkPaid`, `autoPayWalletId`
- Modify: `lib/data/database/app_database.dart` — migration v19
- Modify: `lib/domain/entities/recurring_rule_entity.dart` — add fields
- Modify: `lib/features/recurring/presentation/screens/recurring_screen.dart` — full UI revamp
- Modify: `lib/features/recurring/presentation/screens/add_recurring_screen.dart` — add auto-pay UI
- Create: `lib/core/services/auto_pay_service.dart` — on-app-open check
- Modify: `lib/main.dart` — call auto-pay check on startup
- Modify: `lib/l10n/app_en.arb` + `lib/l10n/app_ar.arb` — new l10n keys

### Step Group A: Schema & Data Layer

- [ ] **Step 1: Add columns to recurring_rules_table.dart**

```dart
BoolColumn get autoMarkPaid => boolean().withDefault(const Constant(false))();
IntColumn get autoPayWalletId => integer().nullable()
    .references(Wallets, #id, onDelete: KeyAction.setNull)();
```

- [ ] **Step 2: Add migration v19 in app_database.dart**

Bump `schemaVersion` from 18 to 19. Add after `if (from < 18)`:
```dart
if (from < 19) {
  await customStatement(
    "ALTER TABLE recurring_rules ADD COLUMN auto_mark_paid INTEGER NOT NULL DEFAULT 0",
  );
  await customStatement(
    "ALTER TABLE recurring_rules ADD COLUMN auto_pay_wallet_id INTEGER",
  );
}
```

- [ ] **Step 3: Update recurring_rule_entity.dart**

Add fields:
```dart
this.autoMarkPaid = false,
this.autoPayWalletId,
```
And:
```dart
final bool autoMarkPaid;
final int? autoPayWalletId;
```

- [ ] **Step 4: Update repository _toEntity mapping**

In `lib/data/repositories/recurring_rule_repository_impl.dart`, add to `_toEntity`:
```dart
autoMarkPaid: r.autoMarkPaid,
autoPayWalletId: r.autoPayWalletId,
```

- [ ] **Step 5: Update create/update methods to accept new fields**

In the repository, add `bool autoMarkPaid = false` and `int? autoPayWalletId` parameters to `create()` and `update()`, pass them to the Drift companion.

### Step Group B: Auto-Pay Service

- [ ] **Step 6: Create auto_pay_service.dart**

```dart
// lib/core/services/auto_pay_service.dart
import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/repository_providers.dart';

/// Checks for overdue auto-pay bills on app open and creates transactions retroactively.
class AutoPayService {
  static Future<void> processOverdueAutoPay(WidgetRef ref) async {
    try {
      final recurringRepo = ref.read(recurringRuleRepositoryProvider);
      final txRepo = ref.read(transactionRepositoryProvider);
      final rules = await recurringRepo.getAll();
      final now = DateTime.now();

      for (final rule in rules) {
        if (!rule.isActive || !rule.autoMarkPaid || rule.autoPayWalletId == null) continue;
        if (rule.isPaid) continue;
        if (rule.nextDueDate.isAfter(now)) continue;

        // Overdue + auto-pay enabled → create transaction
        try {
          await txRepo.create(
            walletId: rule.autoPayWalletId!,
            categoryId: rule.categoryId,
            amount: rule.amount,
            type: rule.type,
            title: rule.title,
            transactionDate: rule.nextDueDate,
            source: 'auto',
          );
          // Mark as paid and advance nextDueDate
          await recurringRepo.markPaid(rule.id);
          dev.log('Auto-paid: ${rule.title}', name: 'AutoPay');
        } catch (e) {
          dev.log('Auto-pay failed for ${rule.title}: $e', name: 'AutoPay');
        }
      }
    } catch (e) {
      dev.log('AutoPayService error: $e', name: 'AutoPay');
    }
  }
}
```

- [ ] **Step 7: Call auto-pay on dashboard open**

In `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, in `initState` after the notification permission block, add:
```dart
AutoPayService.processOverdueAutoPay(ref);
```
Import the service file.

### Step Group C: Subscriptions UI Revamp

- [ ] **Step 8: Add l10n keys**

In `app_en.arb`:
```json
"recurring_view_all": "View All",
"recurring_monthly_total": "Monthly Total",
"recurring_due_this_week": "{count} due this week",
"recurring_overdue": "Overdue",
"recurring_upcoming": "Upcoming",
"recurring_paid_section": "Paid",
"recurring_auto_pay_label": "Automatically mark as paid",
"recurring_auto_pay_wallet": "Deduct from account",
"recurring_mark_paid": "Mark Paid"
```

In `app_ar.arb`:
```json
"recurring_view_all": "عرض الكل",
"recurring_monthly_total": "الإجمالي الشهري",
"recurring_due_this_week": "{count} مستحق هذا الأسبوع",
"recurring_overdue": "متأخر",
"recurring_upcoming": "قادم",
"recurring_paid_section": "مدفوع",
"recurring_auto_pay_label": "وضع علامة مدفوع تلقائياً",
"recurring_auto_pay_wallet": "خصم من الحساب",
"recurring_mark_paid": "وضع علامة مدفوع"
```

- [ ] **Step 9: Revamp recurring_screen.dart**

Rewrite the screen body to match the Stitch mockup:
- Add summary header card with monthly total + "due this week" badge
- Add "View All" toggle button in the app bar
- Status-grouped sections with tinted backgrounds (no section headers — use color tints)
- Each card: GlassCard with left accent bar, brand/category icon, title, frequency, amount, Mark Paid button / toggle
- Mark Paid creates a transaction via `transactionRepositoryProvider.create()`, then calls `recurringRuleRepositoryProvider.markPaid()`

- [ ] **Step 10: Add auto-pay UI to add_recurring_screen.dart**

In the create/edit form, add after the existing fields:
- `SwitchListTile` for "Automatically mark as paid" (`_autoMarkPaid` state)
- When enabled, show wallet picker dropdown for `_autoPayWalletId`
- Pass both to repository on save

- [ ] **Step 11: Run codegen, gen-l10n, analyze, commit**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter analyze lib/
git add lib/ 
git commit -m "feat: revamp Subscriptions & Bills with auto-pay and status grouping"
```

---

## Task 4: Unified Transaction Detail Screen (Item 8)

**Files:**
- Modify: `pubspec.yaml` — add `flutter_map`, `latlong2`
- Modify: `lib/features/transactions/presentation/screens/transaction_detail_screen.dart` — redesign
- Modify: `lib/features/wallets/presentation/screens/transfer_detail_screen.dart` — unify with transaction style
- Modify: `lib/l10n/app_en.arb` + `lib/l10n/app_ar.arb` — map-related keys

- [ ] **Step 1: Add flutter_map and latlong2 dependencies**

In `pubspec.yaml`, under dependencies:
```yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1
```
Run: `flutter pub get`

- [ ] **Step 2: Redesign transaction_detail_screen.dart hero card**

Replace the hero card section with the unified design:
- GlassCard with margin `EdgeInsets.all(AppSizes.screenHPadding)`, padding `EdgeInsets.symmetric(horizontal: AppSizes.lg, vertical: AppSizes.xl)`
- Centered column: category icon in 48px tinted circle → amount (displayLarge, bold, color-coded) → title (bodyMedium) → type+date badge pills row
- Use consistent `_DetailRow` widget pattern for metadata

- [ ] **Step 3: Add OpenStreetMap widget for location**

When `tx.latitude != null && tx.longitude != null`, show a map tile:
```dart
if (tx.latitude != null && tx.longitude != null) ...[
  const SizedBox(height: AppSizes.md),
  ClipRRect(
    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
    child: SizedBox(
      height: AppSizes.chartHeightMd,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(tx.latitude!, tx.longitude!),
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.masarify.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(tx.latitude!, tx.longitude!),
                child: Icon(AppIcons.location, color: cs.primary, size: AppSizes.iconLg),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
],
```

Add imports:
```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
```

- [ ] **Step 4: Unify transfer_detail_screen.dart styling**

Update `transfer_detail_screen.dart` to use the same hero card pattern:
- Same GlassCard margins and padding as transaction detail
- Icon in 48px tinted circle (transfer icon)
- Amount in displayLarge with `transferColor`
- FROM → TO wallet flow with arrow icon
- Detail rows using same `_DetailRow` pattern (icon badge + label + value, 16px spacing, no dividers)

- [ ] **Step 5: Run pub get, analyze, commit**

```bash
flutter pub get
flutter analyze lib/
git add pubspec.yaml pubspec.lock lib/features/transactions/ lib/features/wallets/presentation/screens/transfer_detail_screen.dart
git commit -m "feat: unified transaction detail with OpenStreetMap"
```

---

## Verification

1. `dart run build_runner build --delete-conflicting-outputs` (after Task 3)
2. `flutter gen-l10n` (after Task 3)
3. `flutter analyze lib/` — zero issues
4. `flutter test` — all tests pass
5. Manual testing:
   - Hero section: Cash wallet standalone, editorial spacing, Net label visible
   - Voice review: Cards match swipe-card weight, transcript visible, chips row, include toggle
   - Subscriptions: Summary header, status groups, Mark Paid creates transaction, auto-pay checkbox in create/edit
   - Transaction detail: Unified hero card, map shows for geolocated transactions, edit/delete buttons work
   - Transfer detail: Same visual style as transaction detail, FROM→TO flow
6. RTL validation in Arabic
7. Dark mode glass tier check
