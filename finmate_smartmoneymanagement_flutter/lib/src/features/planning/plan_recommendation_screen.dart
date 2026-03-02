import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import 'manage_budget_screen.dart';
import 'manual_allocation_screen.dart';

class PlanRecommendationScreen extends StatelessWidget {
  const PlanRecommendationScreen({super.key});

  static const String routeName = '/plan-recommendation';
  static const int _necessaryPercent = 60;
  static const int _accumulationPercent = 20;
  static const int _flexibilityPercent = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Financial Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.overview,
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
                  Text(
                    'Personalized Recommendation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crafted specifically for your goals.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ConfidenceChip(),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _PlanPill(
                        label: 'Necessary',
                        value: '$_necessaryPercent%',
                      ),
                      _PlanPill(
                        label: 'Accumulation',
                        value: '$_accumulationPercent%',
                      ),
                      _PlanPill(
                        label: 'Flexibility',
                        value: '$_flexibilityPercent%',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Allocation Split',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _AllocationBar(
                    segments: const [
                      _AllocationSegment(
                        color: Color(0xFF2CB67D),
                        percent: _necessaryPercent,
                      ),
                      _AllocationSegment(
                        color: Color(0xFF6366F1),
                        percent: _accumulationPercent,
                      ),
                      _AllocationSegment(
                        color: Color(0xFFF59E0B),
                        percent: _flexibilityPercent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _WhyFitsCard(),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Apply this plan',
                    color: AppColors.primaryBlue,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        ManageBudgetScreen.routeName,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          ManualAllocationScreen.routeName,
                        );
                      },
                      child: const Text(
                        'Customize manually',
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

class _ConfidenceChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFD4FF)),
      ),
      child: Text(
        'CONFIDENCE: HIGH',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primaryBlue,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _AllocationSegment {
  const _AllocationSegment({required this.color, required this.percent});

  final Color color;
  final int percent;
}

class _AllocationBar extends StatelessWidget {
  const _AllocationBar({required this.segments});

  final List<_AllocationSegment> segments;

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.percent);
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: segments
            .map(
              (segment) => Expanded(
                flex: (segment.percent * 10).clamp(1, total * 10).toInt(),
                child: Container(color: segment.color),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _WhyFitsCard extends StatelessWidget {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.primaryBlue,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this fits',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your survey results, we recommend balancing stability and growth. This split protects your essentials while moving you toward long-term goals.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
