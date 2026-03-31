import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';

/// A single account chip for the balance header.
///
/// Shows an account name, wallet icon, and mini-balance. The chip is enriched
/// with the wallet's color accent and type icon for instant visual identity.
class AccountChip extends StatelessWidget {
  const AccountChip({
    super.key,
    required this.label,
    required this.balance,
    required this.isSelected,
    required this.onTap,
    this.isAllAccounts = false,
    this.hidden = false,
    this.walletType,
    this.colorHex,
  });

  final String label;
  final int balance;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAllAccounts;
  final bool hidden;

  /// Wallet type string (e.g. 'bank', 'mobile_wallet') — resolves to icon.
  final String? walletType;

  /// Wallet's personal color hex — used as subtle accent.
  final String? colorHex;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final walletColor =
        colorHex != null ? ColorUtils.fromHex(colorHex!) : cs.primary;

    // Determine chip visual state
    final Color backgroundColor;
    final Color textColor;
    final Color iconColor;
    final BoxBorder? border;

    if (isAllAccounts && isSelected) {
      // "All" selected: hero primary fill
      backgroundColor = cs.primary;
      textColor = cs.onPrimary;
      iconColor = cs.onPrimary;
      border = null;
    } else if (isSelected) {
      // Individual selected: glass card with wallet color tint
      backgroundColor = Color.alphaBlend(
        walletColor.withValues(alpha: AppSizes.opacityXLight),
        theme.glassCardSurface,
      );
      textColor = cs.onSurface;
      iconColor = walletColor;
      border = Border.all(
        color: walletColor.withValues(alpha: AppSizes.opacityQuarter),
      );
    } else {
      // Unselected: subtle outline
      backgroundColor = cs.surface;
      textColor = cs.onSurface.withValues(alpha: AppSizes.opacityStrong);
      iconColor = cs.onSurfaceVariant.withValues(alpha: AppSizes.opacityMedium);
      border = Border.all(
        color: cs.outlineVariant.withValues(alpha: AppSizes.opacityLight4),
      );
    }

    final miniBalance = hidden ? '---' : MoneyFormatter.formatCompact(balance);
    final icon = isAllAccounts
        ? AppIcons.wallet
        : AppIcons.walletType(walletType ?? 'bank');

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
              horizontal: AppSizes.sm + AppSizes.xxs,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
              border: border,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppSizes.iconXs, color: iconColor),
                const SizedBox(width: AppSizes.xs),
                Text(
                  label,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!isAllAccounts) ...[
                  const SizedBox(width: AppSizes.xs),
                  Container(
                    width: AppSizes.borderWidth,
                    height: AppSizes.iconXs,
                    color: textColor.withValues(alpha: AppSizes.opacityLight),
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Text(
                    miniBalance,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: isSelected
                          ? textColor.withValues(alpha: AppSizes.opacityStrong)
                          : textColor.withValues(
                              alpha: AppSizes.opacityMedium,
                            ),
                      fontWeight: FontWeight.w500,
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
