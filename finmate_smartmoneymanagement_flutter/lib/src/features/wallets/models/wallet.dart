class Wallet {
  Wallet({
    required this.id,
    required this.name,
    this.balance,
    this.currency,
    this.icon,
  });

  final int id;
  final String name;
  final double? balance;
  final String? currency;
  final String? icon;

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      balance: _parseDouble(json['balance']),
      currency: json['currency']?.toString(),
      icon: json['icon']?.toString(),
    );
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
