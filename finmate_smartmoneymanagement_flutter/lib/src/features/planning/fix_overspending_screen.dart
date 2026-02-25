import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import '../settings/settings_screen.dart';

class FixOverspendingScreen extends StatefulWidget {
  const FixOverspendingScreen({super.key});

  static const String routeName = '/fix-overspending';

  @override
  State<FixOverspendingScreen> createState() => _FixOverspendingScreenState();
}

class _FixOverspendingScreenState extends State<FixOverspendingScreen> {
  static const double _overspentAmount = 25.00;
  static const String _overspentCategory = 'Dining Out';

  final List<_MoveSource> _sources = [
    _MoveSource(
      name: 'Groceries',
      available: 50,
      icon: Icons.shopping_basket_outlined,
    ),
    _MoveSource(
      name: 'Entertainment',
      available: 40,
      icon: Icons.movie_outlined,
    ),
    _MoveSource(
      name: 'Clothing',
      available: 15,
      icon: Icons.checkroom_outlined,
    ),
    _MoveSource(
      name: 'Gas & Fuel',
      available: 5,
      icon: Icons.local_gas_station_outlined,
    ),
  ];

  int? _selectedIndex;
  final TextEditingController _amountController = TextEditingController(
    text: _overspentAmount.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectSource(int index) {
    final source = _sources[index];
    setState(() {
      _selectedIndex = index;
      final safeAmount = min(_overspentAmount, source.available);
      _amountController.text = safeAmount.toStringAsFixed(2);
    });
  }

  Future<void> _confirmTransfer() async {
    if (_selectedIndex == null) {
      _showSnack('Select a category to move money from');
      return;
    }
    final source = _sources[_selectedIndex!];
    final moved = await _openMoveSheet(source);
    if (moved == true && mounted) {
      _showSnack('Transfer completed');
      Navigator.pushNamedAndRemoveUntil(
        context,
        SettingsScreen.routeName,
        (_) => false,
      );
    }
  }

  Future<bool?> _openMoveSheet(_MoveSource source) {
    final amountController = TextEditingController(
      text: _amountController.text,
    );
    String from = source.name;
    String to = _overspentCategory;
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Move Money',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                        border: InputBorder.none,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: from,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                      ),
                      items: _sources
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.name,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => from = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: to,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: _overspentCategory,
                          child: Text(_overspentCategory),
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 18),
                    PrimaryButton(
                      label: 'Move money',
                      color: AppColors.primaryBlue,
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fix Overspending'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.overview,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _OverspentCard(),
                        const SizedBox(height: 16),
                        Text(
                          'Where would you like to move money from?',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select a category with available budget to cover the deficit.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Column(
                          children: List.generate(
                            _sources.length,
                            (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _SourceCard(
                                source: _sources[index],
                                selected: _selectedIndex == index,
                                amountController: _amountController,
                                onSelect: () => _selectSource(index),
                                onMax: () {
                                  final available = _sources[index].available;
                                  _amountController.text = available
                                      .toStringAsFixed(2);
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: 'Confirm Transfer',
                color: AppColors.primaryBlue,
                onPressed: _confirmTransfer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverspentCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E4),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_outlined,
              color: AppColors.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overspent Category',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dining Out',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  '-\$25.00',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryRed,
                    fontWeight: FontWeight.w700,
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

class _MoveSource {
  const _MoveSource({
    required this.name,
    required this.available,
    required this.icon,
  });

  final String name;
  final double available;
  final IconData icon;
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.selected,
    required this.amountController,
    required this.onSelect,
    required this.onMax,
  });

  final _MoveSource source;
  final bool selected;
  final TextEditingController amountController;
  final VoidCallback onSelect;
  final VoidCallback onMax;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.fieldBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(source.icon, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    source.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '\$${source.available.toStringAsFixed(2)} Available',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!selected) ...[
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Move'),
                  ),
                ],
              ],
            ),
            if (selected) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: onMax,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('MAX'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
