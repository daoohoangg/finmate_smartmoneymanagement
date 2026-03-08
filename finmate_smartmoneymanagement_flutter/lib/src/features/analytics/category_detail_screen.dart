import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class CategoryDetailScreen extends StatelessWidget {
  const CategoryDetailScreen({super.key});

  static const String routeName = '/analytics/category-detail';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Food & Dining'),
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
                  _TotalCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Transactions',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text('October', style: TextStyle(color: AppColors.primaryBlue)),
                      ),
                    ],
                  ),
                  const _TransactionItem(
                    date: 'Oct 28',
                    title: 'Whole Foods Market',
                    subtitle: 'Groceries',
                    amount: '-\$142.50',
                    time: '2:14 PM',
                  ),
                  const SizedBox(height: 8),
                  const _TransactionItem(
                    date: 'Oct 26',
                    title: 'Starbucks Coffee',
                    subtitle: 'Morning Caffeine',
                    amount: '-\$5.75',
                    time: '8:45 AM',
                  ),
                  const SizedBox(height: 8),
                  const _TransactionItem(
                    date: 'Oct 25',
                    title: 'Chipotle Mexican Grill',
                    subtitle: 'Dinner out',
                    amount: '-\$18.40',
                    time: '7:30 PM',
                  ),
                  const SizedBox(height: 8),
                  const _TransactionItem(
                    date: 'Oct 22',
                    title: 'Sweetgreen',
                    subtitle: 'Lunch delivery',
                    amount: '-\$24.95',
                    time: '1:12 PM',
                  ),
                  const SizedBox(height: 8),
                  const _TransactionItem(
                    date: 'Oct 20',
                    title: 'Trader Joe\'s',
                    subtitle: 'Weekly groceries',
                    amount: '-\$89.30',
                    time: '6:45 PM',
                  ),
                  const SizedBox(height: 8),
                  const _TransactionItem(
                    date: 'Oct 18',
                    title: 'Blue Bottle Coffee',
                    subtitle: 'Beverage',
                    amount: '-\$6.50',
                    time: '10:20 AM',
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

class _TotalCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant, color: Color(0xFF22C55E)),
          ),
          const SizedBox(height: 10),
          Text(
            'Total Spent',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            '\$1,200.00',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F9ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+2% vs last month',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  const _TransactionItem({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.time,
  });

  final String date;
  final String title;
  final String subtitle;
  final String amount;
  final String time;

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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.fieldBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                date.split(' ').last,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
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
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.primaryRed, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
