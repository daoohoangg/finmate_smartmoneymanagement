import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/storage/session_storage.dart';
import '../planning/plan_recommendation_screen.dart';

enum FinancialGoal {
  emergencyFund,
  controlSpending,
  savePurchase,
  growWealth,
}

enum TimeHorizon {
  lessThanOneYear,
  oneToThreeYears,
  threeToFiveYears,
  moreThanFiveYears,
}

enum RiskTolerance {
  sellImmediately,
  waitAndSee,
  stayTheCourse,
  investMore,
}

enum SafetyNetMonths {
  lessThanOne,
  oneToThree,
  threeToSix,
  moreThanSix,
}

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  static const String routeName = '/onboarding';

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  FinancialGoal? _goal;
  TimeHorizon? _horizon;
  RiskTolerance? _risk;
  SafetyNetMonths? _safety;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!_isSelectionValid()) {
      _showSnack('Please select an option to continue.');
      return;
    }
    if (_currentStep == 3) {
      _completeSurvey();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _goBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  void _skip() {
    _pageController.animateToPage(
      3,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  bool _isSelectionValid() {
    switch (_currentStep) {
      case 0:
        return _goal != null;
      case 1:
        return _horizon != null;
      case 2:
        return _risk != null;
      case 3:
        return _safety != null;
    }
    return false;
  }

  Future<void> _completeSurvey() async {
    await SessionStorage.instance.setSurveyCompleted(true);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      PlanRecommendationScreen.routeName,
      (_) => false,
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double get _progress => (_currentStep + 1) / 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: _buildHeader(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildProgress(),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _GoalStep(
                    selected: _goal,
                    onSelected: (value) => setState(() => _goal = value),
                  ),
                  _HorizonStep(
                    selected: _horizon,
                    onSelected: (value) => setState(() => _horizon = value),
                  ),
                  _RiskStep(
                    selected: _risk,
                    onSelected: (value) => setState(() => _risk = value),
                  ),
                  _SafetyStep(
                    selected: _safety,
                    onSelected: (value) => setState(() => _safety = value),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: _buildBottomButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final titles = [
      'Step 1 of 4',
      'Question 2',
      'Onboarding',
      'Safety Check',
    ];
    final showSkip = _currentStep == 1 || _currentStep == 2;
    return Row(
      children: [
        IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            titles[_currentStep],
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        if (showSkip)
          TextButton(
            onPressed: _skip,
            child: const Text(
              'Skip',
              style: TextStyle(color: AppColors.primaryRed),
            ),
          ),
      ],
    );
  }

  Widget _buildProgress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step ${_currentStep + 1} of 4',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              '${(_progress * 100).round()}%',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              _currentStep == 0
                  ? AppColors.primaryBlue
                  : _currentStep == 1
                      ? const Color(0xFFE98964)
                      : AppColors.primaryRed,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    final label = _currentStep == 0
        ? 'Next'
        : _currentStep == 3
            ? 'Complete'
            : 'Continue';
    final color = _currentStep == 0
        ? AppColors.primaryBlue
        : _currentStep == 1
            ? const Color(0xFFE98964)
            : AppColors.primaryRed;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _goNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _GoalStep extends StatelessWidget {
  const _GoalStep({
    required this.selected,
    required this.onSelected,
  });

  final FinancialGoal? selected;
  final ValueChanged<FinancialGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What do you want your money to help you with right now?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the goal that matters most to you today.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _GoalCard(
                icon: Icons.shield_outlined,
                color: const Color(0xFF2CB67D),
                label: 'Build an emergency fund',
                selected: selected == FinancialGoal.emergencyFund,
                onTap: () => onSelected(FinancialGoal.emergencyFund),
              ),
              _GoalCard(
                icon: Icons.wallet_outlined,
                color: const Color(0xFFB5179E),
                label: 'Control spending',
                selected: selected == FinancialGoal.controlSpending,
                onTap: () => onSelected(FinancialGoal.controlSpending),
              ),
              _GoalCard(
                icon: Icons.card_giftcard_outlined,
                color: const Color(0xFFF59E0B),
                label: 'Save for a purchase',
                selected: selected == FinancialGoal.savePurchase,
                onTap: () => onSelected(FinancialGoal.savePurchase),
              ),
              _GoalCard(
                icon: Icons.trending_up,
                color: const Color(0xFF6366F1),
                label: 'Grow wealth',
                selected: selected == FinancialGoal.growWealth,
                onTap: () => onSelected(FinancialGoal.growWealth),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HorizonStep extends StatelessWidget {
  const _HorizonStep({
    required this.selected,
    required this.onSelected,
  });

  final TimeHorizon? selected;
  final ValueChanged<TimeHorizon> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'When do you need this money?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecting a time horizon helps us recommend the best plan for your goals.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _ChoiceTile(
            label: 'Less than 1 year',
            selected: selected == TimeHorizon.lessThanOneYear,
            onTap: () => onSelected(TimeHorizon.lessThanOneYear),
            accent: const Color(0xFFE98964),
          ),
          _ChoiceTile(
            label: '1-3 years',
            selected: selected == TimeHorizon.oneToThreeYears,
            onTap: () => onSelected(TimeHorizon.oneToThreeYears),
            accent: const Color(0xFFE98964),
          ),
          _ChoiceTile(
            label: '3-5 years',
            selected: selected == TimeHorizon.threeToFiveYears,
            onTap: () => onSelected(TimeHorizon.threeToFiveYears),
            accent: const Color(0xFFE98964),
          ),
          _ChoiceTile(
            label: 'More than 5 years',
            selected: selected == TimeHorizon.moreThanFiveYears,
            onTap: () => onSelected(TimeHorizon.moreThanFiveYears),
            accent: const Color(0xFFE98964),
          ),
        ],
      ),
    );
  }
}

class _RiskStep extends StatelessWidget {
  const _RiskStep({
    required this.selected,
    required this.onSelected,
  });

  final RiskTolerance? selected;
  final ValueChanged<RiskTolerance> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'If your plan dropped by 20%, what would you do?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Risk tolerance assessment',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _ChoiceTile(
            label: 'Sell immediately',
            subtitle: 'Conservative approach',
            selected: selected == RiskTolerance.sellImmediately,
            onTap: () => onSelected(RiskTolerance.sellImmediately),
            accent: AppColors.primaryRed,
          ),
          _ChoiceTile(
            label: 'Wait and see',
            subtitle: 'Moderate approach',
            selected: selected == RiskTolerance.waitAndSee,
            onTap: () => onSelected(RiskTolerance.waitAndSee),
            accent: AppColors.primaryRed,
          ),
          _ChoiceTile(
            label: 'Stay the course',
            subtitle: 'Aggressive approach',
            selected: selected == RiskTolerance.stayTheCourse,
            onTap: () => onSelected(RiskTolerance.stayTheCourse),
            accent: AppColors.primaryRed,
          ),
          _ChoiceTile(
            label: 'Invest more',
            subtitle: 'Very aggressive approach',
            selected: selected == RiskTolerance.investMore,
            onTap: () => onSelected(RiskTolerance.investMore),
            accent: AppColors.primaryRed,
          ),
        ],
      ),
    );
  }
}

class _SafetyStep extends StatelessWidget {
  const _SafetyStep({
    required this.selected,
    required this.onSelected,
  });

  final SafetyNetMonths? selected;
  final ValueChanged<SafetyNetMonths> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How many months of expenses could you cover today?',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us suggest a safe pace for your goals.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _ChoiceTile(
            label: '< 1 month',
            selected: selected == SafetyNetMonths.lessThanOne,
            onTap: () => onSelected(SafetyNetMonths.lessThanOne),
            accent: AppColors.primaryRed,
          ),
          _ChoiceTile(
            label: '1-3 months',
            selected: selected == SafetyNetMonths.oneToThree,
            onTap: () => onSelected(SafetyNetMonths.oneToThree),
            accent: AppColors.primaryRed,
          ),
          _ChoiceTile(
            label: '3-6 months',
            selected: selected == SafetyNetMonths.threeToSix,
            onTap: () => onSelected(SafetyNetMonths.threeToSix),
            accent: AppColors.primaryRed,
          ),
          _ChoiceTile(
            label: '> 6 months',
            selected: selected == SafetyNetMonths.moreThanSix,
            onTap: () => onSelected(SafetyNetMonths.moreThanSix),
            accent: AppColors.primaryRed,
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? accent.withOpacity(0.08) : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? accent : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? accent : AppColors.border,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
