enum TransactionType {
  income,
  expense,
  transfer,
  savingsCommit,
  investmentExecution,
}

extension TransactionTypeX on TransactionType {
  String get apiValue {
    switch (this) {
      case TransactionType.income:
        return 'INCOME';
      case TransactionType.expense:
        return 'EXPENSE';
      case TransactionType.transfer:
        return 'TRANSFER';
      case TransactionType.savingsCommit:
        return 'SAVINGS_COMMIT';
      case TransactionType.investmentExecution:
        return 'INVESTMENT_EXECUTION';
    }
  }
}
