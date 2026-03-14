import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../dashboard/monthly_dashboard_screen.dart';
import '../transactions/add_transaction_screen.dart';
import '../transactions/filter_transactions_screen.dart';
import '../transactions/services/transaction_service.dart';

void _noopAction() {}

class WeeklyCalendarScreen extends StatefulWidget {
  const WeeklyCalendarScreen({super.key});

  static const String routeName = '/calendar/weekly';

  @override
  State<WeeklyCalendarScreen> createState() => _WeeklyCalendarScreenState();
}

class _WeeklyCalendarScreenState extends State<WeeklyCalendarScreen>
    with WidgetsBindingObserver {
  final TransactionService _transactionService = TransactionService();

  bool _isLoading = true;
  bool _showAmounts = true;
  String? _error;

  List<_CalendarTransaction> _transactions = const <_CalendarTransaction>[];
  DateTime _visibleMonth = _monthStart(DateTime.now());
  DateTime _selectedDate = _dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTransactions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final raw = await _transactionService.getTransactions();
      final parsed =
          raw
              .map(_CalendarTransaction.fromJson)
              .where((transaction) => transaction.transactionDate != null)
              .toList(growable: false)
            ..sort((a, b) => b.localDate.compareTo(a.localDate));

      if (!mounted) return;

      var nextSelected = _selectedDate;
      if (!_isInSameMonth(nextSelected, _visibleMonth)) {
        nextSelected =
            _firstDayWithTransactions(_visibleMonth, source: parsed) ??
            DateTime(_visibleMonth.year, _visibleMonth.month, 1);
      }

      setState(() {
        _transactions = parsed;
        _selectedDate = nextSelected;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    final nextMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + delta,
      1,
    );
    final daysInNextMonth = DateTime(
      nextMonth.year,
      nextMonth.month + 1,
      0,
    ).day;
    final targetDay = _selectedDate.day > daysInNextMonth
        ? daysInNextMonth
        : _selectedDate.day;

    setState(() {
      _visibleMonth = nextMonth;
      _selectedDate = DateTime(nextMonth.year, nextMonth.month, targetDay);
    });
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

  void _openTransactionEntry() {
    Navigator.pushNamed(context, AddTransactionScreen.routeName).then((_) {
      if (!mounted) return;
      _loadTransactions();
    });
  }

  List<_CalendarTransaction> _transactionsOnDate(DateTime date) {
    final target = _dateOnly(date);
    final filtered =
        _transactions
            .where((transaction) {
              return _dateOnly(transaction.localDate) == target;
            })
            .toList(growable: false)
          ..sort((a, b) => b.localDate.compareTo(a.localDate));
    return filtered;
  }

  _MonthSummary _buildMonthSummary() {
    var income = 0.0;
    var expense = 0.0;
    for (final transaction in _transactions) {
      final date = transaction.localDate;
      if (date.year != _visibleMonth.year ||
          date.month != _visibleMonth.month) {
        continue;
      }
      if (transaction.isIncome) {
        income += transaction.amount;
      } else if (transaction.isExpense) {
        expense += transaction.amount;
      }
    }
    return _MonthSummary(income: income, expense: expense);
  }

  Map<int, _DaySummary> _buildDaySummaries() {
    final map = <int, _DaySummary>{};
    for (final transaction in _transactions) {
      final date = transaction.localDate;
      if (date.year != _visibleMonth.year ||
          date.month != _visibleMonth.month) {
        continue;
      }
      if (!transaction.isIncome && !transaction.isExpense) {
        continue;
      }
      final current = map[date.day] ?? const _DaySummary();
      if (transaction.isIncome) {
        map[date.day] = _DaySummary(
          income: current.income + transaction.amount,
          expense: current.expense,
        );
      } else {
        map[date.day] = _DaySummary(
          income: current.income,
          expense: current.expense + transaction.amount,
        );
      }
    }
    return map;
  }

  DateTime? _firstDayWithTransactions(
    DateTime month, {
    required List<_CalendarTransaction> source,
  }) {
    DateTime? found;
    for (final transaction in source) {
      final date = transaction.localDate;
      if (date.year != month.year || date.month != month.month) continue;
      final day = DateTime(date.year, date.month, date.day);
      if (found == null || day.isBefore(found)) {
        found = day;
      }
    }
    return found;
  }

  @override
  Widget build(BuildContext context) {
    final monthSummary = _buildMonthSummary();
    final daySummaries = _buildDaySummaries();
    final selectedTransactions = _transactionsOnDate(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.page,
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.calendar,
      ),
      body: Column(
        children: [
          _CalendarHeader(
            onBack: _goBack,
            onToday: _noopAction,
            onOpenAiChat: _noopAction,
            onOpenHome: _noopAction,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            if (_error != null)
                              _CalendarError(
                                message: _error!,
                                onRetry: _loadTransactions,
                              ),
                            _MonthToolbar(
                              monthText:
                                  'Month ${_visibleMonth.month}/${_visibleMonth.year}',
                              showAmounts: _showAmounts,
                              onToggleAmount: () {
                                setState(() {
                                  _showAmounts = !_showAmounts;
                                });
                              },
                              onPreviousMonth: () => _changeMonth(-1),
                              onNextMonth: () => _changeMonth(1),
                              onOpenFilter: () => Navigator.pushNamed(
                                context,
                                FilterTransactionsScreen.routeName,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _MonthSummaryCard(summary: monthSummary),
                            const SizedBox(height: 12),
                            const _WeekdayHeader(),
                            const SizedBox(height: 10),
                            _MonthGrid(
                              visibleMonth: _visibleMonth,
                              selectedDate: _selectedDate,
                              showAmounts: _showAmounts,
                              daySummaries: daySummaries,
                              onSelectDay: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            const _LegendRow(),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _TransactionsPanel(
                    selectedDate: _selectedDate,
                    records: selectedTransactions,
                    onOpenTransactionEntry: _openTransactionEntry,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.onBack,
    required this.onToday,
    required this.onOpenAiChat,
    required this.onOpenHome,
  });

  final VoidCallback onBack;
  final VoidCallback onToday;
  final VoidCallback onOpenAiChat;
  final VoidCallback onOpenHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 14),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                color: AppColors.textPrimary,
                iconSize: 28,
              ),
              const SizedBox(width: 2),
              Text(
                'Calendar',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthToolbar extends StatelessWidget {
  const _MonthToolbar({
    required this.monthText,
    required this.showAmounts,
    required this.onToggleAmount,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onOpenFilter,
  });

  final String monthText;
  final bool showAmounts;
  final VoidCallback onToggleAmount;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onOpenFilter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FlatIconButton(
          icon: showAmounts
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          onTap: onToggleAmount,
        ),
        const SizedBox(width: 8),
        _FlatIconButton(
          icon: Icons.chevron_left_rounded,
          onTap: onPreviousMonth,
        ),
        Expanded(
          child: Text(
            monthText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _FlatIconButton(icon: Icons.chevron_right_rounded, onTap: onNextMonth),
        const SizedBox(width: 8),
        _FlatIconButton(icon: Icons.filter_alt_outlined, onTap: onOpenFilter),
      ],
    );
  }
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({required this.summary});

  final _MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E8FF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryColumn(
              title: 'Income',
              value: _formatCurrencyVnd(summary.income),
              color: AppColors.success,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryColumn(
              title: 'Spending',
              value: _formatCurrencyVnd(summary.expense),
              color: AppColors.textPrimary,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: _SummaryColumn(
              title: 'Difference',
              value: _formatCurrencyVnd(summary.balance, showSign: true),
              color: summary.balance < 0
                  ? AppColors.textPrimary
                  : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: const Color(0xFFCFE2F6),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: labels.map((label) {
        return Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.showAmounts,
    required this.daySummaries,
    required this.onSelectDay,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final bool showAmounts;
  final Map<int, _DaySummary> daySummaries;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final leadingEmpty = firstDayOfMonth.weekday - 1;
    final totalSlots = leadingEmpty + daysInMonth;
    final rowCount = (totalSlots / 7).ceil();
    final cellCount = rowCount * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cellCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.54,
      ),
      itemBuilder: (context, index) {
        final day = index - leadingEmpty + 1;
        if (day < 1 || day > daysInMonth) {
          return const SizedBox.shrink();
        }
        final date = DateTime(visibleMonth.year, visibleMonth.month, day);
        final summary = daySummaries[day];
        final selected = DateUtils.isSameDay(date, selectedDate);
        return _DayCell(
          dayNumber: day,
          summary: summary,
          selected: selected,
          showAmounts: showAmounts,
          onTap: () => onSelectDay(date),
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.dayNumber,
    required this.summary,
    required this.selected,
    required this.showAmounts,
    required this.onTap,
  });

  final int dayNumber;
  final _DaySummary? summary;
  final bool selected;
  final bool showAmounts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expense = summary?.expense ?? 0;
    final income = summary?.income ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 86;
          final showExpense = showAmounts && expense > 0;
          var showIncome = showAmounts && income > 0;
          if (compact && showExpense && showIncome) {
            // Keep one line in tight cells to avoid RenderFlex overflow.
            showIncome = false;
          }

          final dayFontSize = compact ? 12.0 : 14.0;
          final amountFontSize = compact ? 13.0 : 16.0;

          return Container(
            padding: EdgeInsets.fromLTRB(
              compact ? 4 : 6,
              compact ? 4 : 6,
              compact ? 4 : 6,
              compact ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F2FF) : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primaryBlue : AppColors.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Text(
                    '$dayNumber',
                    textScaler: TextScaler.noScaling,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: dayFontSize,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showExpense)
                          _DayAmountText(
                            value: _formatCompactAmount(expense),
                            color: AppColors.textPrimary,
                            fontSize: amountFontSize,
                          ),
                        if (showIncome)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: _DayAmountText(
                              value: _formatCompactAmount(income),
                              color: AppColors.success,
                              fontSize: amountFontSize,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DayAmountText extends StatelessWidget {
  const _DayAmountText({
    required this.value,
    required this.color,
    required this.fontSize,
  });

  final String value;
  final Color color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          maxLines: 1,
          softWrap: false,
          textScaler: TextScaler.noScaling,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _LegendDot(color: AppColors.success, label: 'In'),
        SizedBox(width: 22),
        _LegendDot(color: AppColors.textPrimary, label: 'Out'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TransactionsPanel extends StatelessWidget {
  const _TransactionsPanel({
    required this.selectedDate,
    required this.records,
    required this.onOpenTransactionEntry,
  });

  final DateTime selectedDate;
  final List<_CalendarTransaction> records;
  final VoidCallback onOpenTransactionEntry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.keyboard_double_arrow_up_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction List',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateTag(date: selectedDate),
                    const SizedBox(height: 10),
                    if (records.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No transactions for this day.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: onOpenTransactionEntry,
                              icon: const Icon(Icons.edit_note_rounded),
                              label: const Text('Record Transaction'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryBlue,
                                side: const BorderSide(
                                  color: AppColors.primaryBlue,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ...records.map((record) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TransactionCard(record: record),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTag extends StatelessWidget {
  const _DateTag({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E5F2)),
      ),
      child: Text(
        _formatDateLabel(date),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.record});

  final _CalendarTransaction record;

  @override
  Widget build(BuildContext context) {
    final iconColor = record.iconColor;
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(record.icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.displayTitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${record.displaySubtitle} • ${record.timeLabel}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            record.amountLabel,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: record.amountColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarError extends StatelessWidget {
  const _CalendarError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD4D8)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.primaryRed,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.primaryRed),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _FlatIconButton extends StatelessWidget {
  const _FlatIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: AppColors.textPrimary),
      ),
    );
  }
}

class _MonthSummary {
  const _MonthSummary({required this.income, required this.expense});

  final double income;
  final double expense;

  double get balance => income - expense;
}

class _DaySummary {
  const _DaySummary({this.income = 0, this.expense = 0});

  final double income;
  final double expense;
}

class _CalendarTransaction {
  const _CalendarTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.note,
    required this.categoryName,
    required this.walletName,
    required this.transactionDate,
  });

  final int id;
  final String type;
  final double amount;
  final String? note;
  final String? categoryName;
  final String? walletName;
  final DateTime? transactionDate;

  DateTime get localDate => transactionDate!.toLocal();

  bool get isIncome => type == 'INCOME';
  bool get isExpense => type == 'EXPENSE';

  IconData get icon {
    final category = (categoryName ?? '').toLowerCase();
    if (isIncome) return Icons.arrow_circle_down_rounded;
    if (category.contains('market') || category.contains('chợ')) {
      return Icons.shopping_basket_outlined;
    }
    if (category.contains('food') || category.contains('ăn')) {
      return Icons.restaurant_outlined;
    }
    if (category.contains('transport') || category.contains('di chuyển')) {
      return Icons.directions_car_filled_outlined;
    }
    if (category.contains('bill') || category.contains('hóa đơn')) {
      return Icons.receipt_long_outlined;
    }
    if (category.contains('saving') || category.contains('tiết kiệm')) {
      return Icons.savings_outlined;
    }
    if (category.contains('learning') || category.contains('học')) {
      return Icons.school_outlined;
    }
    if (category.contains('shopping') || category.contains('mua sắm')) {
      return Icons.shopping_cart_outlined;
    }
    if (category.contains('entertainment') || category.contains('giải trí')) {
      return Icons.movie_outlined;
    }
    if (category.contains('charity') || category.contains('từ thiện')) {
      return Icons.volunteer_activism_outlined;
    }
    if (type == 'TRANSFER') return Icons.swap_horiz_rounded;
    return isExpense ? Icons.payments_outlined : Icons.receipt_long_outlined;
  }

  Color get iconColor {
    if (isIncome) return AppColors.success;
    if (isExpense) return AppColors.textPrimary;
    if (type == 'TRANSFER') return const Color(0xFF2563EB);
    return AppColors.textSecondary;
  }

  Color get amountColor => isIncome ? AppColors.success : AppColors.textPrimary;

  String get displayTitle {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isNotEmpty) return trimmedNote;

    final trimmedCategory = categoryName?.trim();
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      return trimmedCategory;
    }

    switch (type) {
      case 'INCOME':
        return 'Income';
      case 'EXPENSE':
        return 'Expense';
      case 'TRANSFER':
        return 'Transfer';
      case 'SAVINGS_COMMIT':
        return 'Savings Deposit';
      case 'INVESTMENT_EXECUTION':
        return 'Investment';
      default:
        return 'Transaction';
    }
  }

  String get displaySubtitle {
    final trimmedWallet = walletName?.trim();
    if (trimmedWallet != null && trimmedWallet.isNotEmpty) {
      return trimmedWallet;
    }
    return 'Unknown wallet';
  }

  String get amountLabel {
    final sign = isIncome ? '+' : '-';
    return '$sign${_formatCurrencyVnd(amount)}';
  }

  String get timeLabel {
    final local = localDate;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  factory _CalendarTransaction.fromJson(Map<String, dynamic> json) {
    return _CalendarTransaction(
      id: _toInt(json['id']),
      type: json['type']?.toString().toUpperCase() ?? 'UNKNOWN',
      amount: _toDouble(json['amount']),
      note: json['note']?.toString(),
      categoryName: json['categoryName']?.toString(),
      walletName: json['walletName']?.toString(),
      transactionDate: _toDateTime(json['transactionDate']),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _monthStart(DateTime value) => DateTime(value.year, value.month, 1);

bool _isInSameMonth(DateTime date, DateTime month) {
  return date.year == month.year && date.month == month.month;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _toDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw);
}

String _monthShort(int month) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  if (month < 1 || month > 12) return '';
  return months[month - 1];
}

String _formatDateLabel(DateTime date) {
  return '${_monthShort(date.month)} ${date.day}, ${date.year}';
}

String _formatCompactAmount(double amount) {
  final absolute = amount.abs().round();
  if (absolute >= 1000000) {
    final value = (absolute / 1000000).toStringAsFixed(1);
    final trimmed = value.endsWith('.0')
        ? value.substring(0, value.length - 2)
        : value;
    return '${trimmed}m';
  }
  if (absolute >= 1000) {
    return '${(absolute / 1000).round()}k';
  }
  return '$absolute';
}

String _formatCurrencyVnd(double amount, {bool showSign = false}) {
  final rounded = amount.round();
  final sign = showSign && rounded > 0
      ? '+'
      : showSign && rounded < 0
      ? '-'
      : '';
  final absolute = rounded.abs().toString();
  final grouped = absolute.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '$sign$grouped VND';
}
