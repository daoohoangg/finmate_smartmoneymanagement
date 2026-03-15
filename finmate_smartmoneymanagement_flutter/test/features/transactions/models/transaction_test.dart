import 'package:flutter_test/flutter_test.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/transactions/models/transaction.dart';

void main() {
  group('TransactionType Extension Tests', () {
    test('apiValue maps income correctly', () {
      expect(TransactionType.income.apiValue, 'INCOME');
    });

    test('apiValue maps expense correctly', () {
      expect(TransactionType.expense.apiValue, 'EXPENSE');
    });

    test('apiValue maps transfer correctly', () {
      expect(TransactionType.transfer.apiValue, 'TRANSFER');
    });

    test('apiValue maps savingsCommit correctly', () {
      expect(TransactionType.savingsCommit.apiValue, 'SAVINGS_COMMIT');
    });

    test('apiValue maps investmentExecution correctly', () {
      expect(TransactionType.investmentExecution.apiValue, 'INVESTMENT_EXECUTION');
    });
  });
}
