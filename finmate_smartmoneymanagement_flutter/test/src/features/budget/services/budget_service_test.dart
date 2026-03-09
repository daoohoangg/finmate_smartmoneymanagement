import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/budget/services/budget_service.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/budget/models/budget.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late BudgetService budgetService;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    budgetService = BudgetService(client: mockApiClient);
  });

  group('BudgetService', () {
    final mockBudgetJson = {
      'id': 1,
      'name': 'Test Budget',
      'categoryId': 2,
      'categoryName': 'Food',
      'amountLimit': 500,
      'spent': 100,
      'available': 400,
      'period': 'MONTH',
      'percentageUsed': 20,
    };

    test('getBudgets returns list of budgets', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => [mockBudgetJson]);

      final result = await budgetService.getBudgets();

      expect(result, isA<List<Budget>>());
      expect(result.length, 1);
      expect(result.first.id, 1);
      expect(result.first.name, 'Test Budget');
      verify(() => mockApiClient.get('/api/budgets')).called(1);
    });

    test('getBudgets returns empty list when no data', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => []);

      final result = await budgetService.getBudgets();

      expect(result, isEmpty);
    });

    test('getBudgetById returns a budget', () async {
      when(() => mockApiClient.get(any())).thenAnswer((_) async => mockBudgetJson);

      final result = await budgetService.getBudgetById(1);

      expect(result, isA<Budget>());
      expect(result.id, 1);
      verify(() => mockApiClient.get('/api/budgets/1')).called(1);
    });

    test('createBudget posts data correctly', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => mockBudgetJson);

      final result = await budgetService.createBudget(
        name: 'New',
        categoryId: 3,
        amountLimit: 1000,
        period: BudgetPeriod.week,
      );

      expect(result, equals(mockBudgetJson));
      verify(() => mockApiClient.post(
            '/api/budgets',
            body: {
              'name': 'New',
              'categoryId': 3,
              'amountLimit': 1000,
              'period': 'WEEK',
            },
          )).called(1);
    });

    test('addContribution posts data correctly', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => mockBudgetJson);

      final result = await budgetService.addContribution(
        budgetId: 1,
        amount: 50,
        walletId: 2,
        note: 'Test note',
      );

      expect(result, isA<Budget>());
      verify(() => mockApiClient.post(
            '/api/budgets/1/contributions',
            body: {
              'amount': 50,
              'walletId': 2,
              'note': 'Test note',
            },
          )).called(1);
    });
  });
}
