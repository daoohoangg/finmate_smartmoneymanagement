import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../wallets/models/wallet.dart';
import '../wallets/services/wallet_service.dart';
import 'models/budget.dart';
import 'services/budget_service.dart';

class BudgetStatusTrackScreen extends StatefulWidget {
  const BudgetStatusTrackScreen({super.key});

  static const String routeName = '/budget/status-track';

  @override
  State<BudgetStatusTrackScreen> createState() =>
      _BudgetStatusTrackScreenState();
}

class _BudgetStatusTrackScreenState extends State<BudgetStatusTrackScreen> {
  final BudgetService _budgetService = BudgetService();
  final WalletService _walletService = WalletService();

  bool _isLoading = true;
  bool _isLoadingWallets = false;
  String? _error;
  List<Budget> _budgets = const [];
  List<Wallet> _wallets = const [];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    _loadWallets();
  }

  Future<void> _loadBudgets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final budgets = await _budgetService.getBudgets();
      if (!mounted) return;
      setState(() {
        _budgets = budgets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadWallets() async {
    if (_isLoadingWallets) return;
    setState(() => _isLoadingWallets = true);
    try {
      final wallets = await _walletService.getWallets();
      if (!mounted) return;
      setState(() => _wallets = wallets);
    } catch (_) {
      // Keep current wallet list on failure.
    } finally {
      if (mounted) {
        setState(() => _isLoadingWallets = false);
      }
    }
  }

  String _formatVnd(num amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix$separatedđ';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  double _savingPercent(Budget budget) {
    if (budget.amountLimit <= 0) return 0;
    if (budget.savingProgressPercentage > 0) {
      return budget.savingProgressPercentage.toDouble();
    }
    return (budget.savedAmount / budget.amountLimit) * 100;
  }

  Color _progressColor(double percent) {
    if (percent >= 100) return AppColors.success;
    if (percent >= 75) return const Color(0xFFF59E0B);
    return AppColors.primaryBlue;
  }

  String _budgetTitle(Budget budget) {
    if (budget.name.trim().isNotEmpty) {
      return budget.name.trim();
    }
    if (budget.categoryName.trim().isNotEmpty) {
      return budget.categoryName.trim();
    }
    return 'Fund #${budget.id}';
  }

  num? _parseContributionAmount(String raw) {
    final cleaned = raw.trim().replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    final parsed = num.tryParse(cleaned);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Future<void> _openAddMoneyDialog(Budget budget) async {
    if (_wallets.isEmpty) {
      await _loadWallets();
    }
    if (!mounted) return;
    if (_wallets.isEmpty) {
      _showSnack('Please create a wallet first');
      return;
    }

    final amountController = TextEditingController();
    final noteController = TextEditingController();
    final input = await showDialog<_FundContributionInput>(
      context: context,
      builder: (dialogContext) {
        int selectedWalletId = _wallets.first.id;
        String? localError;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add money to fund'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedWalletId,
                      decoration: const InputDecoration(labelText: 'Wallet'),
                      items: _wallets
                          .map(
                            (wallet) => DropdownMenuItem<int>(
                              value: wallet.id,
                              child: Text(
                                '${wallet.name} (${_formatVnd(wallet.balance ?? 0)})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedWalletId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        hintText: 'Example: 500000',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (optional)',
                        hintText: 'Example: Save for emergency fund',
                      ),
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        localError!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = _parseContributionAmount(
                      amountController.text,
                    );
                    if (parsed == null) {
                      setDialogState(
                        () => localError = 'Please enter a valid amount',
                      );
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      _FundContributionInput(
                        amount: parsed,
                        walletId: selectedWalletId,
                        note: noteController.text.trim(),
                      ),
                    );
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
    noteController.dispose();
    if (input == null) return;
    await _addMoneyToFund(
      budgetId: budget.id,
      amount: input.amount,
      walletId: input.walletId,
      note: input.note,
    );
  }

  Future<void> _addMoneyToFund({
    required int budgetId,
    required num amount,
    required int walletId,
    String? note,
  }) async {
    try {
      final updatedBudget = await _budgetService.addContribution(
        budgetId: budgetId,
        amount: amount,
        walletId: walletId,
        note: note,
      );
      if (!mounted) return;
      setState(() {
        _budgets = _budgets
            .map((budget) => budget.id == budgetId ? updatedBudget : budget)
            .toList(growable: false);
      });
      _loadWallets();
      _showSnack('Money added successfully');
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    }
  }

  Future<void> _openBudgetDetail(Budget budget) async {
    final progress = _savingPercent(budget);
    final color = _progressColor(progress);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _budgetTitle(budget),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      budget.period.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  budget.categoryName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(
                      '${progress.toStringAsFixed(0)}% saved',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Target ${_formatVnd(budget.amountLimit)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (progress / 100).clamp(0, 1),
                    minHeight: 10,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 14),
                _DetailRow(
                  label: 'Target',
                  value: _formatVnd(budget.amountLimit),
                ),
                const SizedBox(height: 8),
                _DetailRow(label: 'Saved', value: _formatVnd(budget.savedAmount)),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Remaining',
                  value: _formatVnd(budget.remainingToGoal),
                  valueColor: budget.remainingToGoal < 0
                      ? AppColors.primaryRed
                      : AppColors.success,
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  label: 'Progress',
                  value: '${progress.toStringAsFixed(0)}%',
                  valueColor: color,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _openAddMoneyDialog(budget);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add money'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load funds list',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadBudgets,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_budgets.isEmpty) {
      return Center(
        child: Text(
          'No funds found',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final completedCount = _budgets
        .where((budget) => _savingPercent(budget) >= 100)
        .length;

    return RefreshIndicator(
      onRefresh: _loadBudgets,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _budgets.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _BudgetSummaryHeader(
              totalBudgets: _budgets.length,
              completedBudgets: completedCount,
            );
          }
          final budget = _budgets[index - 1];
          final progress = _savingPercent(budget);
          final color = _progressColor(progress);
          return _BudgetItemCard(
            title: _budgetTitle(budget),
            categoryName: budget.categoryName,
            targetText: _formatVnd(budget.amountLimit),
            savedText: _formatVnd(budget.savedAmount),
            progressText: '${progress.toStringAsFixed(0)}%',
            usageColor: color,
            progress: (progress / 100).clamp(0, 1),
            onTap: () => _openBudgetDetail(budget),
            onAddMoney: () => _openAddMoneyDialog(budget),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Funds Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: _loadBudgets,
          ),
        ],
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.overview,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }
}

class _BudgetSummaryHeader extends StatelessWidget {
  const _BudgetSummaryHeader({
    required this.totalBudgets,
    required this.completedBudgets,
  });

  final int totalBudgets;
  final int completedBudgets;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalBudgets funds',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  completedBudgets > 0
                      ? '$completedBudgets reached target'
                      : 'Keep adding to reach your targets',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetItemCard extends StatelessWidget {
  const _BudgetItemCard({
    required this.title,
    required this.categoryName,
    required this.targetText,
    required this.savedText,
    required this.progressText,
    required this.usageColor,
    required this.progress,
    required this.onTap,
    required this.onAddMoney,
  });

  final String title;
  final String categoryName;
  final String targetText;
  final String savedText;
  final String progressText;
  final Color usageColor;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onAddMoney;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    progressText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: usageColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                categoryName,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(usageColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Saved: $savedText / $targetText',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onAddMoney,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FundContributionInput {
  const _FundContributionInput({
    required this.amount,
    required this.walletId,
    this.note,
  });

  final num amount;
  final int walletId;
  final String? note;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
