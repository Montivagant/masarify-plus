import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/transaction_entity.dart';
import '../extensions/build_context_extensions.dart';
import '../extensions/datetime_extensions.dart';

/// Returns a localized date label: "Today", "Yesterday", or formatted date.
/// Uses [DateTimeX.isToday] and [DateTimeX.isYesterday] extensions.
String transactionDateLabel(BuildContext context, DateTime date) {
  if (date.isToday) return context.l10n.date_today;
  if (date.isYesterday) return context.l10n.date_yesterday;
  return DateFormat.yMd(context.languageCode).format(date.startOfDay);
}

/// Groups transactions by date label, preserving insertion order.
Map<String, List<TransactionEntity>> groupTransactionsByDate(
  BuildContext context,
  List<TransactionEntity> transactions,
) {
  final map = <String, List<TransactionEntity>>{};
  for (final tx in transactions) {
    final label = transactionDateLabel(context, tx.transactionDate);
    (map[label] ??= []).add(tx);
  }
  return map;
}
