import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class TrendAnalysisScreen extends StatefulWidget {
  const TrendAnalysisScreen({super.key});

  static const String routeName = '/analytics/trend';

  @override
  State<TrendAnalysisScreen> createState() => _TrendAnalysisScreenState();
}

class _TrendAnalysisScreenState extends State<TrendAnalysisScreen> {
  String _range = '6M';
  bool _barChart = true;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChartToggle(
                    barChart: _barChart,
                    onChanged: (value) => setState(() => _barChart = value),
                  ),
                  const SizedBox(height: 12),
                  _RangeToggle(
                    selected: _range,
                    onSelected: (value) => setState(() => _range = value),
                  ),
                  const SizedBox(height: 16),
                  _NetComparison(),
                  const SizedBox(height: 14),
                  _BarChart(),
                  const SizedBox(height: 16),
                  _MonthlyAverage(),
                  const SizedBox(height: 16),
                  _AverageSavings(),
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
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Net Comparison',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 6),
        Text(
          '+\$1,120.00',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '+12.4% vs prev 6 months',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.success),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    const income = [60.0, 80.0, 70.0, 90.0, 75.0, 95.0];
    const expense = [40.0, 55.0, 50.0, 65.0, 60.0, 70.0];
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(months.length, (index) {
              return Column(
                children: [
                  SizedBox(
                    height: 90,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 8,
                          height: income[index],
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 8,
                          height: expense[index],
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
                    months[index],
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                ],
              );
            }),
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
  @override
  Widget build(BuildContext context) {
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
            'Monthly Average',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            '\$4,520.00',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: 0.72,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '+3% vs last 6 months',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

class _AverageSavings extends StatelessWidget {
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
              'Avg. Net Savings',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.white70),
            ),
          ),
          Text(
            '\$1,120.00',
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

