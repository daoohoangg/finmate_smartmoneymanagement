import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../categories/models/category.dart' as fm;
import '../categories/services/category_service.dart';
import '../categories/utils/category_ui.dart';
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
  int? _selectedParentCategoryId;
  int? _selectedWalletId;
  List<fm.Category>? _categories;
  List<fm.Category>? _parentCategories;
  Map<int, List<fm.Category>> _childrenByParent = const <int, List<fm.Category>>{};
  List<Wallet>? _wallets;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  DateTime? _selectedDate;
  bool _isSeedingWallets = false;
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

  CategoryService get _categorySvc => _categoryService ??= CategoryService();
  WalletService get _walletSvc => _walletService ??= WalletService();
  TransactionService get _transactionSvc => _transactionService ??= TransactionService();
  ReceiptUploadService get _receiptUploadSvc =>
      _receiptUploadService ??= ReceiptUploadService();

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
    _childrenByParent = const <int, List<fm.Category>>{};
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
      final order = <String, int>{
        'cash': 0,
        'bank account': 1,
        'card': 2,
      };
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
      setState(() {
        _wallets = wallets;
        _selectedWalletId = _resolveSelectedWalletId(wallets, _selectedWalletId);
        if (_isExpense) {
          final categoryTree = _buildExpenseCategoryTree(loadedCategories);
          final parentCategories = categoryTree.parentCategories;
          final childrenByParent = categoryTree.childrenByParent;
          final parentId =
              (_selectedParentCategoryId != null &&
                  parentCategories.any((category) => category.id == _selectedParentCategoryId))
              ? _selectedParentCategoryId
              : (parentCategories.isNotEmpty ? parentCategories.first.id : null);
          final childCategories =
              parentId != null ? (childrenByParent[parentId] ?? const <fm.Category>[]) : const <fm.Category>[];
          final selectedCategoryId =
              (_selectedCategoryId != null &&
                  childCategories.any((category) => category.id == _selectedCategoryId))
              ? _selectedCategoryId
              : (childCategories.isNotEmpty ? childCategories.first.id : null);
          _parentCategories = parentCategories;
          _childrenByParent = childrenByParent;
          _selectedParentCategoryId = parentId;
          _categories = childCategories;
          _selectedCategoryId = selectedCategoryId;
        } else {
          _parentCategories = const <fm.Category>[];
          _childrenByParent = const <int, List<fm.Category>>{};
          _selectedParentCategoryId = null;
          _categories = const <fm.Category>[];
          _selectedCategoryId = null;
        }
      });
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
      final defaults = <String>[
        'Cash',
        'Bank Account',
        'Card',
      ];
      final existingNames =
          wallets.map((w) => w.name.trim().toLowerCase()).toSet();
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
      setState(() {
        if (_isExpense) {
          final categoryTree = _buildExpenseCategoryTree(loadedCategories);
          final parentCategories = categoryTree.parentCategories;
          final childrenByParent = categoryTree.childrenByParent;
          final parentId = parentCategories.isNotEmpty ? parentCategories.first.id : null;
          final childCategories =
              parentId != null ? (childrenByParent[parentId] ?? const <fm.Category>[]) : const <fm.Category>[];
          _parentCategories = parentCategories;
          _childrenByParent = childrenByParent;
          _selectedParentCategoryId = parentId;
          _categories = childCategories;
          _selectedCategoryId = childCategories.isNotEmpty ? childCategories.first.id : null;
        } else {
          _parentCategories = const <fm.Category>[];
          _childrenByParent = const <int, List<fm.Category>>{};
          _selectedParentCategoryId = null;
          _categories = const <fm.Category>[];
          _selectedCategoryId = null;
        }
      });
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
  }) _buildExpenseCategoryTree(List<fm.Category> loadedCategories) {
    final expenseCategories = loadedCategories
        .where((category) => category.type == fm.CategoryType.expense)
        .toList();
    final parentCandidates = expenseCategories
        .where((category) => category.parentId == null)
        .toList();
    final parentCategories = _selectPrimaryParentCategories(parentCandidates);
    final parentIds = parentCategories.map((category) => category.id).toSet();
    final childrenByParent = <int, List<fm.Category>>{};
    for (final category in expenseCategories) {
      final parentId = category.parentId;
      if (parentId == null || !parentIds.contains(parentId)) continue;
      childrenByParent.putIfAbsent(parentId, () => <fm.Category>[]).add(category);
    }
    for (final entry in childrenByParent.entries) {
      entry.value.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return (
      parentCategories: parentCategories,
      childrenByParent: childrenByParent,
    );
  }

  List<fm.Category> _selectPrimaryParentCategories(List<fm.Category> parentCandidates) {
    final candidates = List<fm.Category>.from(parentCandidates)
      ..sort((a, b) {
        final groupOrderDiff = _categoryGroupOrder(a.group) - _categoryGroupOrder(b.group);
        if (groupOrderDiff != 0) return groupOrderDiff;
        if (a.isSystemCategory != b.isSystemCategory) {
          return a.isSystemCategory ? 1 : -1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    final selected = <fm.Category>[];
    const preferredGroups = <fm.CategoryGroup>[
      fm.CategoryGroup.necessary,
      fm.CategoryGroup.accumulation,
      fm.CategoryGroup.flexibility,
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
      if (selected.any((item) => item.id == category.id)) continue;
      selected.add(category);
      if (selected.length >= 3) break;
    }

    if (selected.length > 3) {
      return selected.take(3).toList();
    }
    return selected;
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

  void _selectParentCategory(int parentId) {
    if (!_isExpense) return;
    final childCategories = _childrenByParent[parentId] ?? const <fm.Category>[];
    setState(() {
      _selectedParentCategoryId = parentId;
      _categories = childCategories;
      final currentCategoryId = _selectedCategoryId;
      if (currentCategoryId != null &&
          childCategories.any((category) => category.id == currentCategoryId)) {
        _selectedCategoryId = currentCategoryId;
      } else {
        _selectedCategoryId = childCategories.isNotEmpty ? childCategories.first.id : null;
      }
    });
  }

  num? _parseAmount(String raw) {
    final normalized = raw.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
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
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    final isMobile = !kIsWeb &&
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
    final fileName =
        (_receiptName != null && _receiptName!.trim().isNotEmpty)
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
    final parentCategories =
        rawParentCategories?.whereType<fm.Category>().toList() ?? const <fm.Category>[];
    final categoryIds = categories.map((category) => category.id).toSet();
    final selectedCategoryId =
        _selectedCategoryId != null && categoryIds.contains(_selectedCategoryId)
            ? _selectedCategoryId
            : null;
    final wallets = _dedupeWalletsById(
      rawWallets?.whereType<Wallet>().toList() ?? const <Wallet>[],
    );
    final walletIds = wallets.map((wallet) => wallet.id).toSet();
    final selectedWalletId =
        _selectedWalletId != null && walletIds.contains(_selectedWalletId)
            ? _selectedWalletId
            : null;
    final receiptSizeLabel =
        _receiptSize != null ? _formatBytes(_receiptSize!) : null;
    final hasInvalidCategories =
        rawCategories != null && rawCategories.any((item) => item is! fm.Category);
    final hasInvalidParentCategories =
        rawParentCategories != null && rawParentCategories.any((item) => item is! fm.Category);
    final hasInvalidWallets = rawWallets != null && rawWallets.any((item) => item is! Wallet);
    if ((hasInvalidCategories || hasInvalidParentCategories || hasInvalidWallets) && !_isLoading) {
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
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.history),
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
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.primaryRed),
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: amountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [_VndInputFormatter()],
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 32, fontWeight: FontWeight.w700),
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
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
                    onChanged: (value) => setState(() => _selectedWalletId = value),
                  ),
                  if (_isExpense) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Category',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    if (parentCategories.isEmpty)
                      Text(
                        'No main categories available.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    if (parentCategories.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Text(
                          'Step 1: Choose main category',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    if (parentCategories.isNotEmpty)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 10.0;
                          final itemWidth = (constraints.maxWidth - (spacing * 2)) / 3;
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: parentCategories.asMap().entries.map((entry) {
                                final index = entry.key;
                                final category = entry.value;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    right: index == parentCategories.length - 1 ? 0 : spacing,
                                  ),
                                  child: SizedBox(
                                    width: itemWidth,
                                    child: _CategoryChip(
                                      label: category.name,
                                      icon: CategoryUi.iconFromString(category.icon),
                                      color: CategoryUi.colorFromString(
                                        category.color,
                                        fallback: AppColors.primaryBlue,
                                      ),
                                      selected: category.id == _selectedParentCategoryId,
                                      onTap: () => _selectParentCategory(category.id),
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
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    if (parentCategories.isNotEmpty && categories.isEmpty)
                      Text(
                        'No subcategories in this main category.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
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
                        onChanged: (value) => setState(() => _selectedCategoryId = value),
                      ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
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
        ? (fileName?.trim().isNotEmpty == true ? fileName!.trim() : 'Receipt attached')
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
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
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
