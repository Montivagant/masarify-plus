import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/ai_transaction_parser.dart';
import '../../../../core/services/notification_transaction_parser.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/wallet_resolver.dart';
import '../../../../domain/entities/sms_parser_log_entity.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/ai_provider.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/database_provider.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_icon_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Rule #7: SMS/notification-parsed transactions MUST pass review — never auto-save.
class ParserReviewScreen extends ConsumerStatefulWidget {
  const ParserReviewScreen({super.key});

  @override
  ConsumerState<ParserReviewScreen> createState() => _ParserReviewScreenState();

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
  final _enrichingIds = <int>{};
  final _walletOverrides = <int, int>{}; // logId → walletId
  bool _enrichingAll = false;

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingParsedTransactionsProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.parsed_transactions_title,
        actions: [
          AppIconButton(
            icon: AppIcons.refresh,
            onPressed: isOnline && !_enrichingAll ? () => _enrichAll() : null,
            tooltip: context.l10n.parser_enrich_all,
          ),
        ],
      ),
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

          final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

          return _buildLogList(logs, wallets, isOnline);
        },
      ),
    );
  }

  Widget _buildLogList(
    List<SmsParserLogEntity> logs,
    List<WalletEntity> wallets,
    bool isOnline,
  ) {
    // Pre-compute parsed amounts once per build to avoid O(N^2) re-parsing.
    final parsedAmounts = <int, int>{};
    for (final log in logs) {
      final p = NotificationTransactionParser.parse(
        sender: log.senderAddress,
        body: log.body,
        receivedAt: log.receivedAt,
      );
      if (p != null) parsedAmounts[log.id] = p.amountPiastres;
    }

    // Pre-compute duplicate flags using HashMap grouping (O(N) vs O(N²)).
    // Group logs by amount, then check time windows only within same-amount groups.
    final duplicateIds = <int>{};
    final byAmount = <int, List<SmsParserLogEntity>>{};
    for (final log in logs) {
      final amount = parsedAmounts[log.id];
      if (amount != null) (byAmount[amount] ??= []).add(log);
    }
    for (final group in byAmount.values) {
      if (group.length < 2) continue;
      for (var i = 0; i < group.length; i++) {
        for (var j = i + 1; j < group.length; j++) {
          if ((group[i].receivedAt.difference(group[j].receivedAt).abs() <
              AppDurations.transactionDedupeWindow)) {
            duplicateIds.add(group[i].id);
            duplicateIds.add(group[j].id);
          }
        }
      }
    }

    final hasCashWallet = wallets.any((w) => w.isSystemWallet);

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: AppSizes.xs,
        bottom: AppSizes.bottomScrollPadding,
      ),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        final hasEnrichment = log.aiEnrichmentJson != null;
        final isDuplicate = duplicateIds.contains(log.id);

        // Resolve wallet: override > sender match > default account > first non-system.
        final defaultAccount =
            wallets.where((w) => w.isDefaultAccount).firstOrNull;
        final fallbackId = defaultAccount?.id ??
            wallets.where((w) => !w.isSystemWallet).firstOrNull?.id ??
            wallets.firstOrNull?.id;
        final resolvedWalletId = _walletOverrides[log.id] ??
            WalletResolver.resolve(
              log.senderAddress,
              wallets,
            ) ??
            fallbackId;

        final walletName =
            wallets.where((w) => w.id == resolvedWalletId).firstOrNull?.name ??
                '';

        // WS3b: ATM detection.
        final isAtm = NotificationTransactionParser.isAtmWithdrawal(
          log.body,
        );

        return _PendingLogCard(
          log: log,
          isProcessing: _processingIds.contains(log.id),
          isEnriching: _enrichingIds.contains(log.id),
          showEnrichButton: !hasEnrichment && isOnline,
          isDuplicate: isDuplicate,
          isAtm: isAtm,
          hasCashWallet: hasCashWallet,
          walletName: walletName,
          wallets: wallets,
          onApprove: _processingIds.contains(log.id)
              ? null
              : () => _approveWithGuard(log),
          onSkip: _processingIds.contains(log.id) ? null : () => _skip(log),
          onEnrich:
              _enrichingIds.contains(log.id) ? null : () => _enrichSingle(log),
          onWalletChanged: (walletId) => setState(
            () => _walletOverrides[log.id] = walletId,
          ),
          onApproveAsTransfer: _processingIds.contains(log.id)
              ? null
              : () => _approveAsTransfer(log),
        );
      },
    );
  }

  Future<void> _enrichSingle(SmsParserLogEntity log) async {
    if (_enrichingIds.contains(log.id)) return;
    setState(() => _enrichingIds.add(log.id));
    try {
      final success = await _enrichLog(log);
      if (!success && mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      if (mounted) setState(() => _enrichingIds.remove(log.id));
    }
  }

  Future<void> _enrichAll() async {
    if (_enrichingAll) return;
    setState(() => _enrichingAll = true);
    var failed = 0;
    try {
      final logs =
          ref.read(pendingParsedTransactionsProvider).valueOrNull ?? [];
      final unenriched = logs.where((l) => l.aiEnrichmentJson == null).toList();
      for (final log in unenriched) {
        if (!mounted) break;
        if (_enrichingIds.contains(log.id) || _processingIds.contains(log.id)) {
          continue; // skip if already enriching or being approved
        }
        setState(() => _enrichingIds.add(log.id));
        try {
          final success = await _enrichLog(log);
          if (!success) failed++;
        } finally {
          if (mounted) setState(() => _enrichingIds.remove(log.id));
        }
      }
      if (mounted) {
        ref.invalidate(pendingParsedTransactionsProvider);
        if (failed > 0) {
          SnackHelper.showError(
            context,
            context.l10n.common_error_generic,
          );
        }
      }
    } finally {
      if (mounted) setState(() => _enrichingAll = false);
    }
  }

  /// Returns true if enrichment succeeded, false otherwise.
  Future<bool> _enrichLog(SmsParserLogEntity log) async {
    final aiParser = ref.read(aiTransactionParserProvider);
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final repo = ref.read(smsParserLogRepositoryProvider);
    if (categories.isEmpty) return false;

    final parsed = NotificationTransactionParser.parse(
      sender: log.senderAddress,
      body: log.body,
      receivedAt: log.receivedAt,
    );
    if (parsed == null) return false;

    try {
      final enrichment = await aiParser.enrich(
        sender: log.senderAddress,
        body: log.body,
        amountPiastres: parsed.amountPiastres,
        type: parsed.type,
        categories: categories,
      );
      if (enrichment != null) {
        await repo.updateEnrichment(
          log.id,
          jsonEncode(enrichment.toJson()),
        );
        if (mounted) ref.invalidate(pendingParsedTransactionsProvider);
        return true;
      }
      return false;
    } catch (e) {
      dev.log(
        'Enrichment failed for log ${log.id}: $e',
        name: 'ParserReview',
      );
      return false;
    }
  }

  Future<void> _approveWithGuard(SmsParserLogEntity log) async {
    if (_processingIds.contains(log.id)) return;
    setState(() => _processingIds.add(log.id));
    try {
      await _approve(log);
    } finally {
      if (mounted) setState(() => _processingIds.remove(log.id));
    }
  }

  Future<void> _approve(SmsParserLogEntity log) async {
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

    // Resolve wallet: user override > auto-match by sender > default account > first non-system.
    final approveDefaultAccount =
        wallets.where((w) => w.isDefaultAccount).firstOrNull;
    final approveFallbackId = approveDefaultAccount?.id ??
        wallets.where((w) => !w.isSystemWallet).firstOrNull?.id ??
        wallets.firstOrNull?.id;
    if (approveFallbackId == null) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
      return;
    }
    final resolvedWalletId = _walletOverrides[log.id] ??
        WalletResolver.resolve(log.senderAddress, wallets) ??
        approveFallbackId;

    final txRepo = ref.read(transactionRepositoryProvider);
    final smsRepo = ref.read(smsParserLogRepositoryProvider);
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    if (!mounted) return;
    final approvedMsg = context.l10n.parser_approved_msg;
    final errorMsg = context.l10n.common_error_generic;

    // Resolve category via 5-step chain.
    final enrichment = ParserReviewScreen.parseEnrichment(log.aiEnrichmentJson);
    final txType = parsed.type;
    var title = log.senderAddress;
    int? categoryId;

    if (enrichment != null) {
      // Prefer AI title > merchant name > sender address.
      if (enrichment.title.isNotEmpty) {
        title = enrichment.title;
      } else if (enrichment.merchant.isNotEmpty) {
        title = enrichment.merchant;
      }

      final aiIcon = enrichment.categoryIcon.toLowerCase();
      final typeMatching = categories.where(
        (c) => c.type == txType || c.type == 'both',
      );

      // Step 1: Match by iconName (existing).
      categoryId = typeMatching
          .where((c) => c.iconName.toLowerCase() == aiIcon)
          .map((c) => c.id)
          .firstOrNull;

      // Step 2: Fuzzy match by category name — catches AI returning
      // "salary" (name) instead of "payments" (iconName).
      categoryId ??= typeMatching
          .where(
            (c) =>
                c.name.toLowerCase() == aiIcon ||
                c.nameAr == enrichment.categoryIcon,
          )
          .map((c) => c.id)
          .firstOrNull;
    }

    // Step 3: Learning service — user's past manual mappings.
    categoryId ??= await ref
        .read(categorizationLearningServiceProvider)
        .suggestCategory(title);

    // Step 4: Fall back to "Other Income" / "Other Expense".
    categoryId ??= categories
        .where(
          (c) =>
              c.iconName == 'more_horiz' &&
              (c.type == txType || c.type == 'both'),
        )
        .map((c) => c.id)
        .firstOrNull;

    // Step 5: Last resort — prefer "Other" categories (icon contains 'more')
    // before any named category. Never silently fall to "Salary" or similar.
    categoryId ??= categories
        .where(
          (c) =>
              (c.type == txType || c.type == 'both') &&
              c.iconName.toLowerCase().contains('more'),
        )
        .map((c) => c.id)
        .firstOrNull;

    // Step 6: Absolute last resort — first matching type.
    categoryId ??= categories
        .where((c) => c.type == txType || c.type == 'both')
        .map((c) => c.id)
        .firstOrNull;

    if (categoryId == null) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
      return;
    }
    final resolvedCategoryId = categoryId;

    // WS3: Cross-table dedup — check if a similar transaction already exists.
    final txDao = ref.read(transactionDaoProvider);
    final hasSimilar = await txDao.existsSimilar(
      walletId: resolvedWalletId,
      amount: parsed.amountPiastres,
      type: parsed.type,
      aroundDate: log.receivedAt,
    );
    if (hasSimilar && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.parser_possible_duplicate),
          content: Text(context.l10n.parser_duplicate_exists),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: Text(context.l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () => ctx.pop(true),
              child: Text(context.l10n.sms_review_approve),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    HapticFeedback.mediumImpact();

    try {
      // Atomic: create transaction + mark log approved in one DB transaction
      // to prevent duplicate transactions if app crashes between the two steps.
      // Note: txRepo.create() uses its own inner transaction (Drift promotes to savepoint).
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        final txId = await txRepo.create(
          walletId: resolvedWalletId,
          categoryId: resolvedCategoryId,
          amount: parsed.amountPiastres,
          type: parsed.type,
          title: title,
          currencyCode: parsed.currency,
          transactionDate: log.receivedAt,
          source: log.source,
          rawSourceText: log.body,
        );

        await smsRepo.markStatus(log.id, 'approved', transactionId: txId);
      });

      // Record title→category for future auto-categorization learning.
      await ref
          .read(categorizationLearningServiceProvider)
          .recordMapping(title, resolvedCategoryId);

      // WS3d: Auto-link sender to wallet for future auto-matching.
      await ref
          .read(walletRepositoryProvider)
          .addLinkedSender(resolvedWalletId, log.senderAddress);

      ref.invalidate(pendingParsedTransactionsProvider);
      if (mounted) SnackHelper.showSuccess(context, approvedMsg);
    } catch (e) {
      dev.log('Approve failed: $e', name: 'ParserReview');
      if (mounted) SnackHelper.showError(context, errorMsg);
    }
  }

  Future<void> _skip(SmsParserLogEntity log) async {
    final repo = ref.read(smsParserLogRepositoryProvider);
    if (!mounted) return;
    final skippedMsg = context.l10n.parser_skipped_msg;

    HapticFeedback.lightImpact();
    await repo.markStatus(log.id, 'skipped');
    ref.invalidate(pendingParsedTransactionsProvider);
    if (mounted) SnackHelper.showInfo(context, skippedMsg);
  }

  /// WS3b: Approve an ATM withdrawal as a transfer (bank → cash wallet).
  Future<void> _approveAsTransfer(SmsParserLogEntity log) async {
    if (_processingIds.contains(log.id)) return;
    setState(() => _processingIds.add(log.id));

    try {
      await _doApproveAsTransfer(log);
    } finally {
      if (mounted) setState(() => _processingIds.remove(log.id));
    }
  }

  Future<void> _doApproveAsTransfer(SmsParserLogEntity log) async {
    final parsed = NotificationTransactionParser.parse(
      sender: log.senderAddress,
      body: log.body,
      receivedAt: log.receivedAt,
    );
    if (parsed == null) return;

    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final cashWallets = wallets.where((w) => w.isSystemWallet).toList();

    if (cashWallets.isEmpty) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.parser_select_cash_wallet);
      }
      return;
    }

    // If only one cash wallet, use it directly. Otherwise, show picker.
    final int cashWalletId;
    if (cashWallets.length == 1) {
      cashWalletId = cashWallets.first.id;
    } else {
      final picked = await showModalBottomSheet<int>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  context.l10n.parser_select_cash_wallet,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
              ...cashWallets.map(
                (w) => ListTile(
                  leading: Icon(AppIcons.wallet, color: ctx.colors.primary),
                  title: Text(w.name),
                  onTap: () => ctx.pop(w.id),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
            ],
          ),
        ),
      );
      if (picked == null) return;
      cashWalletId = picked;
    }

    final transferDefaultAccount =
        wallets.where((w) => w.isDefaultAccount).firstOrNull;
    final transferFallbackId = transferDefaultAccount?.id ??
        wallets.where((w) => !w.isSystemWallet).firstOrNull?.id ??
        wallets.firstOrNull?.id;
    final fromWalletId = _walletOverrides[log.id] ??
        WalletResolver.resolve(log.senderAddress, wallets) ??
        transferFallbackId;
    if (fromWalletId == null) return;

    // Guard: cannot transfer to the same wallet.
    if (fromWalletId == cashWalletId) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
      return;
    }

    final transferRepo = ref.read(transferRepositoryProvider);
    final smsRepo = ref.read(smsParserLogRepositoryProvider);
    if (!mounted) return;
    final approvedMsg = context.l10n.parser_approved_msg;

    HapticFeedback.mediumImpact();

    try {
      final db = ref.read(databaseProvider);
      await db.transaction(() async {
        final transferId = await transferRepo.create(
          fromWalletId: fromWalletId,
          toWalletId: cashWalletId,
          amount: parsed.amountPiastres,
          transferDate: log.receivedAt,
          note: log.body,
        );
        await smsRepo.markStatus(log.id, 'approved');
        // Store transfer link in the log.
        await smsRepo.linkTransfer(log.id, transferId);
      });

      ref.invalidate(pendingParsedTransactionsProvider);
      if (mounted) SnackHelper.showSuccess(context, approvedMsg);
    } catch (e) {
      dev.log('Approve as transfer failed: $e', name: 'ParserReview');
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    }
  }
}

// ── Pending log card ──────────────────────────────────────────────────────

class _PendingLogCard extends StatelessWidget {
  const _PendingLogCard({
    required this.log,
    required this.isProcessing,
    required this.isEnriching,
    required this.showEnrichButton,
    required this.isDuplicate,
    required this.isAtm,
    required this.hasCashWallet,
    required this.walletName,
    required this.wallets,
    required this.onApprove,
    required this.onSkip,
    required this.onEnrich,
    required this.onWalletChanged,
    this.onApproveAsTransfer,
  });

  final SmsParserLogEntity log;
  final bool isProcessing;
  final bool isEnriching;
  final bool showEnrichButton;
  final bool isDuplicate;
  final bool isAtm;
  final bool hasCashWallet;
  final String walletName;
  final List<WalletEntity> wallets;
  final VoidCallback? onApprove;
  final VoidCallback? onSkip;
  final VoidCallback? onEnrich;
  final ValueChanged<int> onWalletChanged;
  final VoidCallback? onApproveAsTransfer;

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

    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: category icon + title + amount ──
          Row(
            children: [
              if (enrichment != null && enrichment.categoryIcon.isNotEmpty) ...[
                Icon(
                  CategoryIconMapper.fromName(enrichment.categoryIcon),
                  size: AppSizes.iconSm,
                  color: cs.primary,
                ),
                const SizedBox(width: AppSizes.xs),
              ] else ...[
                Icon(
                  AppIcons.sms,
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
            enrichment?.note.isNotEmpty == true ? enrichment!.note : log.body,
            style: context.textStyles.bodySmall?.copyWith(
              color: cs.outline,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textDirection: _guessDirection(
              enrichment?.note.isNotEmpty == true ? enrichment!.note : log.body,
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Wallet + currency + duplicate indicators ──────────
          Wrap(
            spacing: AppSizes.xs,
            runSpacing: AppSizes.xxs,
            children: [
              if (walletName.isNotEmpty)
                GestureDetector(
                  onTap: () => _showWalletPicker(context),
                  child: Chip(
                    avatar: Icon(
                      AppIcons.wallet,
                      size: AppSizes.iconXs,
                      color: cs.primary,
                    ),
                    label: Text(
                      walletName,
                      style: context.textStyles.labelSmall,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              if (parsed != null && parsed.currency != 'EGP') ...[
                Chip(
                  avatar: Icon(
                    AppIcons.currency,
                    size: AppSizes.iconXs,
                    color: cs.tertiary,
                  ),
                  label: Text(
                    parsed.currency,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              if (isDuplicate) ...[
                Chip(
                  avatar: Icon(
                    AppIcons.warning,
                    size: AppSizes.iconXs,
                    color: cs.error,
                  ),
                  label: Text(
                    context.l10n.parser_possible_duplicate,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.error,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              // WS3b: ATM withdrawal chip.
              if (isAtm) ...[
                Chip(
                  avatar: Icon(
                    AppIcons.wallet,
                    size: AppSizes.iconXs,
                    color: cs.tertiary,
                  ),
                  label: Text(
                    context.l10n.parser_atm_detected,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSizes.xs),

          // ── Source indicator + Actions ─────────────────────────
          Row(
            children: [
              Icon(
                AppIcons.sms,
                size: AppSizes.iconXs,
                color: cs.outline,
              ),
              const SizedBox(width: AppSizes.xxs),
              Text(
                context.l10n.transaction_source_sms,
                style: context.textStyles.labelSmall?.copyWith(
                  color: cs.outline,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: AppSizes.xs,
                  runSpacing: AppSizes.xxs,
                  children: [
                    if (showEnrichButton)
                      TextButton(
                        onPressed: onEnrich,
                        child: isEnriching
                            ? SizedBox(
                                width: AppSizes.iconXs,
                                height: AppSizes.iconXs,
                                child: CircularProgressIndicator(
                                  strokeWidth: AppSizes.spinnerStrokeWidth,
                                  color: cs.primary,
                                ),
                              )
                            : Text(context.l10n.parser_enrich),
                      ),
                    TextButton(
                      onPressed: onSkip,
                      child: Text(context.l10n.sms_review_skip),
                    ),
                    // WS3b: Split approve button for ATM withdrawals.
                    if (isAtm && hasCashWallet) ...[
                      OutlinedButton(
                        onPressed: onApprove,
                        child: Text(context.l10n.sms_review_approve),
                      ),
                      FilledButton.tonal(
                        onPressed: onApproveAsTransfer,
                        child: isProcessing
                            ? const SizedBox(
                                width: AppSizes.spinnerSizeSm,
                                height: AppSizes.spinnerSizeSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: AppSizes.spinnerStrokeWidth,
                                ),
                              )
                            : Text(context.l10n.parser_approve_as_transfer),
                      ),
                    ] else
                      FilledButton.tonal(
                        onPressed: onApprove,
                        child: isProcessing
                            ? const SizedBox(
                                width: AppSizes.spinnerSizeSm,
                                height: AppSizes.spinnerSizeSm,
                                child: CircularProgressIndicator(
                                  strokeWidth: AppSizes.spinnerStrokeWidth,
                                ),
                              )
                            : Text(context.l10n.sms_review_approve),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWalletPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                context.l10n.parser_wallet_label,
                style: ctx.textStyles.titleMedium,
              ),
            ),
            ...wallets.map(
              (w) => ListTile(
                leading: Icon(AppIcons.wallet, color: ctx.colors.primary),
                title: Text(w.name),
                onTap: () {
                  onWalletChanged(w.id);
                  ctx.pop();
                },
              ),
            ),
            const SizedBox(height: AppSizes.sm),
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
