import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../categories/create_category_screen.dart';
import '../categories/models/category.dart' as fm;
import '../categories/services/category_service.dart';
import '../categories/utils/category_ui.dart';
import '../planning/services/allocation_plan_service.dart';
import '../wallets/models/wallet.dart';
import '../wallets/services/wallet_service.dart';
import 'models/transaction.dart';
import 'services/receipt_upload_service.dart';
import 'services/transaction_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.initialIsExpense = true});

  static const String routeName = '/transactions/add';
  final bool initialIsExpense;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  late bool _isExpense;
  int? _selectedCategoryId;
  int? _selectedWalletId;
  List<fm.Category>? _categories;
  List<fm.Category>? _parentCategories;
  List<Wallet>? _wallets;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime? _selectedDate;
  bool _isSeedingWallets = false;
  Map<int, double> _parentAllocatedAmounts = const <int, double>{};
  Uint8List? _receiptBytes;
  String? _receiptName;
  int? _receiptSize;
  String? _receiptImageUrl;

  TextEditingController? _amountController;
  final TextEditingController _noteController = TextEditingController();

  CategoryService? _categoryService;
  WalletService? _walletService;
  TransactionService? _transactionService;
  ReceiptUploadService? _receiptUploadService;
  AllocationPlanService? _allocationPlanService;

  CategoryService get _categorySvc => _categoryService ??= CategoryService();
  WalletService get _walletSvc => _walletService ??= WalletService();
  TransactionService get _transactionSvc =>
      _transactionService ??= TransactionService();
  ReceiptUploadService get _receiptUploadSvc =>
      _receiptUploadService ??= ReceiptUploadService();
  AllocationPlanService get _allocationPlanSvc =>
      _allocationPlanService ??= AllocationPlanService();

  static const int _maxReceiptBytes = 5 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialIsExpense;
    _amountController ??= TextEditingController();
    _selectedDate ??= DateTime.now();
    _loadData();
  }

  @override
  void reassemble() {
    super.reassemble();
    _categories = null;
    _parentCategories = null;
    _wallets = null;
    _selectedDate ??= DateTime.now();
    _loadData();
  }

  @override
  void dispose() {
    _amountController?.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      var wallets = await _walletSvc.getWallets();
      if (!_isSeedingWallets) {
        wallets = await _ensureDefaultWallets(wallets);
      }
      wallets = List<Wallet>.from(wallets);
      final order = <String, int>{'cash': 0, 'bank account': 1, 'card': 2};
      wallets.sort((a, b) {
        final aKey = a.name.trim().toLowerCase();
        final bKey = b.name.trim().toLowerCase();
        final aOrder = order[aKey] ?? 100;
        final bOrder = order[bKey] ?? 100;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      wallets = _dedupeWalletsById(wallets);
      final loadedCategories = await _categorySvc.getCategories(
        type: _isExpense ? fm.CategoryType.expense : fm.CategoryType.income,
      );
      if (!mounted) return;
      var parentCategoriesForAllocation = const <fm.Category>[];
      setState(() {
        _wallets = wallets;
        _selectedWalletId = _resolveSelectedWalletId(
          wallets,
          _selectedWalletId,
        );
        if (_isExpense) {
          final categoryTree = _buildExpenseCategoryTree(loadedCategories);
          final parentCategories = categoryTree.parentCategories;
          final childrenByParent = categoryTree.childrenByParent;
          final childCategories = _buildAllSubcategories(
            parentCategories: parentCategories,
            childrenByParent: childrenByParent,
          );
          final selectedCategoryId =
              (_selectedCategoryId != null &&
                  childCategories.any(
                    (category) => category.id == _selectedCategoryId,
                  ))
              ? _selectedCategoryId
              : null;
          _parentCategories = parentCategories;
          _categories = childCategories
              .where(
                (c) =>
                    c.name.toLowerCase() != 'house' &&
                    c.name.toLowerCase() != 'housing' &&
                    c.name.toLowerCase() != 'nhà' &&
                    c.name.toLowerCase() != 'nhà cửa',
              )
              .toList();
          _selectedCategoryId = selectedCategoryId;
          parentCategoriesForAllocation = parentCategories;
        } else {
          _parentCategories = const <fm.Category>[];
          _categories = const <fm.Category>[];
          _selectedCategoryId = null;
          _parentAllocatedAmounts = const <int, double>{};
        }
      });
      if (_isExpense) {
        await _loadParentAllocationLimits(parentCategoriesForAllocation);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Wallet>> _ensureDefaultWallets(List<Wallet> wallets) async {
    _isSeedingWallets = true;
    try {
      final defaults = <String>['Cash', 'Bank Account', 'Card'];
      final existingNames = wallets
          .map((w) => w.name.trim().toLowerCase())
          .toSet();
      final created = <Wallet>[];
      for (final name in defaults) {
        if (existingNames.contains(name.toLowerCase())) continue;
        final wallet = await _walletSvc.createWallet(name: name);
        created.add(wallet);
      }
      if (created.isEmpty) return wallets;
      return [...wallets, ...created];
    } catch (e) {
      _showSnack(e.toString());
      return await _walletSvc.getWallets();
    } finally {
      _isSeedingWallets = false;
    }
  }

  List<Wallet> _dedupeWalletsById(List<Wallet> wallets) {
    final seenIds = <int>{};
    final result = <Wallet>[];
    for (final wallet in wallets) {
      if (!seenIds.add(wallet.id)) continue;
      result.add(wallet);
    }
    return result;
  }

  List<fm.Category> _dedupeCategoriesById(List<fm.Category> categories) {
    final seenIds = <int>{};
    final result = <fm.Category>[];
    for (final category in categories) {
      if (!seenIds.add(category.id)) continue;
      result.add(category);
    }
    return result;
  }

  int? _resolveSelectedWalletId(List<Wallet> wallets, int? current) {
    if (current != null && wallets.any((wallet) => wallet.id == current)) {
      return current;
    }
    return wallets.isNotEmpty ? wallets.first.id : null;
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final loadedCategories = await _categorySvc.getCategories(
        type: _isExpense ? fm.CategoryType.expense : fm.CategoryType.income,
      );
      if (!mounted) return;
      var parentCategoriesForAllocation = const <fm.Category>[];
      setState(() {
        if (_isExpense) {
          final categoryTree = _buildExpenseCategoryTree(loadedCategories);
          final parentCategories = categoryTree.parentCategories;
          final childrenByParent = categoryTree.childrenByParent;
          final childCategories = _buildAllSubcategories(
            parentCategories: parentCategories,
            childrenByParent: childrenByParent,
          );
          final selectedCategoryId =
              (_selectedCategoryId != null &&
                  childCategories.any(
                    (category) => category.id == _selectedCategoryId,
                  ))
              ? _selectedCategoryId
              : null;
          _parentCategories = parentCategories;
          _categories = childCategories
              .where(
                (c) =>
                    c.name.toLowerCase() != 'house' &&
                    c.name.toLowerCase() != 'housing' &&
                    c.name.toLowerCase() != 'nhà' &&
                    c.name.toLowerCase() != 'nhà cửa',
              )
              .toList();
          _selectedCategoryId = selectedCategoryId;
          parentCategoriesForAllocation = parentCategories;
        } else {
          _parentCategories = const <fm.Category>[];
          _categories = const <fm.Category>[];
          _selectedCategoryId = null;
          _parentAllocatedAmounts = const <int, double>{};
        }
      });
      if (_isExpense) {
        await _loadParentAllocationLimits(parentCategoriesForAllocation);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ({
    List<fm.Category> parentCategories,
    Map<int, List<fm.Category>> childrenByParent,
  })
  _buildExpenseCategoryTree(List<fm.Category> loadedCategories) {
    final expenseCategories = loadedCategories
        .where((category) => category.type == fm.CategoryType.expense)
        .toList();
    final parentCandidates = expenseCategories
        .where((category) => category.parentId == null)
        .toList();
    final parentCategories = _sortParentCategories(parentCandidates);
    final parentIds = parentCategories.map((category) => category.id).toSet();
    final childrenByParent = <int, List<fm.Category>>{};
    for (final category in expenseCategories) {
      final parentId = category.parentId;
      if (parentId == null || !parentIds.contains(parentId)) continue;
      childrenByParent
          .putIfAbsent(parentId, () => <fm.Category>[])
          .add(category);
    }
    for (final parent in parentCategories) {
      childrenByParent.putIfAbsent(parent.id, () => <fm.Category>[]);
    }
    final parentById = <int, fm.Category>{
      for (final parent in parentCategories) parent.id: parent,
    };
    for (final entry in childrenByParent.entries) {
      final group = parentById[entry.key]?.group;
      entry.value.sort((a, b) => _compareSubcategory(group, a.name, b.name));
    }
    return (
      parentCategories: parentCategories,
      childrenByParent: childrenByParent,
    );
  }

  List<fm.Category> _sortParentCategories(List<fm.Category> parentCandidates) {
    final sorted = List<fm.Category>.from(parentCandidates)
      ..sort((a, b) {
        final groupOrderDiff =
            _categoryGroupOrder(a.group) - _categoryGroupOrder(b.group);
        if (groupOrderDiff != 0) return groupOrderDiff;
        if (a.isSystemCategory != b.isSystemCategory) {
          return a.isSystemCategory ? 1 : -1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return _dedupeCategoriesById(sorted);
  }

  List<fm.Category> _buildAllSubcategories({
    required List<fm.Category> parentCategories,
    required Map<int, List<fm.Category>> childrenByParent,
  }) {
    final allChildren = <fm.Category>[];
    for (final parent in parentCategories) {
      allChildren.addAll(childrenByParent[parent.id] ?? const <fm.Category>[]);
    }
    return _dedupeCategoriesById(allChildren);
  }

  void _selectSubcategory(int? categoryId) {
    if (!_isExpense) return;
    setState(() {
      _selectedCategoryId = categoryId;
    });
  }

  int _compareSubcategory(
    fm.CategoryGroup? group,
    String firstName,
    String secondName,
  ) {
    final firstOrder = _subcategoryOrder(group, firstName);
    final secondOrder = _subcategoryOrder(group, secondName);
    if (firstOrder != secondOrder) {
      return firstOrder.compareTo(secondOrder);
    }
    return firstName.toLowerCase().compareTo(secondName.toLowerCase());
  }

  int _subcategoryOrder(fm.CategoryGroup? group, String name) {
    final normalized = name.trim().toLowerCase();
    switch (group) {
      case fm.CategoryGroup.necessary:
        const necessaryOrder = <String, int>{
          'market': 0,
          'food': 1,
          'transport': 2,
          'bill': 3,
        };
        return necessaryOrder[normalized] ?? 1000;
      case fm.CategoryGroup.accumulation:
        const accumulationOrder = <String, int>{'saving': 0, 'learning': 1};
        return accumulationOrder[normalized] ?? 1000;
      case fm.CategoryGroup.flexibility:
        const flexibilityOrder = <String, int>{
          'shopping': 0,
          'entertainment': 1,
          'charity': 2,
        };
        return flexibilityOrder[normalized] ?? 1000;
      case null:
        return 1000;
    }
  }

  int _categoryGroupOrder(fm.CategoryGroup? group) {
    switch (group) {
      case fm.CategoryGroup.necessary:
        return 0;
      case fm.CategoryGroup.accumulation:
        return 1;
      case fm.CategoryGroup.flexibility:
        return 2;
      case null:
        return 100;
    }
  }

  Color _parentFallbackColor(fm.CategoryGroup? group) {
    switch (group) {
      case fm.CategoryGroup.necessary:
        return const Color(0xFFF59E0B);
      case fm.CategoryGroup.accumulation:
        return const Color(0xFF2CB67D);
      case fm.CategoryGroup.flexibility:
        return const Color(0xFF6366F1);
      case null:
        return AppColors.primaryBlue;
    }
  }

  Future<void> _loadParentAllocationLimits(
    List<fm.Category> parentCategories,
  ) async {
    if (!_isExpense || parentCategories.isEmpty) {
      if (!mounted) return;
      setState(() => _parentAllocatedAmounts = const <int, double>{});
      return;
    }
    try {
      final responses = await Future.wait<dynamic>([
        _allocationPlanSvc.getAllocationPlan(),
        _transactionSvc.getTransactions(),
      ]);
      if (!mounted) return;
      final allocationPlan = responses[0] as AllocationPlan;
      final transactions = responses[1] as List<Map<String, dynamic>>;
      final spendableAmount = _calculateSpendableAmount(transactions);
      final allocatedByParent = <int, double>{};
      for (var index = 0; index < parentCategories.length; index++) {
        final parent = parentCategories[index];
        final percent = _allocatedPercentForParent(
          parent.group,
          allocationPlan,
          fallbackIndex: index,
        );
        allocatedByParent[parent.id] = spendableAmount * (percent / 100);
      }
      setState(() => _parentAllocatedAmounts = allocatedByParent);
    } catch (_) {
      if (!mounted) return;
      setState(() => _parentAllocatedAmounts = const <int, double>{});
    }
  }

  double _calculateSpendableAmount(List<Map<String, dynamic>> transactions) {
    var income = 0.0;
    var expense = 0.0;
    for (final transaction in transactions) {
      final type = transaction['type']?.toString().toUpperCase();
      final amount = _toDouble(transaction['amount']);
      if (type == 'INCOME') {
        income += amount;
      } else if (type == 'EXPENSE') {
        if (_isFundContributionTransaction(transaction)) continue;
        expense += amount;
      }
    }
    final spendable = income - expense;
    return spendable < 0 ? 0 : spendable;
  }

  bool _isFundContributionTransaction(Map<String, dynamic> transaction) {
    final note = transaction['note']?.toString().trim().toLowerCase() ?? '';
    return note.startsWith('fund contribution -');
  }

  double _allocatedPercentForParent(
    fm.CategoryGroup? group,
    AllocationPlan plan, {
    required int fallbackIndex,
  }) {
    switch (group) {
      case fm.CategoryGroup.necessary:
        return plan.necessary;
      case fm.CategoryGroup.accumulation:
        return plan.accumulation;
      case fm.CategoryGroup.flexibility:
        return plan.flexibility;
      case null:
        final fallback = <double>[
          plan.necessary,
          plan.accumulation,
          plan.flexibility,
        ];
        if (fallbackIndex < 0 || fallbackIndex >= fallback.length) return 0;
        return fallback[fallbackIndex];
    }
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  ({String parentName, double allocated})? _parentAllocationForSubcategory(
    int? subCategoryId,
  ) {
    if (!_isExpense || subCategoryId == null) return null;
    try {
      final rawCategories = _categories;
      final categories =
          (rawCategories as List<dynamic>?)?.whereType<fm.Category>().toList(
            growable: false,
          ) ??
          const <fm.Category>[];
      if (categories.isEmpty) return null;

      fm.Category? selectedSubcategory;
      for (final category in categories) {
        if (category.id == subCategoryId) {
          selectedSubcategory = category;
          break;
        }
      }
      final parentId = selectedSubcategory?.parentId;
      if (parentId == null) return null;

      final allocatedRaw = _parentAllocatedAmounts[parentId];
      if (allocatedRaw == null) return null;
      final allocated = _toDouble(allocatedRaw);

      var parentName = 'Parent Category';
      final rawParentCategories = _parentCategories;
      final parentCategories =
          (rawParentCategories as List<dynamic>?)
              ?.whereType<fm.Category>()
              .toList(growable: false) ??
          const <fm.Category>[];
      for (final parent in parentCategories) {
        if (parent.id == parentId) {
          parentName = parent.name;
          break;
        }
      }
      return (parentName: parentName, allocated: allocated);
    } catch (_) {
      return null;
    }
  }

  String? _parentAllocationWarningText({
    required num amount,
    required int? subCategoryId,
  }) {
    final parentAllocation = _parentAllocationForSubcategory(subCategoryId);
    if (parentAllocation == null) return null;
    if (amount <= parentAllocation.allocated) return null;
    final exceedAmount = amount - parentAllocation.allocated;
    return 'Warning: Spending exceeded amount allocated for '
        '"${parentAllocation.parentName}" (${_formatVnd(parentAllocation.allocated)}), '
        'exceeds by ${_formatVnd(exceedAmount)}.';
  }

  Future<void> _openCategoryPickerModal({
    required List<fm.Category> parentCategories,
    required List<fm.Category> childCategories,
  }) async {
    if (!_isExpense || childCategories.isEmpty) return;
    String searchQuery = '';
    final searchController = TextEditingController();
    final childrenByParent = <int, List<fm.Category>>{};
    for (final category in childCategories) {
      final parentId = category.parentId;
      if (parentId == null) continue;
      childrenByParent
          .putIfAbsent(parentId, () => <fm.Category>[])
          .add(category);
    }
    final parentById = <int, fm.Category>{
      for (final parent in parentCategories) parent.id: parent,
    };
    for (final entry in childrenByParent.entries) {
      final group = parentById[entry.key]?.group;
      entry.value.sort((a, b) => _compareSubcategory(group, a.name, b.name));
    }
    final orderedParentIds = <int>[];
    for (final parent in parentCategories) {
      if (childrenByParent[parent.id]?.isNotEmpty ?? false) {
        orderedParentIds.add(parent.id);
      }
    }
    final remainingParentIds =
        childrenByParent.keys
            .where((id) => !orderedParentIds.contains(id))
            .toList(growable: false)
          ..sort((a, b) => a.compareTo(b));
    orderedParentIds.addAll(remainingParentIds);
    final pickerResult = await showModalBottomSheet<_CategoryPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.82;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final keyword = searchQuery.trim().toLowerCase();
            final filteredByParent = <int, List<fm.Category>>{};
            for (final parentId in orderedParentIds) {
              final items = childrenByParent[parentId] ?? const <fm.Category>[];
              final parentName = parentById[parentId]?.name.toLowerCase() ?? '';
              final filtered = items
                  .where((category) {
                    if (keyword.isEmpty) return true;
                    return category.name.toLowerCase().contains(keyword) ||
                        parentName.contains(keyword);
                  })
                  .toList(growable: false);
              if (filtered.isNotEmpty) {
                filteredByParent[parentId] = filtered;
              }
            }
            final visibleParentIds = orderedParentIds
                .where((id) => filteredByParent.containsKey(id))
                .toList(growable: false);

            return SafeArea(
              top: false,
              child: SizedBox(
                height: maxHeight,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Select category',
                              style: Theme.of(sheetContext).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.fieldBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TextField(
                                controller: searchController,
                                onChanged: (value) => setModalState(() {
                                  searchQuery = value;
                                }),
                                decoration: const InputDecoration(
                                  hintText: 'Search',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.pop(
                              sheetContext,
                              const _CategoryPickerResult.openCreate(),
                            ),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 18,
                            ),
                            label: const Text('Create'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(108, 44),
                              side: const BorderSide(color: AppColors.border),
                              foregroundColor: AppColors.textPrimary,
                              backgroundColor: AppColors.card,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: visibleParentIds.isEmpty
                          ? Center(
                              child: Text(
                                'Category not found',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: visibleParentIds.length,
                              separatorBuilder: (_, index) =>
                                  const SizedBox(height: 14),
                              itemBuilder: (context, index) {
                                final parentId = visibleParentIds[index];
                                final parent = parentById[parentId];
                                final parentName =
                                    parent?.name ?? 'Parent Category';
                                final parentColor = CategoryUi.colorFromString(
                                  parent?.color,
                                  fallback: _parentFallbackColor(parent?.group),
                                );
                                final parentIcon = CategoryUi.iconFromString(
                                  parent?.icon,
                                );
                                final childItems =
                                    filteredByParent[parentId] ??
                                    const <fm.Category>[];
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: parentColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: parentColor.withValues(
                                            alpha: 0.35,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            parentIcon,
                                            size: 20,
                                            color: parentColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            parentName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  color: parentColor,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...childItems.map((category) {
                                      final isSelected =
                                          category.id == _selectedCategoryId;
                                      final childColor =
                                          CategoryUi.colorFromString(
                                            category.color,
                                            fallback: parentColor,
                                          );
                                      final childIcon =
                                          CategoryUi.iconFromString(
                                            category.icon,
                                          );
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: InkWell(
                                          onTap: () => Navigator.pop(
                                            sheetContext,
                                            _CategoryPickerResult.select(
                                              category.id,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? AppColors.primaryBlue
                                                        .withValues(alpha: 0.1)
                                                  : AppColors.card,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primaryBlue
                                                    : AppColors.border,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(
                                                    8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: childColor
                                                        .withValues(
                                                          alpha: 0.16,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Icon(
                                                    childIcon,
                                                    size: 18,
                                                    color: childColor,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    category.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  const Icon(
                                                    Icons.check_circle,
                                                    color: AppColors.success,
                                                    size: 18,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    searchController.dispose();
    if (!mounted || pickerResult == null) return;
    if (pickerResult.openCreate) {
      final created = await Navigator.pushNamed(
        context,
        CreateCategoryScreen.routeName,
        arguments: const CreateCategoryArgs(type: fm.CategoryType.expense),
      );
      if (!mounted) return;
      if (created == true) {
        await _loadCategories();
      }
      return;
    }
    if (pickerResult.selectedCategoryId != null) {
      _selectSubcategory(pickerResult.selectedCategoryId);
    }
  }

  num? _parseAmount(String raw) {
    final normalized = raw.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _formatVnd(num amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix$absolute VND';
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    final walletId = _selectedWalletId;
    if (walletId == null) {
      _showSnack('Please select a wallet');
      return;
    }
    final amountController = _amountController;
    if (amountController == null) {
      _showSnack('Amount is required');
      return;
    }
    final amount = _parseAmount(amountController.text);
    if (amount == null || amount <= 0) {
      _showSnack('Please enter a valid amount');
      return;
    }
    final categoryId = _isExpense ? _selectedCategoryId : null;
    if (_isExpense && categoryId == null) {
      _showSnack('Please select a subcategory');
      return;
    }
    final parentWarning = _parentAllocationWarningText(
      amount: amount,
      subCategoryId: categoryId,
    );
    if (parentWarning != null) {
      _showSnack(parentWarning);
    }
    setState(() => _isSaving = true);
    try {
      String? imageUrl;
      if (_receiptBytes != null) {
        imageUrl = await _uploadReceiptIfNeeded();
      }
      await _transactionSvc.createTransaction(
        walletId: walletId,
        categoryId: categoryId,
        type: _isExpense ? TransactionType.expense : TransactionType.income,
        amount: amount,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        imageUrl: imageUrl,
        transactionDate: _effectiveDate(),
      );
      if (!mounted) return;
      _showSnack('Transaction saved successfully');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _effectiveDate() {
    return _selectedDate ?? DateTime.now();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) {
      return 'Today';
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveDate(),
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  Future<_PickedReceipt?> _pickReceiptFile() async {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    if (isMobile || kIsWeb) {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return null;
      final bytes = await image.readAsBytes();
      final name = image.name.isNotEmpty ? image.name : 'receipt.jpg';
      return _PickedReceipt(bytes: bytes, name: name);
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    return _PickedReceipt(bytes: bytes, name: file.name);
  }

  Future<void> _pickReceipt() async {
    if (_isSaving) return;
    try {
      final picked = await _pickReceiptFile();
      if (picked == null) return;
      if (picked.bytes.length > _maxReceiptBytes) {
        _showSnack('Receipt must be 5MB or smaller');
        return;
      }
      setState(() {
        _receiptBytes = picked.bytes;
        _receiptName = picked.name;
        _receiptSize = picked.bytes.length;
        _receiptImageUrl = null;
      });
    } catch (e) {
      _showSnack('Failed to pick receipt: $e');
    }
  }

  void _clearReceipt() {
    setState(() {
      _receiptBytes = null;
      _receiptName = null;
      _receiptSize = null;
      _receiptImageUrl = null;
    });
  }

  Future<String?> _uploadReceiptIfNeeded() async {
    if (_receiptBytes == null) return null;
    if (_receiptImageUrl != null && _receiptImageUrl!.isNotEmpty) {
      return _receiptImageUrl;
    }
    final fileName = (_receiptName != null && _receiptName!.trim().isNotEmpty)
        ? _receiptName!.trim()
        : 'receipt.jpg';
    final url = await _receiptUploadSvc.uploadReceipt(_receiptBytes!, fileName);
    _receiptImageUrl = url;
    return url;
  }

  String _formatBytes(int bytes) {
    const kb = 1024;
    const mb = 1024 * 1024;
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    }
    if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  @override
  Widget build(BuildContext context) {
    final amountController = _amountController ??= TextEditingController();
    final rawCategories = _categories as List<dynamic>?;
    final rawParentCategories = _parentCategories as List<dynamic>?;
    final rawWallets = _wallets as List<dynamic>?;
    final categories = _dedupeCategoriesById(
      rawCategories?.whereType<fm.Category>().toList() ?? const <fm.Category>[],
    );
    final parentCategories = _dedupeCategoriesById(
      rawParentCategories?.whereType<fm.Category>().toList() ??
          const <fm.Category>[],
    );
    final categoryIds = categories.map((category) => category.id).toSet();
    final selectedCategoryId =
        _selectedCategoryId != null && categoryIds.contains(_selectedCategoryId)
        ? _selectedCategoryId
        : null;
    final quickCategories = categories.take(3).toList(growable: false);
    final quickCategoryIds = quickCategories
        .map((category) => category.id)
        .toSet();
    final selectedCategory = selectedCategoryId != null
        ? categories.firstWhere((category) => category.id == selectedCategoryId)
        : null;
    final selectedOutsideQuick =
        selectedCategoryId != null &&
        !quickCategoryIds.contains(selectedCategoryId);
    final parentAllocationWarning = _parentAllocationWarningText(
      amount: _parseAmount(amountController.text) ?? 0,
      subCategoryId: selectedCategoryId,
    );
    final wallets = _dedupeWalletsById(
      rawWallets?.whereType<Wallet>().toList() ?? const <Wallet>[],
    );
    final walletIds = wallets.map((wallet) => wallet.id).toSet();
    final selectedWalletId =
        _selectedWalletId != null && walletIds.contains(_selectedWalletId)
        ? _selectedWalletId
        : null;
    final receiptSizeLabel = _receiptSize != null
        ? _formatBytes(_receiptSize!)
        : null;
    final hasInvalidCategories =
        rawCategories != null &&
        rawCategories.any((item) => item is! fm.Category);
    final hasInvalidParentCategories =
        rawParentCategories != null &&
        rawParentCategories.any((item) => item is! fm.Category);
    final hasInvalidWallets =
        rawWallets != null && rawWallets.any((item) => item is! Wallet);
    if ((hasInvalidCategories ||
            hasInvalidParentCategories ||
            hasInvalidWallets) &&
        !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadData();
        }
      });
    }
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.success),
            onPressed: _isSaving ? null : _handleSave,
          ),
        ],
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.transactions,
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
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ),
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
                  const SizedBox(height: 20),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'AMOUNT',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: amountController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.number,
                          inputFormatters: const [_VndInputFormatter()],
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                              ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: _formatDate(_effectiveDate()),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wallet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int?>(
                    value: selectedWalletId,
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
                        child: Text('Select a wallet'),
                      ),
                      ...wallets.map(
                        (wallet) => DropdownMenuItem<int?>(
                          value: wallet.id,
                          child: Text(wallet.name),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedWalletId = value),
                  ),
                  if (_isExpense) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Category',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (categories.isEmpty)
                      Text(
                        'No subcategories available.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (categories.isNotEmpty)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 10.0;
                          final itemWidth =
                              (constraints.maxWidth - (spacing * 3)) / 4;
                          return Row(
                            children: [
                              for (var i = 0; i < 3; i++)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: spacing,
                                  ),
                                  child: SizedBox(
                                    width: itemWidth,
                                    child: _CategoryQuickTile(
                                      label: i < quickCategories.length
                                          ? quickCategories[i].name
                                          : '-',
                                      icon: i < quickCategories.length
                                          ? CategoryUi.iconFromString(
                                              quickCategories[i].icon,
                                            )
                                          : null,
                                      iconColor: i < quickCategories.length
                                          ? CategoryUi.colorFromString(
                                              quickCategories[i].color,
                                              fallback: AppColors.primaryBlue,
                                            )
                                          : null,
                                      selected:
                                          i < quickCategories.length &&
                                          quickCategories[i].id ==
                                              selectedCategoryId,
                                      onTap: i < quickCategories.length
                                          ? () => _selectSubcategory(
                                              quickCategories[i].id,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: itemWidth,
                                child: _CategoryQuickTile(
                                  label: selectedCategory?.name ?? 'More',
                                  icon: selectedCategory != null
                                      ? CategoryUi.iconFromString(
                                          selectedCategory.icon,
                                        )
                                      : null,
                                  iconColor: selectedCategory != null
                                      ? CategoryUi.colorFromString(
                                          selectedCategory.color,
                                          fallback: AppColors.primaryBlue,
                                        )
                                      : null,
                                  selected: selectedOutsideQuick,
                                  onTap: () => _openCategoryPickerModal(
                                    parentCategories: parentCategories,
                                    childCategories: categories,
                                  ),
                                  isMore: selectedCategory == null,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    if (parentAllocationWarning != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Text(
                          parentAllocationWarning,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFFB45309),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  _NoteField(controller: _noteController),
                  const SizedBox(height: 16),
                  _AttachmentCard(
                    fileBytes: _receiptBytes,
                    fileName: _receiptName,
                    fileSize: receiptSizeLabel,
                    onTap: _pickReceipt,
                    onRemove: _receiptBytes != null ? _clearReceipt : null,
                    isDisabled: _isSaving,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Save Transaction',
                    color: const Color(0xFF22C55E),
                    isLoading: _isSaving,
                    onPressed: _isSaving ? null : _handleSave,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: content,
    );
  }
}

class _CategoryQuickTile extends StatelessWidget {
  const _CategoryQuickTile({
    required this.label,
    required this.selected,
    this.onTap,
    this.isMore = false,
    this.icon,
    this.iconColor,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool isMore;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryBlue.withValues(alpha: 0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primaryBlue : AppColors.border,
          width: selected ? 1.3 : 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isMore)
              const Icon(
                Icons.more_horiz,
                size: 16,
                color: AppColors.textSecondary,
              )
            else if (icon != null)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.primaryBlue).withValues(
                    alpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 15,
                  color: iconColor ?? AppColors.primaryBlue,
                ),
              ),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return Opacity(opacity: 0.5, child: tile);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: tile,
    );
  }
}

class _CategoryPickerResult {
  const _CategoryPickerResult.select(this.selectedCategoryId)
    : openCreate = false;

  const _CategoryPickerResult.openCreate()
    : selectedCategoryId = null,
      openCreate = true;

  final int? selectedCategoryId;
  final bool openCreate;
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Add an optional note...',
          border: InputBorder.none,
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.onTap,
    this.onRemove,
    this.fileBytes,
    this.fileName,
    this.fileSize,
    this.isDisabled = false,
  });

  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final Uint8List? fileBytes;
  final String? fileName;
  final String? fileSize;
  final bool isDisabled;

  @override
  Widget build(BuildContext context) {
    final hasFile = fileBytes != null;
    final title = hasFile
        ? (fileName?.trim().isNotEmpty == true
              ? fileName!.trim()
              : 'Receipt attached')
        : 'Attach Receipt';
    final subtitle = hasFile
        ? (fileSize != null ? 'Tap to change • $fileSize' : 'Tap to change')
        : 'JPG, PNG (max 5MB)';

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          if (hasFile)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                fileBytes!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.fieldBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long, color: AppColors.textMuted),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasFile && onRemove != null)
            IconButton(
              onPressed: isDisabled ? null : onRemove,
              icon: const Icon(Icons.close, color: AppColors.textMuted),
            )
          else
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                color: AppColors.primaryBlue,
              ),
            ),
        ],
      ),
    );

    return Opacity(
      opacity: isDisabled ? 0.6 : 1,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}

class _PickedReceipt {
  const _PickedReceipt({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class _VndInputFormatter extends TextInputFormatter {
  const _VndInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
