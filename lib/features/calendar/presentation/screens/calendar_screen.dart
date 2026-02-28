import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../shared/providers/calendar_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  /// H12 fix: map user pref int to table_calendar enum.
  static StartingDayOfWeek _mapStartingDay(int day) => switch (day) {
        1 => StartingDayOfWeek.monday,
        7 => StartingDayOfWeek.sunday,
        _ => StartingDayOfWeek.saturday,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final year = _focusedDay.year;
    final month = _focusedDay.month;

    final txAsync = ref.watch(transactionsByMonthProvider((year, month)));

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.calendar_title),
      body: txAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(context.l10n.common_error_generic),
        ),
        data: (transactions) {
          final daySummary = ref.read(
            calendarDaySummaryProvider(
              (year, month, transactions),
            ),
          );

          return Column(
            children: [
              // ── Calendar ──────────────────────────────────────────
              TableCalendar<TransactionEntity>(
                firstDay: DateTime(2020),
                lastDay: now.add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    _selectedDay != null && isSameDay(_selectedDay, day),
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  setState(() {
                    _focusedDay = focused;
                    _selectedDay = null;
                  });
                },
                availableCalendarFormats: const {
                  CalendarFormat.month: '',
                },
                // H12 fix: read user preference instead of hardcoding
                startingDayOfWeek: _mapStartingDay(
                  ref.watch(firstDayOfWeekProvider).valueOrNull ?? 6,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle:
                      Theme.of(context).textTheme.titleMedium ??
                          const TextStyle(),
                  leftChevronIcon: const Icon(
                    AppIcons.chevronLeft,
                    size: AppSizes.iconSm,
                  ),
                  rightChevronIcon: const Icon(
                    AppIcons.chevronRight,
                    size: AppSizes.iconSm,
                  ),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.primary,
                      width: 2,
                    ),
                  ),
                  todayTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ) ?? const TextStyle(),
                  selectedDecoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (ctx, day, events) {
                    final key = DateTime(day.year, day.month, day.day);
                    final summary = daySummary[key];
                    if (summary == null) return null;

                    return Positioned(
                      bottom: 4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (summary.hasIncome)
                            Container(
                              width: AppSizes.dotSm,
                              height: AppSizes.dotSm,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1,
                              ),
                              decoration: BoxDecoration(
                                color: ctx.appTheme.incomeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          if (summary.hasExpense)
                            Container(
                              width: AppSizes.dotSm,
                              height: AppSizes.dotSm,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1,
                              ),
                              decoration: BoxDecoration(
                                color: ctx.appTheme.expenseColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // ── Day transactions ──────────────────────────────────
              Expanded(
                child: _selectedDay != null
                    ? _DayTransactionList(
                        transactions: transactions
                            .where(
                              (tx) => isSameDay(
                                tx.transactionDate,
                                _selectedDay!,
                              ),
                            )
                            .toList(),
                      )
                    : Center(
                        child: Text(
                          context.l10n.calendar_empty_title,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: cs.outline),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Day transaction list ──────────────────────────────────────────────────

class _DayTransactionList extends ConsumerWidget {
  const _DayTransactionList({required this.transactions});

  final List<TransactionEntity> transactions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return Center(
        child: Text(
          context.l10n.calendar_no_transactions_day,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      );
    }

    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    // Summary row
    int totalIncome = 0;
    int totalExpense = 0;
    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
      children: [
        // Day summary
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              if (totalIncome > 0) ...[
                Icon(
                  AppIcons.income,
                  size: AppSizes.iconXs,
                  color: context.appTheme.incomeColor,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  '+${MoneyFormatter.formatAmount(totalIncome)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.incomeColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(width: AppSizes.md),
              ],
              if (totalExpense > 0) ...[
                Icon(
                  AppIcons.expense,
                  size: AppSizes.iconXs,
                  color: context.appTheme.expenseColor,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  '\u2212${MoneyFormatter.formatAmount(totalExpense)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.appTheme.expenseColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        // Transaction rows
        ...transactions.map((tx) {
          final cat =
              categories.where((c) => c.id == tx.categoryId).firstOrNull;
          final catIcon = cat != null
              ? CategoryIconMapper.fromName(cat.iconName)
              : AppIcons.category;
          final catColor = cat != null
              ? ColorUtils.fromHex(cat.colorHex)
              : Theme.of(context).colorScheme.outline;
          final typeColor = tx.type == 'income'
              ? context.appTheme.incomeColor
              : context.appTheme.expenseColor;
          final prefix = tx.type == 'income' ? '+' : '\u2212';

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
              vertical: AppSizes.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSizes.iconContainerMd,
                  height: AppSizes.iconContainerMd,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: AppSizes.opacityLight),
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                  child: Icon(
                    catIcon,
                    size: AppSizes.iconSm,
                    color: ColorUtils.contrastColor(catColor),
                  ),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.title,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (cat != null)
                        Text(
                          cat.displayName(context.languageCode),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.outline,
                              ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '$prefix ${MoneyFormatter.formatAmount(tx.amount)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
