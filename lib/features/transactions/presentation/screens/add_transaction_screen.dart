import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/goal_keyword_matcher.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/smart_defaults_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_date_picker.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Core transaction entry screen — supports both add and edit modes.
///
/// Layout (Glass Sections):
///   ChoiceChip row (type: expense/income/withdraw/deposit) — scrollable
///   GlassCard (Amount) — tinted with type color
///   GlassCard (Details) — title, category chips, wallet picker (expense/income)
///               OR — wallet picker only (cash_withdrawal/cash_deposit)
///   GlassCard (Optional) — date, note, location chips (expense/income only)
///   AppButton (Save) — sticky bottom
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.initialType = 'expense',
    this.editId,
  });

  final String initialType;
  final int? editId;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  // ── Form state ────────────────────────────────────────────────────────────
  late String _type;
  int _amountPiastres = 0;
  int? _selectedCategoryId;
  int? _walletId;
  DateTime _date = DateTime.now();
  final _noteController = TextEditingController();
  final _titleController = TextEditingController(); // WS-10
  bool _loading = false;
  bool _showOptional = false;
  bool _smartDefaultApplied = false;
  TransactionEntity? _editTx;
  String? _locationName;
  double? _latitude;
  double? _longitude;
  bool _detectingLocation = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    if (widget.editId != null) {
      _loadForEdit();
    } else {
      _initWallet();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  // ── Init helpers ──────────────────────────────────────────────────────────

  Future<void> _initWallet() async {
    final wallets = await ref.read(walletRepositoryProvider).getAll();
    if (!mounted) return;
    if (wallets.isEmpty) return;
    // For cash types, pick the first non-system (bank) wallet.
    if (_isCashType) {
      final nonSystem = wallets.where((w) => !w.isSystemWallet).toList();
      if (nonSystem.isNotEmpty) {
        setState(() => _walletId = nonSystem.first.id);
      }
    } else {
      setState(() => _walletId = wallets.first.id);
    }
  }

  /// Applies last-used category default once categories are loaded.
  /// Called from build — guarded by [_smartDefaultApplied] flag.
  void _tryApplySmartDefault(List<CategoryEntity> typeCats) {
    if (_smartDefaultApplied || widget.editId != null) return;
    if (typeCats.isEmpty) return;
    _smartDefaultApplied = true;

    final service = ref.read(categoryFrequencyServiceProvider);
    final lastId = service.getLastUsedCategoryId(_type);
    if (lastId == null) return;
    final valid = typeCats.any((c) => c.id == lastId);
    if (valid) {
      // Safe: called during build, schedules after current frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedCategoryId = lastId);
      });
    }
  }

  Future<void> _loadForEdit() async {
    final tx =
        await ref.read(transactionRepositoryProvider).getById(widget.editId!);
    if (!mounted || tx == null) return;

    setState(() {
      _editTx = tx;
      _type = tx.type;
      _amountPiastres = tx.amount;
      _selectedCategoryId = tx.categoryId;
      _walletId = tx.walletId;
      _date = tx.transactionDate;
      _locationName = tx.locationName;
      _latitude = tx.latitude;
      _longitude = tx.longitude;
      if (tx.note != null) _noteController.text = tx.note!;
      _titleController.text = tx.title; // WS-10
    });
  }

  // ── Location detection ──────────────────────────────────────────────────

  Future<void> _detectLocation() async {
    // Debounce: prevent concurrent requests
    if (_detectingLocation) return;

    try {
      // Per AGENTS.md Rule 6: show rationale BEFORE requesting permission.
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        await PermissionHelper.openAppSettings();
        return;
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        final allowed = await PermissionHelper.showRationale(
          context,
          title: context.l10n.permission_location_title,
          rationale: context.l10n.permission_location_body,
        );
        if (!allowed || !mounted) return;
      }

      setState(() => _detectingLocation = true);
      final result = await LocationService.detect();
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _locationName = result.name;
          _latitude = result.lat;
          _longitude = result.lng;
          _detectingLocation = false;
        });
      } else {
        setState(() => _detectingLocation = false);
        SnackHelper.showError(context, context.l10n.location_failed);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _detectingLocation = false);
      SnackHelper.showError(context, context.l10n.location_failed);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  bool get _isCashType => _type == 'cash_withdrawal' || _type == 'cash_deposit';

  // ── Save ──────────────────────────────────────────────────────────────────

  /// Saves a cash withdrawal or cash deposit as a Transfer
  /// (bank account <-> Cash system wallet).
  Future<void> _saveCashTransfer() async {
    if (_loading) return;
    final walletId = _walletId;
    if (_amountPiastres <= 0 || walletId == null) return;

    setState(() => _loading = true);
    try {
      final cashWallet = ref.read(systemWalletProvider).valueOrNull;
      if (cashWallet == null) {
        setState(() => _loading = false);
        if (mounted) {
          SnackHelper.showError(context, context.l10n.common_error_generic);
        }
        return;
      }

      final transferRepo = ref.read(transferRepositoryProvider);
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      if (_type == 'cash_withdrawal') {
        // Withdraw from bank → Cash
        await transferRepo.create(
          fromWalletId: walletId,
          toWalletId: cashWallet.id,
          amount: _amountPiastres,
          note: note,
          transferDate: DateTime.now(),
        );
      } else {
        // Deposit from Cash → bank
        await transferRepo.create(
          fromWalletId: cashWallet.id,
          toWalletId: walletId,
          amount: _amountPiastres,
          note: note,
          transferDate: DateTime.now(),
        );
      }

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      SnackHelper.showSuccess(context, context.l10n.transfer_success);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

  /// Finds the first active goal whose keywords match [title] or [note].
  /// Returns both goalId and goalName for the SnackBar prompt.
  ({int goalId, String goalName})? _matchGoalWithName(
    String title,
    String? note,
  ) {
    final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];
    for (final goal in goals) {
      final List<String> kws;
      try {
        kws = (jsonDecode(goal.keywords) as List).cast<String>();
      } catch (_) {
        continue;
      }
      final matcher = GoalKeywordMatcher(keywords: kws);
      if (matcher.matches(title) || (note != null && matcher.matches(note))) {
        return (goalId: goal.id, goalName: goal.name);
      }
    }
    return null;
  }

  Future<void> _save() async {
    // I13 fix: prevent double-tap race condition
    if (_loading) return;
    final categoryId = _selectedCategoryId;
    final walletId = _walletId;
    if (_amountPiastres <= 0 || categoryId == null || walletId == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
      // H3 fix: don't silently fallback to wrong category
      final cat = cats.where((c) => c.id == categoryId).firstOrNull;
      if (cat == null) {
        // Category was deleted between form open and save
        setState(() => _loading = false);
        if (mounted) {
          SnackHelper.showError(context, context.l10n.common_error_generic);
        }
        return;
      }
      // H4 fix: verify category type matches transaction type
      if (cat.type != _type && cat.type != 'both') {
        setState(() => _loading = false);
        if (mounted) {
          SnackHelper.showError(context, context.l10n.common_error_generic);
        }
        return;
      }

      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();

      // WS-10: use user's title if provided, else fallback to category name.
      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : cat.displayName(context.languageCode);
      int txId;

      if (widget.editId != null && _editTx != null) {
        txId = _editTx!.id;
        await repo.update(
          _editTx!.copyWith(
            walletId: walletId,
            categoryId: categoryId,
            amount: _amountPiastres,
            type: _type,
            title: title,
            note: note,
            transactionDate: _date,
            locationName: _locationName,
            latitude: _latitude,
            longitude: _longitude,
          ),
        );
      } else {
        txId = await repo.create(
          walletId: walletId,
          categoryId: categoryId,
          amount: _amountPiastres,
          type: _type,
          title: title,
          transactionDate: _date,
          note: note,
          locationName: _locationName,
          latitude: _latitude,
          longitude: _longitude,
        );
        await ref
            .read(categoryFrequencyServiceProvider)
            .recordUsage(_type, categoryId);
        // Record title→category mapping for auto-categorization learning.
        await ref
            .read(categorizationLearningServiceProvider)
            .recordMapping(title, categoryId);
      }

      HapticFeedback.heavyImpact();
      if (!mounted) return;

      // Check for goal keyword match and prompt with SnackBar.
      final match = _matchGoalWithName(title, note);
      if (match != null) {
        final messenger = ScaffoldMessenger.of(context);
        final l10n = context.l10n;
        messenger.showSnackBar(
          SnackBar(
            duration: AppDurations.snackbarLong,
            content: Text(l10n.goal_link_prompt(match.goalName)),
            action: SnackBarAction(
              label: l10n.goal_link_action,
              onPressed: () async {
                // CR-18 fix: wrap in try/catch to handle async errors
                try {
                  final tx = await repo.getById(txId);
                  if (tx != null) {
                    await repo.update(tx.copyWith(goalId: match.goalId));
                  }
                } catch (_) {
                  // M12 fix: show error feedback for goal link failure
                  messenger.showSnackBar(
                    SnackBar(content: Text(l10n.common_error_generic)),
                  );
                }
              },
            ),
          ),
        );
      }

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

  // ── Pickers ───────────────────────────────────────────────────────────────

  void _showWalletPicker() {
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    if (wallets.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(ctx).height * AppSizes.bottomSheetHeightRatio,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                width: AppSizes.dragHandleWidth,
                height: AppSizes.dragHandleHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ctx.colors.outlineVariant,
                  borderRadius:
                      BorderRadius.circular(AppSizes.dragHandleHeight / 2),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.md,
                  0,
                  AppSizes.md,
                  AppSizes.sm,
                ),
                child: Text(
                  context.l10n.transaction_wallet_picker,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: wallets
                      .map(
                        (w) => ListTile(
                          leading: Icon(_walletTypeIcon(w.type)),
                          title: Text(w.name),
                          trailing: _walletId == w.id
                              ? const Icon(AppIcons.check)
                              : null,
                          onTap: () {
                            setState(() => _walletId = w.id);
                            ctx.pop();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllCategories(List<CategoryEntity> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CategoryPickerSheet(
        categories: categories,
        selectedId: _selectedCategoryId,
        onSelected: (id) {
          setState(() => _selectedCategoryId = id);
          context.pop();
        },
      ),
    );
  }

  // ── Wallet icon helper ─────────────────────────────────────────────────

  static IconData _walletTypeIcon(String type) => switch (type) {
        'physical_cash' => AppIcons.physicalCash,
        'bank' => AppIcons.bank,
        'mobile_wallet' => AppIcons.phone,
        'credit_card' => AppIcons.creditCard,
        'prepaid_card' => AppIcons.prepaidCard,
        'investment' => AppIcons.investmentAccount,
        _ => AppIcons.wallet,
      };

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final typeCats =
        allCats.where((c) => c.type == _type || c.type == 'both').toList();
    if (!_isCashType) _tryApplySmartDefault(typeCats);
    final freqService = ref.read(categoryFrequencyServiceProvider);
    final sortedCats = freqService.sortByFrequency(typeCats, _type);
    final topCats = sortedCats.take(AppSizes.categoryChipMaxVisible).toList();
    final todKeywords = freqService.getTimeOfDaySuggestedKeywords();

    final typeColor = switch (_type) {
      'income' => context.appTheme.incomeColor,
      'cash_withdrawal' || 'cash_deposit' => context.appTheme.transferColor,
      _ => context.appTheme.expenseColor,
    };

    final canSave = _isCashType
        ? _amountPiastres > 0 && _walletId != null
        : _amountPiastres > 0 &&
            _selectedCategoryId != null &&
            _walletId != null;

    // Resolve current wallet for the wallet picker row.
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    // For cash types, exclude the Cash system wallet from the picker
    // (user picks the bank account only).
    final pickableWallets = _isCashType
        ? wallets.where((w) => !w.isSystemWallet).toList()
        : wallets;
    final currentWallet =
        pickableWallets.where((w) => w.id == _walletId).firstOrNull;

    // Type chip definitions: value, label, icon
    final typeOptions = <({String value, String label, IconData icon})>[
      (
        value: 'expense',
        label: context.l10n.transaction_type_expense,
        icon: AppIcons.expense,
      ),
      (
        value: 'income',
        label: context.l10n.transaction_type_income,
        icon: AppIcons.income,
      ),
      (
        value: 'cash_withdrawal',
        label: context.l10n.transaction_type_cash_withdrawal_short,
        icon: AppIcons.bank,
      ),
      (
        value: 'cash_deposit',
        label: context.l10n.transaction_type_cash_deposit_short,
        icon: AppIcons.bank,
      ),
    ];

    return Scaffold(
      appBar: AppAppBar(
        title: widget.editId != null
            ? context.l10n.transaction_edit_title
            : context.l10n.transactions_add,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Type toggle (scrollable chips — 4 options) ───────────
            if (widget.editId == null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                  vertical: AppSizes.sm,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: typeOptions.map((opt) {
                      final selected = _type == opt.value;
                      final chipColor = switch (opt.value) {
                        'income' => context.appTheme.incomeColor,
                        'cash_withdrawal' ||
                        'cash_deposit' =>
                          context.appTheme.transferColor,
                        _ => context.appTheme.expenseColor,
                      };
                      return Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSizes.sm,
                        ),
                        child: ChoiceChip(
                          selected: selected,
                          label: Text(opt.label),
                          avatar: Icon(opt.icon, size: AppSizes.iconXs),
                          selectedColor: chipColor.withValues(
                            alpha: AppSizes.opacityLight2,
                          ),
                          side: selected ? BorderSide(color: chipColor) : null,
                          onSelected: (_) {
                            setState(() {
                              _type = opt.value;
                              _selectedCategoryId = null;
                              _smartDefaultApplied = false;
                              // For cash types, auto-select first non-system wallet
                              if (_isCashType && pickableWallets.isNotEmpty) {
                                final nonSystem = pickableWallets
                                    .where((w) => !w.isSystemWallet)
                                    .toList();
                                if (nonSystem.isNotEmpty) {
                                  _walletId = nonSystem.first.id;
                                }
                              }
                            });
                          },
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // ── Type toggle (edit mode — only expense/income) ────────
            if (widget.editId != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                  vertical: AppSizes.sm,
                ),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'expense',
                      label: Text(context.l10n.transaction_type_expense),
                      icon: const Icon(AppIcons.expense),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text(context.l10n.transaction_type_income),
                      icon: const Icon(AppIcons.income),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) {
                    setState(() {
                      _type = v.first;
                      _selectedCategoryId = null;
                      _smartDefaultApplied = false;
                    });
                  },
                ),
              ),

            // ── Amount Card (tinted glass) ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: GlassCard(
                tintColor: typeColor.withValues(alpha: AppSizes.opacitySubtle),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.sm,
                ),
                child: AmountInput(
                  initialPiastres: _amountPiastres,
                  onAmountChanged: (p) => setState(() => _amountPiastres = p),
                  autofocus: widget.editId == null,
                  textColor: typeColor,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Cash type: simplified form (account + note) ──────────
            if (_isCashType) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank account picker
                      _WalletPickerRow(
                        wallet: currentWallet,
                        onTap: () => _showWalletPickerFiltered(pickableWallets),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      // Optional note
                      AppTextField(
                        label: context.l10n.transaction_note,
                        hint: context.l10n.transaction_note_hint,
                        controller: _noteController,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ── Expense/Income: full form ────────────────────────────
            if (!_isCashType) ...[
              // Details Card (title + categories + wallet)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title input with icon prefix, no floating label
                      AppTextField(
                        label: context.l10n.transaction_title_label,
                        hint: context.l10n.transaction_title_hint,
                        controller: _titleController,
                        prefixIcon: Icon(
                          AppIcons.edit,
                          size: AppSizes.iconSm,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Category chips row
                      SizedBox(
                        height: AppSizes.categoryChipSize,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: topCats.length + 1,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSizes.xs),
                          itemBuilder: (_, i) {
                            if (i == topCats.length) {
                              return ActionChip(
                                label: Text(context.l10n.common_all),
                                avatar: const Icon(
                                  AppIcons.expandMore,
                                  size: AppSizes.iconXxs2,
                                ),
                                onPressed: () => _showAllCategories(typeCats),
                              );
                            }
                            final cat = topCats[i];
                            final color = ColorUtils.fromHex(cat.colorHex);
                            final isSelected = cat.id == _selectedCategoryId;
                            final isTimeHint = !isSelected &&
                                todKeywords.any(
                                  (kw) =>
                                      cat.name.toLowerCase().contains(kw) ||
                                      cat.nameAr.contains(kw),
                                );
                            return AnimatedScale(
                              scale: isSelected ? 1.0 : 0.95,
                              duration: context.reduceMotion
                                  ? Duration.zero
                                  : AppDurations.microBounce,
                              curve: Curves.easeOutBack,
                              child: FilterChip(
                                selected: isSelected,
                                avatar: Icon(
                                  CategoryIconMapper.fromName(
                                    cat.iconName,
                                  ),
                                  size: AppSizes.iconXs,
                                  color: isSelected
                                      ? cs.onSecondaryContainer
                                      : color,
                                ),
                                label: Text(
                                  cat.displayName(
                                    context.languageCode,
                                  ),
                                ),
                                side: isTimeHint
                                    ? BorderSide(
                                        color: cs.primary,
                                        width: AppSizes.borderWidthEmphasis,
                                      )
                                    : null,
                                onSelected: (_) {
                                  setState(() => _selectedCategoryId = cat.id);
                                  // WS-10: auto-fill title on category selection if empty.
                                  if (_titleController.text.trim().isEmpty) {
                                    _titleController.text = cat.displayName(
                                      context.languageCode,
                                    );
                                  }
                                },
                                showCheckmark: false,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Wallet picker row
                      _WalletPickerRow(
                        wallet: currentWallet,
                        onTap: _showWalletPicker,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.md),

              // Optional Card (date, note, location)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: _OptionalSection(
                  expanded: _showOptional,
                  onToggle: () =>
                      setState(() => _showOptional = !_showOptional),
                  date: _date,
                  onDateChanged: (d) => setState(() => _date = d),
                  noteController: _noteController,
                  locationName: _locationName,
                  detectingLocation: _detectingLocation,
                  onDetectLocation: _detectLocation,
                  onLocationChanged: (v) => setState(() => _locationName = v),
                ),
              ),
            ],

            // Extra space for scrolling when keyboard opens
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSizes.screenHPadding,
            AppSizes.sm,
            AppSizes.screenHPadding,
            AppSizes.md,
          ),
          child: AppButton(
            label: widget.editId != null
                ? context.l10n.common_save_changes
                : context.l10n.common_save,
            onPressed: canSave && !_loading
                ? (_isCashType ? _saveCashTransfer : _save)
                : null,
            isLoading: _loading,
            icon: AppIcons.check,
          ),
        ),
      ),
    );
  }

  /// Shows wallet picker filtered to exclude the Cash system wallet.
  void _showWalletPickerFiltered(List<WalletEntity> filteredWallets) {
    if (filteredWallets.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(ctx).height * AppSizes.bottomSheetHeightRatio,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                width: AppSizes.dragHandleWidth,
                height: AppSizes.dragHandleHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ctx.colors.outlineVariant,
                  borderRadius:
                      BorderRadius.circular(AppSizes.dragHandleHeight / 2),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.md,
                  0,
                  AppSizes.md,
                  AppSizes.sm,
                ),
                child: Text(
                  context.l10n.transaction_wallet_picker,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: filteredWallets
                      .map(
                        (w) => ListTile(
                          leading: Icon(_walletTypeIcon(w.type)),
                          title: Text(w.name),
                          trailing: _walletId == w.id
                              ? const Icon(AppIcons.check)
                              : null,
                          onTap: () {
                            setState(() => _walletId = w.id);
                            ctx.pop();
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Wallet picker row ────────────────────────────────────────────────────

class _WalletPickerRow extends StatelessWidget {
  const _WalletPickerRow({
    required this.wallet,
    required this.onTap,
  });

  final WalletEntity? wallet;
  final VoidCallback onTap;

  static IconData _typeIcon(String type) => switch (type) {
        'physical_cash' => AppIcons.physicalCash,
        'bank' => AppIcons.bank,
        'mobile_wallet' => AppIcons.phone,
        'credit_card' => AppIcons.creditCard,
        'prepaid_card' => AppIcons.prepaidCard,
        'investment' => AppIcons.investmentAccount,
        _ => AppIcons.wallet,
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    if (wallet == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Row(
          children: [
            Icon(
              _typeIcon(wallet!.type),
              size: AppSizes.iconSm,
              color: cs.primary,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                wallet!.name,
                style: context.textStyles.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              AppIcons.chevronRight,
              size: AppSizes.iconXs,
              color: cs.outline,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Optional section (wrapped in GlassCard) ──────────────────────────────

class _OptionalSection extends StatelessWidget {
  const _OptionalSection({
    required this.expanded,
    required this.onToggle,
    required this.date,
    required this.onDateChanged,
    required this.noteController,
    required this.locationName,
    required this.detectingLocation,
    required this.onDetectLocation,
    required this.onLocationChanged,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final TextEditingController noteController;
  final String? locationName;
  final bool detectingLocation;
  final VoidCallback onDetectLocation;
  final ValueChanged<String?> onLocationChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Collapsed state: tappable chips row ──────────────────
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(
                  expanded ? AppIcons.expandLess : AppIcons.expandMore,
                  size: AppSizes.iconXs,
                  color: cs.outline,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  context.l10n.transaction_optional_details,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: cs.outline,
                  ),
                ),
                const Spacer(),
                // Quick-access chips when collapsed
                if (!expanded) ...[
                  _QuickChip(
                    icon: AppIcons.calendar,
                    label: context.l10n.date_today,
                  ),
                  const SizedBox(width: AppSizes.xs),
                  if (locationName != null)
                    _QuickChip(
                      icon: AppIcons.location,
                      label: locationName!,
                    ),
                ],
              ],
            ),
          ),

          // ── Expanded state: full form fields ─────────────────────
          AnimatedSize(
            duration:
                context.reduceMotion ? Duration.zero : AppDurations.animQuick,
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: AppSizes.sm),
                    child: Column(
                      children: [
                        AppDatePicker(
                          selectedDate: date,
                          onDateChanged: onDateChanged,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        AppTextField(
                          label: context.l10n.transaction_note,
                          hint: context.l10n.transaction_note_hint,
                          controller: noteController,
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        // ── Location ──────────────────────────────
                        Row(
                          children: [
                            const Icon(
                              AppIcons.location,
                              size: AppSizes.iconXs,
                            ),
                            const SizedBox(width: AppSizes.xs),
                            Expanded(
                              child: locationName != null
                                  ? Text(
                                      locationName!,
                                      style: context.textStyles.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Text(
                                      context.l10n.location_hint,
                                      style: context.textStyles.bodySmall
                                          ?.copyWith(
                                        color: cs.outline,
                                      ),
                                    ),
                            ),
                            if (locationName != null)
                              IconButton(
                                icon: const Icon(
                                  AppIcons.close,
                                  size: AppSizes.iconXs,
                                ),
                                onPressed: () => onLocationChanged(null),
                                visualDensity: VisualDensity.compact,
                                tooltip: context.l10n.common_delete,
                              ),
                            const SizedBox(width: AppSizes.xs),
                            TextButton(
                              onPressed:
                                  detectingLocation ? null : onDetectLocation,
                              child: detectingLocation
                                  ? const SizedBox(
                                      width: AppSizes.md,
                                      height: AppSizes.md,
                                      child: CircularProgressIndicator(
                                        strokeWidth:
                                            AppSizes.spinnerStrokeWidth,
                                      ),
                                    )
                                  : Text(
                                      context.l10n.location_detect,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Quick chip (compact label for collapsed optional section) ────────────

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconXxs2, color: cs.primary),
          const SizedBox(width: AppSizes.xs),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Category picker bottom sheet ──────────────────────────────────────────

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryEntity> categories;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: AppSizes.sheetInitialSize,
      minChildSize: AppSizes.sheetSmallInitialSize,
      maxChildSize: AppSizes.sheetMaxSize,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
            width: AppSizes.dragHandleWidth,
            height: AppSizes.dragHandleHeight,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusXs),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.l10n.transaction_category_picker,
                style: ctx.textStyles.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Expanded(
            child: GridView.builder(
              controller: scrollController,
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md,
                AppSizes.xs,
                AppSizes.md,
                AppSizes.bottomScrollPadding,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.85,
                crossAxisSpacing: AppSizes.xs,
                mainAxisSpacing: AppSizes.xs,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final color = ColorUtils.fromHex(cat.colorHex);
                final isSelected = cat.id == selectedId;
                return GestureDetector(
                  onTap: () => onSelected(cat.id),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: AppSizes.categoryChipSize,
                        height: AppSizes.categoryChipSize,
                        decoration: isSelected
                            ? BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.borderRadiusMd,
                                ),
                                border: Border.all(
                                  color: cs.primary,
                                  width: AppSizes.borderWidthFocus,
                                ),
                              )
                            : null,
                        child: Icon(
                          CategoryIconMapper.fromName(cat.iconName),
                          size: AppSizes.iconMd,
                          color: isSelected ? cs.primary : color,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        cat.displayName(ctx.languageCode),
                        style: ctx.textStyles.labelSmall,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
