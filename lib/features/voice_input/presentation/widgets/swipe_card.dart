import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Tinder-style swipeable transaction card for the voice review screen.
///
/// Drag right to approve, drag left to skip. Stamp overlays fade in
/// proportionally to drag distance. On release, the card either flies
/// off-screen or springs back depending on the drag threshold.
class SwipeCard extends StatefulWidget {
  const SwipeCard({
    super.key,
    required this.categoryIcon,
    required this.categoryColor,
    this.categoryName,
    this.walletName,
    required this.amount,
    required this.type,
    required this.title,
    required this.rawTranscript,
    required this.transactionDate,
    this.matchedGoalName,
    this.isSubscriptionLike = false,
    this.subscriptionAdded = false,
    this.unmatchedHint,
    this.unmatchedToHint,
    required this.onApprove,
    required this.onSkip,
    this.onTypeTap,
    this.onCategoryTap,
    this.onWalletTap,
    this.onAmountTap,
    this.onTitleTap,
    this.onSubscriptionTap,
    this.onCreateWallet,
    this.onCreateToWallet,
  });

  final IconData categoryIcon;
  final Color categoryColor;
  final String? categoryName;
  final String? walletName;
  final int amount;
  final String type;
  final String title;
  final String rawTranscript;
  final DateTime transactionDate;
  final String? matchedGoalName;
  final bool isSubscriptionLike;
  final bool subscriptionAdded;
  final String? unmatchedHint;
  final String? unmatchedToHint;
  final VoidCallback onApprove;
  final VoidCallback onSkip;
  final VoidCallback? onTypeTap;
  final VoidCallback? onCategoryTap;
  final VoidCallback? onWalletTap;
  final VoidCallback? onAmountTap;
  final VoidCallback? onTitleTap;
  final VoidCallback? onSubscriptionTap;
  final VoidCallback? onCreateWallet;
  final VoidCallback? onCreateToWallet;

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0;
  late AnimationController _animController;
  Animation<double>? _animation;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Drag handling ──────────────────────────────────────────────────────

  void _onDragUpdate(DragUpdateDetails details) {
    if (_exiting) return;
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_exiting) return;
    final screenWidth = context.screenWidth;
    final threshold = screenWidth * AppSizes.swipeDragThreshold;

    if (_dragOffset.abs() > threshold) {
      _animateExit(screenWidth);
    } else {
      _animateReturn();
    }
  }

  void _animateExit(double screenWidth) {
    _exiting = true;
    final isRight = _dragOffset > 0;
    final target = isRight ? screenWidth * 1.5 : -screenWidth * 1.5;

    _animController.duration = AppDurations.swipeOut;
    _animation = Tween<double>(begin: _dragOffset, end: target).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    )..addListener(() {
        setState(() => _dragOffset = _animation!.value);
      });

    _animController.forward(from: 0).then((_) {
      if (isRight) {
        widget.onApprove();
      } else {
        widget.onSkip();
      }
    });
  }

  void _animateReturn() {
    _animController.duration = AppDurations.swipeReturn;
    _animation = Tween<double>(begin: _dragOffset, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _dragOffset = _animation!.value);
      });

    _animController.forward(from: 0);
  }

  // ── Type helpers ───────────────────────────────────────────────────────

  Color _typeColor(BuildContext context) {
    final theme = context.appTheme;
    return switch (widget.type) {
      'income' => theme.incomeColor,
      'expense' => theme.expenseColor,
      'transfer' || 'cash_withdrawal' || 'cash_deposit' => theme.transferColor,
      _ => theme.expenseColor,
    };
  }

  String _typeLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (widget.type) {
      'expense' => l10n.transaction_type_expense,
      'income' => l10n.transaction_type_income,
      'transfer' => l10n.transaction_type_transfer,
      'cash_withdrawal' => l10n.transaction_type_cash_withdrawal_short,
      'cash_deposit' => l10n.transaction_type_cash_deposit_short,
      _ => l10n.transaction_type_expense,
    };
  }

  String _formatDate(BuildContext context) {
    final now = DateTime.now();
    final date = widget.transactionDate;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return context.l10n.date_today;
    }
    return DateFormat.yMMMd(context.languageCode).format(date);
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = context.screenWidth;
    final rotation = _dragOffset / screenWidth * AppSizes.swipeRotationAngle;
    final stampOpacity =
        (_dragOffset.abs() / (screenWidth * AppSizes.opacityMedium))
            .clamp(0.0, AppSizes.swipeStampOpacity);
    final colors = context.colors;
    final typeColor = _typeColor(context);

    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragOffset, 0),
        child: Transform.rotate(
          angle: rotation,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.swipeCardMaxWidth,
            ),
            child: Stack(
              children: [
                // ── Card body ────────────────────────────────────────
                GlassCard(
                  tier: GlassTier.background,
                  tintColor:
                      typeColor.withValues(alpha: AppSizes.opacitySubtle),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeBadge(context, typeColor),
                      const SizedBox(height: AppSizes.md),
                      _buildMainSection(context, typeColor, colors),
                      const SizedBox(height: AppSizes.sm),
                      _buildRawTranscript(context, colors),
                      const SizedBox(height: AppSizes.sm),
                      _buildDivider(colors),
                      const SizedBox(height: AppSizes.sm),
                      _buildMetadataRow(context, colors),
                      ..._buildBanners(context, colors),
                    ],
                  ),
                ),

                // ── Approve stamp ────────────────────────────────────
                if (_dragOffset > 0)
                  _buildStamp(
                    context,
                    opacity: stampOpacity,
                    label: context.l10n.sms_review_approve,
                    icon: AppIcons.check,
                    color: context.appTheme.incomeColor,
                    rotationAngle: -AppSizes.swipeRotationAngle,
                  ),

                // ── Skip stamp ───────────────────────────────────────
                if (_dragOffset < 0)
                  _buildStamp(
                    context,
                    opacity: stampOpacity,
                    label: context.l10n.sms_review_skip,
                    icon: AppIcons.close,
                    color: context.appTheme.expenseColor,
                    rotationAngle: AppSizes.swipeRotationAngle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────

  Widget _buildTypeBadge(BuildContext context, Color typeColor) {
    return GestureDetector(
      onTap: widget.onTypeTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: AppSizes.opacityLight),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppSizes.dotSm,
              height: AppSizes.dotSm,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              _typeLabel(context),
              style: context.textStyles.labelSmall?.copyWith(
                color: typeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainSection(
    BuildContext context,
    Color typeColor,
    ColorScheme colors,
  ) {
    return GestureDetector(
      onTap: widget.onCategoryTap,
      child: Row(
        children: [
          Container(
            width: AppSizes.iconContainerSm,
            height: AppSizes.iconContainerSm,
            decoration: BoxDecoration(
              color:
                  widget.categoryColor.withValues(alpha: AppSizes.opacityLight),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.categoryIcon,
              size: AppSizes.iconMd,
              color: widget.categoryColor,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.onTitleTap,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xxs),
                GestureDetector(
                  onTap: widget.onAmountTap,
                  child: Text(
                    MoneyFormatter.format(widget.amount),
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawTranscript(BuildContext context, ColorScheme colors) {
    return Text(
      widget.rawTranscript,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: context.textStyles.bodySmall?.copyWith(
        color: colors.onSurfaceVariant,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildDivider(ColorScheme colors) {
    return Container(
      height: AppSizes.glassBorderWidthSubtle,
      color: colors.outlineVariant.withValues(alpha: AppSizes.opacityLight),
    );
  }

  Widget _buildMetadataRow(BuildContext context, ColorScheme colors) {
    final metaStyle = context.textStyles.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onWalletTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.wallet,
                size: AppSizes.iconXs,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(widget.walletName ?? '—', style: metaStyle),
            ],
          ),
        ),
        const Spacer(),
        Icon(
          AppIcons.calendar,
          size: AppSizes.iconXs,
          color: colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSizes.xs),
        Text(_formatDate(context), style: metaStyle),
      ],
    );
  }

  List<Widget> _buildBanners(BuildContext context, ColorScheme colors) {
    final banners = <Widget>[];

    // ── Goal banner ──────────────────────────────────────────────────
    if (widget.matchedGoalName != null) {
      banners.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm),
          child: Row(
            children: [
              Icon(
                AppIcons.goals,
                size: AppSizes.iconXs,
                color: colors.tertiary,
              ),
              const SizedBox(width: AppSizes.xs),
              Flexible(
                child: Text(
                  widget.matchedGoalName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: colors.tertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Subscription banner ──────────────────────────────────────────
    if (widget.isSubscriptionLike && !widget.subscriptionAdded) {
      banners.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm),
          child: GestureDetector(
            onTap: widget.onSubscriptionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: AppSizes.xs,
              ),
              decoration: BoxDecoration(
                color: colors.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.recurring,
                    size: AppSizes.iconXs,
                    color: colors.onTertiaryContainer,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  Flexible(
                    child: Text(
                      context.l10n.voice_confirm_subscription_suggest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: colors.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Unmatched wallet banner ──────────────────────────────────────
    if (widget.unmatchedHint != null) {
      banners.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm),
          child: GestureDetector(
            onTap: widget.onCreateWallet,
            child: Row(
              children: [
                Icon(
                  AppIcons.add,
                  size: AppSizes.iconXs,
                  color: colors.primary,
                ),
                const SizedBox(width: AppSizes.xs),
                Flexible(
                  child: Text(
                    context.l10n
                        .voice_create_wallet_instead(widget.unmatchedHint!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Unmatched destination wallet banner (transfers) ─────────────
    if (widget.unmatchedToHint != null) {
      banners.add(
        Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm),
          child: GestureDetector(
            onTap: widget.onCreateToWallet,
            child: Row(
              children: [
                Icon(
                  AppIcons.add,
                  size: AppSizes.iconXs,
                  color: colors.tertiary,
                ),
                const SizedBox(width: AppSizes.xs),
                Flexible(
                  child: Text(
                    context.l10n
                        .voice_create_wallet_instead(widget.unmatchedToHint!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: colors.tertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return banners;
  }

  // ── Stamp overlay ──────────────────────────────────────────────────────

  Widget _buildStamp(
    BuildContext context, {
    required double opacity,
    required String label,
    required IconData icon,
    required Color color,
    required double rotationAngle,
  }) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Center(
            child: Transform.rotate(
              angle: rotationAngle,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.lg,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: color,
                    width: AppSizes.borderWidthSelected,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: AppSizes.iconMd),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      label.toUpperCase(),
                      style: context.textStyles.titleMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
