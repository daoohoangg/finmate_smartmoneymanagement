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

  Future<Budget> reassignBudget({
    required int fromCategoryId,
    required int toCategoryId,
    required num amount,
  }) async {
    final data = await _client.post(
      '/api/budgets/reassign',
      body: {
        'fromCategoryId': fromCategoryId,
        'toCategoryId': toCategoryId,
        'amount': amount,
      },
    );
    return Budget.fromJson(data as Map<String, dynamic>);
  }

  Future<Budget> updateBudgetAmount({
    required int budgetId,
    required num amountLimit,
    required BudgetPeriod period,
  }) async {
    final data = await _client.put(
      '/api/budgets/$budgetId',
      body: {'amountLimit': amountLimit, 'period': period.apiValue},
    );
    return Budget.fromJson(data as Map<String, dynamic>);
  }

  Future<Budget> updateBudgetStatus({
    required int budgetId,
    required BudgetStatus status,
    required num amountLimit, // Required for the backend payload currently
    required BudgetPeriod period,
  }) async {
    final data = await _client.put(
      '/api/budgets/$budgetId',
      body: {
        'amountLimit': amountLimit, 
        'period': period.apiValue,
        'status': status.apiValue,
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
