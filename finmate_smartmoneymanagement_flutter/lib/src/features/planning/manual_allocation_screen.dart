import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import 'fix_overspending_screen.dart';

class ManualAllocationScreen extends StatefulWidget {
  const ManualAllocationScreen({super.key});

  static const String routeName = '/manual-allocation';

  @override
  State<ManualAllocationScreen> createState() => _ManualAllocationScreenState();
}

class _ManualAllocationScreenState extends State<ManualAllocationScreen> {
  static const double _recommendedBuffer = 20;
  static const double _recommendedLife = 60;
  static const double _recommendedGoals = 20;

  double _buffer = _recommendedBuffer;
  double _life = 50;
  double _goals = 30;

  double get _total => _buffer + _life + _goals;

  void _resetToRecommended() {
    setState(() {
      _buffer = _recommendedBuffer;
      _life = _recommendedLife;
      _goals = _recommendedGoals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalText = '${_total.round()}%';
    final totalColor = (_total - 100).abs() < 1
        ? AppColors.success
        : AppColors.primaryRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Allocation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Plan Overview',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Total: $totalText',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: totalColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adjust sliders to balance your budget.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  _AllocationPreview(
                    buffer: _buffer,
                    life: _life,
                    goals: _goals,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Customize Your Plan',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
  _SliderCard(
    title: 'Buffer',
    subtitle: 'Safety net for unexpected costs',
    icon: Icons.shield_outlined,
    color: const Color(0xFFF59E0B),
    value: _buffer,
    onChanged: (value) => setState(() => _buffer = value),
  ),
                  const SizedBox(height: 12),
  _SliderCard(
    title: 'Life',
    subtitle: 'Daily expenses and lifestyle',
    icon: Icons.favorite_border,
    color: const Color(0xFF2CB67D),
    value: _life,
    onChanged: (value) => setState(() => _life = value),
  ),
                  const SizedBox(height: 12),
  _SliderCard(
    title: 'Goals',
    subtitle: 'Savings and long-term investments',
    icon: Icons.rocket_launch_outlined,
    color: const Color(0xFF6366F1),
    value: _goals,
    onChanged: (value) => setState(() => _goals = value),
  ),
                  const SizedBox(height: 16),
                  _HelpCard(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Custom Plan',
                    color: AppColors.primaryBlue,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        FixOverspendingScreen.routeName,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: _resetToRecommended,
                      child: const Text(
                        'Reset to Recommended',
                        style: TextStyle(color: AppColors.primaryBlue),
                      ),
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

class _AllocationPreview extends StatelessWidget {
  const _AllocationPreview({
    required this.buffer,
    required this.life,
    required this.goals,
  });

  final double buffer;
  final double life;
  final double goals;

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
          Row(
            children: [
              Text(
                'Allocation Split',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${buffer.round()} / ${life.round()} / ${goals.round()}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final total = buffer + life + goals;
              double safeWidth(double value) =>
                  total == 0 ? 0 : constraints.maxWidth * (value / total);
              return Row(
                children: [
                  Container(
                    width: safeWidth(buffer),
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: safeWidth(life),
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2CB67D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: safeWidth(goals),
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(label: 'Buffer', color: const Color(0xFFF59E0B)),
              const SizedBox(width: 12),
              _LegendDot(label: 'Life', color: const Color(0xFF2CB67D)),
              const SizedBox(width: 12),
              _LegendDot(label: 'Goals', color: const Color(0xFF6366F1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _SliderCard extends StatelessWidget {
  const _SliderCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
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
                '${value.round()}%',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: AppColors.border,
              thumbColor: Colors.white,
              overlayColor: color.withOpacity(0.12),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need help?',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our smart tool can suggest the best allocation based on your income.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.show_chart, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
