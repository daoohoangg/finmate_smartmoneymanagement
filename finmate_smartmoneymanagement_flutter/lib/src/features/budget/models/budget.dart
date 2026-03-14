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

  String get label {
    switch (this) {
      case BudgetPeriod.week:
        return 'Week';
      case BudgetPeriod.month:
        return 'Month';
    }
  }

  static BudgetPeriod fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'WEEK':
        return BudgetPeriod.week;
      case 'MONTH':
        return BudgetPeriod.month;
      default:
        return BudgetPeriod.month;
    }
  }
}

enum BudgetStatus { processing, completed }

extension BudgetStatusX on BudgetStatus {
  String get apiValue {
    switch (this) {
      case BudgetStatus.processing:
        return 'PROCESSING';
      case BudgetStatus.completed:
        return 'COMPLETED';
    }
  }

  String get label {
    switch (this) {
      case BudgetStatus.processing:
        return 'Processing';
      case BudgetStatus.completed:
        return 'Completed';
    }
  }

  static BudgetStatus fromApi(String? value) {
    if (value?.toUpperCase() == 'COMPLETED') return BudgetStatus.completed;
    return BudgetStatus.processing;
  }
}

class Budget {
  Budget({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.amountLimit,
    required this.savedAmount,
    required this.remainingToGoal,
    required this.savingProgressPercentage,
    required this.spent,
    required this.available,
    required this.period,
    required this.percentageUsed,
    this.status = BudgetStatus.processing,
  });

  final int id;
  final String name;
  final int categoryId;
  final String categoryName;
  final double amountLimit;
  final double savedAmount;
  final double remainingToGoal;
  final int savingProgressPercentage;
  final double spent;
  final double available;
  final BudgetPeriod period;
  final int percentageUsed;
  final BudgetStatus status;

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      categoryId: _parseInt(json['categoryId']),
      categoryName: json['categoryName']?.toString() ?? '',
      amountLimit: _parseDouble(json['amountLimit']),
      savedAmount: _parseDouble(json['savedAmount'] ?? json['spent']),
      remainingToGoal: _parseDouble(
        json['remainingToGoal'] ?? json['available'],
      ),
      savingProgressPercentage: _parseInt(
        json['savingProgressPercentage'] ?? json['percentageUsed'],
      ),
      spent: _parseDouble(json['spent']),
      available: _parseDouble(json['available']),
      period: BudgetPeriodX.fromApi(json['period']?.toString()),
      percentageUsed: _parseInt(json['percentageUsed']),
      status: BudgetStatusX.fromApi(json['status']?.toString()),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
