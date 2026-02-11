import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import 'recurring_custom_screen.dart';

class RecurringSetupScreen extends StatefulWidget {
  const RecurringSetupScreen({super.key});

  static const String routeName = '/recurring/setup';

  @override
  State<RecurringSetupScreen> createState() => _RecurringSetupScreenState();
}

class _RecurringSetupScreenState extends State<RecurringSetupScreen> {
  String _selectedFrequency = 'Monthly';
  bool _enabled = true;

  void _openCustom() {
    Navigator.pushNamed(context, RecurringCustomScreen.routeName);
  }

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
                    title: 'Coffee',
                    amount: '-\$15.00',
                    wallet: 'Cash',
                    icon: Icons.local_cafe_outlined,
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
                      if (value == 'Custom') {
                        _openCustom();
                      } else {
                        setState(() => _selectedFrequency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.refresh, size: 16, color: AppColors.primaryBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Repeat on the 24th of every month',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Schedule',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Expanded(
                        child: _ScheduleCard(
                          label: 'Start Date',
                          value: 'Sep 24, 2023',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ScheduleCard(
                          label: 'End Date',
                          value: 'Never',
                          icon: Icons.event_busy_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          child: const Icon(Icons.autorenew, color: AppColors.primaryBlue, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Enable Recurring',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Switch(
                          value: _enabled,
                          activeColor: AppColors.primaryBlue,
                          onChanged: (value) => setState(() => _enabled = value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Recurring Rule',
                    color: AppColors.primaryBlue,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Next transaction will be created automatically on Oct 24, 2023.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
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
    required this.wallet,
    required this.icon,
  });

  final String title;
  final String amount;
  final String wallet;
  final IconData icon;

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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '$title - $wallet',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.primaryBlue, size: 18),
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

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}
