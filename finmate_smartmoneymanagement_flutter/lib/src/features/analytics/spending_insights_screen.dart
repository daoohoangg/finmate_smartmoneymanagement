import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class SpendingInsightsScreen extends StatelessWidget {
  const SpendingInsightsScreen({super.key});

  static const String routeName = '/analytics/insights';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Spending Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
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
                  Text(
                    'AI Analysis',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 10),
                  _InsightCard(
                    title: 'Food & Drinks',
                    message:
                        'You spent 20% more on food compared to last month. Consider setting a daily budget.',
                    color: const Color(0xFFFFE4E4),
                    icon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 12),
                  _InsightCard(
                    title: 'Weekend Spending',
                    message:
                        'You spend the most on weekends. Try planning your meals and errands in advance.',
                    color: const Color(0xFFFFF7ED),
                    icon: Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        'Recent Activities',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'See all',
                          style: TextStyle(color: AppColors.primaryBlue),
                        ),
                      ),
                    ],
                  ),
                  const _ActivityRow(
                    title: 'Starbucks',
                    subtitle: 'Dining - Today, 10:45 AM',
                    amount: '-\$12.50',
                    color: AppColors.primaryRed,
                    icon: Icons.local_cafe_outlined,
                  ),
                  const SizedBox(height: 8),
                  const _ActivityRow(
                    title: 'Apple Subscription',
                    subtitle: 'Entertainment - Yesterday',
                    amount: '-\$9.99',
                    color: AppColors.primaryRed,
                    icon: Icons.subscriptions_outlined,
                  ),
                  const SizedBox(height: 8),
                  const _ActivityRow(
                    title: 'Whole Foods Market',
                    subtitle: 'Groceries - Oct 14',
                    amount: '-\$84.20',
                    color: AppColors.primaryRed,
                    icon: Icons.shopping_cart_outlined,
                  ),
                  const SizedBox(height: 8),
                  const _ActivityRow(
                    title: 'Shell Gas Station',
                    subtitle: 'Transport - Oct 13',
                    amount: '-\$45.00',
                    color: AppColors.primaryRed,
                    icon: Icons.local_gas_station_outlined,
                  ),
                  const SizedBox(height: 8),
                  const _ActivityRow(
                    title: 'Payroll Deposit',
                    subtitle: 'Income - Oct 12',
                    amount: '+\$3,250.00',
                    color: AppColors.success,
                    icon: Icons.account_balance_wallet_outlined,
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

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryRed, size: 18),
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
                const SizedBox(height: 4),
                Text(
                  message,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color color;
  final IconData icon;

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
              color: color.withOpacity(0.12),
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

