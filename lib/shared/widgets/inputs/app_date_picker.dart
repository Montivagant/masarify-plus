import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// Locale-aware date picker presented as a tappable chip.
/// Tapping opens Flutter's [showDatePicker] and emits the selected date.
class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.label,
    this.firstDate,
    this.lastDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String? label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) onDateChanged(picked);
  }

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMd(context.languageCode).format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? context.l10n.common_date,
      value: _formatDate(context, selectedDate),
      button: true,
      child: InkWell(
        onTap: () => _pick(context),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.colors.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.calendar,
                size: AppSizes.iconSm,
                color: context.colors.primary,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                _formatDate(context, selectedDate),
                style: context.textStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
