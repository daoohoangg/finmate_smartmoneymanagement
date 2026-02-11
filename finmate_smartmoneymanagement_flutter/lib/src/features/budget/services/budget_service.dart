import '../../../core/network/api_client.dart';
import '../models/budget.dart';

class BudgetService {
  BudgetService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> createBudget({
    required int categoryId,
    required num amountLimit,
    required BudgetPeriod period,
  }) async {
    final data = await _client.post(
      '/api/budgets',
      body: {
        'categoryId': categoryId,
        'amountLimit': amountLimit,
        'period': period.apiValue,
      },
    );
    return data as Map<String, dynamic>;
  }
}
