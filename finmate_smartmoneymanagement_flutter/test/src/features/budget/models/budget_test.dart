import 'package:flutter_test/flutter_test.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/budget/models/budget.dart';

void main() {
  group('Budget Model', () {
    test('fromJson creates correct instance from valid JSON', () {
      final json = {
        'id': 1,
        'name': 'Groceries',
        'categoryId': 2,
        'categoryName': 'Food',
        'amountLimit': 500.0,
        'savedAmount': 100.0,
        'remainingToGoal': 400.0,
        'savingProgressPercentage': 20,
        'spent': 150.0,
        'available': 350.0,
        'period': 'MONTH',
        'percentageUsed': 30,
      };

      final budget = Budget.fromJson(json);

      expect(budget.id, 1);
      expect(budget.name, 'Groceries');
      expect(budget.categoryId, 2);
      expect(budget.categoryName, 'Food');
      expect(budget.amountLimit, 500.0);
      expect(budget.savedAmount, 100.0);
      expect(budget.remainingToGoal, 400.0);
      expect(budget.savingProgressPercentage, 20);
      expect(budget.spent, 150.0);
      expect(budget.available, 350.0);
      expect(budget.period, BudgetPeriod.month);
      expect(budget.percentageUsed, 30);
    });

    test('fromJson uses fallback values and types appropriately', () {
      final json = {
        'id': '1', // String instead of int
        'amountLimit': '500', // String instead of double
        'spent': 150, // int instead of double
        'available': 350,
        'period': 'WEEK',
        // Missing savedAmount, remainingToGoal, savingProgressPercentage
        'percentageUsed': '30',
      };

      final budget = Budget.fromJson(json);

      expect(budget.id, 1);
      expect(budget.amountLimit, 500.0);
      expect(budget.savedAmount, 150.0); // Fallbacks to spent
      expect(budget.remainingToGoal, 350.0); // Fallbacks to available
      expect(budget.savingProgressPercentage, 30); // Fallbacks to percentageUsed
      expect(budget.spent, 150.0);
      expect(budget.period, BudgetPeriod.week);
      expect(budget.percentageUsed, 30);
    });
  });

  group('BudgetPeriodX', () {
    test('apiValue returns correct string', () {
      expect(BudgetPeriod.month.apiValue, 'MONTH');
      expect(BudgetPeriod.week.apiValue, 'WEEK');
    });

    test('fromApi parses correct string', () {
      expect(BudgetPeriodX.fromApi('MONTH'), BudgetPeriod.month);
      expect(BudgetPeriodX.fromApi('WEEK'), BudgetPeriod.week);
      expect(BudgetPeriodX.fromApi('unknown'), BudgetPeriod.month); // Fallback
      expect(BudgetPeriodX.fromApi(null), BudgetPeriod.month); // Fallback
    });
  });
}
