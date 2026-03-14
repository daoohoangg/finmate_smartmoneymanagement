import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

const String _overviewRoute = '/dashboard/monthly';
const String _calendarRoute = '/calendar/weekly';
const String _transactionsRoute = '/transactions/add';
const String _aiChatbotRoute = '/ai-coach/chat';
const String _utilitiesRoute = '/utilities';

enum FinMateNavItem { overview, calendar, transactions, aiChatbot, utilities }

class FinMateBottomNav extends StatelessWidget {
  const FinMateBottomNav({super.key, this.active});

  final FinMateNavItem? active;

  void _open(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  void _openTransactions(BuildContext context) {
    if (active == FinMateNavItem.transactions) return;
    Navigator.pushNamed(context, _transactionsRoute);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width > 800) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: 'Overview',
                icon: Icons.home_filled,
                active: active == FinMateNavItem.overview,
                onTap: () => _open(context, _overviewRoute),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Calendar',
                icon: Icons.calendar_month_outlined,
                active: active == FinMateNavItem.calendar,
                onTap: () => _open(context, _calendarRoute),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Add',
                icon: Icons.edit_note_rounded,
                active: active == FinMateNavItem.transactions,
                onTap: () => _openTransactions(context),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'FinMateAI',
                icon: Icons.smart_toy_outlined,
                active: active == FinMateNavItem.aiChatbot,
                onTap: () => _open(context, _aiChatbotRoute),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Utilities',
                icon: Icons.widgets_outlined,
                active: active == FinMateNavItem.utilities,
                onTap: () => _open(context, _utilitiesRoute),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryBlue : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontSize: 10,
              height: 1.1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
