import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../budget/models/budget.dart';
import '../budget/services/budget_service.dart';
import '../budget/budget_create_screen.dart';
import '../budget/budget_status_track_screen.dart';
import '../categories/manage_categories_screen.dart';
import '../planning/manage_budget_screen.dart';
import '../recurring/recurring_setup_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/services/transaction_service.dart';
import '../transactions/transactions_list_screen.dart';
import '../utilities/utilities_screen.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class MonthlyDashboardScreen extends StatefulWidget {
  const MonthlyDashboardScreen({super.key});

  static const String routeName = '/dashboard/monthly';

  @override
  State<MonthlyDashboardScreen> createState() => _MonthlyDashboardScreenState();
}

class _MonthlyDashboardScreenState extends State<MonthlyDashboardScreen>
    with WidgetsBindingObserver {
  final TransactionService _transactionService = TransactionService();
  final BudgetService _budgetService = BudgetService();

  bool _loadingTotals = true;
  List<_MonthData> _recentMonths = [];
  List<Budget> _budgetList = [];
  int _selectedMonthIndex = 2; // Default to current month (index 2)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initEmptyData();
    _loadTotals();
  }

  void _initEmptyData() {
    final now = DateTime.now();
    _recentMonths = [
      _MonthData(month: DateTime(now.year, now.month - 2, 1), income: 0, expense: 0),
      _MonthData(month: DateTime(now.year, now.month - 1, 1), income: 0, expense: 0),
      _MonthData(month: DateTime(now.year, now.month, 1), income: 0, expense: 0),
    ];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTotals();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadTotals() async {
    setState(() {
      _loadingTotals = true;
    });
    try {
      final futures = await Future.wait([
        _transactionService.getTransactions(),
        _budgetService.getBudgets(),
      ]);
      final transactions = futures[0] as List<dynamic>;
      final budgetsData = (futures[1] as List<Budget>?) ?? [];
      
      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final prevMonthStart = DateTime(now.year, now.month - 1, 1);
      final prevPrevMonthStart = DateTime(now.year, now.month - 2, 1);

      List<double> incomes = [0.0, 0.0, 0.0];
      List<double> expenses = [0.0, 0.0, 0.0];

      for (final transaction in transactions) {
        final txDate = _parseDate(transaction['transactionDate']);
        if (txDate != null) {
          final type = transaction['type']?.toString().toUpperCase();
          final amount = _toDouble(transaction['amount']);
          
          if (txDate.year == currentMonthStart.year && txDate.month == currentMonthStart.month) {
            if (type == 'INCOME') incomes[2] += amount;
            else if (type == 'EXPENSE') expenses[2] += amount;
          } else if (txDate.year == prevMonthStart.year && txDate.month == prevMonthStart.month) {
            if (type == 'INCOME') incomes[1] += amount;
            else if (type == 'EXPENSE') expenses[1] += amount;
          } else if (txDate.year == prevPrevMonthStart.year && txDate.month == prevPrevMonthStart.month) {
            if (type == 'INCOME') incomes[0] += amount;
            else if (type == 'EXPENSE') expenses[0] += amount;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _recentMonths = [
          _MonthData(month: prevPrevMonthStart, income: incomes[0], expense: expenses[0]),
          _MonthData(month: prevMonthStart, income: incomes[1], expense: expenses[1]),
          _MonthData(month: currentMonthStart, income: incomes[2], expense: expenses[2]),
        ];
        _budgetList = budgetsData;
        _loadingTotals = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initEmptyData();
        _budgetList = [];
        _loadingTotals = false;
      });
    }
  }

  double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(Object? value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  String _formatVnd(double amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix$separatedđ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadTotals,
                  color: const Color(0xFFD6336C),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopActionRow(onDataChanged: _loadTotals),
                          const SizedBox(height: 24),
                          const _SituationHeader(),
                          const SizedBox(height: 12),
                          _SituationCard(
                            recentMonths: _recentMonths,
                            selectedIndex: _selectedMonthIndex,
                            isLoading: _loadingTotals,
                            formatter: _formatVnd,
                            onDataChanged: _loadTotals,
                            onMonthSelected: (idx) {
                              setState(() {
                                _selectedMonthIndex = idx;
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          _BudgetSection(budgets: _budgetList.where((b) {
                            final bName = b.name.trim().toLowerCase();
                            final cName = b.categoryName.trim().toLowerCase();
                            return bName.isEmpty || cName.isEmpty || bName == cName;
                          }).toList()),
                          const SizedBox(height: 24),
                          _FinancialPictureSection(funds: _budgetList.where((b) {
                            final bName = b.name.trim().toLowerCase();
                            final cName = b.categoryName.trim().toLowerCase();
                            return bName.isNotEmpty && cName.isNotEmpty && bName != cName;
                          }).toList()),
                          const SizedBox(height: 48), // Padding bottom
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'FinMate - Smart Money Management',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// THÀNH PHẦN 1: TOP ACTiON ROW (MENU 4 NÚT)
// ==========================================
class _TopActionRow extends StatelessWidget {
  const _TopActionRow({required this.onDataChanged});
  
  final Future<void> Function() onDataChanged;

  @override
  Widget build(BuildContext context) {
    Future<void> openRoute(Future<Object?> route) async {
       await route;
       await onDataChanged.call();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionButton(
            label: 'Add\nTransaction',
            icon: Icons.post_add_rounded,
            color: const Color(0xFF20C997),
            onTap: () => openRoute(Navigator.pushNamed(context, AddTransactionScreen.routeName)),
          ),
          _ActionButton(
            label: 'Cash\nFlow',
            icon: Icons.ssid_chart,
            color: const Color(0xFF15AABF),
            onTap: () => openRoute(Navigator.pushNamed(context, TransactionsListScreen.routeName)),
          ),
          _ActionButton(
            label: 'Savings\nFunds',
            icon: Icons.savings_outlined,
            color: const Color(0xFF4C6EF5),
            onTap: () => openRoute(Navigator.pushNamed(context, BudgetStatusTrackScreen.routeName)),
          ),
          _ActionButton(
            label: 'More\nUtilities',
            icon: Icons.grid_view_rounded,
            color: const Color(0xFF868E96),
            onTap: () => openRoute(Navigator.pushNamed(context, UtilitiesScreen.routeName)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});
  
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF495057),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}


// ==========================================
// THÀNH PHẦN 2: TÌNH HÌNH THU CHI
// ==========================================
class _SituationHeader extends StatelessWidget {
  const _SituationHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Income & Expenses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.visibility, color: Color(0xFFD6336C), size: 20),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.pie_chart_outline, color: Color(0xFF495057), size: 16),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              const SizedBox(width: 12),
              const Icon(Icons.bar_chart, color: Color(0xFFD6336C), size: 16),
              const SizedBox(width: 4),
              const Text(
                'Trends',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFD6336C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SituationCard extends StatelessWidget {
  const _SituationCard({
    required this.recentMonths,
    required this.selectedIndex,
    required this.isLoading,
    required this.formatter,
    required this.onDataChanged,
    required this.onMonthSelected,
  });

  final List<_MonthData> recentMonths;
  final int selectedIndex;
  final bool isLoading;
  final String Function(double) formatter;
  final Future<void> Function() onDataChanged;
  final ValueChanged<int> onMonthSelected;

  String _formatCompactMin(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1).replaceAll('.0', '')}tr';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final currentData = recentMonths.isNotEmpty ? recentMonths[selectedIndex] : null;
    final expense = currentData?.expense ?? 0.0;
    final income = currentData?.income ?? 0.0;

    String monthLabel = 'This month';
    if (selectedIndex == 0) {
      monthLabel = '2 months ago';
    } else if (selectedIndex == 1) {
      monthLabel = 'Last month';
    }

    // Calculate max expense for chart scaling
    double maxExpense = 0;
    for (var m in recentMonths) {
      if (m.expense > maxExpense) maxExpense = m.expense;
    }
    if (maxExpense == 0) maxExpense = 1; // Prevent division by zero

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Phần chọn tháng
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF868E96)),
                  onPressed: selectedIndex > 0 ? () => onMonthSelected(selectedIndex - 1) : null,
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF333333)),
                    const SizedBox(width: 6),
                    Text(
                      monthLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF868E96)),
                  onPressed: selectedIndex < 2 ? () => onMonthSelected(selectedIndex + 1) : null,
                ),
              ],
            ),
          ),
          
          // Phần hiển thị số dư 2 khung
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFFFA8C2)),
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFFFFF0F5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.arrow_outward, color: Color(0xFFD6336C), size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              'Spending',
                              style: TextStyle(fontSize: 13, color: Color(0xFF495057), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLoading ? '--' : formatter(expense),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.call_received, color: Color(0xFF495057), size: 14),
                            const SizedBox(width: 4),
                            const Text(
                              'Income',
                              style: TextStyle(fontSize: 13, color: Color(0xFF495057), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isLoading ? '--' : formatter(income),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Previous month comparison footer
          if (selectedIndex > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Color(0xFF339AF0), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final previousExpense = recentMonths[selectedIndex - 1].expense;
                          if (previousExpense == 0) {
                            return const Text('No data for last month');
                          }
                          final diff = expense - previousExpense;
                          final diffStr = formatter(diff.abs());
                          if (diff > 0) {
                            return Text('Spent $diffStr more than last month', style: const TextStyle(color: Color(0xFFD6336C), fontWeight: FontWeight.w500, fontSize: 13));
                          } else if (diff < 0) {
                            return Text('Spent $diffStr less than last month', style: const TextStyle(color: Color(0xFF20C997), fontWeight: FontWeight.w500, fontSize: 13));
                          }
                          return const Text('No change since last month', style: TextStyle(fontSize: 13, color: Color(0xFF495057), fontWeight: FontWeight.w500));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (recentMonths.every((m) => m.expense == 0 && m.income == 0) && !isLoading)
            // Empty chart state
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Record every transaction to track your financial health accurately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF495057),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, AddTransactionScreen.routeName);
                        await onDataChanged.call();
                      },
                      icon: const Icon(Icons.post_add),
                      label: const Text('Record an expense', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD6336C),
                        side: const BorderSide(color: Color(0xFFD6336C)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Biểu đồ tương tác
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                height: 150,
                child: Row(
                  children: [
                    // Cột dọc (Y-axis labels)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(_formatCompactMin(maxExpense), style: const TextStyle(fontSize: 10, color: Color(0xFF868E96))),
                        Text(_formatCompactMin(maxExpense * 0.66), style: const TextStyle(fontSize: 10, color: Color(0xFF868E96))),
                        Text(_formatCompactMin(maxExpense * 0.33), style: const TextStyle(fontSize: 10, color: Color(0xFF868E96))),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 24), // Căn dòng chữ 0 trùng với đáy (chừa khoảng label tháng)
                          child: Text('0', style: TextStyle(fontSize: 10, color: Color(0xFF868E96))),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Khu vực biểu đồ
                    Expanded(
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(height: 1, color: const Color(0xFFF1F3F5), margin: const EdgeInsets.only(top: 6)),
                              Container(height: 1, color: const Color(0xFFF1F3F5), margin: const EdgeInsets.only(top: 6)),
                              Container(height: 1, color: const Color(0xFFF1F3F5), margin: const EdgeInsets.only(top: 6)),
                              Container(height: 1, color: const Color(0xFFF1F3F5), margin: const EdgeInsets.only(bottom: 24)),
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(recentMonths.length, (index) {
                              final m = recentMonths[index];
                              // Minimum height 4 for visibility if there is ANY expense, otherwise 0
                              final minHeight = m.expense > 0 ? 4.0 : 0.0;
                              final barHeight = (m.expense / maxExpense) * 110.0;
                              final finalHeight = barHeight < minHeight ? minHeight : barHeight;
                              final isSelected = index == selectedIndex;
                              
                              String label = '';
                              if (index == 0) label = 'T-${m.month.month}';
                              else if (index == 1) label = 'T-${m.month.month}';
                              else label = 'Nay';

                              return GestureDetector(
                                onTap: () => onMonthSelected(index),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 44,
                                      height: finalHeight,
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFD6336C) : const Color(0xFFD0EBFF),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF333333) : const Color(0xFF868E96),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// THÀNH PHẦN 3: NGÂN SÁCH CHI TIÊU
// ==========================================
class _BudgetSection extends StatelessWidget {
  const _BudgetSection({List<Budget>? budgets})
    : budgets = budgets ?? const <Budget>[];

  final List<Budget> budgets;

  String _formatVnd(double amount) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    final prefix = rounded < 0 ? '-' : '';
    return '$prefix$separatedđ';
  }

  @override
  Widget build(BuildContext context) {
    void openManageBudget() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const ManageBudgetScreen(),
        ),
      );
    }

    final spendingBudgets = budgets.toList();
    final totalSpendingBudget = spendingBudgets.fold<double>(
      0.0,
      (sum, budget) => sum + budget.amountLimit,
    );

    return Column(
      children: [
        GestureDetector(
          onTap: openManageBudget,
          behavior: HitTestBehavior.opaque,
          child: Row(
             children: [
               const Text(
                 'Spending budget',
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
               ),
               const Spacer(),
               Container(
                 padding: const EdgeInsets.all(4),
                 decoration: const BoxDecoration(color: Color(0xFFFFF0F5), shape: BoxShape.circle),
                 child: const Icon(Icons.chevron_right, color: Color(0xFFD6336C), size: 18),
               ),
             ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              ...spendingBudgets.map((budget) {
                final budgetTitle = budget.name.trim().isNotEmpty
                    ? budget.name.trim()
                    : budget.categoryName;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _BudgetCard(
                    title: budgetTitle,
                    icon: Icons.pie_chart,
                    iconBg: const Color(0xFF20C997),
                    descColor: const Color(0xFF20C997),
                    descLabel: budget.categoryName,
                    amount: _formatVnd(budget.amountLimit),
                    statusLabel:
                        budget.percentageUsed >= 100 ? 'Overspent' : 'On Track',
                    statusIcon: budget.percentageUsed >= 100
                        ? Icons.warning_rounded
                        : Icons.check_circle,
                    statusBg: budget.percentageUsed >= 100
                        ? const Color(0xFFFFE3E3)
                        : const Color(0xFFE6FCF5),
                    statusTextColor: budget.percentageUsed >= 100
                        ? const Color(0xFFFA5252)
                        : const Color(0xFF0CA678),
                    onTap: openManageBudget,
                  ),
                );
              }),
              _BudgetCard(
                title: 'Total Budget',
                icon: Icons.savings,
                iconBg: const Color(0xFFFFA8C2),
                descColor: const Color(0xFF868E96),
                descLabel: spendingBudgets.isEmpty
                    ? 'No spending budget yet'
                    : 'Total spending budget',
                amount: _formatVnd(totalSpendingBudget),
                statusLabel: spendingBudgets.isEmpty ? 'Set Now' : 'View All',
                statusIcon: Icons.arrow_forward_rounded,
                statusBg: const Color(0xFFFFF0F5),
                statusTextColor: const Color(0xFFD6336C),
                isSuggest: true,
                onTap: openManageBudget,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.descLabel,
    required this.amount,
    required this.statusLabel,
    required this.statusIcon,
    required this.statusBg,
    required this.descColor,
    required this.onTap,
    this.statusTextColor = const Color(0xFF495057),
    this.isSuggest = false,
  });

  final String title;
  final IconData icon;
  final Color iconBg;
  final String descLabel;
  final String amount;
  final String statusLabel;
  final IconData statusIcon;
  final Color statusBg;
  final Color statusTextColor;
  final Color descColor;
  final VoidCallback onTap;
  final bool isSuggest;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.only(top: 16, bottom: 8),
               child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF495057))),
             ),
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 border: Border.all(color: iconBg.withOpacity(0.5), width: 4),
                 color: iconBg.withOpacity(0.1),
               ),
               child: Icon(icon, color: iconBg, size: 28),
             ),
             const Spacer(),
             Text(descLabel, style: TextStyle(fontSize: 11, color: descColor, fontWeight: FontWeight.w500)),
             const SizedBox(height: 2),
             Text(amount, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
             const SizedBox(height: 8),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.symmetric(vertical: 8),
               decoration: BoxDecoration(
                 color: statusBg,
                 borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   if (!isSuggest) Icon(statusIcon, color: statusTextColor, size: 14),
                   if (!isSuggest) const SizedBox(width: 4),
                   Text(
                     statusLabel,
                     style: TextStyle(
                       fontSize: 12,
                       fontWeight: FontWeight.w600,
                       color: statusTextColor,
                     ),
                   ),
                   if (isSuggest) const SizedBox(width: 4),
                   if (isSuggest) Icon(statusIcon, color: statusTextColor, size: 14),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// THÀNH PHẦN 4: BỨC TRANH TÀI CHÍNH
// ==========================================
class _FinancialPictureSection extends StatelessWidget {
  const _FinancialPictureSection({this.funds = const <Budget>[]});
  
  final List<Budget> funds;

  @override
  Widget build(BuildContext context) {
    void openFundStatus() {
      Navigator.of(context).pushNamed('/budget/status-track');
    }

    final hasFund = funds.isNotEmpty;
    final firstFund = hasFund ? funds.first : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
           children: const [
             Text(
               'Financial Picture',
               style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333)),
             ),
           ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
               Row(
                 children: const [
                   Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF15AABF), size: 20),
                   SizedBox(width: 8),
                   Text('More management', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                   Icon(Icons.chevron_right, color: Color(0xFF868E96), size: 20),
                   Spacer(),
                   Icon(Icons.more_horiz, color: Color(0xFF868E96)),
                 ],
               ),
               const SizedBox(height: 16),
               Row(
                 children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9E7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Offers since start of year', style: TextStyle(fontSize: 12, color: Color(0xFF495057))),
                            const SizedBox(height: 4),
                            const Text('7,000 VND', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Text('+0 VND', style: TextStyle(fontSize: 13, color: Color(0xFF20C997), fontWeight: FontWeight.w600)),
                                const Spacer(),
                                Icon(Icons.local_offer, color: const Color(0xFFD6336C).withOpacity(0.5), size: 24),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: openFundStatus,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD0EBFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(hasFund ? firstFund!.categoryName : 'Save 10% of income', style: const TextStyle(fontSize: 12, color: Color(0xFF495057))),
                              const SizedBox(height: 4),
                              Text(hasFund ? firstFund!.name : 'Emergency Fund', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFD6336C))),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Text(hasFund ? '${firstFund!.percentageUsed.toStringAsFixed(0)}% reached' : 'Try creating now', style: const TextStyle(fontSize: 11, color: Color(0xFF495057))),
                                  const Icon(Icons.arrow_forward, size: 12),
                                  const Spacer(),
                                  Icon(Icons.savings_outlined, color: Colors.orange.shade300, size: 24),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                 ],
               ),
               const SizedBox(height: 16),
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
                 child: Row(
                   children: const [
                      Icon(Icons.info_outline, color: Color(0xFF495057), size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Spending data differs from transaction limits set by the State Bank. See details',
                          style: TextStyle(fontSize: 12, color: Color(0xFF495057)),
                        ),
                      )
                   ],
                 ),
               )
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthData {
  final DateTime month;
  final double income;
  final double expense;

  const _MonthData({
    required this.month,
    required this.income,
    required this.expense,
  });
}
