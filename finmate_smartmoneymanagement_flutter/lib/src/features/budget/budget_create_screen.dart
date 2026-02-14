import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../categories/create_category_screen.dart';
import '../categories/models/category.dart';
import '../categories/services/category_service.dart';
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
  List<Category>? _categories;
  bool _isLoadingCategories = false;
  String? _categoriesError;
  bool _isSaving = false;

  TextEditingController? _amountController;
  CategoryService? _categoryService;
  BudgetService? _budgetService;

  CategoryService get _service => _categoryService ??= CategoryService();
  BudgetService get _budget => _budgetService ??= BudgetService();

  @override
  void initState() {
    super.initState();
    _amountController ??= TextEditingController();
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController?.dispose();
    super.dispose();
  }

  Future<void> _loadCategories({int? selectId}) async {
    setState(() {
      _isLoadingCategories = true;
      _categoriesError = null;
    });
    try {
      final categories = (await _service.getCategories(type: CategoryType.expense))
          .where((category) => category.parentId != null && !category.isPrimary)
          .toList();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        final desired = selectId ?? _selectedCategoryId;
        if (desired != null && categories.any((c) => c.id == desired)) {
          _selectedCategoryId = desired;
        } else {
          _selectedCategoryId = null;
        }
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
      _loadCategories();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      _showSnack('Please select a category');
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
        categoryId: categoryId,
        amountLimit: amount,
        period: _selectedPeriod(),
      );
      if (!mounted) return;
      _showSnack('Budget saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountController = _amountController ??= TextEditingController();
    final categories = _categories ?? const <Category>[];
    final amountText = amountController.text.trim();
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Create Budget'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.overview),
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
                    'Expense Category',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    value: _selectedCategoryId,
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
                        child: Text('Select a category'),
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
                        : (value) => setState(() => _selectedCategoryId = value),
                  ),
                  if (_categoriesError != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _categoriesError!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
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
                    'Budget Limit Amount',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                    period: _period,
                    category: _selectedCategory()?.name ?? '---',
                    limit: amountText.isEmpty ? '---' : amountText,
                  ),
                  const SizedBox(height: 22),
                  PrimaryButton(
                    label: 'Save Budget',
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
              'Set a spending limit for a category in a period.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
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
          border: Border.all(color: selected ? AppColors.primaryBlue : AppColors.border),
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
    required this.period,
    required this.category,
    required this.limit,
  });

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
            'Budget Summary',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
