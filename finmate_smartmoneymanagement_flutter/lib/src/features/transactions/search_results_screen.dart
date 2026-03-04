import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';

class SearchResultsScreen extends StatelessWidget {
  const SearchResultsScreen({super.key});

  static const String routeName = '/transactions/search';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      appBar: AppBar(
        title: const Text('Search Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.transactions),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  _SearchBar(),
                  const SizedBox(height: 30),
                  _EmptyState(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Clear All Filters'),
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

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Coffee and snacks August',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.border,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.search_off, color: AppColors.primaryRed),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'No transactions found',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Try adjusting your filters or use different search terms to find what you are looking for.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

