import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/bill_entity.dart';
import '../../../../shared/providers/bill_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.bills_title),
      body: billsAsync.when(
        loading: () => const ShimmerList(),
        error: (_, __) => EmptyState(
          title: context.l10n.common_error_generic,
          ctaLabel: context.l10n.voice_retry,
          onCta: () => ref.invalidate(billsProvider),
        ),
        data: (bills) {
          if (bills.isEmpty) {
            return EmptyState(
              title: context.l10n.bills_empty_title,
              subtitle: context.l10n.bills_empty_sub,
              ctaLabel: context.l10n.bills_add,
              onCta: () => context.push(AppRoutes.billAdd),
            );
          }

          final overdue =
              bills.where((b) => !b.isPaid && b.isOverdue).toList();
          final upcoming =
              bills.where((b) => !b.isPaid && !b.isOverdue).toList();
          final paid = bills.where((b) => b.isPaid).toList();

          return ListView(
            padding: const EdgeInsets.only(
              bottom: AppSizes.bottomScrollPadding,
            ),
            children: [
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.bill_overdue_section,
                  color: context.appTheme.expenseColor,
                ),
                ...overdue.map(
                  (b) => _BillCard(
                    bill: b,
                    categories: categories,
                  ),
                ),
              ],
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.bill_upcoming_section,
                ),
                ...upcoming.map(
                  (b) => _BillCard(
                    bill: b,
                    categories: categories,
                  ),
                ),
              ],
              if (paid.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.bill_paid_section,
                ),
                ...paid.map(
                  (b) => _BillCard(
                    bill: b,
                    categories: categories,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.billAdd),
        child: const Icon(AppIcons.add),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.screenHPadding,
        AppSizes.md,
        AppSizes.screenHPadding,
        AppSizes.xs,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
      ),
    );
  }
}

// ── Bill card ─────────────────────────────────────────────────────────────

class _BillCard extends ConsumerWidget {
  const _BillCard({
    required this.bill,
    required this.categories,
  });

  final BillEntity bill;
  final List categories;

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}/$m/$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final cat = categories
        .where((c) => c.id == bill.categoryId)
        .firstOrNull;
    final catIcon = cat != null
        ? CategoryIconMapper.fromName(cat.iconName)
        : AppIcons.bill;
    final catColor = cat != null
        ? ColorUtils.fromHex(cat.colorHex)
        : cs.outline;

    return Slidable(
      key: ValueKey(bill.id),
      startActionPane: !bill.isPaid
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => context.push(
                    AppRoutes.billEdit
                        .replaceFirst(':id', '${bill.id}'),
                  ),
                  backgroundColor: context.appTheme.transferColor,
                  foregroundColor: cs.onPrimary,
                  icon: AppIcons.edit,
                  label: context.l10n.common_edit,
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
              ],
            )
          : null,
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: context.appTheme.expenseColor,
            foregroundColor: cs.onError,
            icon: AppIcons.delete,
            label: context.l10n.common_delete,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          ),
        ],
      ),
      child: InkWell(
        onTap: !bill.isPaid
            ? () => context.push(
                  AppRoutes.billEdit
                      .replaceFirst(':id', '${bill.id}'),
                )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              // Category icon badge
              Container(
                width: AppSizes.iconContainerLg,
                height: AppSizes.iconContainerLg,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: Icon(catIcon, size: AppSizes.iconMd, color: catColor),
              ),
              const SizedBox(width: AppSizes.md),
              // Name + due date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.name,
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Row(
                      children: [
                        Icon(
                          AppIcons.calendar,
                          size: AppSizes.iconXxs,
                          color: bill.isOverdue
                              ? context.appTheme.expenseColor
                              : cs.outline,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          '${context.l10n.bills_due}: ${_formatDate(bill.dueDate)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: bill.isOverdue
                                    ? context.appTheme.expenseColor
                                    : cs.outline,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              // Amount + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    MoneyFormatter.formatAmount(bill.amount),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  if (bill.isPaid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.appTheme.incomeColor.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                      ),
                      child: Text(
                        context.l10n.bills_paid,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: context.appTheme.incomeColor,
                                ),
                      ),
                    )
                  else
                    SizedBox(
                      height: AppSizes.iconContainerXs,
                      child: TextButton(
                        onPressed: () => _markPaid(context, ref),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          context.l10n.bills_mark_paid,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: cs.primary),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markPaid(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.bills_mark_paid),
        content: Text(context.l10n.bill_mark_paid_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // H2 fix: single atomic operation for mark-paid
    final billRepo = ref.read(billRepositoryProvider);
    await billRepo.markPaidAtomic(
      billId: bill.id,
      walletId: bill.walletId,
      categoryId: bill.categoryId,
      amount: bill.amount,
      title: bill.name,
    );

    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.bill_paid_success)),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final hasTx = bill.isPaid && bill.linkedTransactionId != null;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.bill_delete_title),
        content: Text(
          hasTx
              ? '${context.l10n.bill_delete_confirm}\n\n${context.l10n.bill_delete_linked_tx_warning}'
              : context.l10n.bill_delete_confirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.common_cancel),
          ),
          // H3 fix: if paid bill has linked tx, also delete the transaction
          TextButton(
            onPressed: () async {
              if (hasTx) {
                await ref
                    .read(transactionRepositoryProvider)
                    .delete(bill.linkedTransactionId!);
              }
              await ref.read(billRepositoryProvider).delete(bill.id);
              HapticFeedback.mediumImpact();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(
              context.l10n.common_delete,
              style: context.textStyles.bodyMedium?.copyWith(color: context.appTheme.expenseColor),
            ),
          ),
        ],
      ),
    );
  }
}
