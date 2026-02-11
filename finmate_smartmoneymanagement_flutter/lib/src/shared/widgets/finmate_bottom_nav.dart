import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
const String _overviewRoute = '/dashboard/monthly';
const String _historyRoute = '/transactions/list';
const String _addTransactionRoute = '/transactions/add';
const String _statsRoute = '/analytics/insights';
const String _settingsRoute = '/settings';

enum FinMateNavItem {
  overview,
  history,
  stats,
  settings,
}

class FinMateBottomNav extends StatelessWidget {
  const FinMateBottomNav({super.key, this.active});

  final FinMateNavItem? active;

  void _open(BuildContext context, String route) {
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavItem(
              label: 'Overview',
              icon: Icons.home_filled,
              active: active == FinMateNavItem.overview,
              onTap: () => _open(context, _overviewRoute),
            ),
            _NavItem(
              label: 'History',
              icon: Icons.event_note_outlined,
              active: active == FinMateNavItem.history,
              onTap: () => _open(
                context,
                _historyRoute,
              ),
            ),
            _PrimaryNavButton(
              onTap: () => Navigator.pushNamed(
                context,
                _addTransactionRoute,
              ),
            ),
            _NavItem(
              label: 'Stats',
              icon: Icons.bar_chart_rounded,
              active: active == FinMateNavItem.stats,
              onTap: () => _open(
                context,
                _statsRoute,
              ),
            ),
            _NavItem(
              label: 'Settings',
              icon: Icons.settings_outlined,
              active: active == FinMateNavItem.settings,
              onTap: () => _open(
                context,
                _settingsRoute,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryNavButton extends StatelessWidget {
  const _PrimaryNavButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF2F8CFF), Color(0xFF1E6CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
