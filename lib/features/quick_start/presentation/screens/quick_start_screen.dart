import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../domain/quick_start_service.dart';

/// Wallet type options for the "Other" custom wallet picker.
const _kWalletTypes = [
  ('bank', 'Bank'),
  ('mobile_wallet', 'Mobile Wallet'),
  ('credit_card', 'Credit Card'),
  ('prepaid_card', 'Prepaid Card'),
  ('investment', 'Investment'),
];

/// 5-step offline Quick Start wizard — zero AI tokens.
class QuickStartScreen extends ConsumerStatefulWidget {
  const QuickStartScreen({super.key});

  @override
  ConsumerState<QuickStartScreen> createState() => _QuickStartScreenState();
}

class _QuickStartScreenState extends ConsumerState<QuickStartScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _busy = false;

  // ── Step 1: Money sources
  final _selectedSources = <String>{};
  // Custom "Other" wallet fields
  bool _otherSourceSelected = false;
  String _customWalletName = '';
  String _customWalletType = 'bank';

  // ── Step 2: Spending categories
  final _selectedCategories = <String>{};
  // key -> l10n label for display in Steps 3/4
  final _categoryLabels = <String, String>{};

  // ── Step 3: Budget amounts (categoryName -> piastres)
  final _budgetAmounts = <String, int>{};

  // ── Step 4: Bills
  final _selectedBills = <String>{};
  final _billAmounts = <String, int>{};
  final _billLabels = <String, String>{};
  // Custom bills list: [{name, amount}]
  final _customBills = <Map<String, dynamic>>[];
  bool _showCustomBillForm = false;
  String _customBillName = '';
  int _customBillAmount = 20000; // default 200 EGP

  // ── Step 5: Goals
  String? _selectedGoal;
  String? _selectedGoalLabel;
  int _goalAmount = 0;
  // Custom goal fields
  bool _customGoalSelected = false;
  String _customGoalName = '';

  static const _totalSteps = 5;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // Dismiss keyboard before navigating
    FocusScope.of(context).unfocus();
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: AppDurations.pageTransition,
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _previousStep() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: AppDurations.pageTransition,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final service = QuickStartService(
        walletRepo: ref.read(walletRepositoryProvider),
        budgetRepo: ref.read(budgetRepositoryProvider),
        recurringRepo: ref.read(recurringRuleRepositoryProvider),
        goalRepo: ref.read(goalRepositoryProvider),
      );

      // Step 1: Create wallets (use l10n labels for DB names)
      final l10n = context.l10n;
      for (final source in _selectedSources) {
        final (name, type) = switch (source) {
          'bank' => (l10n.wallet_type_bank_short, 'bank'),
          'mobile' => (l10n.wallet_type_mobile_wallet_short, 'mobile_wallet'),
          _ => (l10n.wallet_type_bank_short, 'bank'),
        };
        await service.createWalletIfNeeded(name: name, type: type);
      }

      // Step 1 "Other": create custom wallet
      if (_otherSourceSelected && _customWalletName.trim().isNotEmpty) {
        await service.createWalletIfNeeded(
          name: _customWalletName.trim(),
          type: _customWalletType,
        );
      }

      // Step 3: Create budgets
      if (_budgetAmounts.isNotEmpty) {
        final categories = ref.read(categoriesProvider).valueOrNull ?? [];
        final now = DateTime.now();
        final catAmounts = <int, int>{};
        for (final entry in _budgetAmounts.entries) {
          final cat = _findCategoryByKeyword(entry.key, categories);
          if (cat != null) {
            catAmounts[cat.id] = entry.value;
          }
        }
        if (catAmounts.isNotEmpty) {
          await service.createBudgets(
            categoryAmounts: catAmounts,
            month: now.month,
            year: now.year,
          );
        }
      }

      // Step 4: Create recurring bills
      final allBills = <String>{..._selectedBills};
      final allBillAmounts = <String, int>{..._billAmounts};
      final allBillLabels = <String, String>{..._billLabels};

      // Merge custom bills into the maps
      for (var i = 0; i < _customBills.length; i++) {
        final cb = _customBills[i];
        final key = '_custom_$i';
        allBills.add(key);
        allBillLabels[key] = cb['name'] as String;
        allBillAmounts[key] = cb['amount'] as int;
      }

      if (allBills.isNotEmpty) {
        final wallets = ref.read(walletsProvider).valueOrNull ?? [];
        final activeWallet = wallets.isNotEmpty ? wallets.first : null;
        final categories = ref.read(categoriesProvider).valueOrNull ?? [];
        final billsCat = _findCategoryByKeyword('Bills', categories);

        if (activeWallet != null && billsCat != null) {
          for (final bill in allBills) {
            final amount = allBillAmounts[bill] ?? 20000; // default 200 EGP
            await service.createRecurringBill(
              walletId: activeWallet.id,
              categoryId: billsCat.id,
              amount: amount,
              title: allBillLabels[bill] ?? bill,
              frequency: 'monthly',
            );
          }
        }
      }

      // Step 5: Create goal
      if (_selectedGoal != null && _goalAmount > 0) {
        final goalName = _customGoalSelected
            ? (_customGoalName.trim().isNotEmpty
                ? _customGoalName.trim()
                : _selectedGoalLabel ?? _selectedGoal!)
            : (_selectedGoalLabel ?? _selectedGoal!);
        await service.createGoal(
          name: goalName,
          targetAmount: _goalAmount,
        );
      }

      // Mark wizard as done
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.markQuickStartDone();

      if (!mounted) return;
      SnackHelper.showSuccess(context, context.l10n.quick_start_done_title);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      SnackHelper.showError(context, context.l10n.common_error_generic);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  CategoryEntity? _findCategoryByKeyword(
    String keyword,
    List<CategoryEntity> categories,
  ) {
    final q = keyword.toLowerCase();
    for (final c in categories) {
      if (c.name.toLowerCase() == q ||
          c.nameAr.toLowerCase() == q ||
          c.name.toLowerCase().contains(q)) {
        return c;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppAppBar(title: l10n.quick_start_title),
      body: Column(
        children: [
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
              vertical: AppSizes.sm,
            ),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: Text(
              '${_currentStep + 1} / $_totalSteps',
              style: context.textStyles.labelSmall?.copyWith(
                color: context.colors.outline,
              ),
            ),
          ),

          // Steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Sources(context),
                _buildStep2Categories(context),
                _buildStep3Budgets(context),
                _buildStep4Bills(context),
                _buildStep5Goals(context),
              ],
            ),
          ),
        ],
      ),
      // Navigation buttons pinned above keyboard
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              if (_currentStep > 0)
                TextButton(
                  onPressed: _previousStep,
                  child: Text(l10n.common_back),
                ),
              const Spacer(),
              if (_currentStep < _totalSteps - 1)
                TextButton(
                  onPressed: _nextStep,
                  child: Text(l10n.common_skip),
                ),
              const SizedBox(width: AppSizes.sm),
              AppButton(
                label: _currentStep == _totalSteps - 1
                    ? l10n.common_done
                    : l10n.common_next,
                icon: _currentStep == _totalSteps - 1
                    ? AppIcons.check
                    : AppIcons.arrowForward,
                onPressed: _busy ? null : _nextStep,
                isLoading: _busy,
                isFullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Money Sources ──────────────────────────────────────────────

  Widget _buildStep1Sources(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      ('bank', l10n.quick_start_source_bank, AppIcons.bank),
      ('mobile', l10n.quick_start_source_mobile, AppIcons.phone),
    ];

    return _StepBody(
      title: l10n.quick_start_step_wallets,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              ...options.map((o) {
                final selected = _selectedSources.contains(o.$1);
                return FilterChip(
                  label: Text(o.$2),
                  avatar: Icon(o.$3, size: AppSizes.iconXs),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedSources.add(o.$1);
                    } else {
                      _selectedSources.remove(o.$1);
                    }
                  }),
                );
              }),
              // "Other" chip
              FilterChip(
                label: Text(l10n.quick_start_source_other),
                avatar: const Icon(AppIcons.add, size: AppSizes.iconXs),
                selected: _otherSourceSelected,
                onSelected: (v) => setState(() {
                  _otherSourceSelected = v;
                }),
              ),
            ],
          ),
          // Custom wallet fields when "Other" is selected
          if (_otherSourceSelected) ...[
            const SizedBox(height: AppSizes.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: l10n.quick_start_custom_wallet_name,
                      hintText: l10n.wallet_name_hint_example,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => _customWalletName = v,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    l10n.quick_start_wallet_type_label,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: context.colors.outline,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: _kWalletTypes.map((wt) {
                      final selected = _customWalletType == wt.$1;
                      return ChoiceChip(
                        label: Text(wt.$2),
                        selected: selected,
                        onSelected: (v) {
                          if (v) setState(() => _customWalletType = wt.$1);
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 2: Spending Categories ────────────────────────────────────────

  Widget _buildStep2Categories(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      ('Food', l10n.quick_start_category_food),
      ('Rent', l10n.quick_start_category_rent),
      ('Transport', l10n.quick_start_category_transport),
      ('Bills', l10n.quick_start_category_bills),
      ('Shopping', l10n.quick_start_category_shopping),
      ('Health', l10n.quick_start_category_health),
      ('Education', l10n.quick_start_category_education),
      ('Other', l10n.quick_start_category_other),
    ];

    return _StepBody(
      title: l10n.quick_start_step_categories,
      child: Wrap(
        spacing: AppSizes.sm,
        runSpacing: AppSizes.sm,
        children: options.map((o) {
          final selected = _selectedCategories.contains(o.$1);
          return FilterChip(
            label: Text(o.$2),
            selected: selected,
            onSelected: (v) => setState(() {
              if (v) {
                _selectedCategories.add(o.$1);
                _categoryLabels[o.$1] = o.$2;
                // Pre-fill budget with default
                _budgetAmounts[o.$1] = QuickStartService.defaultBudgetFor(o.$1);
              } else {
                _selectedCategories.remove(o.$1);
                _categoryLabels.remove(o.$1);
                _budgetAmounts.remove(o.$1);
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 3: Budget Amounts ─────────────────────────────────────────────

  Widget _buildStep3Budgets(BuildContext context) {
    final l10n = context.l10n;

    if (_selectedCategories.isEmpty) {
      return _StepBody(
        title: l10n.quick_start_step_budgets,
        child: Text(
          l10n.budgets_empty_sub,
          style: context.textStyles.bodyMedium?.copyWith(
            color: context.colors.outline,
          ),
        ),
      );
    }

    return _StepBody(
      title: l10n.quick_start_step_budgets,
      child: Column(
        children: _selectedCategories.map((cat) {
          final amount = _budgetAmounts[cat] ?? 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: GlassCard(
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _categoryLabels[cat] ?? cat,
                      style: context.textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: (amount / 100).toStringAsFixed(0),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        suffixText: MoneyFormatter.currencySymbol(),
                        hintText: l10n.quick_start_budget_hint,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (parsed != null && parsed > 0) {
                          _budgetAmounts[cat] = parsed * 100;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Step 4: Bills ──────────────────────────────────────────────────────

  Widget _buildStep4Bills(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      ('Internet', l10n.quick_start_bill_internet, 20000),
      ('Phone', l10n.quick_start_bill_phone, 15000),
      ('Electricity', l10n.quick_start_bill_electricity, 30000),
      ('Gas', l10n.quick_start_bill_gas, 10000),
      ('Gym', l10n.quick_start_bill_gym, 50000),
      ('Subscription', l10n.quick_start_bill_subscription, 10000),
    ];

    return _StepBody(
      title: l10n.quick_start_step_bills,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              ...options.map((o) {
                final selected = _selectedBills.contains(o.$1);
                return FilterChip(
                  label: Text(o.$2),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) {
                      _selectedBills.add(o.$1);
                      _billLabels[o.$1] = o.$2;
                      _billAmounts[o.$1] = o.$3;
                    } else {
                      _selectedBills.remove(o.$1);
                      _billLabels.remove(o.$1);
                      _billAmounts.remove(o.$1);
                    }
                  }),
                );
              }),
              // "Custom" chip to add custom bills
              FilterChip(
                label: Text(l10n.quick_start_bill_other),
                avatar: const Icon(AppIcons.add, size: AppSizes.iconXs),
                selected: _showCustomBillForm,
                onSelected: (v) => setState(() {
                  _showCustomBillForm = v;
                }),
              ),
            ],
          ),
          // Amount editors for selected preset bills
          if (_selectedBills.isNotEmpty) ...[
            const SizedBox(height: AppSizes.md),
            ..._selectedBills.map(
              (bill) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  children: [
                    Expanded(child: Text(_billLabels[bill] ?? bill)),
                    SizedBox(
                      width: AppSizes.shimmerWidthLg + AppSizes.xl,
                      child: TextFormField(
                        initialValue: ((_billAmounts[bill] ?? 0) / 100)
                            .toStringAsFixed(0),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          suffixText: MoneyFormatter.currencySymbol(),
                          isDense: true,
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) {
                          final parsed = int.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            _billAmounts[bill] = parsed * 100;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          // Custom bills already added
          if (_customBills.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            ..._customBills.asMap().entries.map((entry) {
              final i = entry.key;
              final cb = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(cb['name'] as String),
                    ),
                    Text(
                      '${((cb['amount'] as int) / 100).toStringAsFixed(0)}'
                      ' ${MoneyFormatter.currencySymbol()}',
                      style: context.textStyles.bodyMedium,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    IconButton(
                      icon: Icon(
                        AppIcons.close,
                        size: AppSizes.iconXs,
                        color: context.colors.error,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _customBills.removeAt(i);
                      }),
                    ),
                  ],
                ),
              );
            }),
          ],
          // Custom bill form
          if (_showCustomBillForm) ...[
            const SizedBox(height: AppSizes.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: l10n.quick_start_bill_name_hint,
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (v) => _customBillName = v,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          initialValue: '200',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            suffixText: MoneyFormatter.currencySymbol(),
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            final parsed = int.tryParse(v);
                            if (parsed != null && parsed > 0) {
                              _customBillAmount = parsed * 100;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      icon: const Icon(AppIcons.add, size: AppSizes.iconXs),
                      label: Text(l10n.quick_start_add_another),
                      onPressed: () {
                        if (_customBillName.trim().isEmpty) return;
                        setState(() {
                          _customBills.add({
                            'name': _customBillName.trim(),
                            'amount': _customBillAmount,
                          });
                          _customBillName = '';
                          _customBillAmount = 20000;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Step 5: Goals ──────────────────────────────────────────────────────

  Widget _buildStep5Goals(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      ('Emergency Fund', l10n.quick_start_goal_emergency),
      ('Vacation', l10n.quick_start_goal_vacation),
      ('Car', l10n.quick_start_goal_car),
      ('Wedding', l10n.quick_start_goal_wedding),
      ('Education', l10n.quick_start_goal_education),
    ];

    return _StepBody(
      title: l10n.quick_start_step_goals,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              ...options.map((o) {
                final selected = _selectedGoal == o.$1 && !_customGoalSelected;
                return ChoiceChip(
                  label: Text(o.$2),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    _selectedGoal = v ? o.$1 : null;
                    _selectedGoalLabel = v ? o.$2 : null;
                    _customGoalSelected = false;
                  }),
                );
              }),
              // "Custom" chip
              ChoiceChip(
                label: Text(l10n.quick_start_goal_custom),
                selected: _customGoalSelected,
                onSelected: (v) => setState(() {
                  _customGoalSelected = v;
                  if (v) {
                    _selectedGoal = 'Custom';
                    _selectedGoalLabel = l10n.quick_start_goal_custom;
                  } else {
                    _selectedGoal = null;
                    _selectedGoalLabel = null;
                  }
                }),
              ),
            ],
          ),
          if (_selectedGoal != null) ...[
            const SizedBox(height: AppSizes.lg),
            // Custom goal name field
            if (_customGoalSelected) ...[
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.quick_start_goal_custom_name,
                  hintText: l10n.goal_name_hint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => _customGoalName = v,
              ),
              const SizedBox(height: AppSizes.md),
            ],
            TextFormField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.quick_start_goal_target,
                suffixText: MoneyFormatter.currencySymbol(),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                final parsed = int.tryParse(v);
                if (parsed != null && parsed > 0) {
                  _goalAmount = parsed * 100; // to piastres
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Reusable step body wrapper with title.
class _StepBody extends StatelessWidget {
  const _StepBody({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.md,
      ),
      children: [
        Text(
          title,
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSizes.lg),
        child,
      ],
    );
  }
}
