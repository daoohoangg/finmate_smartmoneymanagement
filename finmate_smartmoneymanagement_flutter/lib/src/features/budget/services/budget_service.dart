import '../../../core/network/api_client.dart';
import '../models/budget.dart';

class BudgetService {
  BudgetService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Budget>> getBudgets() async {
    final data = await _client.get('/api/budgets');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Budget.fromJson)
          .toList();
    }
    return [];
  }

  Future<Budget> getBudgetById(int budgetId) async {
    final data = await _client.get('/api/budgets/$budgetId');
    return Budget.fromJson(data as Map<String, dynamic>);
  }

  Future<Budget> addContribution({
    required int budgetId,
    required num amount,
    required int walletId,
    String? note,
  }) async {
    final trimmedNote = note?.trim();
    final data = await _client.post(
      '/api/budgets/$budgetId/contributions',
      body: {
        'amount': amount,
        'walletId': walletId,
        if (trimmedNote != null && trimmedNote.isNotEmpty) 'note': trimmedNote,
      },
    );
    return Budget.fromJson(data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> createBudget({
    required String name,
    required int categoryId,
    required num amountLimit,
    required BudgetPeriod period,
  }) async {
    final data = await _client.post(
      '/api/budgets',
      body: {
        'name': name,
        'categoryId': categoryId,
        'amountLimit': amountLimit,
        'period': period.apiValue,
      },
    );
    return data as Map<String, dynamic>;
  }
}
