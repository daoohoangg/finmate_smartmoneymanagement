import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import 'filter_transactions_screen.dart';
import 'search_results_screen.dart';
import 'services/transaction_service.dart';

class TransactionsListScreen extends StatefulWidget {
  const TransactionsListScreen({super.key});

  static const String routeName = '/transactions/list';

  @override
  State<TransactionsListScreen> createState() => _TransactionsListScreenState();
}

class _TransactionsListScreenState extends State<TransactionsListScreen>
    with WidgetsBindingObserver {
  final TransactionService _transactionService = TransactionService();

  bool _isLoading = true;
  String? _error;
  List<_TransactionRecord> _records = const <_TransactionRecord>[];

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
      final rawTransactions = await _transactionService.getTransactions();
      final parsed = rawTransactions
          .map(_TransactionRecord.fromJson)
          .toList(growable: false)
        ..sort((a, b) {
          final aDate = a.transactionDate;
          final bDate = b.transactionDate;
          if (aDate == null && bDate == null) return b.id.compareTo(a.id);
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
      if (!mounted) return;
      setState(() {
        _records = parsed;
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

  String _formatMoney(double amount, {required bool isIncome}) {
    final rounded = amount.round();
    final absolute = rounded.abs().toString();
    final separated = absolute.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    final sign = isIncome ? '+' : '-';
    return '$sign$separated VND';
  }

  String _formatGroupLabel(DateTime? date) {
    if (date == null) return 'Unknown date';
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(local.year, local.month, local.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (target == today) return 'Today';
    if (target == yesterday) return 'Yesterday';
    return '${_twoDigits(local.day)} ${_monthShort(local.month)} ${local.year}';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:--';
    final local = date.toLocal();
    final hour24 = local.hour;
    final minute = _twoDigits(local.minute);
    final suffix = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    return '$hour12:$minute $suffix';
  }

  String _monthShort(int month) {
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '---';
    return months[month - 1];
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  List<_GroupedTransactions> _groupedByDate() {
    if (_records.isEmpty) return const <_GroupedTransactions>[];
    final grouped = <String, List<_TransactionRecord>>{};
    final keys = <String, DateTime?>{};

    for (final record in _records) {
      final date = record.transactionDate?.toLocal();
      final key = date == null
          ? 'unknown'
          : '${date.year}-${_twoDigits(date.month)}-${_twoDigits(date.day)}';
      grouped.putIfAbsent(key, () => <_TransactionRecord>[]).add(record);
      keys[key] = date;
    }

    final entries = grouped.entries.map((entry) {
      final date = keys[entry.key];
      return _GroupedTransactions(date: date, records: entry.value);
    }).toList(growable: false)
      ..sort((a, b) {
        if (a.date == null && b.date == null) return 0;
        if (a.date == null) return 1;
        if (b.date == null) return -1;
        return b.date!.compareTo(a.date!);
      });

    return entries;
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load transactions',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadTransactions, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final grouped = _groupedByDate();

    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          _SearchField(
            hint: 'Search by note or amount',
            onTap: () => Navigator.pushNamed(context, SearchResultsScreen.routeName),
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            children: [
              _FilterChip(label: 'All history', active: true),
            ],
          ),
          const SizedBox(height: 16),
          if (_records.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'No transactions yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ...grouped.expand((group) {
            return <Widget>[
              _SectionHeader(title: _formatGroupLabel(group.date)),
              const SizedBox(height: 8),
              ...group.records.map((record) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TransactionRow(
                    title: record.displayTitle,
                    subtitle:
                        '${record.displaySubtitle} - ${_formatTime(record.transactionDate)}',
                    amount: _formatMoney(
                      record.amount,
                      isIncome: record.isIncome,
                    ),
                    amountColor:
                        record.isIncome ? AppColors.success : AppColors.primaryRed,
                    icon: record.icon,
                    iconColor: record.iconColor,
                  ),
                );
              }),
              const SizedBox(height: 6),
            ];
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textMuted),
            onPressed: () => Navigator.pushNamed(
              context,
              FilterTransactionsScreen.routeName,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textMuted),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.transactions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: _buildBody(context),
          ),
        ),
      ),
    );
  }
}

class _GroupedTransactions {
  const _GroupedTransactions({required this.date, required this.records});

  final DateTime? date;
  final List<_TransactionRecord> records;
}

class _TransactionRecord {
  const _TransactionRecord({
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

  bool get isIncome => type == 'INCOME';

  String get displayTitle {
    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      return trimmedNote;
    }
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
        return 'Savings commit';
      case 'INVESTMENT_EXECUTION':
        return 'Investment execution';
      default:
        return 'Transaction';
    }
  }

  String get displaySubtitle {
    final trimmedWallet = walletName?.trim();
    final wallet =
        trimmedWallet != null && trimmedWallet.isNotEmpty
            ? trimmedWallet
            : 'Unknown wallet';
    final trimmedCategory = categoryName?.trim();
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      return '$trimmedCategory • $wallet';
    }
    return '$type • $wallet';
  }

  IconData get icon {
    switch (type) {
      case 'INCOME':
        return Icons.trending_up;
      case 'EXPENSE':
        return Icons.shopping_cart_outlined;
      case 'TRANSFER':
        return Icons.swap_horiz;
      case 'SAVINGS_COMMIT':
        return Icons.savings_outlined;
      case 'INVESTMENT_EXECUTION':
        return Icons.show_chart;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  Color get iconColor {
    switch (type) {
      case 'INCOME':
        return AppColors.success;
      case 'EXPENSE':
        return AppColors.primaryRed;
      case 'TRANSFER':
        return const Color(0xFF3B82F6);
      case 'SAVINGS_COMMIT':
        return const Color(0xFFF59E0B);
      case 'INVESTMENT_EXECUTION':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.textSecondary;
    }
  }

  factory _TransactionRecord.fromJson(Map<String, dynamic> json) {
    return _TransactionRecord(
      id: _parseInt(json['id']),
      type: json['type']?.toString().toUpperCase() ?? 'UNKNOWN',
      amount: _parseDouble(json['amount']),
      note: json['note']?.toString(),
      categoryName: json['categoryName']?.toString(),
      walletName: json['walletName']?.toString(),
      transactionDate: _parseDateTime(json['transactionDate']),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? _parseDateTime(dynamic value) {
  final raw = value?.toString();
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw);
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onTap});

  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              hint,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryRed : AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: active ? AppColors.primaryRed : AppColors.border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: active ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textMuted,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final IconData icon;
  final Color iconColor;

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
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
