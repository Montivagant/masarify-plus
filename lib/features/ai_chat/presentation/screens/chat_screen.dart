import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/ai_chat_service.dart';
import '../../../../core/services/ai/chat_action.dart';
import '../../../../core/services/ai/chat_action_messages.dart';
import '../../../../core/services/ai/chat_response_parser.dart';
import '../../../../core/services/ai/openrouter_service.dart';
import '../../../../domain/entities/chat_message_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/chat_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_icon_button.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/action_card.dart';
import '../widgets/message_bubble.dart';
import '../widgets/subscription_suggest_card.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

/// Subscription suggestion data for interactive card rendering.
class _SubscriptionSuggestion {
  const _SubscriptionSuggestion({
    required this.title,
    required this.categoryName,
  });

  final String title;
  final String categoryName;
}

/// Common subscription keywords for detecting recurring patterns.
const _subscriptionKeywords = [
  'netflix', 'spotify', 'youtube', 'disney', 'hulu', 'hbo',
  'apple music', 'amazon prime', 'deezer', 'anghami', 'shahid',
  'osn', 'crunchyroll', 'gym', 'internet', 'vodafone', 'orange',
  'etisalat', 'we', 'instapay', 'adobe', 'microsoft', 'google one',
  'icloud', 'dropbox', 'notion', 'figma', 'canva', 'chatgpt',
  'openai', 'copilot', 'github', 'slack',
  // Arabic equivalents
  'نتفلكس', 'سبوتيفاي', 'يوتيوب', 'أنغامي', 'شاهد',
  'فودافون', 'أورنج', 'اتصالات', 'وي', 'جيم', 'إنترنت',
];

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;

  /// In-memory action status for the current session. On confirm or cancel,
  /// the message content is stripped of its JSON block in the DB (via
  /// [ChatMessageDao.updateContent]), making the resolved state durable
  /// across restarts. The status enum itself is not stored in the DB.
  final Map<int, ChatActionStatus> _actionStates = {};
  final Set<int> _executingActions = {};

  /// Subscription suggestion shown as an interactive card after a confirmed
  /// transaction that matches known subscription keywords.
  _SubscriptionSuggestion? _pendingSubscriptionSuggestion;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_isSending) return; // concurrency guard — keyboard onSubmitted bypass
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() => _isSending = true);

    final repo = ref.read(chatMessageRepositoryProvider);
    final aiService = ref.read(aiChatServiceProvider);
    final financialCtx = ref.read(financialContextProvider);

    // Cache l10n strings before async gap.
    final l10n = context.l10n;
    final errorRateLimit = l10n.chat_error_rate_limit;
    final errorUnauthorized = l10n.chat_error_unauthorized;
    final errorTimeout = l10n.chat_error_timeout;
    final errorGeneric = l10n.chat_error_generic;

    // Insert user message.
    final userTokens = AiChatService.estimateTokens(text);
    await repo.insert(
      role: 'user',
      content: text,
      tokenCount: userTokens,
    );

    try {
      // Read current messages for context window (fresh from DB, not stale provider cache).
      final messages = await repo.watchAll().first;

      final response = await aiService.sendMessage(
        allMessages: messages,
        financialContext: financialCtx,
      );

      final content = response.content.trim();
      await repo.insert(
        role: 'assistant',
        content: content.isNotEmpty ? content : errorGeneric,
        tokenCount: content.isNotEmpty ? response.completionTokens : 0,
      );
    } on OpenRouterException catch (e) {
      final errorText = e.isRateLimit
          ? errorRateLimit
          : e.isUnauthorized
              ? errorUnauthorized
              : errorGeneric;
      await repo.insert(
        role: 'assistant',
        content: errorText,
        tokenCount: 0,
      );
    } on TimeoutException {
      await repo.insert(
        role: 'assistant',
        content: errorTimeout,
        tokenCount: 0,
      );
    } catch (e, st) {
      dev.log(
        'Chat send failed: $e',
        name: 'ChatScreen',
        error: e,
        stackTrace: st,
      );
      await repo.insert(
        role: 'assistant',
        content:
            kDebugMode ? '$errorGeneric\n(${e.runtimeType})' : errorGeneric,
        tokenCount: 0,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.chat_clear),
        content: Text(ctx.l10n.chat_clear_confirm),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(ctx.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(ctx.l10n.common_clear),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _actionStates.clear();
        _executingActions.clear();
        _pendingSubscriptionSuggestion = null;
      });
      await ref.read(chatMessageRepositoryProvider).deleteAll();
    }
  }

  Future<void> _onConfirmAction(
    int messageId,
    ChatAction action,
    String strippedText,
  ) async {
    if (_executingActions.contains(messageId)) return;
    setState(() => _executingActions.add(messageId));

    final executor = ref.read(chatActionExecutorProvider);
    final categoriesAsync = ref.read(categoriesProvider);
    final walletsAsync = ref.read(walletsProvider);
    final l10n = context.l10n;
    final errorGeneric = l10n.chat_error_generic;
    final repo = ref.read(chatMessageRepositoryProvider);

    // Guard against cold-start or error: providers may not be ready yet.
    if (categoriesAsync is! AsyncData || walletsAsync is! AsyncData) {
      if (mounted) {
        setState(() => _executingActions.remove(messageId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorGeneric),
            duration: AppDurations.snackbarShort,
          ),
        );
      }
      return;
    }
    final categories = categoriesAsync.valueOrNull ?? [];
    final wallets = walletsAsync.valueOrNull ?? [];

    // Resolve l10n messages before the async gap.
    final messages = ChatActionMessages(
      invalidAmount: l10n.chat_action_invalid_amount,
      invalidTarget: l10n.chat_action_invalid_target,
      invalidBudgetLimit: l10n.chat_action_invalid_budget_limit,
      categoryNotFound: l10n.chat_action_category_not_found,
      noActiveWallet: l10n.chat_action_no_active_wallet,
      budgetExists: l10n.chat_action_budget_exists,
      walletExists: l10n.chat_action_wallet_exists,
      txNotFound: l10n.chat_action_tx_not_found,
      goalCreated: l10n.chat_action_goal_created,
      txRecorded: l10n.chat_action_tx_recorded,
      budgetCreated: l10n.chat_action_budget_created,
      recurringCreated: l10n.chat_action_recurring_created,
      walletCreated: l10n.chat_action_wallet_created,
      txDeleted: l10n.chat_action_tx_deleted,
    );

    try {
      final selectedWalletId = ref.read(selectedAccountIdProvider);
      final successMsg = await executor.execute(
        action,
        categories: categories,
        wallets: wallets,
        messages: messages,
        selectedWalletId: selectedWalletId,
      );
      // Atomic: strip JSON + insert success message in one transaction so a
      // crash between them cannot leave inconsistent state. Done before
      // mounted check so the DB write completes even if the widget unmounts.
      final newTokens = AiChatService.estimateTokens(strippedText);
      await repo.finalizeAction(
        messageId: messageId,
        strippedContent: strippedText,
        strippedTokenCount: newTokens,
        followUpContent: successMsg,
      );
      if (!mounted) return;
      setState(() {
        _actionStates[messageId] = ChatActionStatus.confirmed;
        // Check if the confirmed transaction looks like a subscription.
        if (action is CreateTransactionAction) {
          final titleLc = action.title.toLowerCase();
          final isSubscription =
              _subscriptionKeywords.any((kw) => titleLc.contains(kw));
          if (isSubscription) {
            _pendingSubscriptionSuggestion = _SubscriptionSuggestion(
              title: action.title,
              categoryName: action.categoryName,
            );
          }
        }
      });
    } catch (e) {
      final errorMsg = e is ArgumentError ? e.message.toString() : errorGeneric;
      await repo.insert(
        role: 'assistant',
        content: errorMsg,
        tokenCount: 0,
      );
      if (!mounted) return;
      setState(() => _actionStates[messageId] = ChatActionStatus.failed);
    } finally {
      if (mounted) setState(() => _executingActions.remove(messageId));
    }
  }

  Future<void> _onCancelAction(int messageId, String strippedText) async {
    setState(() => _actionStates[messageId] = ChatActionStatus.cancelled);
    // Strip JSON so the action card doesn't reappear after navigation.
    try {
      final newTokens = AiChatService.estimateTokens(strippedText);
      await ref.read(chatMessageRepositoryProvider).updateContent(
            messageId,
            strippedText,
            tokenCount: newTokens,
          );
    } catch (e, st) {
      dev.log(
        'Cancel strip failed: $e',
        name: 'ChatScreen',
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.chat_title,
        actions: [
          AppIconButton(
            icon: AppIcons.delete,
            onPressed: _clearChat,
            tooltip: context.l10n.chat_clear,
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner.
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.sm,
              ),
              color: context.appTheme.expenseColor
                  .withValues(alpha: AppSizes.opacityLight),
              child: Text(
                context.l10n.chat_offline,
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.appTheme.expenseColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Messages list.
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Text(context.l10n.chat_error_generic),
              ),
              data: (messages) {
                final hasSuggestion = _pendingSubscriptionSuggestion != null;
                final itemCount = messages.length +
                    (_isSending ? 1 : 0) +
                    (hasSuggestion ? 1 : 0);
                if (itemCount == 0) {
                  return Center(
                    child: Text(
                      context.l10n.chat_input_hint,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurface.withValues(
                          alpha: AppSizes.opacityLight4,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                    vertical: AppSizes.sm,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    // Slot 0 (bottom): typing indicator when sending.
                    if (_isSending && index == 0) {
                      return const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: AppSizes.sm,
                          ),
                          child: TypingIndicator(),
                        ),
                      );
                    }
                    // Subscription suggestion card sits just above
                    // the typing indicator (or at slot 0 when idle).
                    final suggestionSlot = _isSending ? 1 : 0;
                    if (hasSuggestion && index == suggestionSlot) {
                      return SubscriptionSuggestCard(
                        title: _pendingSubscriptionSuggestion!.title,
                        categoryName:
                            _pendingSubscriptionSuggestion!.categoryName,
                      );
                    }
                    // Offset past virtual slots to get real message.
                    final virtualSlots =
                        (_isSending ? 1 : 0) + (hasSuggestion ? 1 : 0);
                    final msgIndex =
                        messages.length - 1 - (index - virtualSlots);
                    final msg = messages[msgIndex];

                    // For assistant messages, parse for action JSON.
                    if (msg.role == 'assistant') {
                      final parsed = ChatResponseParser.parse(msg.content);
                      if (parsed.action != null) {
                        final status =
                            _actionStates[msg.id] ?? ChatActionStatus.pending;
                        final textMsg = ChatMessageEntity(
                          id: msg.id,
                          role: msg.role,
                          content: parsed.textContent,
                          tokenCount: msg.tokenCount,
                          createdAt: msg.createdAt,
                        );
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (parsed.textContent.isNotEmpty)
                              MessageBubble(message: textMsg),
                            ActionCard(
                              action: parsed.action!,
                              status: status,
                              onConfirm: status == ChatActionStatus.pending ||
                                      status == ChatActionStatus.failed
                                  ? () => _onConfirmAction(
                                        msg.id,
                                        parsed.action!,
                                        parsed.textContent,
                                      )
                                  : null,
                              onCancel: status == ChatActionStatus.pending
                                  ? () => _onCancelAction(
                                        msg.id,
                                        parsed.textContent,
                                      )
                                  : null,
                            ),
                          ],
                        );
                      }
                    }
                    // After JSON stripping, content may be empty — skip.
                    if (msg.content.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return MessageBubble(message: msg);
                  },
                );
              },
            ),
          ),

          // Input bar.
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: context.colors.outlineVariant
                      .withValues(alpha: AppSizes.opacityLight4),
                ),
              ),
              color: context.colors.surface,
            ),
            padding: EdgeInsetsDirectional.only(
              start: AppSizes.screenHPadding,
              end: AppSizes.xs,
              top: AppSizes.sm,
              bottom: AppSizes.sm + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: isOnline && !_isSending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: context.l10n.chat_input_hint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.borderRadiusLg,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: context.colors.onSurface.withValues(
                        alpha: AppSizes.opacityXLight2,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                    ),
                    style: context.textStyles.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                AppIconButton(
                  icon: AppIcons.send,
                  onPressed: isOnline && !_isSending ? _send : null,
                  tooltip: context.l10n.chat_input_hint,
                  color: context.colors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
