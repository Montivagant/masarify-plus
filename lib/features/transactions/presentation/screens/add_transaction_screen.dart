import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

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
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_date_picker.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Core transaction entry screen — supports both add and edit modes.
///
/// Layout (≤ 4 taps to save):
///   Zone 1  Type toggle (مصروف | دخل)
///   Zone 2  Amount display
///   Zone 3  Category chips (top 6 + "الكل" overflow)
///   Zone 4  Optional fields (collapsed by default)
///           Calculator keypad fills remaining space
///   Sticky save button in bottomNavigationBar
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
    if (wallets.isNotEmpty) setState(() => _walletId = wallets.first.id);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.location_failed)),
      );
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

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
      // R5-C1 fix: use firstOrNull to avoid StateError on empty list
      final cat = cats.where((c) => c.id == categoryId).firstOrNull ??
          cats.firstOrNull;
      if (cat == null) {
        // IM-27 fix: reset loading and show error instead of silently aborting
        setState(() => _loading = false);
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
      }

      HapticFeedback.mediumImpact();
      if (!mounted) return;

      // Check for goal keyword match and prompt with SnackBar.
      final match = _matchGoalWithName(title, note);
      if (match != null) {
        final messenger = ScaffoldMessenger.of(context);
        final l10n = context.l10n;
        messenger.showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
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
                  // Goal linking is best-effort; failure is acceptable
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
            maxHeight: MediaQuery.sizeOf(ctx).height * AppSizes.bottomSheetHeightRatio,
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
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.md, 0, AppSizes.md, AppSizes.sm,
                ),
                child: Text(
                  context.l10n.transaction_wallet_picker,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: wallets.map(
                    (w) => ListTile(
                      leading: const Icon(AppIcons.wallet),
                      title: Text(w.name),
                      trailing:
                          _walletId == w.id ? const Icon(AppIcons.check) : null,
                      onTap: () {
                        setState(() => _walletId = w.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  ).toList(),
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
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final typeCats =
        allCats.where((c) => c.type == _type || c.type == 'both').toList();
    final topCats = typeCats.take(6).toList();

    final typeColor =
        _type == 'income' ? context.appTheme.incomeColor : context.appTheme.expenseColor;
    final canSave =
        _amountPiastres > 0 && _selectedCategoryId != null && _walletId != null;

    return Scaffold(
      appBar: AppAppBar(
        title: widget.editId != null
            ? context.l10n.transaction_edit_title
            : context.l10n.transactions_add,
        actions: [
          ref.watch(walletsProvider).when(
            data: (wallets) {
              final w = wallets.where((w) => w.id == _walletId).firstOrNull;
              if (w == null) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: _showWalletPicker,
                label: Text(w.name, overflow: TextOverflow.ellipsis),
                icon: const Icon(AppIcons.wallet, size: AppSizes.iconXs),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Zone 1: Type toggle ──────────────────────────────────────
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
              onSelectionChanged: (v) => setState(() {
                _type = v.first;
                _selectedCategoryId = null;
              }),
            ),
          ),

          // ── Zone 2: Amount input (native keyboard) ─────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
              vertical: AppSizes.xs,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: AppSizes.opacityLight),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              ),
              child: AmountInput(
                initialPiastres: _amountPiastres,
                onAmountChanged: (p) => setState(() => _amountPiastres = p),
                autofocus: widget.editId == null,
                textColor: typeColor,
              ),
            ),
          ),

          // ── WS-10: Title input ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
              vertical: AppSizes.xs,
            ),
            child: AppTextField(
              label: context.l10n.transaction_title_label,
              hint: context.l10n.transaction_title_hint,
              controller: _titleController,
            ),
          ),

          // ── Zone 3: Category chips ───────────────────────────────────
          SizedBox(
            height: AppSizes.categoryChipSize,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              itemCount: topCats.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
              itemBuilder: (_, i) {
                if (i == topCats.length) {
                  return ActionChip(
                    label: Text(context.l10n.common_all),
                    avatar: const Icon(AppIcons.expandMore, size: AppSizes.iconXxs2),
                    onPressed: () => _showAllCategories(typeCats),
                  );
                }
                final cat = topCats[i];
                final color = ColorUtils.fromHex(cat.colorHex);
                final isSelected = cat.id == _selectedCategoryId;
                return FilterChip(
                  selected: isSelected,
                  avatar: Icon(
                    CategoryIconMapper.fromName(cat.iconName),
                    size: AppSizes.iconXs,
                    color: isSelected ? cs.onSecondaryContainer : color,
                  ),
                  label: Text(cat.displayName(context.languageCode)),
                  onSelected: (_) {
                    setState(() => _selectedCategoryId = cat.id);
                    // WS-10: auto-fill title on category selection if empty.
                    if (_titleController.text.trim().isEmpty) {
                      _titleController.text =
                          cat.displayName(context.languageCode);
                    }
                  },
                  showCheckmark: false,
                );
              },
            ),
          ),
          const SizedBox(height: AppSizes.xs),

          // ── Zone 4: Optional fields ──────────────────────────────────
          _OptionalSection(
            expanded: _showOptional,
            onToggle: () => setState(() => _showOptional = !_showOptional),
            date: _date,
            onDateChanged: (d) => setState(() => _date = d),
            noteController: _noteController,
            locationName: _locationName,
            detectingLocation: _detectingLocation,
            onDetectLocation: _detectLocation,
            onLocationChanged: (v) => setState(() => _locationName = v),
          ),

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
            onPressed: canSave && !_loading ? _save : null,
            isLoading: _loading,
            icon: AppIcons.check,
          ),
        ),
      ),
    );
  }
}

// ── Optional section ──────────────────────────────────────────────────────

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
              vertical: AppSizes.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expanded ? AppIcons.expandLess : AppIcons.expandMore,
                  size: AppSizes.iconXs,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  context.l10n.transaction_optional_details,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSizes.screenHPadding,
                    AppSizes.xs,
                    AppSizes.screenHPadding,
                    AppSizes.sm,
                  ),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : Text(
                                    context.l10n.location_hint,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline,
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
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
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
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(context.l10n.location_detect),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
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
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
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
                style: Theme.of(ctx).textTheme.titleMedium,
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
                        decoration: BoxDecoration(
                          color: isSelected
                              ? cs.primaryContainer
                              : color.withValues(alpha: AppSizes.opacityLight),
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadiusMd),
                          border: isSelected
                              ? Border.all(color: cs.primary, width: 2)
                              : null,
                        ),
                        child: Icon(
                          CategoryIconMapper.fromName(cat.iconName),
                          size: AppSizes.iconSm,
                          color: isSelected ? cs.primary : color,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        cat.displayName(ctx.languageCode),
                        style: Theme.of(ctx).textTheme.labelSmall,
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
