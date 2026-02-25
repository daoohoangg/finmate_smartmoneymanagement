import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

import '../budget/allocate_funds_screen.dart';
import '../budget/budget_create_screen.dart';
import '../budget/budget_status_track_screen.dart';
import '../categories/manage_categories_screen.dart';
import '../planning/manual_allocation_screen.dart';
import '../planning/plan_recommendation_screen.dart';
import '../recurring/recurring_setup_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/services/transaction_service.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class MonthlyDashboardScreen extends StatefulWidget {
  const MonthlyDashboardScreen({super.key});

  static const String routeName = '/dashboard/monthly';

  @override
  State<MonthlyDashboardScreen> createState() => _MonthlyDashboardScreenState();
}

class _MonthlyDashboardScreenState extends State<MonthlyDashboardScreen> {
  final TransactionService _transactionService = TransactionService();

  bool _loadingTotals = true;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _todayIncome = 0;
  double _todayExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadTotals();
  }

  Future<void> _loadTotals() async {
    setState(() {
      _loadingTotals = true;
    });
    try {
      final transactions = await _transactionService.getTransactions();
      final now = DateTime.now();
      double income = 0;
      double expense = 0;
      double todayIncome = 0;
      double todayExpense = 0;
      for (final transaction in transactions) {
        final type = transaction['type']?.toString().toUpperCase();
        final amount = _toDouble(transaction['amount']);
        final txDate = _parseDate(transaction['transactionDate']);
        final isToday = txDate != null && _isSameDate(txDate.toLocal(), now);
        if (type == 'INCOME') {
          income += amount;
          if (isToday) {
            todayIncome += amount;
          }
        } else if (type == 'EXPENSE') {
          expense += amount;
          if (isToday) {
            todayExpense += amount;
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _todayIncome = todayIncome;
        _todayExpense = todayExpense;
        _loadingTotals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _totalIncome = 0;
        _totalExpense = 0;
        _todayIncome = 0;
        _todayExpense = 0;
        _loadingTotals = false;
      });
    }
  }

  double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _safeDisplayAmount(Object? value) {
    if (value is num) {
      final parsed = value.toDouble();
      if (parsed.isFinite && !parsed.isNaN) {
        return parsed;
      }
    }
    return 0;
  }

  DateTime? _parseDate(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _formatVnd(Object? amountValue) {
    final amount = _safeDisplayAmount(amountValue);
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix$separatedđ';
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance =
        _safeDisplayAmount(_totalIncome) - _safeDisplayAmount(_totalExpense);
    final balanceText = _loadingTotals ? '--' : _formatVnd(totalBalance);
    final incomeText = _loadingTotals ? '--' : _formatVnd(_todayIncome);
    final expenseText = _loadingTotals ? '--' : _formatVnd(_todayExpense);

    return Scaffold(
      backgroundColor: _HomeColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BalanceHeader(balanceText: balanceText),
                        const SizedBox(height: 18),
                        _WalletCard(balanceText: balanceText),
                        const SizedBox(height: 22),
                        _QuickActionsGrid(onDataChanged: _loadTotals),
                        const SizedBox(height: 22),
                        _SummaryRow(
                          expenseText: expenseText,
                          incomeText: incomeText,
                        ),
                        const SizedBox(height: 22),
                        const _GoalsSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const FinMateBottomNav(active: FinMateNavItem.overview),
          ],
        ),
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.balanceText});

  final String balanceText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    balanceText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _HomeColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.visibility_outlined,
                    color: _HomeColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Total balance',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _HomeColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, SettingsScreen.routeName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _HomeColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _HomeColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.swap_horiz,
                  color: _HomeColors.textPrimary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Switch wallet',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _HomeColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.balanceText});

  final String balanceText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: CustomPaint(
        foregroundPainter: _DiagonalLinesPainter(
          color: Colors.white.withOpacity(0.08),
          spacing: 18,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2D325E), Color(0xFF3B2A89)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Personal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.visibility, color: Colors.white70, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                balanceText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _HomeColors.success,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+100.0%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'vs last month',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({this.onDataChanged});

  final Future<void> Function()? onDataChanged;

  @override
  Widget build(BuildContext context) {
    Future<void> openRoute(Future<Object?> route) async {
      await route;
      if (onDataChanged != null) {
        await onDataChanged!.call();
      }
    }

    Future<void> openAddTransaction({required bool isExpense}) async {
      await openRoute(
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTransactionScreen(initialIsExpense: isExpense),
          ),
        ),
      );
    }

    final actions = [
      _ActionData(
        label: 'Manual\nallocation',
        icon: Icons.pie_chart_outline_rounded,
        colors: const [Color(0xFFCE3CC5), Color(0xFF7D5CFF)],
        onTap: () => openRoute(
          Navigator.pushNamed(context, ManualAllocationScreen.routeName),
        ),
      ),
      _ActionData(
        label: 'Scan\nreceipt',
        icon: Icons.qr_code_scanner,
        colors: const [Color(0xFF1FB5FF), Color(0xFF3E60FF)],
        onTap: () => openAddTransaction(isExpense: true),
      ),
      _ActionData(
        label: 'Add\nexpense',
        icon: Icons.shopping_cart_outlined,
        colors: const [Color(0xFFFF8A34), Color(0xFFFF5F27)],
        onTap: () => openAddTransaction(isExpense: true),
      ),
      _ActionData(
        label: 'Create\nFunds',
        icon: Icons.account_balance_wallet_outlined,
        colors: const [Color(0xFF12D08E), Color(0xFF11B86A)],
        onTap: () => openRoute(
          Navigator.pushNamed(context, BudgetCreateScreen.routeName),
        ),
      ),
      _ActionData(
        label: 'Manage\ncategories',
        icon: Icons.settings,
        colors: const [Color(0xFF7A5CFF), Color(0xFF4F8DFF)],
        onTap: () => openRoute(
          Navigator.pushNamed(context, ManageCategoriesScreen.routeName),
        ),
      ),
      _ActionData(
        label: 'Transfer',
        icon: Icons.swap_horiz,
        colors: const [Color(0xFF6E63FF), Color(0xFF4B4FF5)],
        onTap: () => openRoute(
          Navigator.pushNamed(context, AllocateFundsScreen.routeName),
        ),
      ),
      _ActionData(
        label: 'Funds\nstatus',
        icon: Icons.receipt_long,
        colors: const [Color(0xFFFFA630), Color(0xFFFF7C1F)],
        onTap: () => openRoute(
          Navigator.pushNamed(context, BudgetStatusTrackScreen.routeName),
        ),
      ),
      _ActionData(
        label: 'Recurring\ntransactions',
        icon: Icons.autorenew,
        colors: const [Color(0xFF9D6BFF), Color(0xFF6F5CFF)],
        badge: 'BETA',
        onTap: () => openRoute(
          Navigator.pushNamed(context, RecurringSetupScreen.routeName),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        return _ActionItem(data: action);
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.expenseText, required this.incomeText});

  final String expenseText;
  final String incomeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniSummaryCard(
            title: 'Expenses',
            subtitle: 'Today',
            amount: expenseText,
            amountColor: _HomeColors.danger,
            icon: Icons.trending_down,
            iconBg: const Color(0xFF3B1F2A),
            iconColor: _HomeColors.danger,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _MiniSummaryCard(
            title: 'Income',
            subtitle: 'Today',
            amount: incomeText,
            amountColor: _HomeColors.success,
            icon: Icons.trending_up,
            iconBg: const Color(0xFF20392E),
            iconColor: _HomeColors.success,
          ),
        ),
      ],
    );
  }
}

class _MiniSummaryCard extends StatelessWidget {
  const _MiniSummaryCard({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _HomeColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _HomeColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _HomeColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _HomeColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: amountColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Goals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _HomeColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                PlanRecommendationScreen.routeName,
              ),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _HomeColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _HomeColors.border),
                ),
                child: const Icon(
                  Icons.add,
                  color: _HomeColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, PlanRecommendationScreen.routeName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: _HomeColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _HomeColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _HomeColors.cardAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.flag,
                    color: _HomeColors.textPrimary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Savings goal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _HomeColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Starting from 2,000,000đ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _HomeColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: _HomeColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({required this.data});

  final _ActionData data;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: data.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: data.colors.first.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(data.icon, color: Colors.white, size: 24),
              ),
              if (data.badge != null)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _HomeColors.badge,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      data.badge!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _HomeColors.badgeText,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _HomeColors.textPrimary,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  const _ActionData({
    required this.label,
    required this.icon,
    required this.colors,
    this.onTap,
    this.badge,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback? onTap;
  final String? badge;
}

class _DiagonalLinesPainter extends CustomPainter {
  _DiagonalLinesPainter({required this.color, this.spacing = 16});

  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = -size.height; x < size.width; x += spacing) {
      final start = Offset(x, size.height);
      final end = Offset(x + size.height, 0);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DiagonalLinesPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.spacing != spacing;
  }
}

class _HomeColors {
  static const Color background = AppColors.page;
  static const Color surface = AppColors.card;
  static const Color border = AppColors.border;
  static const Color navBar = AppColors.card;
  static const Color navBorder = AppColors.border;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;
  static const Color primary = AppColors.primaryBlue;
  static const Color success = AppColors.success;
  static const Color danger = AppColors.primaryRed;
  static const Color badge = Color(0xFFFFB423);
  static const Color badgeText = Color(0xFF5C3B00);
  static const Color cardAccent = AppColors.fieldBackground;
}
