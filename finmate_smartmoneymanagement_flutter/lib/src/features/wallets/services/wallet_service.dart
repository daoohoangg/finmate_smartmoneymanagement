import '../../../core/network/api_client.dart';
import '../models/wallet.dart';

class WalletService {
  WalletService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Wallet>> getWallets() async {
    final data = await _client.get('/api/wallets');
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(Wallet.fromJson)
          .toList();
    }
    return [];
  }

  Future<Wallet> createWallet({
    required String name,
    num? balance,
    String? currency,
    String? icon,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'balance': balance ?? 0,
      'currency': currency ?? 'VND',
    };
    if (icon != null && icon.isNotEmpty) {
      body['icon'] = icon;
    }
    final data = await _client.post('/api/wallets', body: body);
    return Wallet.fromJson(data as Map<String, dynamic>);
  }
}
