import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class RecurringCustomScreen extends StatefulWidget {
  const RecurringCustomScreen({super.key});

  static const String routeName = '/recurring/custom';

  @override
  State<RecurringCustomScreen> createState() => _RecurringCustomScreenState();
}

class _RecurringCustomScreenState extends State<RecurringCustomScreen> {
  String _selectedFrequency = 'Custom';
  String _unit = 'Months';
  final TextEditingController _intervalController = TextEditingController(text: '0');

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  bool get _hasError => _intervalController.text.trim() == '0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Recurring Setup'),
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
                  _ExpenseSummaryCard(
                    title: 'Netflix Subscription',
                    amount: '\$15.99',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Repeat Frequency',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _FrequencySelector(
                    selected: _selectedFrequency,
                    onSelected: (value) {
                      if (value != 'Custom') {
                        Navigator.pop(context);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Repeat every',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _intervalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: '0',
                            filled: true,
                            fillColor: AppColors.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _hasError ? AppColors.primaryRed : AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: _hasError ? AppColors.primaryRed : AppColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _unit,
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
                          items: const [
                            DropdownMenuItem(value: 'Days', child: Text('Days')),
                            DropdownMenuItem(value: 'Weeks', child: Text('Weeks')),
                            DropdownMenuItem(value: 'Months', child: Text('Months')),
                            DropdownMenuItem(value: 'Years', child: Text('Years')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _unit = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  if (_hasError) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.primaryRed),
                        const SizedBox(width: 6),
                        Text(
                          'Interval must be at least 1',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.primaryRed),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primaryRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Custom recurring rules allow you to set specific intervals like "Every 3 Months" or "Every 2 Weeks".',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Configuration',
                    color: _hasError ? const Color(0xFFFCA5A5) : AppColors.primaryRed,
                    onPressed: _hasError ? null : () {},
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Please fix the errors to continue.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
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

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.title,
    required this.amount,
  });

  final String title;
  final String amount;

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
                  'Expense Summary',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.primaryRed, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFECACA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'N',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryRed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const options = ['Daily', 'Weekly', 'Monthly', 'Custom'];
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
                  color: isSelected ? AppColors.primaryRed : Colors.transparent,
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
