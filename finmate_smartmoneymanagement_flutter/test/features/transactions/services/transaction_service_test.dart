import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/transactions/services/transaction_service.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/transactions/models/transaction.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late TransactionService transactionService;

  setUp(() {
    mockApiClient = MockApiClient();
    transactionService = TransactionService(client: mockApiClient);
  });

  group('TransactionService Tests', () {
    test('getTransactions retrieves a list of transaction maps', () async {
      final mockData = [
        {'id': 1, 'amount': 100, 'type': 'EXPENSE'},
        {'id': 2, 'amount': 200, 'type': 'INCOME'},
      ];

      when(() => mockApiClient.get('/api/transactions'))
          .thenAnswer((_) async => mockData);

      final result = await transactionService.getTransactions();

      expect(result.length, 2);
      expect(result.first['amount'], 100);
      verify(() => mockApiClient.get('/api/transactions')).called(1);
    });

    test('getTransactions returns empty list on empty response', () async {
      when(() => mockApiClient.get('/api/transactions'))
          .thenAnswer((_) async => []);

      final result = await transactionService.getTransactions();

      expect(result, isEmpty);
    });
  });
}
