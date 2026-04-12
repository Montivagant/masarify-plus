import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/wallet_provider.dart';

/// Callback signature for filter changes in the tab filter row.
typedef FilterChangedCallback = void Function({
  String? timePreset,
  String? typeFilter,
  int? walletId,
  bool? clearWallet,
  DateTimeRange? customRange,
});

/// Per-tab horizontal filter chip row.
///
/// Each analytics tab embeds its own [TabFilterRow] so filters are
/// independent across Overview / Categories / Trends.
class TabFilterRow extends ConsumerWidget {
  const TabFilterRow({
    super.key,
    required this.timePreset,
    required this.typeFilter,
    required this.walletId,
    this.customRange,
    required this.onFilterChanged,
    this.timePresets,
    this.showTypeFilter = true,
  });

  /// Currently selected time preset key.
  final String timePreset;

  /// Currently selected type filter: 'all', 'expense', or 'income'.
  final String typeFilter;

  /// Currently selected wallet ID (null = all wallets).
  final int? walletId;

  /// Active custom date range (shown on chip when timePreset == 'custom').
  final DateTimeRange? customRange;

  /// Called when any filter changes.
  final FilterChangedCallback onFilterChanged;

  /// Available time presets. Null = default (This Month / Last Month / 3M / 6M).
  final List<({String key, String Function(BuildContext) label})>? timePresets;

  /// Whether to show the All / Expenses / Income type chips.
  final bool showTypeFilter;

  static final _defaultTimePresets =
      <({String key, String Function(BuildContext) label})>[
    (key: 'this_month', label: (c) => c.l10n.reports_this_month),
    (key: 'last_month', label: (c) => c.l10n.reports_last_month),
    (key: '3_months', label: (c) => c.l10n.reports_3_months),
    (key: '6_months', label: (c) => c.l10n.reports_6_months),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final activeWallets = wallets.where((w) => !w.isArchived).toList();
    final effectivePresets = timePresets ?? _defaultTimePresets;

    final hasNonDefault =
        timePreset != 'this_month' || typeFilter != 'all' || walletId != null;

    return SizedBox(
      height: AppSizes.minTapTarget,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
        children: [
          // ── Time presets ──────────────────────────────────────────────
          for (final preset in effectivePresets)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSizes.xs),
              child: FilterChip(
                label: Text(preset.label(context)),
                selected: timePreset == preset.key,
                onSelected: (_) => onFilterChanged(timePreset: preset.key),
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: cs.primary,
                labelStyle: context.textStyles.labelLarge?.copyWith(
                  color: timePreset == preset.key
                      ? cs.onPrimary
                      : cs.onSurfaceVariant,
                ),
              ),
            ),

          // ── Custom date chip ────────────────────────────────────────
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSizes.sm),
            child: FilterChip(
              label: Text(
                timePreset == 'custom' && customRange != null
                    ? _formatRange(context, customRange!)
                    : context.l10n.reports_custom,
              ),
              selected: timePreset == 'custom',
              onSelected: (_) => _pickDateRange(context),
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selectedColor: cs.primary,
              labelStyle: context.textStyles.labelLarge?.copyWith(
                color:
                    timePreset == 'custom' ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
          ),

          // ── Type filter ─────────────────────────────────────────────
          if (showTypeFilter) ...[
            _divider(cs),
            for (final type in ['all', 'expense', 'income'])
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSizes.xs),
                child: FilterChip(
                  label: Text(_typeLabel(context, type)),
                  selected: typeFilter == type,
                  onSelected: (_) => onFilterChanged(typeFilter: type),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selectedColor: cs.primary,
                  labelStyle: context.textStyles.labelLarge?.copyWith(
                    color:
                        typeFilter == type ? cs.onPrimary : cs.onSurfaceVariant,
                  ),
                ),
              ),
          ],

          // ── Wallet filter ───────────────────────────────────────────
          if (activeWallets.length > 1) ...[
            _divider(cs),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSizes.xs),
              child: FilterChip(
                label: Text(
                  walletId == null
                      ? context.l10n.reports_all_accounts
                      : activeWallets
                              .where((w) => w.id == walletId)
                              .firstOrNull
                              ?.name ??
                          context.l10n.reports_all_accounts,
                ),
                selected: walletId != null,
                onSelected: (_) {
                  if (walletId != null) {
                    onFilterChanged(clearWallet: true);
                  } else {
                    _showWalletPicker(context, activeWallets);
                  }
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: cs.primary,
                labelStyle: context.textStyles.labelLarge?.copyWith(
                  color: walletId != null ? cs.onPrimary : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],

          // ── Clear button ────────────────────────────────────────────
          if (hasNonDefault)
            Center(
              child: TextButton(
                onPressed: () => onFilterChanged(
                  timePreset: 'this_month',
                  typeFilter: 'all',
                  clearWallet: true,
                ),
                child: Text(
                  context.l10n.reports_clear_filters,
                  style: context.textStyles.labelSmall
                      ?.copyWith(color: cs.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.xs,
          vertical: AppSizes.sm,
        ),
        child: VerticalDivider(
          width: AppSizes.dividerHeight,
          color: cs.outlineVariant,
        ),
      ),
    );
  }

  String _typeLabel(BuildContext context, String type) {
    return switch (type) {
      'expense' => context.l10n.dashboard_expense,
      'income' => context.l10n.dashboard_income,
      _ => context.l10n.reports_all_types,
    };
  }

  String _formatRange(BuildContext context, DateTimeRange range) {
    final fmt = DateFormat.MMMd(context.languageCode);
    return '${fmt.format(range.start)} - ${fmt.format(range.end)}';
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: customRange,
    );
    if (picked != null) {
      onFilterChanged(
        timePreset: 'custom',
        customRange: picked,
      );
    }
  }

  void _showWalletPicker(
    BuildContext context,
    List<dynamic> wallets,
  ) {
    showModalBottomSheet<int>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.sm),
            for (final w in wallets)
              ListTile(
                title: Text(w.name as String),
                onTap: () => context.pop(w.id as int),
              ),
          ],
        ),
      ),
    ).then((id) {
      if (id != null) {
        onFilterChanged(walletId: id);
      }
    });
  }
}
