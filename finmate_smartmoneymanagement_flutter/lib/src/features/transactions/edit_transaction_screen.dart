import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import 'delete_transaction_screen.dart';

class EditTransactionScreen extends StatefulWidget {
  const EditTransactionScreen({super.key});

  static const String routeName = '/transactions/edit';

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  bool _isExpense = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Edit Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
            onPressed: () => Navigator.pushNamed(context, DeleteTransactionScreen.routeName),
          ),
        ],
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.transactions),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'EDITING TRANSACTION ID: #8821',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF22C55E),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SegmentedToggle(
                    leftLabel: 'Income',
                    rightLabel: 'Expense',
                    isLeftSelected: !_isExpense,
                    activeColor: const Color(0xFF22C55E),
                    onChanged: (value) => setState(() => _isExpense = !value),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$45.00',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: 'Oct 24, 2023',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Wallet',
                    value: 'Bank Account',
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    icon: Icons.shopping_basket_outlined,
                    label: 'Category',
                    value: 'Groceries',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NOTES',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Weekly grocery shopping',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'RECEIPT',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  _ReceiptCard(),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Save Changes',
                    color: const Color(0xFF22C55E),
                    onPressed: () {},
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

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.leftLabel,
    required this.rightLabel,
    required this.isLeftSelected,
    required this.activeColor,
    required this.onChanged,
  });

  final String leftLabel;
  final String rightLabel;
  final bool isLeftSelected;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

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
        children: [
          Expanded(
            child: _SegmentButton(
              label: leftLabel,
              selected: isLeftSelected,
              activeColor: activeColor,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: rightLabel,
              selected: !isLeftSelected,
              activeColor: activeColor,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
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
                'RECEIPT',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'REPLACE',
                  style: TextStyle(color: AppColors.success),
                ),
              ),
            ],
          ),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long, color: Colors.white, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        'Receipt preview',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
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
