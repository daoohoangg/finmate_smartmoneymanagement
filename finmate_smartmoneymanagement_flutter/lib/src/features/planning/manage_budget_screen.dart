import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../../shared/widgets/primary_button.dart';
import '../budget/models/budget.dart';
import '../budget/subcategory_budget_detail_screen.dart';
import '../budget/services/budget_service.dart';
import '../categories/models/category.dart';
import '../categories/services/category_service.dart';
import '../categories/utils/category_ui.dart';
import '../dashboard/monthly_dashboard_screen.dart';
import '../transactions/services/transaction_service.dart';
import 'services/allocation_plan_service.dart';
import 'manual_allocation_screen.dart';

class ManageBudgetScreen extends StatefulWidget {
  const ManageBudgetScreen({super.key});

  static const String routeName = '/manage-budget';

  @override
  State<ManageBudgetScreen> createState() => _ManageBudgetScreenState();
}

class _ManageBudgetScreenState extends State<ManageBudgetScreen> {
  final CategoryService _categoryService = CategoryService();
  final TransactionService _transactionService = TransactionService();
  final AllocationPlanService _allocationPlanService = AllocationPlanService();
  final BudgetService _budgetService = BudgetService();

  List<_MainCategorySummary> _mainCategories = const <_MainCategorySummary>[];
  bool _isLoadingCategoryOverview = false;
  String? _categoryOverviewError;
  double _spendableAmount = 0;
  AllocationPlan _allocationPlan = const AllocationPlan(
    necessary: 60,
    accumulation: 20,
    flexibility: 20,
  );

  @override
  void initState() {
    super.initState();
    _loadCategoryOverview();
  }

  Future<void> _loadCategoryOverview() async {
    setState(() {
      _isLoadingCategoryOverview = true;
      _categoryOverviewError = null;
    });

    try {
      final responses = await Future.wait<dynamic>([
        _categoryService.getCategories(type: CategoryType.expense),
        _transactionService.getTransactions(),
        _allocationPlanService.getAllocationPlan(),
        _budgetService.getBudgets(),
      ]);
      if (!mounted) return;

      final categories = responses[0] as List<Category>;
      final transactions = responses[1] as List<Map<String, dynamic>>;
      final allocationPlan = responses[2] as AllocationPlan;
      final budgets = _filterSpendingBudgets(responses[3] as List<Budget>);
      final budgetByCategory = <int, Budget>{
        for (final budget in budgets) budget.categoryId: budget,
      };

      final tree = _buildExpenseCategoryTree(categories);
      final spendableAmount = _calculateSpendableAmount(transactions);

      final parentEntries = tree.parentCategories.asMap().entries.toList();
      final summaries = parentEntries.map((entry) {
        final index = entry.key;
        final parentCategory = entry.value;
        final children =
            tree.childrenByParent[parentCategory.id] ?? const <Category>[];

        final allocatedPercent = _allocatedPercentForParent(
          parentCategory,
          allocationPlan,
          fallbackIndex: index,
        );
        final allocatedAmount = spendableAmount * (allocatedPercent / 100);

        final childSummaries = children.map((child) {
          final budget = budgetByCategory[child.id];
          return _SubCategorySummary(
            categoryId: child.id,
            name: child.name,
            budgetId: budget?.id,
            period: budget?.period,
            amount: budget?.amountLimit ?? 0,
            available: budget?.available ?? 0,
            hasBudget: budget != null,
          );
        }).toList();

        return _MainCategorySummary(
          categoryId: parentCategory.id,
          name: parentCategory.name,
          icon: CategoryUi.iconFromString(parentCategory.icon),
          color: CategoryUi.colorFromString(
            parentCategory.color,
            fallback: AppColors.primaryBlue,
          ),
          amount: allocatedAmount,
          allocatedPercent: allocatedPercent,
          spendableAmount: spendableAmount,
          subCategories: childSummaries,
        );
      }).toList();

      setState(() {
        _allocationPlan = allocationPlan;
        _spendableAmount = spendableAmount;
        _mainCategories = summaries;
        _isLoadingCategoryOverview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryOverviewError = e.toString();
        _isLoadingCategoryOverview = false;
      });
    }
  }

  ({List<Category> parentCategories, Map<int, List<Category>> childrenByParent})
  _buildExpenseCategoryTree(List<Category> categories) {
    final expenseCategories = categories
        .where((category) => category.type == CategoryType.expense)
        .toList();

    final parentCandidates = expenseCategories
        .where((category) => category.parentId == null)
        .toList();
    final selectedParents = _selectPrimaryParentCategories(parentCandidates);
    final selectedParentIds = selectedParents.map((item) => item.id).toSet();

    final childrenByParent = <int, List<Category>>{};
    for (final category in expenseCategories) {
      final parentId = category.parentId;
      if (parentId == null || !selectedParentIds.contains(parentId)) continue;
      childrenByParent.putIfAbsent(parentId, () => <Category>[]).add(category);
    }

    for (final children in childrenByParent.values) {
      children.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return (
      parentCategories: selectedParents,
      childrenByParent: childrenByParent,
    );
  }

  List<Category> _selectPrimaryParentCategories(
    List<Category> parentCandidates,
  ) {
    final candidates = List<Category>.from(parentCandidates)
      ..sort((a, b) {
        final groupDiff =
            _categoryGroupOrder(a.group) - _categoryGroupOrder(b.group);
        if (groupDiff != 0) return groupDiff;
        if (a.isSystemCategory != b.isSystemCategory) {
          return a.isSystemCategory ? 1 : -1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final selected = <Category>[];
    const preferredGroups = <CategoryGroup>[
      CategoryGroup.necessary,
      CategoryGroup.accumulation,
      CategoryGroup.flexibility,
    ];

    for (final group in preferredGroups) {
      for (final candidate in candidates) {
        if (candidate.group == group &&
            !selected.any((item) => item.id == candidate.id)) {
          selected.add(candidate);
          break;
        }
      }
    }

    for (final candidate in candidates) {
      if (selected.any((item) => item.id == candidate.id)) continue;
      selected.add(candidate);
      if (selected.length >= 3) break;
    }

    return selected.take(3).toList();
  }

  int _categoryGroupOrder(CategoryGroup? group) {
    switch (group) {
      case CategoryGroup.necessary:
        return 0;
      case CategoryGroup.accumulation:
        return 1;
      case CategoryGroup.flexibility:
        return 2;
      case null:
        return 100;
    }
  }

  double _calculateSpendableAmount(List<Map<String, dynamic>> transactions) {
    double income = 0;
    double expense = 0;
    for (final transaction in transactions) {
      final type = transaction['type']?.toString().toUpperCase();
      final amount = _parseDouble(transaction['amount']);
      if (type == 'INCOME') {
        income += amount;
      } else if (type == 'EXPENSE') {
        if (_isFundContributionTransaction(transaction)) continue;
        expense += amount;
      }
    }
    return max(0.0, income - expense);
  }

  List<Budget> _filterSpendingBudgets(List<Budget> budgets) {
    return budgets.where((budget) => !_isFundBudget(budget)).toList();
  }

  bool _isFundBudget(Budget budget) {
    final budgetName = budget.name.trim().toLowerCase();
    final categoryName = budget.categoryName.trim().toLowerCase();
    if (budgetName.isNotEmpty && categoryName.isNotEmpty) {
      if (budgetName != categoryName) return true;
    }
    return false;
  }

  bool _isFundContributionTransaction(Map<String, dynamic> transaction) {
    final note = transaction['note']?.toString().trim().toLowerCase() ?? '';
    return note.startsWith('fund contribution -');
  }

  double _allocatedPercentForParent(
    Category parent,
    AllocationPlan plan, {
    required int fallbackIndex,
  }) {
    switch (parent.group) {
      case CategoryGroup.necessary:
        return plan.necessary;
      case CategoryGroup.accumulation:
        return plan.accumulation;
      case CategoryGroup.flexibility:
        return plan.flexibility;
      case null:
        final fallback = <double>[
          plan.necessary,
          plan.accumulation,
          plan.flexibility,
        ];
        if (fallbackIndex < 0 || fallbackIndex >= fallback.length) {
          return 0;
        }
        return fallback[fallbackIndex];
    }
  }

  double _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatVnd(double amount) {
    final rounded = amount.round();
    final digits = rounded.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix$digits VND';
  }

  // ignore: unused_element
  Future<void> _openTransferSheet(
    _MainCategorySummary mainCategory, {
    int? initialFromCategoryId,
  }) async {
    final transferables = mainCategory.subCategories
        .where((item) => item.hasBudget == true)
        .toList();
    if (transferables.length < 2) {
      _showSnack('Need at least 2 subcategories with budget to transfer');
      return;
    }
    var from = transferables.firstWhere(
      (item) => item.categoryId == initialFromCategoryId,
      orElse: () => transferables.first,
    );
    var to = transferables.firstWhere(
      (item) => item.categoryId != from.categoryId,
      orElse: () => transferables.last,
    );
    final amountController = TextEditingController();
    var isSubmitting = false;

    final moved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final toOptions = transferables
                  .where((item) => item.categoryId != from.categoryId)
                  .toList();
              if (toOptions.every((item) => item.categoryId != to.categoryId)) {
                to = toOptions.first;
              }

              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Move Between Subcategories',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        mainCategory.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: from.categoryId,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                      ),
                      items: transferables
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item.categoryId,
                              child: Text(
                                '${item.name} (Available ${_formatVnd(item.available ?? 0.0)})',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              final selected = transferables.firstWhere(
                                (item) => item.categoryId == value,
                              );
                              setModalState(() => from = selected);
                            },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: to.categoryId,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                      ),
                      items: toOptions
                          .map(
                            (item) => DropdownMenuItem<int>(
                              value: item.categoryId,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              final selected = transferables.firstWhere(
                                (item) => item.categoryId == value,
                              );
                              setModalState(() => to = selected);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      enabled: !isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: '0',
                        suffixText: 'VND',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Move money',
                      color: AppColors.primaryBlue,
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final amount = _parseDouble(
                                amountController.text.trim(),
                              );
                              if (amount <= 0) {
                                _showSnack('Please enter a valid amount');
                                return;
                              }
                              if (from.categoryId == to.categoryId) {
                                _showSnack(
                                  'Source and target subcategory must be different',
                                );
                                return;
                              }
                              if (amount > (from.available ?? 0)) {
                                _showSnack(
                                  'Amount exceeds available budget in source',
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                await _budgetService.reassignBudget(
                                  fromCategoryId: from.categoryId,
                                  toCategoryId: to.categoryId,
                                  amount: amount,
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.of(sheetContext).pop(true);
                              } catch (e) {
                                if (!mounted) return;
                                _showSnack(e.toString());
                                setModalState(() => isSubmitting = false);
                              }
                            },
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    amountController.dispose();

    if (moved == true && mounted) {
      _showSnack('Budget moved successfully');
      await _loadCategoryOverview();
    }
  }

  num? _parsePositiveAmount(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final parsed = num.tryParse(cleaned);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  BudgetPeriod _defaultPeriodForMainCategory(
    _MainCategorySummary mainCategory,
  ) {
    for (final item in mainCategory.subCategories) {
      if (item.period != null) return item.period!;
    }
    return BudgetPeriod.month;
  }

  Future<void> _openAddMoneyDialog(
    _MainCategorySummary mainCategory,
    _SubCategorySummary subCategory,
  ) async {
    final availableFromMain = mainCategory.remainingAmount;
    if (availableFromMain <= 0) {
      _showSnack('No remaining budget in ${mainCategory.name}');
      return;
    }

    final amountController = TextEditingController();
    final addAmount = await showDialog<num>(
      context: context,
      builder: (dialogContext) {
        String? localError;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Add money to ${subCategory.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current: ${_formatVnd((subCategory.amount ?? 0).toDouble())}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Remaining in ${mainCategory.name}: ${_formatVnd(availableFromMain)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount to allocate',
                      hintText: 'Example: 500000',
                      suffixText: 'VND',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (localError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      localError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = _parsePositiveAmount(amountController.text);
                    if (parsed == null) {
                      setDialogState(
                        () => localError = 'Please enter a valid amount',
                      );
                      return;
                    }
                    if (parsed.toDouble() > availableFromMain) {
                      setDialogState(
                        () => localError =
                            'Exceeds remaining amount in main category',
                      );
                      return;
                    }
                    Navigator.pop(dialogContext, parsed);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    amountController.dispose();
    if (addAmount == null) return;
    if (addAmount.toDouble() > availableFromMain) {
      _showSnack('Amount exceeds remaining main category budget');
      return;
    }

    try {
      if (subCategory.hasBudget == true &&
          subCategory.budgetId != null &&
          subCategory.period != null) {
        final currentAmount = subCategory.amount ?? 0;
        final newAmountLimit = currentAmount + addAmount.toDouble();
        await _budgetService.updateBudgetAmount(
          budgetId: subCategory.budgetId!,
          amountLimit: newAmountLimit,
          period: subCategory.period!,
        );
      } else {
        await _budgetService.createBudget(
          name: subCategory.name,
          categoryId: subCategory.categoryId,
          amountLimit: addAmount,
          period: _defaultPeriodForMainCategory(mainCategory),
        );
      }
      if (!mounted) return;
      _showSnack('Budget updated successfully');
      await _loadCategoryOverview();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    }
  }

  Future<void> _openSubCategoryBudgetScreen(
    _MainCategorySummary mainCategory,
    _SubCategorySummary subCategory,
  ) async {
    if (subCategory.hasBudget != true) {
      _showSnack('This subcategory has no budget yet');
      return;
    }
    await Navigator.pushNamed(
      context,
      SubCategoryBudgetDetailScreen.routeName,
      arguments: SubCategoryBudgetDetailArgs(
        categoryId: subCategory.categoryId,
        title: subCategory.name,
        mainCategoryName: mainCategory.name,
        totalBudget: subCategory.amount ?? 0,
        availableBudget: subCategory.available ?? 0,
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToDashboard() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      MonthlyDashboardScreen.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Budget'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.overview,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            ManualAllocationScreen.routeName,
                          ),
                          child: _AllocationOverviewCard(
                            spendableAmount: _spendableAmount,
                            plan: _allocationPlan,
                            formatAmount: _formatVnd,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _MainCategoryOverviewCard(
                          categories: _mainCategories,
                          isLoading: _isLoadingCategoryOverview,
                          error: _categoryOverviewError,
                          formatAmount: _formatVnd,
                          onRetry: _loadCategoryOverview,
                          onAddSubCategory: _openAddMoneyDialog,
                          onOpenSubCategoryScreen: _openSubCategoryBudgetScreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: 'Go to Dashboard',
                color: AppColors.primaryBlue,
                onPressed: _goToDashboard,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainCategorySummary {
  const _MainCategorySummary({
    required this.categoryId,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
    required this.allocatedPercent,
    required this.spendableAmount,
    required this.subCategories,
  });

  final int categoryId;
  final String name;
  final IconData icon;
  final Color color;
  final double? amount;
  final double? allocatedPercent;
  final double? spendableAmount;
  final List<_SubCategorySummary> subCategories;

  double get totalBudget => amount ?? 0.0;
  double get allocatedToSubCategories => subCategories.fold<double>(
    0.0,
    (sum, item) => sum + (item.amount ?? 0.0),
  );
  double get remainingAmount =>
      max<double>(0.0, totalBudget - allocatedToSubCategories);

  bool get canTransfer =>
      subCategories.where((item) => item.hasBudget == true).length >= 2;
}

class _SubCategorySummary {
  const _SubCategorySummary({
    required this.categoryId,
    required this.name,
    required this.budgetId,
    required this.period,
    required this.amount,
    required this.available,
    required this.hasBudget,
  });

  final int categoryId;
  final String name;
  final int? budgetId;
  final BudgetPeriod? period;
  final double? amount;
  final double? available;
  final bool? hasBudget;
}

class _AllocationOverviewCard extends StatelessWidget {
  const _AllocationOverviewCard({
    required this.spendableAmount,
    required this.plan,
    required this.formatAmount,
  });

  final double? spendableAmount;
  final AllocationPlan? plan;
  final String Function(double amount) formatAmount;

  @override
  Widget build(BuildContext context) {
    final safeSpendableAmount = spendableAmount ?? 0.0;
    final safePlan =
        plan ??
        const AllocationPlan(necessary: 0, accumulation: 0, flexibility: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spendable amount',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            formatAmount(safeSpendableAmount),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(
            'Allocated by your plan: ${safePlan.necessary.round()}% / ${safePlan.accumulation.round()}% / ${safePlan.flexibility.round()}%',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MainCategoryOverviewCard extends StatelessWidget {
  const _MainCategoryOverviewCard({
    required this.categories,
    required this.isLoading,
    required this.error,
    required this.formatAmount,
    required this.onRetry,
    required this.onAddSubCategory,
    required this.onOpenSubCategoryScreen,
  });

  final List<_MainCategorySummary>? categories;
  final bool? isLoading;
  final String? error;
  final String Function(double amount) formatAmount;
  final VoidCallback onRetry;
  final Future<void> Function(
    _MainCategorySummary mainCategory,
    _SubCategorySummary subCategory,
  )
  onAddSubCategory;
  final Future<void> Function(
    _MainCategorySummary mainCategory,
    _SubCategorySummary subCategory,
  )
  onOpenSubCategoryScreen;

  @override
  Widget build(BuildContext context) {
    final safeLoading = isLoading == true;
    final safeCategories = categories ?? const <_MainCategorySummary>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3 Main Categories',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Main budgets are calculated from spendable amount by percentage.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (safeLoading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          if (!safeLoading && error != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.primaryRed),
                ),
                const SizedBox(height: 6),
                TextButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          if (!safeLoading && error == null && safeCategories.isEmpty)
            Text(
              'No main categories available.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          if (!safeLoading && error == null && safeCategories.isNotEmpty)
            Column(
              children: safeCategories
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MainCategoryTile(
                        category: category,
                        formatAmount: formatAmount,
                        onAddSubCategory: (subCategory) =>
                            onAddSubCategory(category, subCategory),
                        onOpenSubCategoryScreen: (subCategory) =>
                            onOpenSubCategoryScreen(category, subCategory),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _MainCategoryTile extends StatelessWidget {
  const _MainCategoryTile({
    required this.category,
    required this.formatAmount,
    required this.onAddSubCategory,
    required this.onOpenSubCategoryScreen,
  });

  final _MainCategorySummary category;
  final String Function(double amount) formatAmount;
  final Future<void> Function(_SubCategorySummary subCategory) onAddSubCategory;
  final Future<void> Function(_SubCategorySummary subCategory)
  onOpenSubCategoryScreen;

  @override
  Widget build(BuildContext context) {
    final safeAllocatedAmount = category.amount ?? 0.0;
    final safeAvailableAmount = category.subCategories.fold<double>(
      0.0,
      (sum, item) => sum + (item.available ?? 0.0),
    );
    final safeAllocatedPercent = category.allocatedPercent ?? 0.0;
    final safeSpendableAmount = category.spendableAmount ?? 0.0;
    final safeRemainingAmount = category.remainingAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fieldBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatAmount(safeAvailableAmount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: safeAvailableAmount <= 0
                      ? AppColors.primaryRed
                      : AppColors.primaryBlue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${safeAllocatedPercent.round()}% of ${formatAmount(safeSpendableAmount)} • Target ${formatAmount(safeAllocatedAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Remaining to allocate: ${formatAmount(safeRemainingAmount)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (category.subCategories.isEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'No subcategories',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          if (category.subCategories.isNotEmpty)
            Column(
              children: category.subCategories
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                if (item.hasBudget == true)
                                  Builder(
                                    builder: (context) {
                                      final limitAmount = item.amount ?? 0.0;
                                      final availableAmount =
                                          item.available ?? 0.0;
                                      final spentAmount = max<double>(
                                        0.0,
                                        limitAmount - availableAmount,
                                      );
                                      return Text(
                                        'Budget: ${formatAmount(limitAmount)} • Spent: ${formatAmount(spentAmount)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textMuted,
                                            ),
                                      );
                                    },
                                  ),
                                if (item.hasBudget != true)
                                  Text(
                                    'No budget yet',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.textMuted),
                                  ),
                              ],
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final remainingAmount = item.available ?? 0.0;
                              return Text(
                                formatAmount(remainingAmount),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: remainingAmount <= 0
                                          ? AppColors.primaryRed
                                          : AppColors.primaryBlue,
                                    ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: safeRemainingAmount > 0
                                ? () => onAddSubCategory(item)
                                : null,
                            icon: const Icon(Icons.add, size: 14),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.primaryBlue,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: item.hasBudget == true
                                ? () => onOpenSubCategoryScreen(item)
                                : null,
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                            ),
                            label: const Text('Details'),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              foregroundColor: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
