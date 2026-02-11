enum BudgetPeriod { week, month }

extension BudgetPeriodX on BudgetPeriod {
  String get apiValue {
    switch (this) {
      case BudgetPeriod.week:
        return 'WEEK';
      case BudgetPeriod.month:
        return 'MONTH';
    }
  }
}
