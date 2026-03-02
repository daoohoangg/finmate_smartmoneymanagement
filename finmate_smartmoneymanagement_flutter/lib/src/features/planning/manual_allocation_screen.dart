import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../../shared/widgets/primary_button.dart';
import 'services/allocation_plan_service.dart';
import '../transactions/services/transaction_service.dart';
import 'manage_budget_screen.dart';

double _safeFiniteDouble(Object? value) {
  if (value is num) {
    final parsed = value.toDouble();
    if (parsed.isFinite && !parsed.isNaN) {
      return parsed;
    }
  }
  return 0;
}

int _safeRound(Object? value) => _safeFiniteDouble(value).round();

class ManualAllocationScreen extends StatefulWidget {
  const ManualAllocationScreen({super.key});

  static const String routeName = '/manual-allocation';

  @override
  State<ManualAllocationScreen> createState() => _ManualAllocationScreenState();
}

class _ManualAllocationScreenState extends State<ManualAllocationScreen> {
  static const double _recommendedNecessary = 60;
  static const double _recommendedAccumulation = 20;
  static const double _recommendedFlexibility = 20;

  final TransactionService _transactionService = TransactionService();
  final AllocationPlanService _allocationPlanService = AllocationPlanService();

  double _necessary = _recommendedNecessary;
  double _accumulation = _recommendedAccumulation;
  double _flexibility = _recommendedFlexibility;
  double _baseAmount = 0;
  bool _isLoadingBaseAmount = true;
  bool _isLoadingPlan = true;
  bool _isSavingPlan = false;
  String? _baseAmountError;
  String? _planError;

  double get _total => _necessary + _accumulation + _flexibility;

  @override
  void initState() {
    super.initState();
    _loadBaseAmount();
    _loadAllocationPlan();
  }

  void _resetToRecommended() {
    setState(() {
      _necessary = _recommendedNecessary;
      _accumulation = _recommendedAccumulation;
      _flexibility = _recommendedFlexibility;
    });
  }

  Future<void> _loadBaseAmount() async {
    setState(() {
      _isLoadingBaseAmount = true;
      _baseAmountError = null;
    });
    try {
      final transactions = await _transactionService.getTransactions();
      double income = 0;
      double expense = 0;
      for (final transaction in transactions) {
        final type = transaction['type']?.toString().toUpperCase();
        final amount = _toDouble(transaction['amount']);
        if (type == 'INCOME') {
          income += amount;
        } else if (type == 'EXPENSE') {
          expense += amount;
        }
      }
      if (!mounted) return;
      setState(() {
        _baseAmount = income - expense;
        _isLoadingBaseAmount = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _baseAmountError = e.toString();
        _baseAmount = 0;
        _isLoadingBaseAmount = false;
      });
    }
  }

  Future<void> _loadAllocationPlan() async {
    setState(() {
      _isLoadingPlan = true;
      _planError = null;
    });
    try {
      final plan = await _allocationPlanService.getAllocationPlan();
      if (!mounted) return;
      setState(() {
        _necessary = plan.necessary;
        _accumulation = plan.accumulation;
        _flexibility = plan.flexibility;
        _isLoadingPlan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _planError = e.toString();
        _isLoadingPlan = false;
      });
    }
  }

  double _toDouble(Object? value) {
    if (value is num) return _safeFiniteDouble(value);
    return _safeFiniteDouble(double.tryParse(value?.toString() ?? ''));
  }

  String _formatVnd(Object? amount) {
    final rounded = _safeRound(amount);
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix$separatedđ';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveCustomPlan() async {
    if (_isSavingPlan) return;
    final total = _safeFiniteDouble(_total);
    if ((total - 100).abs() > 0.1) {
      _showSnack('Total allocation must equal 100%');
      return;
    }

    setState(() => _isSavingPlan = true);
    try {
      final savedPlan = await _allocationPlanService.saveAllocationPlan(
        necessary: _necessary,
        accumulation: _accumulation,
        flexibility: _flexibility,
      );
      if (!mounted) return;
      setState(() {
        _necessary = savedPlan.necessary;
        _accumulation = savedPlan.accumulation;
        _flexibility = savedPlan.flexibility;
      });
      _showSnack('Custom plan saved successfully');
      Navigator.pushNamed(context, ManageBudgetScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSavingPlan = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPercent = _safeFiniteDouble(_total);
    final necessaryPercent = _safeFiniteDouble(_necessary);
    final accumulationPercent = _safeFiniteDouble(_accumulation);
    final flexibilityPercent = _safeFiniteDouble(_flexibility);
    final baseAmount = _safeFiniteDouble(_baseAmount);

    final totalText = '${_safeRound(totalPercent)}%';
    final totalColor = (totalPercent - 100).abs() < 1
        ? AppColors.success
        : AppColors.primaryRed;
    final necessaryAmount = baseAmount * (necessaryPercent / 100);
    final accumulationAmount = baseAmount * (accumulationPercent / 100);
    final flexibilityAmount = baseAmount * (flexibilityPercent / 100);
    final baseAmountText = _isLoadingBaseAmount ? '--' : _formatVnd(baseAmount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Allocation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: () {
              _loadBaseAmount();
              _loadAllocationPlan();
            },
          ),
        ],
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.overview,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Plan Overview',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Total: $totalText',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: totalColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adjust sliders to balance your budget.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Total balance:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          baseAmountText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (_baseAmountError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _baseAmountError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                  if (_planError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _planError!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _AllocationPreview(
                    necessary: _necessary,
                    accumulation: _accumulation,
                    flexibility: _flexibility,
                    necessaryAmountText: _isLoadingBaseAmount
                        ? '--'
                        : _formatVnd(necessaryAmount),
                    accumulationAmountText: _isLoadingBaseAmount
                        ? '--'
                        : _formatVnd(accumulationAmount),
                    flexibilityAmountText: _isLoadingBaseAmount
                        ? '--'
                        : _formatVnd(flexibilityAmount),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Customize Your Plan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SliderCard(
                    title: 'Necessary',
                    subtitle: 'Essential living expenses',
                    icon: Icons.home_outlined,
                    color: const Color(0xFF2CB67D),
                    value: _necessary,
                    amountText: _isLoadingBaseAmount
                        ? '--'
                        : _formatVnd(necessaryAmount),
                    onChanged: (value) => setState(() => _necessary = value),
                  ),
                  const SizedBox(height: 12),
                  _SliderCard(
                    title: 'Accumulation',
                    subtitle: 'Savings and long-term goals',
                    icon: Icons.savings_outlined,
                    color: const Color(0xFF6366F1),
                    value: _accumulation,
                    amountText: _isLoadingBaseAmount
                        ? '--'
                        : _formatVnd(accumulationAmount),
                    onChanged: (value) => setState(() => _accumulation = value),
                  ),
                  const SizedBox(height: 12),
                  _SliderCard(
                    title: 'Flexibility',
                    subtitle: 'Variable spending and short-term buffer',
                    icon: Icons.auto_awesome_outlined,
                    color: const Color(0xFFF59E0B),
                    value: _flexibility,
                    amountText: _isLoadingBaseAmount
                        ? '--'
                        : _formatVnd(flexibilityAmount),
                    onChanged: (value) => setState(() => _flexibility = value),
                  ),
                  const SizedBox(height: 16),
                  _HelpCard(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Custom Plan',
                    color: AppColors.primaryBlue,
                    isLoading: _isSavingPlan,
                    onPressed: _isLoadingPlan ? null : _saveCustomPlan,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: _isSavingPlan ? null : _resetToRecommended,
                      child: const Text(
                        'Reset to Recommended',
                        style: TextStyle(color: AppColors.primaryBlue),
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

class _AllocationPreview extends StatelessWidget {
  const _AllocationPreview({
    required this.necessary,
    required this.accumulation,
    required this.flexibility,
    required this.necessaryAmountText,
    required this.accumulationAmountText,
    required this.flexibilityAmountText,
  });

  final double necessary;
  final double accumulation;
  final double flexibility;
  final String necessaryAmountText;
  final String accumulationAmountText;
  final String flexibilityAmountText;

  @override
  Widget build(BuildContext context) {
    final safeNecessary = _safeFiniteDouble(necessary);
    final safeAccumulation = _safeFiniteDouble(accumulation);
    final safeFlexibility = _safeFiniteDouble(flexibility);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Allocation Split',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${_safeRound(safeNecessary)} / ${_safeRound(safeAccumulation)} / ${_safeRound(safeFlexibility)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final total = safeNecessary + safeAccumulation + safeFlexibility;
              double safeWidth(double value) =>
                  total == 0 ? 0 : constraints.maxWidth * (value / total);
              return Row(
                children: [
                  Container(
                    width: safeWidth(safeNecessary),
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2CB67D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: safeWidth(safeAccumulation),
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: safeWidth(safeFlexibility),
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(label: 'Necessary', color: const Color(0xFF2CB67D)),
              const SizedBox(width: 12),
              _LegendDot(label: 'Accumulation', color: const Color(0xFF6366F1)),
              const SizedBox(width: 12),
              _LegendDot(label: 'Flexibility', color: const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _AmountPill(
                  label: 'Necessary',
                  amount: necessaryAmountText,
                  color: const Color(0xFF2CB67D),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountPill(
                  label: 'Accumulation',
                  amount: accumulationAmountText,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AmountPill(
                  label: 'Flexibility',
                  amount: flexibilityAmountText,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AmountPill extends StatelessWidget {
  const _AmountPill({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.amountText,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double value;
  final String amountText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final safeValue = _safeFiniteDouble(value).clamp(0, 100).toDouble();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_safeRound(safeValue)}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amountText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.border,
              thumbColor: Colors.white,
              overlayColor: color.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: safeValue,
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our smart tool can suggest the best allocation based on your income.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.show_chart, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
