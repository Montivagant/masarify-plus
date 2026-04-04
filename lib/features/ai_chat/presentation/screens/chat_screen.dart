import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
import '../../../../shared/providers/database_provider.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_icon_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/guards/pro_feature_guard.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/action_card.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.recapMode = false});

  /// When true, auto-sends a recap priming message on first load.
  final bool recapMode;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  bool _isSending = false;
  bool _showDisclaimer = false;

  /// In-memory action status for the current session. Keyed by compound
  /// string '${messageId}_$actionIndex' to support multiple actions per message.
  /// On confirm or cancel, the message content is stripped of its JSON blocks
  /// in the DB, making the resolved state durable across restarts.
  final Map<String, ChatActionStatus> _actionStates = {};
  final Set<String> _executingActions = {};

  @override
  void initState() {
    super.initState();
    _loadDisclaimerState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadDisclaimerState() async {
    final prefs = await ref.read(preferencesFutureProvider.future);
    if (!mounted) return;
    if (!prefs.hasSeenAiDisclaimer) {
      setState(() => _showDisclaimer = true);
    }
  }

  Future<void> _dismissDisclaimer() async {
    setState(() => _showDisclaimer = false);
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.markAiDisclaimerSeen();
  }

  Future<void> _send() async {
    if (_isSending) return; // concurrency guard — keyboard onSubmitted bypass
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() => _isSending = true);

    final repo = ref.read(chatMessageRepositoryProvider);
    final aiService = ref.read(aiChatServiceProvider);
    // Force fresh DateTime.now() — the cached provider goes stale across
    // midnight or long sessions, making the AI unaware of the current date.
    ref.invalidate(financialContextProvider);
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
    if (confirmed == true && mounted) {
      setState(() {
        _actionStates.clear();
        _executingActions.clear();
      });
      await ref.read(chatMessageRepositoryProvider).deleteAll();
    }
  }

  /// Stable key for action status tracking based on action content.
  /// Uses action's JSON hashCode so keys don't shift when sibling actions
  /// are stripped from the message.
  String _actionKey(int messageId, int actionIndex, ChatAction action) =>
      '${messageId}_${actionIndex}_${action.toJson().toString().hashCode}';

  Widget _buildActionCard(
    int messageId,
    int actionIndex,
    ChatAction action,
    String rawContent,
  ) {
    final key = _actionKey(messageId, actionIndex, action);
    final status = _actionStates[key] ?? ChatActionStatus.pending;
    return ActionCard(
      action: action,
      status: status,
      onConfirm: status == ChatActionStatus.pending ||
              status == ChatActionStatus.failed
          ? () => _onConfirmAction(messageId, actionIndex, action, rawContent)
          : null,
      onCancel: status == ChatActionStatus.pending
          ? () => _onCancelAction(messageId, actionIndex, action, rawContent)
          : null,
    );
  }

  Future<void> _onConfirmAction(
    int messageId,
    int actionIndex,
    ChatAction action,
    String rawContent,
  ) async {
    final key = _actionKey(messageId, actionIndex, action);
    if (_executingActions.contains(key)) return;
    setState(() => _executingActions.add(key));

    final executor = ref.read(chatActionExecutorProvider);
    final categoriesAsync = ref.read(categoriesProvider);
    final walletsAsync = ref.read(walletsProvider);
    final l10n = context.l10n;
    final errorGeneric = l10n.chat_error_generic;
    final repo = ref.read(chatMessageRepositoryProvider);

    // Guard against cold-start or error: providers may not be ready yet.
    if (categoriesAsync is! AsyncData || walletsAsync is! AsyncData) {
      if (mounted) {
        setState(() => _executingActions.remove(key));
        SnackHelper.showError(context, errorGeneric);
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
      walletNotFound: l10n.chat_action_wallet_not_found,
      transferSameWallet: l10n.chat_action_transfer_same_wallet,
      txNotFound: l10n.chat_action_tx_not_found,
      goalCreated: l10n.chat_action_goal_created,
      txRecorded: l10n.chat_action_tx_recorded,
      budgetCreated: l10n.chat_action_budget_created,
      recurringCreated: l10n.chat_action_recurring_created,
      walletCreated: l10n.chat_action_wallet_created,
      transferCreated: l10n.chat_action_transfer_created,
      txDeleted: l10n.chat_action_tx_deleted,
      txUpdated: l10n.chat_action_tx_updated,
      budgetUpdated: l10n.chat_action_budget_updated,
      budgetDeleted: l10n.chat_action_budget_deleted,
      budgetNotFound: l10n.chat_action_budget_not_found,
      goalDeleted: l10n.chat_action_goal_deleted,
      goalNotFound: l10n.chat_action_goal_not_found,
      recurringDeleted: l10n.chat_action_recurring_deleted,
      recurringNotFound: l10n.chat_action_recurring_not_found,
      walletUpdated: l10n.chat_action_wallet_updated,
      goalUpdated: l10n.chat_action_goal_updated,
      recurringUpdated: l10n.chat_action_recurring_updated,
      categoryUpdated: l10n.chat_action_category_updated,
      categoryCreated: l10n.chat_action_category_created,
      walletArchived: l10n.chat_action_wallet_archived,
      categoryNotUpdatable: l10n.chat_action_category_not_updatable,
      categoryExists: l10n.chat_action_category_exists,
      walletHasReferences: l10n.chat_action_wallet_has_references,
    );

    try {
      var selectedWalletId = ref.read(selectedAccountIdProvider);
      // Validate selected wallet still exists — reset if stale (deleted/archived).
      if (selectedWalletId != null &&
          !wallets.any((w) => w.id == selectedWalletId && !w.isArchived)) {
        selectedWalletId = null;
        ref.read(selectedAccountIdProvider.notifier).state = null;
      }
      final db = ref.read(databaseProvider);

      // Wrap action execution + finalize in a single DB transaction so a crash
      // between them cannot leave inconsistent state (action executed but
      // message not finalized → duplicate execution on restart).
      final result = await db.transaction(() async {
        final r = await executor.execute(
          action,
          categories: categories,
          wallets: wallets,
          messages: messages,
          selectedWalletId: selectedWalletId,
        );
        // Strip only THIS action's JSON block, preserving others.
        final contentAfterStrip = ChatResponseParser.stripActionAtIndex(
          rawContent,
          actionIndex,
        );
        final newTokens = AiChatService.estimateTokens(contentAfterStrip);
        await repo.finalizeAction(
          messageId: messageId,
          strippedContent: contentAfterStrip,
          strippedTokenCount: newTokens,
          followUpContent: r.message,
        );
        return r;
      });

      if (!mounted) return;
      setState(() => _actionStates[key] = ChatActionStatus.confirmed);

      // Show subscription suggestion if the created transaction looks recurring.
      if (result.subscriptionSuggestion != null && mounted) {
        final suggestion = result.subscriptionSuggestion!;
        final suggestMsg =
            context.l10n.chat_subscription_suggest(suggestion.title);
        await repo.insert(
          role: 'assistant',
          content: suggestMsg,
          tokenCount: AiChatService.estimateTokens(suggestMsg),
        );
      }
    } catch (e) {
      final errorMsg = e is ArgumentError ? e.message.toString() : errorGeneric;
      await repo.insert(
        role: 'assistant',
        content: errorMsg,
        tokenCount: 0,
      );
      if (!mounted) return;
      setState(() => _actionStates[key] = ChatActionStatus.failed);
    } finally {
      if (mounted) setState(() => _executingActions.remove(key));
    }
  }

  Future<void> _onCancelAction(
    int messageId,
    int actionIndex,
    ChatAction action,
    String rawContent,
  ) async {
    final key = _actionKey(messageId, actionIndex, action);
    setState(() => _actionStates[key] = ChatActionStatus.cancelled);
    // Strip only THIS action's JSON block, preserving others.
    try {
      final contentAfterStrip = ChatResponseParser.stripActionAtIndex(
        rawContent,
        actionIndex,
      );
      final newTokens = AiChatService.estimateTokens(contentAfterStrip);
      await ref.read(chatMessageRepositoryProvider).updateContent(
            messageId,
            contentAfterStrip,
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

    return ProFeatureGuard(
      featureName: context.l10n.paywall_feature_chat,
      child: Scaffold(
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
              GlassCard(
                tier: GlassTier.inset,
                tintColor: context.appTheme.expenseColor
                    .withValues(alpha: AppSizes.opacitySubtle),
                borderRadius: BorderRadius.zero,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                  vertical: AppSizes.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      AppIcons.warning,
                      size: AppSizes.iconXs,
                      color: context.appTheme.expenseColor,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      context.l10n.chat_offline,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.appTheme.expenseColor,
                      ),
                    ),
                  ],
                ),
              ),

            // AI disclaimer banner (first visit only).
            if (_showDisclaimer)
              GlassCard(
                tier: GlassTier.inset,
                tintColor: context.colors.secondaryContainer
                    .withValues(alpha: AppSizes.opacitySubtle),
                borderRadius: BorderRadius.zero,
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                  vertical: AppSizes.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.info,
                      size: AppSizes.iconSm,
                      color: context.colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        context.l10n.disclaimer_financial,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSecondaryContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        AppIcons.close,
                        size: AppSizes.iconXs,
                        color: context.colors.onSecondaryContainer,
                      ),
                      onPressed: _dismissDisclaimer,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
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
                  final itemCount = messages.length + (_isSending ? 1 : 0);
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
                      // Index 0 = bottom of reversed list.
                      if (_isSending && index == 0) {
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSizes.sm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                CircleAvatar(
                                  radius: AppSizes.iconXs,
                                  backgroundColor: context
                                      .colors.primaryContainer
                                      .withValues(
                                    alpha: AppSizes.opacityLight4,
                                  ),
                                  child: Icon(
                                    AppIcons.ai,
                                    size: AppSizes.iconXs,
                                    color: context.colors.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: AppSizes.xs),
                                GlassCard(
                                  tintColor: context
                                      .colors.surfaceContainerHighest
                                      .withValues(
                                    alpha: AppSizes.opacityLight4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.md,
                                    vertical: AppSizes.sm + AppSizes.xs,
                                  ),
                                  child: const TypingIndicator(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final msgIndex = _isSending
                          ? messages.length - index
                          : messages.length - 1 - index;
                      final msg = messages[msgIndex];

                      // For assistant messages, parse for action JSON.
                      if (msg.role == 'assistant') {
                        final parsed = ChatResponseParser.parse(msg.content);
                        if (parsed.actions.isNotEmpty) {
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
                              for (int i = 0; i < parsed.actions.length; i++)
                                _buildActionCard(
                                  msg.id,
                                  i,
                                  parsed.actions[i],
                                  msg.content, // raw content for per-action stripping
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
            GlassCard(
              tier: GlassTier.inset,
              borderRadius: BorderRadius.zero,
              margin: EdgeInsets.zero,
              showBorder: false,
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
      ),
    );
  }
}
