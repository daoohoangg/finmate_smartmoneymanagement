import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/categories/services/category_service.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/categories/models/category.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late CategoryService categoryService;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    categoryService = CategoryService(client: mockApiClient);
  });

  group('CategoryService', () {
    final mockUserCategoryJson = {
      'id': 1,
      'name': 'User Food',
      'type': 'EXPENSE',
      'systemCategory': false,
    };

    final mockSystemCategoryJson = {
      'id': 2,
      'name': 'System Transport',
      'type': 'EXPENSE',
      'systemCategory': true,
    };

    test('getCategories fetches user and system categories', () async {
      when(() => mockApiClient.get('/api/categories'))
          .thenAnswer((_) async => [mockUserCategoryJson]);
      when(() => mockApiClient.get('/api/categories/system'))
          .thenAnswer((_) async => [mockSystemCategoryJson]);

      final result = await categoryService.getCategories();

      expect(result.length, 2);
      expect(result.first.isSystemCategory, true); // System categories come first
      expect(result.last.isSystemCategory, false);
      expect(result.last.name, 'User Food');
      verify(() => mockApiClient.get('/api/categories')).called(1);
      verify(() => mockApiClient.get('/api/categories/system')).called(1);
    });

    test('getCategories filters by type', () async {
      when(() => mockApiClient.get('/api/categories?type=INCOME'))
          .thenAnswer((_) async => []); // Empty user income list
      when(() => mockApiClient.get('/api/categories/system'))
          .thenAnswer((_) async => [mockSystemCategoryJson]); // Expense category

      final result = await categoryService.getCategories(type: CategoryType.income);

      expect(result, isEmpty); // Because the system one is expense
      verify(() => mockApiClient.get('/api/categories?type=INCOME')).called(1);
    });

    test('createCategory posts data and returns Category', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => mockUserCategoryJson);

      final result = await categoryService.createCategory(
        name: 'User Food',
        type: CategoryType.expense,
        group: CategoryGroup.necessary,
      );

      expect(result, isA<Category>());
      expect(result.id, 1);
      verify(() => mockApiClient.post(
            '/api/categories',
            body: {
              'name': 'User Food',
              'type': 'EXPENSE',
              'group': 'NECESSARY',
            },
          )).called(1);
    });

    test('deleteCategory calls delete correctly', () async {
      when(() => mockApiClient.delete(any())).thenAnswer((_) async {});

      await categoryService.deleteCategory(1);

      verify(() => mockApiClient.delete('/api/categories/1')).called(1);
    });
  });
}
