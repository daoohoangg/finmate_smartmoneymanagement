class Category {
  Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    this.parentId,
    this.isSystemCategory = false,
  });

  final int id;
  final String name;
  final CategoryType type;
  final String? icon;
  final String? color;
  final int? parentId;
  final bool isSystemCategory;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: CategoryTypeX.fromApi(json['type']?.toString()),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      parentId: _parseNullableInt(json['parentId']),
      isSystemCategory: _parseBool(json['isSystemCategory']),
    );
  }
}

enum CategoryType { income, expense }

extension CategoryTypeX on CategoryType {
  String get apiValue {
    switch (this) {
      case CategoryType.income:
        return 'INCOME';
      case CategoryType.expense:
        return 'EXPENSE';
    }
  }

  String get label {
    switch (this) {
      case CategoryType.income:
        return 'Income';
      case CategoryType.expense:
        return 'Expense';
    }
  }

  static CategoryType fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'INCOME':
        return CategoryType.income;
      case 'EXPENSE':
        return CategoryType.expense;
      default:
        return CategoryType.expense;
    }
  }
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int? _parseNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool _parseBool(dynamic value) {
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true';
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}
