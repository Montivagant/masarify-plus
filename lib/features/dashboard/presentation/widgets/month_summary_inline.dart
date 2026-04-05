import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/transaction_provider.dart';

/// Glass pill badges showing Income & Expense side-by-side, with Net below.
///
/// Used inline under the balance number in the balance header.
/// Each pill has a tinted glass background matching its category colour.
class MonthSummaryInline extends ConsumerStatefulWidget {
  const MonthSummaryInline({
    super.key,
    this.walletId,
    this.hidden = false,
  });

  /// null = all accounts.
  final int? walletId;
  final bool hidden;

  @override
  ConsumerState<MonthSummaryInline> createState() => _MonthSummaryInlineState();
}

class _MonthSummaryInlineState extends ConsumerState<MonthSummaryInline> {
  final _infoKey = GlobalKey();
  OverlayEntry? _popoverEntry;

  void _togglePopover() {
    if (_popoverEntry != null) {
      _dismissPopover();
      return;
    }

    final renderBox = _infoKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final position = renderBox.localToGlobal(Offset.zero);
    final iconSize = renderBox.size;

    _popoverEntry = OverlayEntry(
      builder: (ctx) => _NetPopover(
        anchorPosition: position,
        anchorSize: iconSize,
        onDismiss: _dismissPopover,
      ),
    );

    overlay.insert(_popoverEntry!);
  }

  void _dismissPopover() {
    _popoverEntry?.remove();
    _popoverEntry = null;
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

    // Filter by wallet if needed.
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
    final bodyMedium = context.textStyles.bodyMedium;
    final hidden = widget.hidden;

    const bullet = '\u2022\u2022\u2022\u2022';

    return Column(
      children: [
        // ── Income / Expense glass pills ───────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Income pill
            Expanded(
              child: _GlassPill(
                icon: AppIcons.income,
                label: context.l10n.dashboard_income,
                amount: hidden ? bullet : MoneyFormatter.formatCompact(income),
                color: incomeColor,
                labelStyle: bodySmall,
                amountStyle: bodyMedium,
                labelColor: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Expense pill
            Expanded(
              child: _GlassPill(
                icon: AppIcons.expense,
                label: context.l10n.dashboard_expense,
                amount: hidden ? bullet : MoneyFormatter.formatCompact(expense),
                color: expenseColor,
                labelStyle: bodySmall,
                amountStyle: bodyMedium,
                labelColor: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSizes.xs),

        // ── Net row with info popover ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
              onTap: _togglePopover,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xs),
                child: Icon(
                  key: _infoKey,
                  AppIcons.infoFilled,
                  size: AppSizes.iconXxs,
                  color: context.colors.onSurfaceVariant.withValues(
                    alpha: AppSizes.opacityMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.xxs),
            Text(
              hidden
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

// ── Glass pill badge ─────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.labelStyle,
    required this.amountStyle,
    required this.labelColor,
  });

  final IconData icon;
  final String label;
  final String amount;
  final Color color;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.opacityLight2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            Icon(icon, size: AppSizes.iconSm, color: color),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: labelStyle?.copyWith(color: labelColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    amount,
                    style: amountStyle?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Net info popover ──────────────────────────────────────────────────────────

class _NetPopover extends StatelessWidget {
  const _NetPopover({
    required this.anchorPosition,
    required this.anchorSize,
    required this.onDismiss,
  });

  final Offset anchorPosition;
  final Size anchorSize;
  final VoidCallback onDismiss;

  static const double _maxWidth = 240;

  @override
  Widget build(BuildContext context) {
    final cardTop = anchorPosition.dy + anchorSize.height + AppSizes.xs;
    // Center the card horizontally on the icon.
    final cardLeft = anchorPosition.dx + anchorSize.width / 2 - _maxWidth / 2;

    return Stack(
      children: [
        // Full-screen transparent dismiss scrim.
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: const ColoredBox(color: AppColors.transparent),
          ),
        ),
        // Positioned card.
        Positioned(
          top: cardTop,
          left: cardLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Material(
              color: context.colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              elevation: AppSizes.elevationHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                child: Text(
                  context.l10n.home_net_tooltip,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
