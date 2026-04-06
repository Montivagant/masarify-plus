# Dashboard UX Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement 6 UX improvements: Net info popover, Cash wallet reordering, All Accounts dropdown, voice recording pill bar, horizontal chip reorder, and upcoming bills rethink.

**Architecture:** Each task is an independent feature that can be implemented, tested, and committed separately. Tasks are ordered by dependency — simpler changes first, larger rewrites later. The voice pill bar (Task 4) is the most complex and should be done last.

**Tech Stack:** Flutter 3.x, Riverpod 2.x, Drift (SQLite), Material Design 3, Phosphor Icons

---

## Task 1: Net Info Popover

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/month_summary_inline.dart`

- [ ] **Step 1: Replace Tooltip with GestureDetector + OverlayEntry**

Replace the `Tooltip` wrapper (lines 87-118) with a `GestureDetector` on the info icon that shows a popover via `OverlayEntry`. Since `MonthSummaryInline` is a `ConsumerWidget`, convert it to `ConsumerStatefulWidget` to manage the overlay lifecycle.

Replace the entire file content with:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/transaction_provider.dart';

class MonthSummaryInline extends ConsumerStatefulWidget {
  const MonthSummaryInline({
    super.key,
    this.walletId,
    this.hidden = false,
  });

  final int? walletId;
  final bool hidden;

  @override
  ConsumerState<MonthSummaryInline> createState() =>
      _MonthSummaryInlineState();
}

class _MonthSummaryInlineState extends ConsumerState<MonthSummaryInline> {
  final _infoKey = GlobalKey();
  OverlayEntry? _popover;

  void _togglePopover() {
    if (_popover != null) {
      _dismissPopover();
      return;
    }
    final renderBox =
        _infoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _popover = OverlayEntry(
      builder: (_) => _NetPopover(
        anchor: offset,
        anchorSize: size,
        message: context.l10n.home_net_tooltip,
        onDismiss: _dismissPopover,
      ),
    );
    overlay.insert(_popover!);
  }

  void _dismissPopover() {
    _popover?.remove();
    _popover = null;
  }

  @override
  void dispose() {
    _dismissPopover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final txs =
        ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];

    final filtered = widget.walletId != null
        ? txs.where((t) => t.walletId == widget.walletId)
        : txs;

    int income = 0;
    int expense = 0;
    for (final t in filtered) {
      if (t.type == 'income') income += t.amount;
      if (t.type == 'expense') expense += t.amount;
    }

    final net = income - expense;
    final isPositive = net >= 0;

    final incomeColor = context.appTheme.incomeColor;
    final expenseColor = context.appTheme.expenseColor;
    final netColor = isPositive ? incomeColor : expenseColor;
    final bodySmall = context.textStyles.bodySmall;

    const bullet = '\u2022\u2022\u2022\u2022';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AppIcons.income, size: AppSizes.iconXs, color: incomeColor),
        const SizedBox(width: AppSizes.xxs),
        Text(
          widget.hidden ? bullet : MoneyFormatter.formatCompact(income),
          style: bodySmall?.copyWith(
            color: incomeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Icon(AppIcons.expense, size: AppSizes.iconXs, color: expenseColor),
        const SizedBox(width: AppSizes.xxs),
        Text(
          widget.hidden ? bullet : MoneyFormatter.formatCompact(expense),
          style: bodySmall?.copyWith(
            color: expenseColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        // Net with info popover
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.home_net_label,
              style: bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSizes.xxs),
            GestureDetector(
              key: _infoKey,
              onTap: _togglePopover,
              child: Icon(
                AppIcons.infoFilled,
                size: AppSizes.iconXxs,
                color: context.colors.onSurfaceVariant
                    .withValues(alpha: AppSizes.opacityMedium),
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              widget.hidden
                  ? bullet
                  : '${isPositive ? '+' : '-'}${MoneyFormatter.formatCompact(net.abs())}',
              style: bodySmall?.copyWith(
                color: netColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Popover bubble anchored to the info icon.
class _NetPopover extends StatelessWidget {
  const _NetPopover({
    required this.anchor,
    required this.anchorSize,
    required this.message,
    required this.onDismiss,
  });

  final Offset anchor;
  final Size anchorSize;
  final String message;
  final VoidCallback onDismiss;

  static const double _maxWidth = 240;
  static const double _arrowSize = 6;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Stack(
      children: [
        // Dismiss scrim
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Popover card positioned below the anchor
        Positioned(
          left: (anchor.dx + anchorSize.width / 2 - _maxWidth / 2)
              .clamp(AppSizes.sm, MediaQuery.of(context).size.width - _maxWidth - AppSizes.sm),
          top: anchor.dy + anchorSize.height + _arrowSize,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusMd),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: AppSizes.opacityLight4),
                    blurRadius: AppSizes.lg,
                  ),
                ],
              ),
              child: Text(
                message,
                style: context.textStyles.bodySmall?.copyWith(
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/features/dashboard/presentation/widgets/month_summary_inline.dart`
Expected: No issues

- [ ] **Step 3: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/month_summary_inline.dart
git commit -m "feat: replace Net tooltip with tap-triggered info popover"
```

---

## Task 2: Cash Wallet Reordering

**Files:**
- Modify: `lib/data/database/daos/wallet_dao.dart:12-28`
- Modify: `lib/features/dashboard/presentation/widgets/account_manage_sheet.dart:40-50`

- [ ] **Step 1: Remove forced system-wallet-first sort in wallet_dao.dart**

In `wallet_dao.dart`, remove `(w) => OrderingTerm.desc(w.isSystemWallet)` from both `watchAll()` and `getAll()`. Keep only `sortOrder` and `id` ordering.

In `watchAll()` (lines 12-19), change to:
```dart
Stream<List<Wallet>> watchAll() => (select(wallets)
      ..where((w) => w.isArchived.not())
      ..orderBy([
        (w) => OrderingTerm.asc(w.sortOrder),
        (w) => OrderingTerm.asc(w.id),
      ]))
    .watch();
```

In `getAll()` (lines 21-28), change to:
```dart
Future<List<Wallet>> getAll() => (select(wallets)
      ..where((w) => w.isArchived.not())
      ..orderBy([
        (w) => OrderingTerm.asc(w.sortOrder),
        (w) => OrderingTerm.asc(w.id),
      ]))
    .get();
```

- [ ] **Step 2: Include system wallet in manage sheet**

In `account_manage_sheet.dart`, in `_loadWallets()` (lines 40-51), remove the `!w.isSystemWallet` filter:

Change:
```dart
final userWallets = wallets.where((w) => !w.isSystemWallet).toList()
```
To:
```dart
final userWallets = wallets.toList()
```

- [ ] **Step 3: Disable archive for system wallet in manage sheet**

In the `_WalletTile` section of `account_manage_sheet.dart`, find the archive toggle button and wrap it with a condition. The system wallet should show the archive icon as disabled/greyed out. Find the `_toggleArchive` call site in the tile and add a guard:

In `_toggleArchive` method, add at the top:
```dart
if (wallet.isSystemWallet) return;
```

In the tile widget, make the archive icon visually disabled for system wallets:
```dart
opacity: wallet.isSystemWallet ? AppSizes.opacityLight4 : 1.0,
```

- [ ] **Step 4: Run analyzer + rebuild Drift**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter analyze lib/`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/data/database/daos/wallet_dao.dart lib/features/dashboard/presentation/widgets/account_manage_sheet.dart
git commit -m "feat: allow Cash wallet to be reordered alongside user wallets"
```

---

## Task 3: All Accounts → Balance Header Dropdown

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/balance_header.dart`
- Modify: `lib/features/dashboard/presentation/widgets/account_chip.dart`

- [ ] **Step 1: Add account selector dropdown to balance_header.dart**

Replace the balance row area (after the balance text and eye toggle, before the chip row) with a tappable account selector. Add this widget between the `MonthSummaryInline` and the chip row:

```dart
// ── Account selector dropdown ─────────────────────────
GestureDetector(
  onTap: () => _showAccountPicker(context, ref, wallets, selectedId, totalBalance),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(
        selectedId == null
            ? context.l10n.dashboard_all_accounts
            : wallets
                    .where((w) => w.id == selectedId)
                    .firstOrNull
                    ?.name ??
                context.l10n.dashboard_all_accounts,
        style: context.textStyles.labelMedium?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
      const SizedBox(width: AppSizes.xxs),
      Icon(
        AppIcons.expandMore,
        size: AppSizes.iconXs,
        color: cs.onSurfaceVariant,
      ),
    ],
  ),
),
```

Convert `BalanceHeader` from `ConsumerWidget` to `ConsumerStatefulWidget` (or use a static method) to show the popup. Add the picker method:

```dart
void _showAccountPicker(
  BuildContext context,
  WidgetRef ref,
  List<WalletEntity> wallets,
  int? selectedId,
  int totalBalance,
) {
  final cs = context.colors;
  showModalBottomSheet<void>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(AppIcons.wallet, color: cs.primary),
            title: Text(context.l10n.dashboard_all_accounts),
            subtitle: Text(MoneyFormatter.format(totalBalance)),
            trailing: selectedId == null
                ? Icon(AppIcons.check, color: cs.primary)
                : null,
            onTap: () {
              ref.read(selectedAccountIdProvider.notifier).state = null;
              Navigator.pop(context);
            },
          ),
          ...wallets.where((w) => !w.isArchived).map(
                (w) => ListTile(
                  leading: Icon(
                    AppIcons.walletType(w.type),
                    color: ColorUtils.fromHex(w.colorHex),
                  ),
                  title: Text(w.name),
                  subtitle: Text(MoneyFormatter.format(w.balance)),
                  trailing: selectedId == w.id
                      ? Icon(AppIcons.check, color: cs.primary)
                      : null,
                  onTap: () {
                    ref.read(selectedAccountIdProvider.notifier).state = w.id;
                    Navigator.pop(context);
                  },
                ),
              ),
        ],
      ),
    ),
  );
}
```

Note: This uses `Navigator.pop` inside the bottom sheet which is acceptable — the sheet is a separate navigator context.

- [ ] **Step 2: Conditionally show chip row**

Wrap the chip row section (lines 94-168) with a condition:

```dart
if (selectedId != null) ...[
  const SizedBox(height: AppSizes.md),
  // ── Account chips row ──
  Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Flexible(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...userWallets.map(
                (w) => AccountChip(
                  label: w.name,
                  balance: w.balance,
                  isSelected: selectedId == w.id,
                  hidden: hidden,
                  walletType: w.type,
                  colorHex: w.colorHex,
                  onTap: () => ref
                      .read(selectedAccountIdProvider.notifier)
                      .state = w.id,
                ),
              ),
              // Quick-add + manage gear stay
            ],
          ),
        ),
      ),
      IconButton(
        icon: Icon(AppIcons.settings, size: AppSizes.iconSm, color: cs.outline),
        tooltip: context.l10n.wallet_manage_title,
        onPressed: () => AccountManageSheet.show(context),
        visualDensity: VisualDensity.compact,
      ),
    ],
  ),
],
```

Remove the `AccountChip` with `isAllAccounts: true` from the chip row (it's now in the dropdown).

- [ ] **Step 3: Clean up AccountChip**

In `account_chip.dart`, remove the `isAllAccounts` parameter and all logic that references it (`_allAccountsWidth`, the icon selection for all accounts, etc.). All chips now use the individual wallet style.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/`
Expected: No issues

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/balance_header.dart lib/features/dashboard/presentation/widgets/account_chip.dart
git commit -m "feat: move All Accounts to balance header dropdown, chip row shows only when wallet selected"
```

---

## Task 4: Voice Recording Pill Bar

**Files:**
- Create: `lib/features/voice_input/presentation/widgets/voice_recording_pill.dart`
- Modify: `lib/features/voice_input/presentation/widgets/voice_input_sheet.dart`
- Modify: `lib/features/voice_input/presentation/widgets/voice_input_button.dart`
- Modify: `lib/shared/widgets/navigation/app_nav_bar.dart`

This is the largest task. The approach: create the new pill widget, then wire it into the app shell as an overlay that sits above the nav bar.

- [ ] **Step 1: Create VoiceRecordingPill widget**

Create `lib/features/voice_input/presentation/widgets/voice_recording_pill.dart`. This widget contains ALL recording logic (moved from `VoiceInputSheet`) in a compact 56dp pill form factor.

The pill has 3 states: recording, processing, error. It manages the `AudioRecorder`, amplitude stream, duration timer, and Gemini API call internally — same logic as the current `VoiceInputSheet` but with a different UI.

Key structure:
```dart
class VoiceRecordingPill extends ConsumerStatefulWidget {
  const VoiceRecordingPill({super.key, required this.onDismiss});
  final VoidCallback onDismiss;
  // ...
}
```

The pill build method returns a `Container` with pill shape, 56dp height, glassmorphic surface. It renders different content based on state:
- **Recording:** [PulsingRedDot] [WaveBars] [Timer "0:04"] [StopButton]
- **Processing:** [MintSpinner] ["Processing..." text]
- **Error:** [ErrorIcon] [Error text] — auto-dismisses after 2 seconds

On successful processing, calls `context.push(AppRoutes.voiceConfirm, extra: drafts)` and `widget.onDismiss()`.

Move the recording logic from `voice_input_sheet.dart` (`_startRecording`, `_stopAndProcess`, `_cleanupTempFile`, amplitude stream, Gemini API call) into this new widget. The logic is identical — only the UI wrapper changes.

- [ ] **Step 2: Add pill overlay slot to AppScaffoldShell**

In `app_nav_bar.dart`, add a `ValueNotifier<bool>` to `_AppScaffoldShellState` to control pill visibility:

```dart
final _showVoicePill = ValueNotifier<bool>(false);
```

Update the FAB's `onVoice` callback to show the pill instead of calling `VoiceInputButton.handleVoiceInput`:

```dart
onVoice: () async {
  // Permission check first
  final status = await Permission.microphone.status;
  if (!status.isGranted) {
    if (!mounted) return;
    await VoiceInputButton.handleVoiceInput(context);
    return;
  }
  _showVoicePill.value = true;
},
```

In the `build` method, wrap the scaffold in a `Stack` and add the pill:

```dart
return Stack(
  children: [
    scaffold,
    // Voice recording pill overlay
    ValueListenableBuilder<bool>(
      valueListenable: _showVoicePill,
      builder: (context, show, _) {
        if (!show) return const SizedBox.shrink();
        return Positioned(
          left: AppSizes.screenHPadding,
          right: AppSizes.screenHPadding,
          bottom: AppSizes.navBarHeight + AppSizes.md,
          child: VoiceRecordingPill(
            onDismiss: () => _showVoicePill.value = false,
          ),
        );
      },
    ),
    // existing FAB hint overlay...
  ],
);
```

- [ ] **Step 3: Update VoiceInputButton for permission-only flow**

In `voice_input_button.dart`, keep the permission handling but when permission is granted, instead of calling `VoiceInputSheet.show()`, have it signal to show the pill. Since the pill is managed by `AppScaffoldShell`, the simplest approach: keep `VoiceInputSheet.show()` as fallback for non-shell contexts, but the primary path goes through the shell's `_showVoicePill`.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/`
Expected: No issues

- [ ] **Step 5: Test manually on device**

1. Tap FAB → Voice button → pill bar slides up
2. Recording starts automatically, wave bars animate, timer counts
3. Tap stop → pill shows "Processing..."
4. Success → pill slides down, review screen appears
5. Error → pill shows error briefly, slides down

- [ ] **Step 6: Commit**

```bash
git add lib/features/voice_input/presentation/widgets/voice_recording_pill.dart lib/features/voice_input/presentation/widgets/voice_input_button.dart lib/shared/widgets/navigation/app_nav_bar.dart
git commit -m "feat: replace voice input overlay with compact floating pill bar"
```

---

## Task 5: Horizontal Drag-to-Reorder Wallet Chips

**Files:**
- Create: `lib/shared/widgets/lists/horizontal_reorderable_row.dart`
- Modify: `lib/features/dashboard/presentation/widgets/balance_header.dart`

- [ ] **Step 1: Create HorizontalReorderableRow widget**

Create `lib/shared/widgets/lists/horizontal_reorderable_row.dart` — a generic horizontal reorder widget using long-press + drag gestures.

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_sizes.dart';

class HorizontalReorderableRow<T> extends StatefulWidget {
  const HorizontalReorderableRow({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.itemWidth = 110,
    this.spacing = AppSizes.sm,
    this.trailing,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, bool isDragging) itemBuilder;
  final void Function(int oldIndex, int newIndex) onReorder;
  final double itemWidth;
  final double spacing;
  final List<Widget>? trailing;

  @override
  State<HorizontalReorderableRow<T>> createState() =>
      _HorizontalReorderableRowState<T>();
}
```

The state manages:
- `_dragIndex`: which item is being dragged (null if not dragging)
- `_dragOffset`: current drag position offset
- `_targetIndex`: where the item would be inserted
- A `ScrollController` for auto-scrolling near edges

Long-press handler:
```dart
void _onLongPressStart(int index, LongPressStartDetails details) {
  HapticFeedback.mediumImpact();
  setState(() {
    _dragIndex = index;
    _dragOffset = 0;
    _targetIndex = index;
  });
}
```

Drag update calculates which position the dragged item should land in based on horizontal offset, and animates other items aside. Drop persists the reorder via the `onReorder` callback.

Build method renders items in a `SingleChildScrollView` with `Axis.horizontal`. Each item is wrapped in a `GestureDetector` with `onLongPressStart`, `onLongPressMoveUpdate`, `onLongPressEnd`. The dragged item is rendered with `Transform.scale(scale: 1.05)` and elevated opacity.

- [ ] **Step 2: Integrate into balance_header.dart**

Replace the `SingleChildScrollView` + `Row` chip rendering with:

```dart
HorizontalReorderableRow<WalletEntity>(
  items: userWallets,
  itemWidth: AccountChip.individualWidth,
  onReorder: (oldIndex, newIndex) async {
    final updates = <({int id, int sortOrder})>[];
    final reordered = [...userWallets];
    if (newIndex > oldIndex) newIndex--;
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    for (var i = 0; i < reordered.length; i++) {
      updates.add((id: reordered[i].id, sortOrder: i));
    }
    ref.read(walletRepositoryProvider).updateSortOrders(updates);
  },
  itemBuilder: (context, w, isDragging) => AccountChip(
    label: w.name,
    balance: w.balance,
    isSelected: selectedId == w.id,
    hidden: hidden,
    walletType: w.type,
    colorHex: w.colorHex,
    onTap: isDragging
        ? () {}
        : () => ref.read(selectedAccountIdProvider.notifier).state = w.id,
  ),
  trailing: [
    // Quick-add chip
    // ... existing ActionChip code
  ],
),
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/`
Expected: No issues

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/lists/horizontal_reorderable_row.dart lib/features/dashboard/presentation/widgets/balance_header.dart
git commit -m "feat: add horizontal drag-to-reorder for wallet chips"
```

---

## Task 6: Upcoming Bills Rethink

**Files:**
- Create: `lib/features/dashboard/presentation/widgets/due_soon_section.dart`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Modify: `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart`
- Modify: `lib/shared/widgets/navigation/app_nav_bar.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

- [ ] **Step 1: Add l10n keys**

In `app_en.arb`, add:
```json
"home_due_soon_title": "Due Soon",
"home_due_soon_today": "Today",
"home_due_soon_tomorrow": "Tomorrow",
"home_due_soon_in_days": "In {count} days",
"@home_due_soon_in_days": { "placeholders": { "count": { "type": "int" } } },
"home_due_soon_more": "+{count} more",
"@home_due_soon_more": { "placeholders": { "count": { "type": "int" } } }
```

In `app_ar.arb`, add:
```json
"home_due_soon_title": "مستحقة قريبا",
"home_due_soon_today": "اليوم",
"home_due_soon_tomorrow": "بكرة",
"home_due_soon_in_days": "بعد {count} يوم",
"home_due_soon_more": "+{count} كمان"
```

Run: `flutter gen-l10n`

- [ ] **Step 2: Create DueSoonSection widget**

Create `lib/features/dashboard/presentation/widgets/due_soon_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

class DueSoonSection extends ConsumerWidget {
  const DueSoonSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(upcomingBillsProvider);
    if (bills.isEmpty) return const SizedBox.shrink();

    final cs = context.colors;
    final displayBills = bills.take(3).toList();
    final remaining = bills.length - displayBills.length;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Icon(AppIcons.bill, size: AppSizes.iconSm, color: cs.primary),
              const SizedBox(width: AppSizes.xs),
              Text(
                context.l10n.home_due_soon_title,
                style: context.textStyles.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          // Horizontal bill cards
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: displayBills.length + (remaining > 0 ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
              itemBuilder: (context, index) {
                if (index >= displayBills.length) {
                  // "+N more" chip
                  return GestureDetector(
                    onTap: () => context.push(AppRoutes.recurring),
                    child: GlassCard(
                      child: Center(
                        child: Text(
                          context.l10n.home_due_soon_more(remaining),
                          style: context.textStyles.labelMedium?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return _BillMiniCard(bill: displayBills[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BillMiniCard extends StatelessWidget {
  const _BillMiniCard({required this.bill});
  final RecurringRuleEntity bill;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(
      bill.nextDueDate.year,
      bill.nextDueDate.month,
      bill.nextDueDate.day,
    );
    final daysUntil = dueDay.difference(today).inDays;

    // Color coding
    final Color urgencyColor;
    final String dueLabel;
    if (daysUntil <= 0) {
      urgencyColor = context.appTheme.expenseColor;
      dueLabel = context.l10n.home_due_soon_today;
    } else if (daysUntil == 1) {
      urgencyColor = context.appTheme.expenseColor;
      dueLabel = context.l10n.home_due_soon_tomorrow;
    } else if (daysUntil <= 3) {
      urgencyColor = context.appTheme.warningColor;
      dueLabel = context.l10n.home_due_soon_in_days(daysUntil);
    } else {
      urgencyColor = context.appTheme.incomeColor;
      dueLabel = context.l10n.home_due_soon_in_days(daysUntil);
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.recurring),
      child: SizedBox(
        width: 140,
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bill.title,
                  style: context.textStyles.labelMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  MoneyFormatter.format(bill.amount),
                  style: context.textStyles.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  dueLabel,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: urgencyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Add DueSoonSection to dashboard_screen.dart**

In `dashboard_screen.dart`, add a new sliver between the `InsightCardsZone` and the `FilterBarDelegate`:

```dart
// ── Due Soon bills section (conditional) ────────
const SliverToBoxAdapter(child: DueSoonSection()),
```

Add the import:
```dart
import '../widgets/due_soon_section.dart';
```

- [ ] **Step 4: Remove upcoming bills from insight_cards_zone.dart**

In `insight_cards_zone.dart`, delete the entire "Priority 3: Upcoming bills" block (lines 94-112):

```dart
// DELETE THIS BLOCK:
// ── Priority 3: Upcoming bills (due within 7 days) ────────────────
final upcomingBills = ref.watch(upcomingBillsProvider);
if (upcomingBills.isNotEmpty) {
  final key = ...
  ...
}
```

- [ ] **Step 5: Add badge to Recurring tab in app_nav_bar.dart**

In the `AppNavBar` widget, find the Recurring tab icon and wrap it with a `Badge` widget:

```dart
NavigationDestination(
  icon: Badge(
    isLabelVisible: upcomingCount > 0,
    label: Text('$upcomingCount'),
    child: const Icon(AppIcons.recurring),
  ),
  selectedIcon: Badge(
    isLabelVisible: upcomingCount > 0,
    label: Text('$upcomingCount'),
    child: const Icon(AppIcons.recurringFilled),
  ),
  label: context.l10n.nav_recurring,
),
```

The `upcomingCount` comes from `ref.watch(upcomingBillsProvider).length`. This requires converting `AppNavBar` to a `ConsumerWidget` (or passing the count as a parameter from the shell).

- [ ] **Step 6: Run analyzer + gen-l10n**

Run: `flutter gen-l10n && flutter analyze lib/`
Expected: No issues

- [ ] **Step 7: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/due_soon_section.dart lib/features/dashboard/presentation/screens/dashboard_screen.dart lib/features/dashboard/presentation/widgets/insight_cards_zone.dart lib/shared/widgets/navigation/app_nav_bar.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb
git commit -m "feat: richer Due Soon bills section + Recurring tab badge"
```

---

## Task 7: Final Verification

- [ ] **Step 1: Run full analyzer**

Run: `flutter analyze lib/`
Expected: 0 issues

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: All 202+ tests pass

- [ ] **Step 3: Manual smoke test on device**

1. Net "i" icon → tap → popover shows → tap outside → dismiss
2. Manage sheet → Cash wallet visible → drag to reorder → verify sort persists
3. Balance header → tap "All Accounts ▾" → dropdown → select wallet → chip row appears → select another → chip row switches → select "All Accounts" → chip row hides
4. FAB → Voice → pill bar slides up → record → stop → processing → review screen
5. Chip row → long-press chip → drag left/right → chips slide → drop → order persists
6. Dashboard → "Due Soon" section shows upcoming bills → tap bill → goes to recurring → Recurring tab has badge count

- [ ] **Step 4: Commit all remaining changes**

```bash
git add -A
git commit -m "feat: dashboard UX revamp — 6 improvements complete"
```
