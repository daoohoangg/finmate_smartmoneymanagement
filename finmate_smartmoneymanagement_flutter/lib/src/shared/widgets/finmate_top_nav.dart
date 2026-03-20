import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class FinMateTopNav extends StatelessWidget {
  const FinMateTopNav({
    super.key,
    required this.currentRouteNotifier,
    required this.navigatorKey,
  });

  final ValueNotifier<String> currentRouteNotifier;
  final GlobalKey<NavigatorState> navigatorKey;

  void _open(String route) {
    if (currentRouteNotifier.value == route) return;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(route, (_) => false);
  }

  void _openTransactions() {
    if (currentRouteNotifier.value == '/transactions/add') return;
    navigatorKey.currentState?.pushNamed('/transactions/add');
  }

  @override
  Widget build(BuildContext context) {
    // Add SafeArea and white background for the top nav
    return Material(
      color: AppColors.card,
      elevation: 0,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Logo or App Name
                const Text(
                  'FinMate',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 48),
                ValueListenableBuilder<String>(
                  valueListenable: currentRouteNotifier,
                  builder: (context, currentRoute, _) {
                    return Row(
                      children: [
                        _NavItem(
                          label: 'Overview',
                          icon: Icons.home_filled,
                          active: currentRoute == '/dashboard/monthly' || currentRoute == '/',
                          onTap: () => _open('/dashboard/monthly'),
                        ),
                        const SizedBox(width: 8),
                        _NavItem(
                          label: 'Calendar',
                          icon: Icons.calendar_month_outlined,
                          active: currentRoute == '/calendar/weekly',
                          onTap: () => _open('/calendar/weekly'),
                        ),
                        const SizedBox(width: 8),
                        _NavItem(
                          label: 'Add transaction',
                          icon: Icons.edit_note_rounded,
                          active: currentRoute == '/transactions/add',
                          onTap: _openTransactions,
                        ),
                        const SizedBox(width: 8),
                        _NavItem(
                          label: 'FinMateAI',
                          icon: Icons.smart_toy_outlined,
                          active: currentRoute == '/ai-coach/chat',
                          onTap: () => _open('/ai-coach/chat'),
                        ),
                        const SizedBox(width: 8),
                        _NavItem(
                          label: 'Utilities',
                          icon: Icons.widgets_outlined,
                          active: currentRoute == '/utilities' ||
                                  currentRoute == '/settings' ||
                                  currentRoute == '/categories/manage',
                          onTap: () => _open('/utilities'),
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
              ],
            ),
          ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryBlue.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
