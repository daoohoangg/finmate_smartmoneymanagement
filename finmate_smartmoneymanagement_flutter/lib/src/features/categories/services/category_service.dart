import '../../../core/network/api_client.dart';
import '../models/category.dart';

class CategoryService {
  CategoryService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<List<Category>> getCategories({
    CategoryType? type,
    bool includeSystem = true,
  }) async {
    final query = type != null ? '?type=${type.apiValue}' : '';
    final data = await _client.get('/api/categories$query');
    final userCategories = _parseList(data);

    if (!includeSystem) return userCategories;

    final systemData = await _client.get('/api/categories/system');
    var systemCategories = _parseList(systemData);
    if (type != null) {
      systemCategories = systemCategories.where((category) => category.type == type).toList();
    }
    return [...systemCategories, ...userCategories];
  }

  Future<Category> createCategory({
    required String name,
    required CategoryType type,
    CategoryGroup? group,
    String? icon,
    String? color,
    int? parentId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'type': type.apiValue,
    };
    if (group != null) {
      body['group'] = group.apiValue;
    }
    if (icon != null && icon.isNotEmpty) {
      body['icon'] = icon;
    }
    if (color != null && color.isNotEmpty) {
      body['color'] = color;
    }
    if (parentId != null) {
      body['parentId'] = parentId;
    }
    final data = await _client.post('/api/categories', body: body);
    return Category.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(int categoryId) async {
    await _client.delete('/api/categories/$categoryId');
  }

  List<Category> _parseList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Category.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }
    return [];
  }
}
