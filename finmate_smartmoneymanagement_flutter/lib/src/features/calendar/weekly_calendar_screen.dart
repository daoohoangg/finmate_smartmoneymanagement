import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class WeeklyCalendarScreen extends StatelessWidget {
  const WeeklyCalendarScreen({super.key});

  static const String routeName = '/calendar/weekly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('October 2023'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Today', style: TextStyle(color: AppColors.primaryBlue)),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.calendar),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ViewToggle(),
                  const SizedBox(height: 16),
                  _WeekStrip(),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Income Today',
                          amount: '+\$450.00',
                          color: AppColors.success,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expense Today',
                          amount: '-\$125.40',
                          color: AppColors.primaryRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thursday, Oct 12',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 8),
                  const _TransactionRow(
                    title: 'Client Payment',
                    subtitle: 'Freelance Project - UI Design',
                    amount: '+\$450.00',
                    wallet: 'Main Savings',
                    icon: Icons.account_balance_wallet_outlined,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 8),
                  const _TransactionRow(
                    title: 'Starbucks Coffee',
                    subtitle: 'Lunch break with the team',
                    amount: '-\$12.40',
                    wallet: 'Apple Pay (Visa)',
                    icon: Icons.local_cafe_outlined,
                    color: Color(0xFFF97316),
                  ),
                  const SizedBox(height: 8),
                  const _TransactionRow(
                    title: 'Weekly Groceries',
                    subtitle: 'Whole Foods Market',
                    amount: '-\$113.00',
                    wallet: 'Mastercard',
                    icon: Icons.shopping_bag_outlined,
                    color: Color(0xFF8B5CF6),
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

class _ViewToggle extends StatelessWidget {
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
        children: const [
          _ToggleItem(label: 'Month', selected: false),
          _ToggleItem(label: 'Week', selected: true),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const dates = [9, 10, 11, 12, 13, 14, 15];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(days.length, (index) {
        final selected = dates[index] == 12;
        return Column(
          children: [
            Text(
              days[index],
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBlue : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? AppColors.primaryBlue : AppColors.border),
              ),
              child: Center(
                child: Text(
                  dates[index].toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  final String title;
  final String amount;
  final Color color;

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
            title,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.wallet,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String wallet;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  wallet.toUpperCase(),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

