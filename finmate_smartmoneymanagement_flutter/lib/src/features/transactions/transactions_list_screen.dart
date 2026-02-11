import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import 'filter_transactions_screen.dart';
import 'search_results_screen.dart';

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  static const String routeName = '/transactions/list';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textMuted),
            onPressed: () => Navigator.pushNamed(context, FilterTransactionsScreen.routeName),
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
                  _SearchField(
                    hint: 'Search by note or amount',
                    onTap: () => Navigator.pushNamed(context, SearchResultsScreen.routeName),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: const [
                      _FilterChip(label: 'Date Range', active: true),
                      _FilterChip(label: 'Category', active: false),
                      _FilterChip(label: 'Wallet', active: false),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Today, Oct 24'),
                  const SizedBox(height: 8),
                  const _TransactionRow(
                    title: 'Whole Foods Market',
                    subtitle: 'Groceries - 10:24 AM',
                    amount: '-\$84.50',
                    amountColor: AppColors.primaryRed,
                    icon: Icons.shopping_cart_outlined,
                    iconColor: Color(0xFFF97316),
                  ),
                  const SizedBox(height: 10),
                  const _TransactionRow(
                    title: 'Shell Gas Station',
                    subtitle: 'Transport - 08:15 AM',
                    amount: '-\$52.00',
                    amountColor: AppColors.primaryRed,
                    icon: Icons.local_gas_station_outlined,
                    iconColor: Color(0xFF3B82F6),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Yesterday, Oct 23'),
                  const SizedBox(height: 8),
                  const _TransactionRow(
                    title: 'Salary Deposit',
                    subtitle: 'Income - Monthly Pay',
                    amount: '+\$3,200.00',
                    amountColor: AppColors.success,
                    icon: Icons.attach_money,
                    iconColor: Color(0xFF22C55E),
                  ),
                  const SizedBox(height: 10),
                  const _TransactionRow(
                    title: 'Monthly Rent',
                    subtitle: 'Housing - Automated',
                    amount: '-\$1,450.00',
                    amountColor: AppColors.primaryRed,
                    icon: Icons.home_work_outlined,
                    iconColor: Color(0xFF22C55E),
                  ),
                  const SizedBox(height: 10),
                  const _TransactionRow(
                    title: 'The Coffee Bean',
                    subtitle: 'Dining - Afternoon Tea',
                    amount: '-\$6.75',
                    amountColor: AppColors.primaryRed,
                    icon: Icons.local_cafe_outlined,
                    iconColor: Color(0xFFF97316),
                  ),
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'Oct 22'),
                  const SizedBox(height: 8),
                  const _TransactionRow(
                    title: 'Cash Withdrawal',
                    subtitle: 'ATM - Main Street',
                    amount: '-\$200.00',
                    amountColor: AppColors.primaryRed,
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Color(0xFF22C55E),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              hint,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryRed : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? AppColors.primaryRed : AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color iconColor;

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
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
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
                .bodyMedium
                ?.copyWith(color: amountColor, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
