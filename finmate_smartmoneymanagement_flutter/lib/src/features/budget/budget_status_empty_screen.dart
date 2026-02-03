import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class BudgetStatusEmptyScreen extends StatelessWidget {
  const BudgetStatusEmptyScreen({super.key});

  static const String routeName = '/budget/status-empty';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Budget Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: _BottomNav(activeIndex: 1),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFED7AA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.account_balance_wallet_outlined,
                          color: Color(0xFFF97316), size: 30),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No budget set for this category.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Track your spending habits better by setting a monthly limit.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 180,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Set a Budget'),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'All values are in VND',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final labels = ['Overview', 'Budget', 'History', 'Profile'];
    final icons = [
      Icons.dashboard_outlined,
      Icons.account_balance_wallet_outlined,
      Icons.receipt_long_outlined,
      Icons.person_outline,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(labels.length, (index) {
          final isActive = activeIndex == index;
          final color = isActive ? AppColors.primaryRed : AppColors.textMuted;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icons[index], color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                labels[index],
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          );
        }),
      ),
    );
  }
}
