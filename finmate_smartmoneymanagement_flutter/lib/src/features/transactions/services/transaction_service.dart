import '../../../core/network/api_client.dart';
import '../models/transaction.dart';

class TransactionService {
  TransactionService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> getTransactions() async {
    final data = await _client.get('/api/transactions');
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> createTransaction({
    required int walletId,
    int? categoryId,
    required TransactionType type,
    required num amount,
    String? note,
    String? imageUrl,
    DateTime? transactionDate,
    int? toWalletId,
    int? savingsGoalId,
    int? investmentPlanId,
  }) async {
    final body = <String, dynamic>{
      'walletId': walletId,
      'type': type.apiValue,
      'amount': amount,
    };
    if (categoryId != null) body['categoryId'] = categoryId;
    if (note != null && note.isNotEmpty) body['note'] = note;
    if (imageUrl != null && imageUrl.isNotEmpty) body['imageUrl'] = imageUrl;
    if (transactionDate != null) {
      body['transactionDate'] = transactionDate.toIso8601String();
    }
    if (toWalletId != null) body['toWalletId'] = toWalletId;
    if (savingsGoalId != null) body['savingsGoalId'] = savingsGoalId;
    if (investmentPlanId != null) body['investmentPlanId'] = investmentPlanId;

    final data = await _client.post('/api/transactions', body: body);
    return data as Map<String, dynamic>;
  }
}
