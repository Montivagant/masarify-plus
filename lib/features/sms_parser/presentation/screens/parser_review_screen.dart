import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/ai_transaction_parser.dart';
import '../../../../core/services/notification_transaction_parser.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../data/database/app_database.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/database_provider.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Rule #7: SMS/notification-parsed transactions MUST pass review — never auto-save.
class ParserReviewScreen extends ConsumerStatefulWidget {
  const ParserReviewScreen({super.key});

  @override
  ConsumerState<ParserReviewScreen> createState() =>
      _ParserReviewScreenState();

  static AiTransactionEnrichment? parseEnrichment(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AiTransactionEnrichment.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

class _ParserReviewScreenState extends ConsumerState<ParserReviewScreen> {
  final _processingIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingParsedTransactionsProvider);

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.parsed_transactions_title),
      body: pendingAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(context.l10n.common_error_generic),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              title: context.l10n.sms_review_title,
              subtitle: context.l10n.parser_no_pending,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSizes.md,
              bottom: AppSizes.bottomScrollPadding,
            ),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return _PendingLogCard(
                log: log,
                isProcessing: _processingIds.contains(log.id),
                onApprove: _processingIds.contains(log.id)
                    ? null
                    : () => _approveWithGuard(log),
                onSkip: _processingIds.contains(log.id)
                    ? null
                    : () => _skip(log),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveWithGuard(SmsParserLog log) async {
    if (_processingIds.contains(log.id)) return;
    setState(() => _processingIds.add(log.id));
    try {
      await _approve(log);
    } finally {
      if (mounted) setState(() => _processingIds.remove(log.id));
    }
  }

  Future<void> _approve(SmsParserLog log) async {
    final parsed = NotificationTransactionParser.parse(
      sender: log.senderAddress,
      body: log.body,
      receivedAt: log.receivedAt,
    );
    if (parsed == null) {
      _skip(log);
      return;
    }

    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    if (wallets.isEmpty) {
      if (!mounted) return;
      SnackHelper.showError(context, context.l10n.common_error_generic);
      return;
    }

    final txRepo = ref.read(transactionRepositoryProvider);
    final dao = ref.read(smsParserLogDaoProvider);
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final approvedMsg = context.l10n.parser_approved_msg;
    final errorMsg = context.l10n.common_error_generic;

    // Resolve AI-suggested category or fall back to a matching-type category.
    final enrichment = ParserReviewScreen.parseEnrichment(log.aiEnrichmentJson);
    final txType = parsed.type;
    var title = log.senderAddress;
    int? categoryId;
    if (enrichment != null) {
      final match = categories.where(
        (c) => c.iconName == enrichment.categoryIcon,
      );
      if (match.isNotEmpty) categoryId = match.first.id;
      // Prefer AI title > merchant name > sender address
      if (enrichment.title.isNotEmpty) {
        title = enrichment.title;
      } else if (enrichment.merchant.isNotEmpty) {
        title = enrichment.merchant;
      }
    }
    // Fall back to a category matching the transaction type
    categoryId ??= categories
        .where((c) => c.type == txType || c.type == 'both')
        .map((c) => c.id)
        .firstOrNull;
    if (categoryId == null) return; // no valid category available

    HapticFeedback.mediumImpact();

    try {
      final txId = await txRepo.create(
        walletId: wallets.first.id,
        categoryId: categoryId,
        amount: parsed.amountPiastres,
        type: parsed.type,
        title: title,
        transactionDate: log.receivedAt,
        source: log.source,
        rawSourceText: log.body,
      );

      await dao.markStatus(log.id, 'approved', transactionId: txId);
      ref.invalidate(pendingParsedTransactionsProvider);
      messenger.showSnackBar(SnackBar(content: Text(approvedMsg)));
    } catch (e) {
      dev.log('Approve failed: $e', name: 'ParserReview');
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  Future<void> _skip(SmsParserLog log) async {
    final dao = ref.read(smsParserLogDaoProvider);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final skippedMsg = context.l10n.parser_skipped_msg;

    HapticFeedback.lightImpact();
    await dao.markStatus(log.id, 'skipped');
    ref.invalidate(pendingParsedTransactionsProvider);
    messenger.showSnackBar(SnackBar(content: Text(skippedMsg)));
  }
}

// ── Pending log card ──────────────────────────────────────────────────────

class _PendingLogCard extends StatelessWidget {
  const _PendingLogCard({
    required this.log,
    required this.isProcessing,
    required this.onApprove,
    required this.onSkip,
  });

  final SmsParserLog log;
  final bool isProcessing;
  final VoidCallback? onApprove;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    final parsed = NotificationTransactionParser.parse(
      sender: log.senderAddress,
      body: log.body,
      receivedAt: log.receivedAt,
    );
    final enrichment = ParserReviewScreen.parseEnrichment(
      log.aiEnrichmentJson,
    );

    final amount =
        parsed != null ? MoneyFormatter.format(parsed.amountPiastres) : '—';

    // Prefer AI title > merchant name > sender address for display.
    final displayTitle = enrichment?.title.isNotEmpty == true
        ? enrichment!.title
        : enrichment?.merchant.isNotEmpty == true
            ? enrichment!.merchant
            : log.senderAddress;

    // Show merchant as subtitle when title already covers the label.
    final displaySubtitle = enrichment?.title.isNotEmpty == true &&
            enrichment!.merchant.isNotEmpty &&
            enrichment.title != enrichment.merchant
        ? enrichment.merchant
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: AppSizes.opacityLight)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: category icon + title + amount ──
            Row(
              children: [
                if (enrichment != null &&
                    enrichment.categoryIcon.isNotEmpty) ...[
                  Icon(
                    CategoryIconMapper.fromName(enrichment.categoryIcon),
                    size: AppSizes.iconSm,
                    color: cs.primary,
                  ),
                  const SizedBox(width: AppSizes.xs),
                ] else ...[
                  Icon(
                    log.source == 'sms'
                        ? AppIcons.sms
                        : AppIcons.notification,
                    size: AppSizes.iconXs,
                    color: cs.outline,
                  ),
                  const SizedBox(width: AppSizes.xs),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: context.textStyles.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (displaySubtitle != null)
                        Text(
                          displaySubtitle,
                          style: context.textStyles.bodySmall?.copyWith(
                                color: cs.outline,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                if (parsed != null)
                  Text(
                    amount,
                    style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: switch (parsed.type) {
                            'income' => context.appTheme.incomeColor,
                            'transfer' => context.appTheme.transferColor,
                            _ => context.appTheme.expenseColor,
                          },
                        ),
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.xs),

            // ── AI note or body text ──────────────────────────────
            Text(
              enrichment?.note.isNotEmpty == true
                  ? enrichment!.note
                  : log.body,
              style: context.textStyles.bodySmall?.copyWith(
                    color: cs.outline,
                  ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              textDirection: _guessDirection(
                enrichment?.note.isNotEmpty == true
                    ? enrichment!.note
                    : log.body,
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Source indicator + Actions ─────────────────────────
            Row(
              children: [
                Icon(
                  log.source == 'sms'
                      ? AppIcons.sms
                      : AppIcons.notification,
                  size: AppSizes.iconXs,
                  color: cs.outline,
                ),
                const SizedBox(width: AppSizes.xxs),
                Text(
                  log.source == 'sms' ? 'SMS' : 'Notification',
                  style: context.textStyles.labelSmall?.copyWith(
                        color: cs.outline,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  child: Text(context.l10n.sms_review_skip),
                ),
                const SizedBox(width: AppSizes.sm),
                FilledButton.tonal(
                  onPressed: onApprove,
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.sms_review_approve),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextDirection _guessDirection(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return TextDirection.ltr;
    final first = trimmed.codeUnitAt(0);
    return (first >= 0x0600 && first <= 0x06FF)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }
}
