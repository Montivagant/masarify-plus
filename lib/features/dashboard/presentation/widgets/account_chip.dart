import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';

/// A single account mini-card for the balance header.
///
/// Shows an account name, wallet icon, and mini-balance in a vertical card
/// layout with color-coded visual states for selection and wallet identity.
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

  /// Card width for "All Accounts" chip (slightly wider).
  static const double _allAccountsWidth = 120;

  /// Card width for individual account chips.
  static const double _individualWidth = 110;

  /// Card height for all chips.
  static const double _cardHeight = 64;

  /// Width of the colored left edge strip on selected individual cards.
  static const double _edgeStripWidth = 4;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final walletColor =
        colorHex != null ? ColorUtils.fromHex(colorHex!) : cs.primary;

    final miniBalance = hidden ? '---' : MoneyFormatter.formatCompact(balance);
    final icon = isAllAccounts
        ? AppIcons.wallet
        : AppIcons.walletType(walletType ?? 'bank');

    final double cardWidth =
        isAllAccounts ? _allAccountsWidth : _individualWidth;

    // Resolve visual state
    final _ChipStyle style = _resolveStyle(cs, walletColor);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
            child: Container(
              width: cardWidth,
              height: _cardHeight,
              decoration: BoxDecoration(
                gradient: style.gradient,
                color: style.gradient == null ? style.backgroundColor : null,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
                border: style.border,
              ),
              child: _buildContent(context, style, icon, miniBalance),
            ),
          ),
        ),
      ),
    );
  }

  /// Build card content — individual selected cards get a left edge strip.
  Widget _buildContent(
    BuildContext context,
    _ChipStyle style,
    IconData icon,
    String miniBalance,
  ) {
    if (!isAllAccounts && isSelected) {
      // Individual selected: left colored strip + content
      return Row(
        children: [
          Container(
            width: _edgeStripWidth,
            decoration: BoxDecoration(
              color: style.stripColor,
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(AppSizes.borderRadiusMdSm),
                bottomStart: Radius.circular(AppSizes.borderRadiusMdSm),
              ),
            ),
          ),
          Expanded(
            child: _CardBody(
              icon: icon,
              label: label,
              miniBalance: miniBalance,
              style: style,
            ),
          ),
        ],
      );
    }

    return _CardBody(
      icon: icon,
      label: label,
      miniBalance: miniBalance,
      style: style,
    );
  }

  /// Determine colors, gradient, and border based on current visual state.
  _ChipStyle _resolveStyle(ColorScheme cs, Color walletColor) {
    if (isAllAccounts && isSelected) {
      // "All Accounts" selected: mint gradient, white text
      return _ChipStyle(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: AppSizes.opacityStrong),
          ],
        ),
        backgroundColor: cs.primary,
        textColor: cs.onPrimary,
        iconColor: cs.onPrimary,
        balanceColor: cs.onPrimary,
      );
    }

    if (isAllAccounts && !isSelected) {
      // "All Accounts" unselected: surface + outline
      return _ChipStyle(
        backgroundColor: cs.surface,
        textColor: cs.onSurface,
        iconColor: cs.outline,
        balanceColor: cs.onSurface,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: AppSizes.opacityLight4),
        ),
      );
    }

    if (isSelected) {
      // Individual selected: tinted bg + wallet-color strip
      return _ChipStyle(
        backgroundColor: walletColor.withValues(alpha: AppSizes.opacityLight2),
        textColor: cs.onSurface,
        iconColor: walletColor,
        balanceColor: cs.onSurface,
        stripColor: walletColor,
      );
    }

    // Individual unselected: subtle tonal surface
    return _ChipStyle(
      backgroundColor: cs.surfaceContainerLow,
      textColor: cs.onSurface.withValues(alpha: AppSizes.opacityStrong),
      iconColor: cs.onSurfaceVariant.withValues(alpha: AppSizes.opacityMedium),
      balanceColor: cs.onSurface.withValues(alpha: AppSizes.opacityStrong),
    );
  }
}

/// Internal card body with vertical layout: top row (icon + name), bottom balance.
class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.icon,
    required this.label,
    required this.miniBalance,
    required this.style,
  });

  final IconData icon;
  final String label;
  final String miniBalance;
  final _ChipStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top row: icon + account name
          Row(
            children: [
              Icon(icon, size: AppSizes.iconXs, color: style.iconColor),
              const SizedBox(width: AppSizes.xs),
              Expanded(
                child: Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: style.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          // Bottom: balance
          Text(
            miniBalance,
            style: context.textStyles.labelSmall?.copyWith(
              color: style.balanceColor,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Encapsulates all visual properties for a chip state.
class _ChipStyle {
  const _ChipStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.balanceColor,
    this.gradient,
    this.border,
    this.stripColor,
  });

  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Color balanceColor;
  final LinearGradient? gradient;
  final BoxBorder? border;
  final Color? stripColor;
}
