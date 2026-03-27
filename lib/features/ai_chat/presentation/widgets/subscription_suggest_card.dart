import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Interactive subscription suggestion card shown in AI chat
/// when a transaction is detected as potentially recurring.
class SubscriptionSuggestCard extends StatefulWidget {
  const SubscriptionSuggestCard({
    super.key,
    required this.title,
    required this.categoryName,
  });

  final String title;
  final String categoryName;

  @override
  State<SubscriptionSuggestCard> createState() =>
      _SubscriptionSuggestCardState();
}

class _SubscriptionSuggestCardState extends State<SubscriptionSuggestCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.screenWidth * AppSizes.chatBubbleMaxWidthFraction,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start:
                AppSizes.iconXs + AppSizes.xs, // align with bubble after avatar
            bottom: AppSizes.sm,
          ),
          child: GlassCard(
            tier: GlassTier.inset,
            tintColor: context.appTheme.transferColor
                .withValues(alpha: AppSizes.opacityXLight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      AppIcons.recurring,
                      color: context.appTheme.transferColor,
                      size: AppSizes.iconMd,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        context.l10n.chat_subscription_suggest(widget.title),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _dismissed = true),
                      child: Text(context.l10n.common_dismiss),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    FilledButton(
                      onPressed: () {
                        context.push(AppRoutes.recurringAdd);
                      },
                      child: Text(context.l10n.common_save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
