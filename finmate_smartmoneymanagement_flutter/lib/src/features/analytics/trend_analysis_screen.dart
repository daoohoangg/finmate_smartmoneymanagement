import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../transactions/services/transaction_service.dart';

class _TrendMonth {
  final String label;
  final double income;
  final double expense;
  _TrendMonth(this.label, this.income, this.expense);
}

class TrendAnalysisScreen extends StatefulWidget {
  const TrendAnalysisScreen({super.key});

  static const String routeName = '/analytics/trend';

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen> {
  String _range = '6M';
  bool _barChart = true;

  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _rawTransactions = [];
  List<_TrendMonth> _chartData = [];

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _avgExpense = 0;
  double _avgNetSavings = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final txs = await _transactionService.getTransactions();
      if (!mounted) return;
      _rawTransactions = txs;
      _calculateData();
      setState(() {
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

  void _calculateData() {
    final now = DateTime.now();
    int monthsToSubtract = 6;
    switch (_range) {
      case '1M':
        monthsToSubtract = 1;
        break;
      case '3M':
        monthsToSubtract = 3;
        break;
      case '6M':
        monthsToSubtract = 6;
        break;
      case '1Y':
        monthsToSubtract = 12;
        break;
    }

    final startDate = DateTime(now.year, now.month - monthsToSubtract + 1, 1);

    final grouped = <String, _TrendMonth>{};

    for (int i = 0; i < monthsToSubtract; i++) {
        final d = DateTime(now.year, now.month - monthsToSubtract + 1 + i, 1);
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
        
        final monthsStrings = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final label = monthsStrings[d.month - 1]; // Short label like 'Jan', 'Feb'

        grouped[key] = _TrendMonth(label, 0, 0);
    }

    double totalInc = 0;
    double totalExp = 0;

    for (final tx in _rawTransactions) {
      final dateStr = tx['transactionDate']?.toString();
      if (dateStr == null) continue;
      final date = DateTime.tryParse(dateStr)?.toLocal();
      if (date == null) continue;

      if (date.isBefore(startDate)) continue;

      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      if (grouped.containsKey(key)) {
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
        final type = tx['type'].toString().toUpperCase();

        final current = grouped[key]!;
        if (type == 'INCOME') {
          grouped[key] = _TrendMonth(current.label, current.income + amount, current.expense);
          totalInc += amount;
        } else if (type == 'EXPENSE') {
          grouped[key] = _TrendMonth(current.label, current.income, current.expense + amount);
          totalExp += amount;
        }
      }
    }

    _chartData = grouped.values.toList();
    _totalIncome = totalInc;
    _totalExpense = totalExp;
    _avgExpense = totalExp / monthsToSubtract;
    _avgNetSavings = (totalInc - totalExp) / monthsToSubtract;
  }

  void _onRangeChanged(String value) {
    setState(() {
      _range = value;
      _calculateData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Trend Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _isLoading 
                ? const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
                : _error != null
                ? Center(child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Text(_error!),
                ))
                : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChartToggle(
                    barChart: _barChart,
                    onChanged: (value) => setState(() => _barChart = value),
                  ),
                  const SizedBox(height: 12),
                  _RangeToggle(
                    selected: _range,
                    onSelected: _onRangeChanged,
                  ),
                  const SizedBox(height: 16),
                  _NetComparison(
                    totalIncome: _totalIncome,
                    totalExpense: _totalExpense,
                    rangeLabel: _range,
                  ),
                  const SizedBox(height: 14),
                  _BarChart(chartData: _chartData),
                  const SizedBox(height: 16),
                  _MonthlyAverage(
                    avgExpense: _avgExpense,
                    rangeLabel: _range,
                    totalIncome: _totalIncome,
                  ),
                  const SizedBox(height: 16),
                  _AverageSavings(
                    avgNetSavings: _avgNetSavings,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.overview),
    );
  }
}

class _ChartToggle extends StatelessWidget {
  const _ChartToggle({required this.barChart, required this.onChanged});

  final bool barChart;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            barChart ? 'Bar Chart' : 'Line Chart',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Switch(
          value: barChart,
          onChanged: onChanged,
          activeColor: AppColors.primaryBlue,
        ),
      ],
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = ['1M', '3M', '6M', '1Y'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: options.map((label) {
          final isSelected = selected == label;
          return Expanded(
            child: InkWell(
              onTap: () => onSelected(label),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NetComparison extends StatelessWidget {
  const _NetComparison({
    required this.totalIncome,
    required this.totalExpense,
    required this.rangeLabel,
  });

  final double totalIncome;
  final double totalExpense;
  final String rangeLabel;

  String _formatVnd(double amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final sign = rounded < 0 ? '-' : '';
    return '$sign$separated VND';
  }

  @override
  Widget build(BuildContext context) {
    final netFlow = totalIncome - totalExpense;
    final isPositive = netFlow >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Net Flow (Income - Expense)',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        Text(
          _formatVnd(netFlow),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          isPositive ? '+Positive flow in the last $rangeLabel' : '-Negative flow in the last $rangeLabel',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: isPositive ? AppColors.success : AppColors.primaryRed),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.chartData});

  final List<_TrendMonth> chartData;

  @override
  Widget build(BuildContext context) {
    double maxAmount = 1; // Prevent div by 0
    for(final d in chartData) {
      if (d.income > maxAmount) maxAmount = d.income;
      if (d.expense > maxAmount) maxAmount = d.expense;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              _LegendDot(label: 'Income', color: AppColors.primaryBlue),
              SizedBox(width: 12),
              _LegendDot(label: 'Expense', color: AppColors.primaryRed),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(chartData.length, (index) {
                final d = chartData[index];
                
                // Set min height to 4 if there is value, otherwise 0
                final incHeightRaw = (d.income / maxAmount) * 90;
                final incHeight = (d.income > 0 && incHeightRaw < 4) ? 4.0 : incHeightRaw;
                
                final expHeightRaw = (d.expense / maxAmount) * 90;
                final expHeight = (d.expense > 0 && expHeightRaw < 4) ? 4.0 : expHeightRaw;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 90,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: 8,
                              height: incHeight,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 8,
                              height: expHeight,
                              decoration: BoxDecoration(
                                color: AppColors.primaryRed,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        d.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }),
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
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MonthlyAverage extends StatelessWidget {
  const _MonthlyAverage({
    required this.avgExpense,
    required this.rangeLabel,
    required this.totalIncome,
  });

  final double avgExpense;
  final String rangeLabel;
  final double totalIncome;

  String _formatVnd(double amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final sign = rounded < 0 ? '-' : '';
    return '$sign$separated VND';
  }

  @override
  Widget build(BuildContext context) {
    final percentage = totalIncome <= 0 ? 0.0 : (avgExpense / (totalIncome / (rangeLabel == '1M' ? 1 : (rangeLabel == '3M' ? 3 : (rangeLabel == '6M' ? 6 : 12)))));

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
          Text(
            'Monthly Average Expense',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            _formatVnd(avgExpense),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryRed), // Expenses are red
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}% of average income',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AverageSavings extends StatelessWidget {
  const _AverageSavings({required this.avgNetSavings});

  final double avgNetSavings;

  String _formatVnd(double amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final sign = rounded < 0 ? '-' : '';
    return '$sign$separated VND';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.savings, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Avg. Monthly Net Savings',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ),
          Text(
            _formatVnd(avgNetSavings),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
