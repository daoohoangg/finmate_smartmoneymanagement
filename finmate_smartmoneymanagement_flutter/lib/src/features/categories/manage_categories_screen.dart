import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../wallets/models/wallet.dart';
import '../wallets/services/wallet_service.dart';
import 'create_category_screen.dart';
import 'models/category.dart';
import 'services/category_service.dart';
import 'utils/category_ui.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  static const String routeName = '/categories/manage';

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  bool _isExpense = true;
  bool _isLoading = false;
  bool? _isDeletingCategory = false;
  bool? _isCreatingWallet = false;
  String? _errorMessage;
  List<Category> _categories = [];
  List<Wallet> _wallets = [];
  final Set<int> _walletBusyIds = <int>{};

  CategoryService? _categoryService;
  WalletService? _walletService;

  CategoryService get _service => _categoryService ??= CategoryService();
  WalletService get _walletSvc => _walletService ??= WalletService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isExpense) {
        final categories = await _service.getCategories(type: CategoryType.expense);
        if (!mounted) return;
        setState(() {
          _categories = categories;
          _wallets = const <Wallet>[];
        });
      } else {
        var wallets = await _walletSvc.getWallets();
        wallets = List<Wallet>.from(wallets)
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        if (!mounted) return;
        setState(() {
          _wallets = wallets;
          _categories = const <Category>[];
        });
      }
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

  bool _toSafeBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  int _groupOrder(CategoryGroup? group) {
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

  List<Category> _selectExpenseMainCategories(List<Category> parentCandidates) {
    final candidates = List<Category>.from(parentCandidates)
      ..sort((a, b) {
        final groupDiff = _groupOrder(a.group) - _groupOrder(b.group);
        if (groupDiff != 0) return groupDiff;
        final aSystem = _toSafeBool((a as dynamic).isSystemCategory);
        final bSystem = _toSafeBool((b as dynamic).isSystemCategory);
        if (aSystem != bSystem) return aSystem ? 1 : -1;
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
        if (category.group == group && !selected.any((item) => item.id == category.id)) {
          selected.add(category);
          break;
        }
      }
    }

    for (final category in candidates) {
      if (selected.length >= 3) break;
      if (selected.any((item) => item.id == category.id)) continue;
      selected.add(category);
    }

    if (selected.length > 3) return selected.take(3).toList();
    return selected;
  }

  List<_CategoryItem> _buildCategoryItems() {
    final parentCandidates = _categories.where((category) => category.parentId == null).toList();
    final parentCategories = _selectExpenseMainCategories(parentCandidates);
    final parentIds = parentCategories.map((item) => item.id).toSet();

    final childrenByParent = <int, List<Category>>{};
    for (final category in _categories) {
      final parentId = category.parentId;
      if (parentId == null || !parentIds.contains(parentId)) continue;
      childrenByParent.putIfAbsent(parentId, () => <Category>[]).add(category);
    }
    for (final children in childrenByParent.values) {
      children.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return parentCategories
        .map(
          (category) {
            final children = (childrenByParent[category.id] ?? const <Category>[])
                .map(
                  (child) => _CategoryChildItem(
                    id: child.id,
                    name: child.name,
                    icon: CategoryUi.iconFromString(child.icon),
                    color: CategoryUi.colorFromString(
                      child.color,
                      fallback: AppColors.primaryBlue,
                    ),
                    isSystemCategory: _toSafeBool((child as dynamic).isSystemCategory),
                  ),
                )
                .toList();

            return _CategoryItem(
              id: category.id,
              name: category.name,
              count: children.length,
              icon: CategoryUi.iconFromString(category.icon),
              color: CategoryUi.colorFromString(category.color, fallback: AppColors.primaryBlue),
              isSystemCategory: _toSafeBool((category as dynamic).isSystemCategory),
              children: children,
            );
          },
        )
        .toList();
  }

  Future<void> _openCreateSubcategory({int? parentCategoryId}) async {
    final created = await Navigator.pushNamed(
      context,
      CreateCategoryScreen.routeName,
      arguments: CreateCategoryArgs(
        type: CategoryType.expense,
        parentCategoryId: parentCategoryId,
        lockParentSelection: parentCategoryId != null,
      ),
    );
    if (created == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _confirmAndDeleteCategory({
    required int categoryId,
    required String categoryName,
    int childCount = 0,
  }) async {
    if (_isDeletingCategory == true || _isLoading) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          childCount > 0
              ? 'Category "$categoryName" has $childCount subcategories and cannot be deleted.'
              : 'Delete category "$categoryName"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          if (childCount == 0)
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    setState(() => _isDeletingCategory = true);
    try {
      await _service.deleteCategory(categoryId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingCategory = false);
      }
    }
  }

  Future<String?> _promptWalletName({
    required String title,
    required String actionLabel,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Wallet name',
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  setDialogState(() => error = 'Wallet name is required');
                  return;
                }
                Navigator.pop(context, value);
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _createWallet() async {
    if (_isCreatingWallet == true || _isLoading) return;
    final name = await _promptWalletName(
      title: 'Create Wallet',
      actionLabel: 'Create',
    );
    if (name == null) return;

    setState(() => _isCreatingWallet = true);
    try {
      await _walletSvc.createWallet(
        name: name,
        icon: _inferWalletIcon(name),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet created')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingWallet = false);
      }
    }
  }

  String _inferWalletIcon(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.contains('bank')) return 'account_balance_outlined';
    if (normalized.contains('saving')) return 'savings_outlined';
    if (normalized.contains('card') ||
        normalized.contains('visa') ||
        normalized.contains('master')) {
      return 'credit_card_outlined';
    }
    if (normalized.contains('cash')) return 'payments_outlined';
    if (normalized.contains('pay') || normalized.contains('wallet')) {
      return 'account_balance_wallet_outlined';
    }
    return 'account_balance_wallet_outlined';
  }

  String _resolveWalletIcon(Wallet wallet) {
    final raw = wallet.icon?.trim();
    if (raw != null && raw.isNotEmpty) {
      return raw;
    }
    return _inferWalletIcon(wallet.name);
  }

  Future<void> _deleteWallet(Wallet wallet) async {
    if (_walletBusyIds.contains(wallet.id) || _isLoading) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wallet'),
        content: Text('Delete wallet "${wallet.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    setState(() => _walletBusyIds.add(wallet.id));
    try {
      await _walletSvc.deleteWallet(wallet.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet deleted')),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _walletBusyIds.remove(wallet.id));
      }
    }
  }

  Widget _buildSwipeDeleteBackground() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryRed.withOpacity(0.3)),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
    );
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

  Widget _buildExpenseCategoryContent(BuildContext context) {
    final items = _buildCategoryItems();
    if (items.isEmpty) {
      return _buildStatusMessage(
        context,
        'No main categories found.',
      );
    }
    return Column(
      children: items
          .map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryCard(
                  item: item,
                  isDeleting: _isDeletingCategory == true,
                  onAddSubcategory: () {
                    _openCreateSubcategory(parentCategoryId: item.id);
                  },
                  onDeleteChild: (child) async {
                    await _confirmAndDeleteCategory(
                      categoryId: child.id,
                      categoryName: child.name,
                    );
                  },
                ),
              );
            },
          )
          .toList(),
    );
  }

  Widget _buildIncomeWalletContent(BuildContext context) {
    if (_wallets.isEmpty) {
      return _buildStatusMessage(
        context,
        'Income categories are wallets. Create your first wallet.',
      );
    }
    return Column(
      children: _wallets
          .map(
            (wallet) {
              final card = _WalletCard(
                wallet: wallet,
                iconString: _resolveWalletIcon(wallet),
                isBusy: _walletBusyIds.contains(wallet.id),
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey('income-wallet-${wallet.id}'),
                  direction: DismissDirection.endToStart,
                  background: _buildSwipeDeleteBackground(),
                  confirmDismiss: (_) async {
                    await _deleteWallet(wallet);
                    return false;
                  },
                  child: card,
                ),
              );
            },
          )
          .toList(),
    );
  }

  Widget _buildBodyContent(BuildContext context) {
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
        onAction: _loadData,
      );
    }
    if (_isExpense) {
      return _buildExpenseCategoryContent(context);
    }
    return _buildIncomeWalletContent(context);
  }

  @override
  Widget build(BuildContext context) {
    final fabDisabled = _isLoading || _isDeletingCategory == true || _isCreatingWallet == true;
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
        onPressed: fabDisabled
            ? null
            : () {
                if (_isExpense) {
                  _openCreateSubcategory();
                } else {
                  _createWallet();
                }
              },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.utilities),
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
                      _loadData();
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_isExpense)
                    Text(
                      'Expense keeps exactly 3 main categories. Tap to expand subcategories, swipe subcategories left to delete.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    )
                  else
                    Text(
                      'Income categories are managed as wallets.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  const SizedBox(height: 12),
                  _buildBodyContent(context),
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
    required this.id,
    required this.name,
    required this.count,
    required this.children,
    required this.icon,
    required this.color,
    this.isSystemCategory,
  });

  final int id;
  final String name;
  final int count;
  final List<_CategoryChildItem> children;
  final IconData icon;
  final Color color;
  final bool? isSystemCategory;
}

class _CategoryChildItem {
  const _CategoryChildItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isSystemCategory,
  });

  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final bool? isSystemCategory;
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.item,
    this.onAddSubcategory,
    this.onDeleteChild,
    this.isDeleting = false,
  });

  final _CategoryItem item;
  final VoidCallback? onAddSubcategory;
  final Future<void> Function(_CategoryChildItem child)? onDeleteChild;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          title: Text(
            item.name,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${item.count} Subcategories',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          trailing: isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
          children: [
            if (onAddSubcategory != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onAddSubcategory,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add subcategory'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primaryBlue,
                  ),
                ),
              ),
            if (item.children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No subcategories',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              ...item.children.map(
                (child) {
                  final row = Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fieldBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: child.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(child.icon, color: child.color, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            child.name,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );

                  final canDelete =
                      child.isSystemCategory != true && onDeleteChild != null;
                  final wrapped = canDelete
                      ? Dismissible(
                          key: ValueKey('subcategory-${item.id}-${child.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primaryRed.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: const Icon(
                              Icons.delete_outline,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            await onDeleteChild!(child);
                            return false;
                          },
                          child: row,
                        )
                      : row;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: wrapped,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.iconString,
    this.isBusy = false,
  });

  final Wallet wallet;
  final String iconString;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final icon = CategoryUi.iconFromString(iconString);
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
              color: AppColors.primaryBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  wallet.name,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  'Wallet',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          isBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.swipe_left_rounded, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}
