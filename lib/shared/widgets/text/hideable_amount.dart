import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/money_formatter.dart';
import '../../providers/hide_balances_provider.dart';

/// Wraps a money amount — shows `••••` when [hideBalancesProvider] is true,
/// the formatted amount when false.
class HideableAmount extends ConsumerWidget {
  const HideableAmount({
    super.key,
    required this.piastres,
    this.style,
    this.currency = 'EGP',
    this.compact = false,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
  });

  final int piastres;
  final TextStyle? style;
  final String currency;
  final bool compact;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden = ref.watch(hideBalancesProvider);

    return Text(
      hidden
          ? '••••'
          : compact
              ? MoneyFormatter.formatCompact(piastres, currency: currency)
              : MoneyFormatter.format(piastres, currency: currency),
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
