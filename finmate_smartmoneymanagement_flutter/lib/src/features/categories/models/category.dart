class Category {
  Category({
    required this.id,
    required this.name,
    required this.type,
    this.group,
    this.isPrimary = false,
    this.icon,
    this.color,
    this.parentId,
    this.isSystemCategory = false,
  });

  final int id;
  final String name;
  final CategoryType type;
  final CategoryGroup? group;
  final bool isPrimary;
  final String? icon;
  final String? color;
  final int? parentId;
  final bool isSystemCategory;

  factory Category.fromJson(Map<String, dynamic> json) {
    final primaryRaw = json.containsKey('isPrimary') ? json['isPrimary'] : json['primary'];
    final systemRaw = json.containsKey('isSystemCategory')
        ? json['isSystemCategory']
        : json['systemCategory'];

    return Category(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: CategoryTypeX.fromApi(json['type']?.toString()),
      group: CategoryGroupX.fromApi(json['group']?.toString()),
      isPrimary: _parseBool(primaryRaw),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      parentId: _parseNullableInt(json['parentId']),
      isSystemCategory: _parseBool(systemRaw),
    );
  }
}

enum CategoryType { income, expense }

enum CategoryGroup { necessary, accumulation, flexibility }

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

extension CategoryGroupX on CategoryGroup {
  String get apiValue {
    switch (this) {
      case CategoryGroup.necessary:
        return 'NECESSARY';
      case CategoryGroup.accumulation:
        return 'ACCUMULATION';
      case CategoryGroup.flexibility:
        return 'FLEXIBILITY';
    }
  }

  static CategoryGroup? fromApi(String? value) {
    switch (value?.toUpperCase()) {
      case 'NECESSARY':
        return CategoryGroup.necessary;
      case 'ACCUMULATION':
        return CategoryGroup.accumulation;
      case 'FLEXIBILITY':
        return CategoryGroup.flexibility;
      default:
        return null;
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
