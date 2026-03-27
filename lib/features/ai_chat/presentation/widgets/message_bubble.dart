import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../domain/entities/chat_message_entity.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessageEntity message;

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Align(
      alignment: _isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.screenWidth * AppSizes.chatBubbleMaxWidthFraction,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: _isUser
                ? (context.isRtl ? TextDirection.ltr : TextDirection.rtl)
                : (context.isRtl ? TextDirection.rtl : TextDirection.ltr),
            children: [
              if (!_isUser) ...[
                CircleAvatar(
                  radius: AppSizes.iconXs,
                  backgroundColor: cs.primaryContainer
                      .withValues(alpha: AppSizes.opacityLight4),
                  child: Icon(
                    AppIcons.ai,
                    size: AppSizes.iconXs,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
              ],
              Flexible(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm + AppSizes.xs,
                  ),
                  tintColor: _isUser
                      ? cs.primary.withValues(alpha: AppSizes.opacityLight)
                      : cs.surfaceContainerHighest
                          .withValues(alpha: AppSizes.opacityLight4),
                  child: _isUser
                      ? Text(
                          message.content,
                          style: context.textStyles.bodyMedium,
                        )
                      : MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: context.textStyles.bodyMedium,
                            h1: context.textStyles.titleMedium,
                            h2: context.textStyles.titleSmall,
                            h3: context.textStyles.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            a: context.textStyles.bodyMedium?.copyWith(
                              color: cs.primary,
                            ),
                            strong: context.textStyles.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            listBullet: context.textStyles.bodyMedium,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
