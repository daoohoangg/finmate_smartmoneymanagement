import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class ExpenseBreakdownScreen extends StatelessWidget {
  const ExpenseBreakdownScreen({super.key});

  static const String routeName = '/analytics/breakdown';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Expense Breakdown'),
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
                  _FilterTabs(),
                  const SizedBox(height: 16),
                  _DonutCard(),
                  const SizedBox(height: 18),
                  Text(
                    'Categories',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const _CategoryRow(
                    title: 'Rent & Utilities',
                    amount: '\$1,500.00',
                    subtitle: '43% of total',
                    tag: 'Monthly Fixed',
                    color: Color(0xFF3B82F6),
                    icon: Icons.home_work_outlined,
                  ),
                  const SizedBox(height: 8),
                  const _CategoryRow(
                    title: 'Food & Dining',
                    amount: '\$1,200.00',
                    subtitle: '35% of total',
                    tag: '+2% vs last month',
                    color: Color(0xFF22C55E),
                    icon: Icons.restaurant_outlined,
                  ),
                  const SizedBox(height: 8),
                  const _CategoryRow(
                    title: 'Transport',
                    amount: '\$450.00',
                    subtitle: '13% of total',
                    tag: 'Fuel and Transit',
                    color: Color(0xFFF97316),
                    icon: Icons.directions_car_filled,
                  ),
                  const SizedBox(height: 8),
                  const _CategoryRow(
                    title: 'Others',
                    amount: '\$300.00',
                    subtitle: '9% of total',
                    tag: 'Misc expenses',
                    color: Color(0xFF8B5CF6),
                    icon: Icons.category_outlined,
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

class _FilterTabs extends StatelessWidget {
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
          _TabItem(label: 'This Week', selected: false),
          _TabItem(label: 'This Month', selected: true),
          _TabItem(label: 'This Year', selected: false),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }
}

class _DonutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(180, 180),
                painter: _DonutPainter(segments: const [
                  _DonutSegment(color: Color(0xFF1E74FF), value: 0.43),
                  _DonutSegment(color: Color(0xFF22C55E), value: 0.35),
                  _DonutSegment(color: Color(0xFFF97316), value: 0.13),
                  _DonutSegment(color: Color(0xFF8B5CF6), value: 0.09),
                ]),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total Spent',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$3,450.00',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '-5.2%',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.primaryRed),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          'Oct 1, 2023 - Oct 31, 2023',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _DonutSegment {
  const _DonutSegment({required this.color, required this.value});

  final Color color;
  final double value;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.segments});

  final List<_DonutSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 16.0;
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    double startAngle = -pi / 2;
    for (final segment in segments) {
      final sweep = 2 * pi * segment.value;
      paint.color = segment.color;
      canvas.drawArc(
        rect.deflate(strokeWidth),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + 0.04;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.tag,
    required this.color,
    required this.icon,
  });

  final String title;
  final String amount;
  final String subtitle;
  final String tag;
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
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                tag,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
