import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../dashboard/monthly_dashboard_screen.dart';

class SubCategoryBudgetDetailArgs {
  const SubCategoryBudgetDetailArgs({
    required this.categoryId,
    required this.title,
    required this.mainCategoryName,
    required this.totalBudget,
    required this.availableBudget,
  });

  final int categoryId;
  final String title;
  final String mainCategoryName;
  final double totalBudget;
  final double availableBudget;
}

class SubCategoryBudgetDetailScreen extends StatefulWidget {
  const SubCategoryBudgetDetailScreen({super.key});

  static const String routeName = '/budget/subcategory-detail';

  @override
  State<SubCategoryBudgetDetailScreen> createState() =>
      _SubCategoryBudgetDetailScreenState();
}

class _SubCategoryBudgetDetailScreenState
    extends State<SubCategoryBudgetDetailScreen> {
  static const List<String> _transactionTabs = <String>[
    'Tất cả',
    'Top chi tiêu',
    'Top người nhận',
  ];

  bool _didLoadArgs = false;
  bool _isMonthView = true;
  int _selectedTransactionTab = 0;
  SubCategoryBudgetDetailArgs _args = const SubCategoryBudgetDetailArgs(
    categoryId: 0,
    title: 'Chi tiết ngân sách',
    mainCategoryName: 'Danh mục',
    totalBudget: 0,
    availableBudget: 0,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadArgs) return;
    final rawArgs = ModalRoute.of(context)?.settings.arguments;
    if (rawArgs is SubCategoryBudgetDetailArgs) {
      _args = rawArgs;
    }
    _didLoadArgs = true;
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      MonthlyDashboardScreen.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalBudget = max<double>(0, _args.totalBudget);
    final availableBudget = max<double>(0, _args.availableBudget);
    final spentBudget = max<double>(0, totalBudget - availableBudget);
    final remainingDays = _daysUntilMonthEnd(now);
    final statusText = availableBudget > 0 ? 'Tốt' : 'Cần chú ý';
    final statusColor = availableBudget > 0
        ? const Color(0xFF16A34A)
        : AppColors.primaryRed;

    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            _HeaderBar(title: _args.title, onBack: _goBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Chi tiêu tháng ${now.month}',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontSize: 42,
                                      height: 1.0,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            _PeriodSwitch(
                              isMonth: _isMonthView,
                              onSwitch: (isMonth) {
                                setState(() => _isMonthView = isMonth);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5A8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatVnd(totalBudget),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _DashedLine(
                          color: Color(0xFF06B6D4),
                          dashWidth: 11,
                        ),
                        const SizedBox(height: 150),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            _AxisLabel(text: '10'),
                            _AxisLabel(text: '11'),
                            _AxisLabel(text: '12'),
                            _AxisLabel(text: '1/2026'),
                            _AxisLabel(text: '2'),
                            _AxisLabel(text: '3', color: AppColors.primaryBlue),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const _DashedLine(
                              color: Color(0xFF06B6D4),
                              dashWidth: 6,
                              gapWidth: 2,
                              length: 24,
                              strokeWidth: 2,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Hạn mức ngân sách mỗi tháng',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'Ngân sách',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE9F9EF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: statusColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusText,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFCE7F3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.more_horiz_rounded,
                                color: Color(0xFFEC4899),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0F7F7),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF14B8C4),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.shopping_basket_rounded,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Đã chi ${_formatVnd(spentBudget)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontSize: 36,
                                            height: 1.0,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    RichText(
                                      text: TextSpan(
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: 18,
                                              color: AppColors.textSecondary,
                                            ),
                                        children: [
                                          TextSpan(
                                            text:
                                                'Còn ${_formatVnd(availableBudget)}',
                                            style: const TextStyle(
                                              color: Color(0xFF0EA5A8),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          TextSpan(
                                            text:
                                                ' - Chi $remainingDays ngày tới',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5D0FE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  size: 15,
                                  color: Color(0xFFC026D3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Phân bổ chi tiêu ${_args.title} theo thu nhập',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Giao dịch',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 42,
                                height: 1.0,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: List<Widget>.generate(
                            _transactionTabs.length,
                            (index) {
                              final isSelected =
                                  _selectedTransactionTab == index;
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index == _transactionTabs.length - 1
                                      ? 0
                                      : 8,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _selectedTransactionTab = index,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFFCE7F3)
                                          : AppColors.card,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFFF9A8D4)
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          index == 0
                                              ? Icons.receipt_long_outlined
                                              : index == 1
                                              ? Icons.bar_chart_rounded
                                              : Icons.account_circle_outlined,
                                          color: isSelected
                                              ? const Color(0xFFEC4899)
                                              : AppColors.textSecondary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _transactionTabs[index],
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: isSelected
                                                    ? const Color(0xFFEC4899)
                                                    : AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 30,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF2F4F7),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 50,
                                  color: Color(0xFFB6BDC8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Không có dữ liệu',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bạn không có giao dịch nào tại thời gian này',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFCE7F3),
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 12),
      child: Row(
        children: [
          _CircleIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const _CircleIconButton(icon: Icons.check_circle_outline_rounded),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.directions_car_filled_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.home_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _PeriodSwitch extends StatelessWidget {
  const _PeriodSwitch({required this.isMonth, required this.onSwitch});

  final bool isMonth;
  final ValueChanged<bool> onSwitch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.chipBackground,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          _PeriodItem(
            label: 'Tuần',
            active: !isMonth,
            onTap: () => onSwitch(false),
          ),
          _PeriodItem(
            label: 'Tháng',
            active: isMonth,
            onTap: () => onSwitch(true),
          ),
        ],
      ),
    );
  }
}

class _PeriodItem extends StatelessWidget {
  const _PeriodItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 70),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: active ? const Color(0xFFEC4899) : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({required this.text, this.color = AppColors.textMuted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: color, fontSize: 22),
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine({
    required this.color,
    this.length,
    this.dashWidth = 8,
    this.gapWidth = 4,
    this.strokeWidth = 1,
  });

  final Color color;
  final double? length;
  final double dashWidth;
  final double gapWidth;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final fixedLength = length;
    if (fixedLength != null) {
      return SizedBox(
        width: fixedLength,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _DashLineFill(
              color: color,
              width: constraints.maxWidth,
              dashWidth: dashWidth,
              gapWidth: gapWidth,
              strokeWidth: strokeWidth,
            );
          },
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return _DashLineFill(
          color: color,
          width: constraints.maxWidth,
          dashWidth: dashWidth,
          gapWidth: gapWidth,
          strokeWidth: strokeWidth,
        );
      },
    );
  }
}

class _DashLineFill extends StatelessWidget {
  const _DashLineFill({
    required this.color,
    required this.width,
    required this.dashWidth,
    required this.gapWidth,
    required this.strokeWidth,
  });

  final Color color;
  final double width;
  final double dashWidth;
  final double gapWidth;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final segments = max<int>(1, (width / (dashWidth + gapWidth)).floor());
    return Row(
      children: List<Widget>.generate(segments, (index) {
        return Container(
          width: dashWidth,
          height: strokeWidth,
          margin: EdgeInsets.only(right: index == segments - 1 ? 0 : gapWidth),
          color: color,
        );
      }),
    );
  }
}

String _formatVnd(num amount) {
  final rounded = amount.round();
  final absolute = rounded.abs().toString();
  final grouped = absolute.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final sign = rounded < 0 ? '-' : '';
  return '$sign$groupedđ';
}

int _daysUntilMonthEnd(DateTime date) {
  final today = DateTime(date.year, date.month, date.day);
  final monthEnd = DateTime(date.year, date.month + 1, 0);
  return max<int>(0, monthEnd.difference(today).inDays);
}
