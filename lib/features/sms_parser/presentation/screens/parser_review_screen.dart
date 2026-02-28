import 'dart:convert';

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
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Rule #7: SMS/notification-parsed transactions MUST pass review — never auto-save.
class ParserReviewScreen extends ConsumerWidget {
  const ParserReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingParsedTransactionsProvider);

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.sms_review_title),
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
                onApprove: () => _approve(context, ref, log),
                onSkip: () => _skip(context, ref, log),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    SmsParserLog log,
  ) async {
    final parsed = NotificationTransactionParser.parse(
      sender: log.senderAddress,
      body: log.body,
      receivedAt: log.receivedAt,
    );
    if (parsed == null) {
      _skip(context, ref, log);
      return;
    }

    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    if (wallets.isEmpty) return;

    final txRepo = ref.read(transactionRepositoryProvider);
    final dao = ref.read(smsParserLogDaoProvider);
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final messenger = ScaffoldMessenger.of(context);
    final approvedMsg = context.l10n.parser_approved_msg;
    final errorMsg = context.l10n.common_error_generic;

    // Resolve AI-suggested category or fall back to a matching-type category.
    final enrichment = _parseEnrichment(log.aiEnrichmentJson);
    final txType = parsed.type;
    var title = log.senderAddress;
    int? categoryId;
    if (enrichment != null) {
      final match = categories.where(
        (c) => c.iconName == enrichment.categoryIcon,
      );
      if (match.isNotEmpty) categoryId = match.first.id;
      if (enrichment.merchant.isNotEmpty) title = enrichment.merchant;
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
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
    }
  }

  Future<void> _skip(
    BuildContext context,
    WidgetRef ref,
    SmsParserLog log,
  ) async {
    final dao = ref.read(smsParserLogDaoProvider);
    final messenger = ScaffoldMessenger.of(context);
    final skippedMsg = context.l10n.parser_skipped_msg;

    HapticFeedback.lightImpact();
    await dao.markStatus(log.id, 'skipped');
    ref.invalidate(pendingParsedTransactionsProvider);
    messenger.showSnackBar(SnackBar(content: Text(skippedMsg)));
  }

  static AiTransactionEnrichment? _parseEnrichment(String? json) {
    if (json == null || json.isEmpty) return null;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return AiTransactionEnrichment.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}

// ── Pending log card ──────────────────────────────────────────────────────

class _PendingLogCard extends StatelessWidget {
  const _PendingLogCard({
    required this.log,
    required this.onApprove,
    required this.onSkip,
  });

  final SmsParserLog log;
  final VoidCallback onApprove;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    final parsed = NotificationTransactionParser.parse(
      sender: log.senderAddress,
      body: log.body,
      receivedAt: log.receivedAt,
    );
    final enrichment = ParserReviewScreen._parseEnrichment(
      log.aiEnrichmentJson,
    );

    final amount =
        parsed != null ? MoneyFormatter.format(parsed.amountPiastres) : '—';
    final isIncome = parsed?.type == 'income';

    // Use AI merchant name if available, otherwise sender address.
    final displayTitle =
        enrichment?.merchant.isNotEmpty == true
            ? enrichment!.merchant
            : log.senderAddress;

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
            // ── Header: category icon + merchant/sender + amount ──
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
                  child: Text(
                    displayTitle,
                    style: context.textStyles.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (parsed != null)
                  Text(
                    amount,
                    style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isIncome
                              ? context.appTheme.incomeColor
                              : context.appTheme.expenseColor,
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

            // ── Actions ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onSkip,
                  child: Text(context.l10n.sms_review_skip),
                ),
                const SizedBox(width: AppSizes.sm),
                FilledButton.tonal(
                  onPressed: onApprove,
                  child: Text(context.l10n.sms_review_approve),
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
