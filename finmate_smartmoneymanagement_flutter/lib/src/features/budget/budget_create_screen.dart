import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../categories/create_category_screen.dart';
import '../categories/models/category.dart';
import '../categories/services/category_service.dart';
import '../categories/utils/category_ui.dart';
import 'models/budget.dart';
import 'services/budget_service.dart';

class BudgetCreateScreen extends StatefulWidget {
  const BudgetCreateScreen({super.key});

  static const String routeName = '/budget/create';

  @override
  State<BudgetCreateScreen> createState() => _BudgetCreateScreenState();
}

class _BudgetCreateScreenState extends State<BudgetCreateScreen> {
  String _period = 'Month';
  int? _selectedCategoryId;
  int? _selectedParentCategoryId;
  List<Category>? _categories;
  List<Category>? _parentCategories;
  Map<int, List<Category>> _childrenByParent = const <int, List<Category>>{};
  bool _isLoadingCategories = false;
  String? _categoriesError;
  bool _isSaving = false;

  TextEditingController? _nameController;
  TextEditingController? _amountController;
  CategoryService? _categoryService;
  BudgetService? _budgetService;

  CategoryService get _service => _categoryService ??= CategoryService();
  BudgetService get _budget => _budgetService ??= BudgetService();

  @override
  void initState() {
    super.initState();
    _nameController ??= TextEditingController();
    _amountController ??= TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController?.dispose();
    _amountController?.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({int? selectId}) async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });
    try {
      final loadedCategories = await _service.getCategories(
        type: CategoryType.expense,
      );
      if (!mounted) return;

      final categoryTree = _buildExpenseCategoryTree(loadedCategories);
      final parentCategories = categoryTree.parentCategories;
      final childrenByParent = categoryTree.childrenByParent;

      setState(() {
        if (parentCategories.isEmpty) {
          _parentCategories = const <Category>[];
          _childrenByParent = const <int, List<Category>>{};
          _selectedParentCategoryId = null;
          _categories = const <Category>[];
          _selectedCategoryId = null;
          return;
        }

        final currentParentId = _selectedParentCategoryId;
        final nextParentId =
            currentParentId != null &&
                parentCategories.any(
                  (category) => category.id == currentParentId,
                )
            ? currentParentId
            : parentCategories.first.id;

        final childCategories =
            childrenByParent[nextParentId] ?? const <Category>[];
        final desiredChildId = selectId ?? _selectedCategoryId;
        final nextChildId =
            desiredChildId != null &&
                childCategories.any((category) => category.id == desiredChildId)
            ? desiredChildId
            : (childCategories.isNotEmpty ? childCategories.first.id : null);

        _parentCategories = parentCategories;
        _childrenByParent = childrenByParent;
        _selectedParentCategoryId = nextParentId;
        _categories = childCategories;
        _selectedCategoryId = nextChildId;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  ({List<Category> parentCategories, Map<int, List<Category>> childrenByParent})
  _buildExpenseCategoryTree(List<Category> loadedCategories) {
    final expenseCategories = loadedCategories
        .where((category) => category.type == CategoryType.expense)
        .toList();

    final parentCandidates = expenseCategories
        .where((category) => category.parentId == null)
        .toList();
    final parentCategories = _selectPrimaryParentCategories(parentCandidates);
    final parentIds = parentCategories.map((category) => category.id).toSet();

    final childrenByParent = <int, List<Category>>{};
    for (final category in expenseCategories) {
      final parentId = category.parentId;
      if (parentId == null || !parentIds.contains(parentId)) continue;
      childrenByParent.putIfAbsent(parentId, () => <Category>[]).add(category);
    }

    for (final entry in childrenByParent.entries) {
      entry.value.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }

    return (
      parentCategories: parentCategories,
      childrenByParent: childrenByParent,
    );
  }

  List<Category> _selectPrimaryParentCategories(
    List<Category> parentCandidates,
  ) {
    final candidates = List<Category>.from(parentCandidates)
      ..sort((a, b) {
        final groupOrderDiff =
            _categoryGroupOrder(a.group) - _categoryGroupOrder(b.group);
        if (groupOrderDiff != 0) return groupOrderDiff;
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
      for (final category in candidates) {
        if (category.group == group &&
            !selected.any((item) => item.id == category.id)) {
          selected.add(category);
          break;
        }
      }
    }

    for (final category in candidates) {
      if (selected.any((item) => item.id == category.id)) continue;
      selected.add(category);
      if (selected.length >= 3) break;
    }

    if (selected.length > 3) {
      return selected.take(3).toList();
    }
    return selected;
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

  void _selectParentCategory(int parentId) {
    final childCategories = _childrenByParent[parentId] ?? const <Category>[];
    setState(() {
      _selectedParentCategoryId = parentId;
      _categories = childCategories;
      final currentCategoryId = _selectedCategoryId;
      if (currentCategoryId != null &&
          childCategories.any((category) => category.id == currentCategoryId)) {
        _selectedCategoryId = currentCategoryId;
      } else {
        _selectedCategoryId = childCategories.isNotEmpty
            ? childCategories.first.id
            : null;
      }
    });
  }

  Category? _selectedCategory() {
    final id = _selectedCategoryId;
    if (id == null) return null;
    final categories = _categories ?? const <Category>[];
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<void> _openCreateCategory() async {
    final created = await Navigator.pushNamed(
      context,
      CreateCategoryScreen.routeName,
      arguments: CategoryType.expense,
    );
    if (created == true) {
      _loadCategories(selectId: _selectedCategoryId);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  num? _parseAmount(TextEditingController controller) {
    final raw = controller.text.trim();
    if (raw.isEmpty) return null;
    final cleaned = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  BudgetPeriod _selectedPeriod() {
    return _period == 'Week' ? BudgetPeriod.week : BudgetPeriod.month;
  }

  Future<void> _handleSaveBudget() async {
    if (_isSaving) return;
    final nameController = _nameController;
    final name = nameController?.text.trim() ?? '';
    if (name.isEmpty) {
      _showSnack('Please enter savings goal name');
      return;
    }
    final categoryId = _selectedCategoryId;
    if (_selectedParentCategoryId == null) {
      _showSnack('Please select a main category');
      return;
    }
    if (categoryId == null) {
      _showSnack('Please select a subcategory');
      return;
    }
    final amountController = _amountController;
    if (amountController == null) {
      _showSnack('Amount is required');
      return;
    }
    final amount = _parseAmount(amountController);
    if (amount == null || amount <= 0) {
      _showSnack('Please enter a valid amount');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _budget.createBudget(
        name: name,
        categoryId: categoryId,
        amountLimit: amount,
        period: _selectedPeriod(),
      );
      if (!mounted) return;
      _showSnack('Funds saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameController = _nameController ??= TextEditingController();
    final amountController = _amountController ??= TextEditingController();
    final categories = _categories ?? const <Category>[];
    final parentCategories = _parentCategories ?? const <Category>[];
    final categoryIds = categories.map((category) => category.id).toSet();
    final selectedCategoryId =
        _selectedCategoryId != null && categoryIds.contains(_selectedCategoryId)
        ? _selectedCategoryId
        : null;
    final goalName = nameController.text.trim();
    final amountText = amountController.text.trim();
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Create Savings Goal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.overview,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoBanner(),
                  const SizedBox(height: 16),
                  Text(
                    'Savings Goal Name',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Example: Emergency Fund',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Expense Category',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (parentCategories.isEmpty)
                    Text(
                      'No main categories available.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (parentCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Step 1: Choose main category',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (parentCategories.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 10.0;
                        final itemWidth =
                            (constraints.maxWidth - (spacing * 2)) / 3;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: parentCategories.asMap().entries.map((
                              entry,
                            ) {
                              final index = entry.key;
                              final category = entry.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == parentCategories.length - 1
                                      ? 0
                                      : spacing,
                                ),
                                child: SizedBox(
                                  width: itemWidth,
                                  child: _CategoryChip(
                                    label: category.name,
                                    icon: CategoryUi.iconFromString(
                                      category.icon,
                                    ),
                                    color: CategoryUi.colorFromString(
                                      category.color,
                                      fallback: AppColors.primaryBlue,
                                    ),
                                    selected:
                                        category.id ==
                                        _selectedParentCategoryId,
                                    onTap: () =>
                                        _selectParentCategory(category.id),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                  if (parentCategories.isNotEmpty) const SizedBox(height: 14),
                  if (parentCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Step 2: Choose subcategory',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  if (parentCategories.isNotEmpty && categories.isEmpty)
                    Text(
                      'No subcategories in this main category.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (categories.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      value: selectedCategoryId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Select a subcategory'),
                        ),
                        ...categories.map(
                          (category) => DropdownMenuItem<int?>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        ),
                      ],
                      onChanged: _isLoadingCategories
                          ? null
                          : (value) =>
                                setState(() => _selectedCategoryId = value),
                    ),
                  if (_categoriesError != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _categoriesError!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.primaryRed),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadCategories,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openCreateCategory,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Create new category'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Funds Limit Amount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: 'VND',
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Period',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _PeriodChip(
                          label: 'Month',
                          selected: _period == 'Month',
                          onTap: () => setState(() => _period = 'Month'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PeriodChip(
                          label: 'Week',
                          selected: _period == 'Week',
                          onTap: () => setState(() => _period = 'Week'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SummaryCard(
                    name: goalName.isEmpty ? '---' : goalName,
                    period: _period,
                    category: _selectedCategory()?.name ?? '---',
                    limit: amountText.isEmpty ? '---' : amountText,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Save Goal',
                    color: AppColors.primaryBlue,
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleSaveBudget,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Create a savings goal with category, amount, and period.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
          ),
        ),
        child: Center(
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.name,
    required this.period,
    required this.category,
    required this.limit,
  });

  final String name;
  final String period;
  final String category;
  final String limit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Savings Goal Summary',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _SummaryItem(label: 'Category', value: category),
              _SummaryItem(label: 'Limit', value: limit),
              _SummaryItem(label: 'Frequency', value: period),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.fieldBackground : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
