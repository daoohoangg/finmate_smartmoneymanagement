import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'create_category_screen.dart';
import 'delete_category_screen.dart';
import 'models/category.dart';
import 'services/category_service.dart';
import 'utils/category_ui.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  static const String routeName = '/categories/manage';

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  bool _isExpense = true;
  bool _isLoading = false;
  String? _errorMessage;
  List<Category> _categories = [];

  CategoryService? _categoryService;

  CategoryService get _service => _categoryService ??= CategoryService();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final type = _isExpense ? CategoryType.expense : CategoryType.income;
      final categories = await _service.getCategories(type: type);
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<_CategoryItem> _buildItems() {
    final parentCategories = _categories.where((category) => category.parentId == null).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final childCounts = <int, int>{};
    for (final category in _categories) {
      final parentId = category.parentId;
      if (parentId == null) continue;
      childCounts[parentId] = (childCounts[parentId] ?? 0) + 1;
    }

    return parentCategories
        .map(
          (category) => _CategoryItem(
            name: category.name,
            count: childCounts[category.id] ?? 0,
            icon: CategoryUi.iconFromString(category.icon),
            color: CategoryUi.colorFromString(category.color, fallback: AppColors.primaryBlue),
            isSystemCategory: category.isSystemCategory,
          ),
        )
        .toList();
  }

  Widget _buildStatusMessage(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_errorMessage != null) {
      return _buildStatusMessage(
        context,
        _errorMessage!,
        actionLabel: 'Retry',
        onAction: _loadCategories,
      );
    }
    final items = _buildItems();
    if (items.isEmpty) {
      return _buildStatusMessage(
        context,
        'No categories yet. Create your first one.',
      );
    }
    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryCard(
                item: item,
                onDelete: item.isSystemCategory
                    ? null
                    : () => Navigator.pushNamed(
                          context,
                          DeleteCategoryScreen.routeName,
                        ),
              ),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final created = await Navigator.pushNamed(
            context,
            CreateCategoryScreen.routeName,
            arguments: _isExpense ? CategoryType.expense : CategoryType.income,
          );
          if (created == true) {
            _loadCategories();
          }
        },
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.settings),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SegmentedToggle(
                    leftLabel: 'Expense',
                    rightLabel: 'Income',
                    isLeftSelected: _isExpense,
                    onChanged: (value) {
                      if (_isExpense == value) return;
                      setState(() => _isExpense = value);
                      _loadCategories();
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildCategoryContent(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeftSelected,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final bool isLeftSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: leftLabel,
              selected: isLeftSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: rightLabel,
              selected: !isLeftSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
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
          color: selected ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  const _CategoryItem({
    required this.name,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSystemCategory,
  });

  final String name;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSystemCategory;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.item, this.onDelete});

  final _CategoryItem item;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.count} Subcategories',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (!item.isSystemCategory)
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 18),
              onPressed: () {},
            ),
          if (!item.isSystemCategory)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed, size: 18),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
