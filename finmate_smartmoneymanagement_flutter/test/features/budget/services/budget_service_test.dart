import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/budget/services/budget_service.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/budget/models/budget.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late BudgetService budgetService;

  setUp(() {
    mockApiClient = MockApiClient();
    budgetService = BudgetService(client: mockApiClient);
  });

  group('BudgetService Tests', () {
    test('getBudgets retrieves and maps list of Budgets', () async {
      // Assuming Budget.fromJson maps this correctly
      final mockData = [
        {
          'id': 1,
          'name': 'Groceries',
          'amountLimit': 500,
          'spent': 100,
          'period': 'MONTHLY',
          'status': 'ACTIVE',
          'categoryId': 1,
          'categoryName': 'Food',
        }
      ];

      when(() => mockApiClient.get('/api/budgets'))
          .thenAnswer((_) async => mockData);

      final result = await budgetService.getBudgets();

      expect(result.length, 1);
      expect(result.first.name, 'Groceries');
      expect(result.first.amountLimit, 500);
      verify(() => mockApiClient.get('/api/budgets')).called(1);
    });

    test('getBudgetById returns a single Budget', () async {
      final mockData = {
        'id': 2,
        'name': 'Rent',
        'amountLimit': 1000,
        'spent': 1000,
        'period': 'MONTHLY',
        'status': 'ACTIVE',
        'categoryId': 2,
        'categoryName': 'Housing',
      };

      when(() => mockApiClient.get('/api/budgets/2'))
          .thenAnswer((_) async => mockData);

      final result = await budgetService.getBudgetById(2);

      expect(result.id, 2);
      expect(result.name, 'Rent');
      verify(() => mockApiClient.get('/api/budgets/2')).called(1);
    });

  });
}
