import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';

/// A single account chip for the balance header.
///
/// Shows an account name and mini-balance. Visual style changes based on
/// whether this is the "All Accounts" chip and whether it's selected.
class AccountChip extends StatelessWidget {
  const AccountChip({
    super.key,
    required this.label,
    required this.balance,
    required this.isSelected,
    required this.onTap,
    this.isAllAccounts = false,
    this.hidden = false,
  });

  final String label;
  final int balance;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAllAccounts;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    // Determine chip colors based on selection state and type.
    final Color backgroundColor;
    final Color textColor;
    final Color? borderColor;

    if (isAllAccounts && isSelected) {
      // "All" chip when active: filled primary — visually distinct (D-03).
      backgroundColor = cs.primary;
      textColor = cs.onPrimary;
      borderColor = null;
    } else if (isSelected) {
      // Individual account selected: secondary container.
      backgroundColor = cs.secondaryContainer;
      textColor = cs.onSecondaryContainer;
      borderColor = null;
    } else {
      // Unselected: outlined.
      backgroundColor = cs.surface;
      textColor = cs.onSurface;
      borderColor = cs.outline.withValues(alpha: AppSizes.opacityLight4);
    }

    final miniBalance = hidden ? '---' : MoneyFormatter.formatCompact(balance);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
          child: Container(
            constraints: const BoxConstraints(minHeight: AppSizes.minTapTarget),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: borderColor != null
                ? BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusFull),
                    border: Border.all(color: borderColor),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isAllAccounts) ...[
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    miniBalance,
                    style: context.textStyles.labelSmall?.copyWith(
                      color:
                          textColor.withValues(alpha: AppSizes.opacityStrong),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
